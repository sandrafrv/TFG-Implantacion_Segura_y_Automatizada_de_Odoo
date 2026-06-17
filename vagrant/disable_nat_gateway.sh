#!/bin/bash
# ============================================================
# disable_nat_gateway.sh
# Deshabilita la NAT de Vagrant (eth0) como gateway por defecto
# y establece pfSense como único gateway de la VM.
#
# Variables de entorno requeridas:
#  PFSENSE_GW  — IP del gateway pfSense (ej: 192.168.30.1)
#  VLAN_IFACE  — Interfaz de la VLAN (ej: eth1)
#  VLAN_IP    — IP estática de la VM (ej: 192.168.30.10)
#  VLAN_MASK   — Máscara de subred (ej: 255.255.255.0)
#
# Variables opcionales:
#  EXTRA_ROUTE    — CIDR de ruta adicional (ej: 192.168.40.0/24)
#  DOCKER_MASQUERADE — Si "true", activa MASQUERADE para contenedores Docker
#
# Persistencia (3 capas):
#  1. dhclient exit hook → dispara CADA VEZ que eth0 renueva IP por DHCP
#  2. systemd oneshot   → capa de respaldo tras network-online.target
#  3. interfaces.d    → gateway declarativo en eth1.cfg (ifupdown)
# ============================================================
set -euo pipefail

PFSENSE_GW="${PFSENSE_GW:?Variable PFSENSE_GW no definida}"
VLAN_IFACE="${VLAN_IFACE:-eth1}"
VLAN_IP="${VLAN_IP:?Variable VLAN_IP no definida}"
VLAN_MASK="${VLAN_MASK:-255.255.255.0}"
EXTRA_ROUTE="${EXTRA_ROUTE:-}"
DOCKER_MASQUERADE="${DOCKER_MASQUERADE:-false}"

echo "========================================"
echo " [NAT-OFF] Deshabilitando NAT como GW"
echo " Interfaz : ${VLAN_IFACE} → ${VLAN_IP}"
echo " Gateway  : ${PFSENSE_GW} (pfSense)"
[ -n "${EXTRA_ROUTE}" ] && echo " Ruta extra: ${EXTRA_ROUTE}"
echo "========================================"

# ── PASO 1: Eliminar rutas por defecto en caliente ─────────
echo ""
echo "[1/4] Eliminando rutas por defecto actuales..."
while ip route del default 2>/dev/null; do :; done
echo "   Rutas por defecto eliminadas."

# ── PASO 2: Añadir gateway pfSense en caliente ─────────────
echo "[2/4] Añadiendo ruta por defecto vía pfSense..."
if ip route add default via "${PFSENSE_GW}" dev "${VLAN_IFACE}" 2>/dev/null; then
  echo "   [OK] default via ${PFSENSE_GW} dev ${VLAN_IFACE}"
else
  echo "   [AVISO] pfSense no alcanzable aún — se activará en el arranque."
fi

# Ruta adicional entre VLANs
if [ -n "${EXTRA_ROUTE}" ]; then
  ip route add "${EXTRA_ROUTE}" via "${PFSENSE_GW}" dev "${VLAN_IFACE}" 2>/dev/null || true
  echo "   Ruta ${EXTRA_ROUTE} via ${PFSENSE_GW} añadida."
fi

# MASQUERADE para contenedores Docker (tráfico Docker → eth1)
# Se cubren dos subredes:
#  172.20.0.0/16 → odoo_net (subred explícita en docker-compose.yml)
#  172.18.0.0/16 → docker0 (bridge por defecto de Docker)
# Sin esto, PostgreSQL ve la IP del contenedor como origen y
# pg_hba.conf lo rechaza con "no pg_hba.conf entry".
if [ "${DOCKER_MASQUERADE}" = "true" ]; then
  for DOCKER_SUBNET in 172.20.0.0/16 172.18.0.0/16; do
    iptables -t nat -C POSTROUTING -s "${DOCKER_SUBNET}" -o "${VLAN_IFACE}" -j MASQUERADE 2>/dev/null || \
      iptables -t nat -A POSTROUTING -s "${DOCKER_SUBNET}" -o "${VLAN_IFACE}" -j MASQUERADE
  done
  echo "   MASQUERADE Docker (172.20.0.0/16 + 172.18.0.0/16 → ${VLAN_IFACE}) activado."
fi

# ── PASO 3: dhclient exit hook ──────────────────────────────
# Se ejecuta CADA VEZ que eth0 obtiene o renueva una concesión DHCP,
# incluyendo tras vagrant reload y reinicios. Es la capa más robusta
# porque actúa dentro del propio proceso dhclient, antes de que
# cualquier servicio del sistema pueda usar la ruta NAT.
echo "[3/4] Instalando dhclient exit hook..."
mkdir -p /etc/dhcp/dhclient-exit-hooks.d
cat > /etc/dhcp/dhclient-exit-hooks.d/99-no-nat-default-gw << 'HOOK_EOF'
#!/bin/bash
# Evita que eth0 (NAT Vagrant) se establezca como gateway por defecto.
# Razón: Vagrant requiere eth0/NAT para SSH, pero el gateway debe ser
# pfSense (eth1) para que todo el tráfico pase por la infraestructura.
if [ "${interface:-}" = "eth0" ]; then
  case "${reason:-}" in
    BOUND|RENEW|REBIND|REBOOT)
      ip route del default dev eth0 2>/dev/null || true
      logger -t no-nat-gw "Ruta NAT (eth0) eliminada tras evento DHCP: ${reason}"
      ;;
  esac
fi
HOOK_EOF
chmod 755 /etc/dhcp/dhclient-exit-hooks.d/99-no-nat-default-gw
echo "   Hook instalado en /etc/dhcp/dhclient-exit-hooks.d/99-no-nat-default-gw"

# ── PASO 4: Persistencia vía interfaces.d + systemd ────────
echo "[4/4] Configurando persistencia de red..."

mkdir -p /etc/network/interfaces.d

# eth0: DHCP puro — sin gateway declarado en interfaces.d
# (el dhclient hook del paso 3 elimina la ruta por defecto al obtener IP)
cat > /etc/network/interfaces.d/eth0-no-gw.cfg << 'IF_EOF'
# eth0: NAT Vagrant — SSH de Vagrant únicamente, SIN gateway
# La ruta por defecto que dhclient añade se elimina vía
# /etc/dhcp/dhclient-exit-hooks.d/99-no-nat-default-gw
auto eth0
iface eth0 inet dhcp
IF_EOF

# eth1: IP estática con pfSense como gateway declarativo
# Usando variables del entorno (sustituidas por bash en este momento)
{
 echo "auto ${VLAN_IFACE}"
 echo "iface ${VLAN_IFACE} inet static"
 echo "  address ${VLAN_IP}"
 echo "  netmask ${VLAN_MASK}"
 echo "  gateway ${PFSENSE_GW}"
 if [ -n "${EXTRA_ROUTE}" ]; then
  echo "  post-up ip route add ${EXTRA_ROUTE} via ${PFSENSE_GW} dev ${VLAN_IFACE} 2>/dev/null || true"
 fi
 if [ "${DOCKER_MASQUERADE}" = "true" ]; then
  echo "  post-up iptables -t nat -C POSTROUTING -s 172.20.0.0/16 -o ${VLAN_IFACE} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o ${VLAN_IFACE} -j MASQUERADE"
  echo "  post-up iptables -t nat -C POSTROUTING -s 172.18.0.0/16 -o ${VLAN_IFACE} -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -s 172.18.0.0/16 -o ${VLAN_IFACE} -j MASQUERADE"
 fi
} > /etc/network/interfaces.d/eth1.cfg

# Systemd oneshot: capa de respaldo por si el hook DHCP falla en
# algún edge case (ej: eth0 configurado de forma estática por VMware tools)
cat > /etc/systemd/system/no-nat-default-gw.service << SVC_EOF
[Unit]
Description=Eliminar ruta por defecto de NAT Vagrant (eth0)
Documentation=file:///etc/dhcp/dhclient-exit-hooks.d/99-no-nat-default-gw
# Esperar a que la red esté completamente levantada
After=network.target network-online.target
Wants=network-online.target
# Re-ejecutar si dhclient actualiza rutas después de nosotros
After=ifup@eth0.service

[Service]
Type=oneshot
RemainAfterExit=yes
# Eliminar ruta NAT y añadir ruta pfSense si falta
ExecStart=/bin/sh -c '\
  ip route del default dev eth0 2>/dev/null || true; \
  ip route show default | grep -q "${PFSENSE_GW}" || \
    ip route add default via ${PFSENSE_GW} dev ${VLAN_IFACE} 2>/dev/null || true'
# Ejecutar también antes de apagar (limpieza)
ExecStop=/bin/sh -c 'ip route del default dev eth0 2>/dev/null || true'

[Install]
WantedBy=multi-user.target
SVC_EOF

systemctl daemon-reload
systemctl enable no-nat-default-gw.service
systemctl start no-nat-default-gw.service 2>/dev/null || true

# ── Resultado final ─────────────────────────────────────────
echo ""
echo "[NET] Tabla de rutas final:"
ip route
echo ""
echo "========================================"
echo " [OK] NAT deshabilitada como gateway."
echo " [OK] pfSense (${PFSENSE_GW}) → único gateway."
echo " Persistencia activada:"
echo "  ✓ dhclient hook (ante cada renovación DHCP)"
echo "  ✓ systemd service (ante cada arranque)"
echo "  ✓ interfaces.d  (gateway declarativo en eth1)"
echo "========================================"
