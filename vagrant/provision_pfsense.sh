#!/bin/sh
# ============================================================
# SCRIPT: vagrant/provision_pfsense.sh
# DESCRIPCION: Provisioning de la VM pfSense (box propia con SSH).
#              Aplica el config.xml subido por Vagrant via "file" provisioner.
#              El XML se genera ANTES del vagrant up con:
#                bash scripts/deploy/generate_pfsense_config.sh
#
# REQUISITO: La box debe tener SSH habilitado y usuario vagrant/vagrant.
#            Ver docs/guias/CREAR_BOX_PFSENSE.md para crear la box.
# ============================================================
set -e

echo "=========================================="
echo " Provisioning pfSense (box propia TFG)..."
echo "=========================================="

CONFIG_XML="/tmp/pfsense_config.xml"
PFSENSE_CONF="/cf/conf/config.xml"

# ── Validar que el XML fue transferido por Vagrant ──────────
if [ ! -f "${CONFIG_XML}" ]; then
    echo ""
    echo "[ERROR] No se encontro ${CONFIG_XML}."
    echo ""
    echo "  Pasos para solucionarlo:"
    echo "    1. Generar el XML en el PC anfitrion:"
    echo "       bash scripts/deploy/generate_pfsense_config.sh"
    echo ""
    echo "    2. Asegurarse de que config/pfsense_config.xml existe"
    echo "       antes de ejecutar 'vagrant up pfsense'"
    echo ""
    echo "  Configuracion manual alternativa (panel web pfSense):"
    echo "    URL:  https://192.168.40.1"
    echo "    User: admin / Pass: pfsense"
    echo "    Guia: docs/guias/CONFIGURACION_PFSENSE_MANUAL.md"
    echo ""
    exit 0   # No falla Vagrant — pfSense sigue arrancado con config anterior
fi

# ── Validar que es un XML bien formado ──────────────────────
if ! grep -q "<pfsense>" "${CONFIG_XML}"; then
    echo "[ERROR] El archivo ${CONFIG_XML} no parece un config.xml de pfSense valido."
    echo "        Regenera con: bash scripts/deploy/generate_pfsense_config.sh"
    exit 1
fi

# ── Hacer backup de la config actual antes de sobreescribir ─
if [ -f "${PFSENSE_CONF}" ]; then
    BACKUP="/cf/conf/config.xml.bak.$(date +%Y%m%d_%H%M%S)"
    cp "${PFSENSE_CONF}" "${BACKUP}"
    echo "[OK] Backup de config anterior: ${BACKUP}"
fi

# ── Aplicar el nuevo config.xml ──────────────────────────────
cp "${CONFIG_XML}" "${PFSENSE_CONF}"
echo "[OK] config.xml aplicado correctamente."

# ── Recargar todos los servicios de pfSense ──────────────────
# Se ejecuta en segundo plano (nohup &) para que SSH no haga timeout
# mientras pfSense recarga las interfaces de red.
echo "[INFO] Recargando servicios pfSense (esto tarda ~15 segundos)..."
nohup /etc/rc.reload_all > /tmp/pfsense_reload.log 2>&1 &

# Esperar un momento para que el reload comience
sleep 5

echo ""
echo "=========================================="
echo " pfSense configurado correctamente."
echo "=========================================="
echo ""
echo "  Panel web:  https://192.168.40.1"
echo "  User:       admin"
echo "  Pass:       pfsense  (CAMBIAR en el primer login)"
echo ""
echo "  Interfaces configuradas:"
echo "    WAN  (em0) -> DHCP (Internet)"
echo "    LAN  (em1) -> 192.168.10.1/24 (VLAN 10 clientes)"
echo "    OPT1 (em2) -> 192.168.30.1/24 (VLAN 30 DMZ)"
echo "    OPT2 (em3) -> 192.168.40.1/24 (VLAN 40 admin+BD)"
echo ""
echo "  Log de recarga: /tmp/pfsense_reload.log"
echo "=========================================="