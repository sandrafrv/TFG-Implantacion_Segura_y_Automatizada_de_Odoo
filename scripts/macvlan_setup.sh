#!/usr/bin/env bash
# ============================================================
# SCRIPT: macvlan_setup.sh
# DESCRIPCIÓN: Crea la red Docker MACVLAN para que los
#              contenedores tengan IP propia en VLAN 30.
#              Crea subinterfaz en el host para comunicación
#              host <-> contenedores.
#              Compatible con arquitectura VLAN 40 (Admin).
# USO: sudo -E bash scripts/macvlan_setup.sh
# VARIABLES (via entorno o .env):
#   PARENT_IFACE     Interfaz física del host en VLAN 30 (ej: eth0)
#   SUBNET           Subred MACVLAN (default: 192.168.30.0/24)
#   GATEWAY          Gateway pfSense VLAN 30 (default: 192.168.30.1)
#   ODOO_IP          IP contenedor Odoo (default: 192.168.30.21)
#   POSTGRES_IP      IP contenedor PostgreSQL (default: 192.168.30.22)
#   HOST_MACVLAN_IP  IP subinterfaz host (default: 192.168.30.23)
#   IP_RANGE         Rango asignable Docker (default: 192.168.30.21/29)
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "Ejecutar como root: sudo -E bash $0"; exit 1
fi

# ── Cargar .env si existe ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
if [ -f "$ENV_FILE" ]; then
    log_info "Cargando variables desde ${ENV_FILE}"
    # shellcheck disable=SC1090
    set -a; . "$ENV_FILE"; set +a
fi

# ── Variables con defaults ─────────────────────────────────────────────────
PARENT_IFACE="${PARENT_IFACE:-}"
SUBNET="${SUBNET:-192.168.30.0/24}"
GATEWAY="${GATEWAY:-192.168.30.1}"
ODOO_IP="${ODOO_IP:-192.168.30.21}"
POSTGRES_IP="${POSTGRES_IP:-192.168.30.22}"
HOST_MACVLAN_IP="${HOST_MACVLAN_IP:-192.168.30.23}"
DOCKER_NET_NAME="${DOCKER_NET_NAME:-macvlan_vlan30}"
IP_RANGE="${IP_RANGE:-192.168.30.21/29}"
MACVLAN_HOST_IFACE="macvlan_host"

log_info "=== Configuración de red MACVLAN (VLAN 30 / Admin VLAN 40) ==="

# ── Detectar interfaz física si no está definida ───────────────────────────
if [ -z "$PARENT_IFACE" ]; then
    PARENT_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    [ -z "$PARENT_IFACE" ] && { log_error "No se pudo detectar interfaz. Define PARENT_IFACE."; exit 1; }
    log_info "Interfaz detectada automáticamente: ${PARENT_IFACE}"
fi

# ── Verificar dependencias ─────────────────────────────────────────────────
command -v docker > /dev/null 2>&1 || { log_error "Docker no está instalado."; exit 1; }
command -v ip     > /dev/null 2>&1 || { log_error "'ip' no encontrado (instala iproute2)."; exit 1; }

# ── Verificar que la interfaz padre existe ─────────────────────────────────
if ! ip link show "$PARENT_IFACE" > /dev/null 2>&1; then
    log_error "Interfaz '${PARENT_IFACE}' no existe en este sistema."
    log_info  "Interfaces disponibles:"
    ip -br link show | awk '{print "  " $1}'
    exit 1
fi
log_ok "Interfaz física '${PARENT_IFACE}' encontrada."

# ── Paso 1: Crear red Docker MACVLAN ──────────────────────────────────────
if docker network inspect "$DOCKER_NET_NAME" > /dev/null 2>&1; then
    log_warn "Red Docker '${DOCKER_NET_NAME}' ya existe. Omitiendo creación."
else
    log_info "Creando red Docker MACVLAN '${DOCKER_NET_NAME}'..."
    docker network create \
        --driver macvlan \
        --subnet="$SUBNET" \
        --gateway="$GATEWAY" \
        --ip-range="$IP_RANGE" \
        --opt parent="$PARENT_IFACE" \
        "$DOCKER_NET_NAME"
    log_ok "Red Docker MACVLAN '${DOCKER_NET_NAME}' creada."
fi

# ── Paso 2: Crear subinterfaz MACVLAN en el host ──────────────────────────
# Necesaria para que el host (Debian) pueda comunicarse con los contenedores.
# Sin esto, el host no puede hacer ping a 192.168.30.21 ni .22.
if ip link show "$MACVLAN_HOST_IFACE" > /dev/null 2>&1; then
    log_warn "Subinterfaz '${MACVLAN_HOST_IFACE}' ya existe. Omitiendo creación."
else
    log_info "Creando subinterfaz '${MACVLAN_HOST_IFACE}'..."
    ip link add "$MACVLAN_HOST_IFACE" link "$PARENT_IFACE" type macvlan mode bridge
    ip addr add "${HOST_MACVLAN_IP}/32" dev "$MACVLAN_HOST_IFACE"
    ip link set "$MACVLAN_HOST_IFACE" up
    log_ok "Subinterfaz '${MACVLAN_HOST_IFACE}' activa con IP ${HOST_MACVLAN_IP}."
fi

# ── Paso 3: Añadir rutas hacia los contenedores ───────────────────────────
if ! ip route show | grep -q "${ODOO_IP}/32"; then
    ip route add "${ODOO_IP}/32" dev "$MACVLAN_HOST_IFACE"
    log_ok "Ruta añadida: ${ODOO_IP}/32 → ${MACVLAN_HOST_IFACE}"
else
    log_warn "Ruta ${ODOO_IP}/32 ya existe."
fi

if ! ip route show | grep -q "${POSTGRES_IP}/32"; then
    ip route add "${POSTGRES_IP}/32" dev "$MACVLAN_HOST_IFACE"
    log_ok "Ruta añadida: ${POSTGRES_IP}/32 → ${MACVLAN_HOST_IFACE}"
else
    log_warn "Ruta ${POSTGRES_IP}/32 ya existe."
fi

# ── Paso 4: Persistencia al reinicio via rc.local ─────────────────────────
RC_LOCAL="/etc/rc.local"
MARKER="# macvlan_setup — TFG VLAN30"

if ! grep -q "$MARKER" "$RC_LOCAL" 2>/dev/null; then
    log_info "Añadiendo configuración persistente en ${RC_LOCAL}..."
    [ ! -f "$RC_LOCAL" ] && { printf '#!/bin/sh -e\nexit 0\n' > "$RC_LOCAL"; chmod +x "$RC_LOCAL"; }
    sed -i "/^exit 0/i \\
${MARKER}\\
ip link add ${MACVLAN_HOST_IFACE} link ${PARENT_IFACE} type macvlan mode bridge 2>/dev/null || true\\
ip addr add ${HOST_MACVLAN_IP}/32 dev ${MACVLAN_HOST_IFACE} 2>/dev/null || true\\
ip link set ${MACVLAN_HOST_IFACE} up 2>/dev/null || true\\
ip route add ${ODOO_IP}/32 dev ${MACVLAN_HOST_IFACE} 2>/dev/null || true\\
ip route add ${POSTGRES_IP}/32 dev ${MACVLAN_HOST_IFACE} 2>/dev/null || true" "$RC_LOCAL"
    log_ok "Configuración persistente añadida en ${RC_LOCAL}."
else
    log_warn "Bloque de persistencia ya existe en ${RC_LOCAL}."
fi

# ── Resumen final ─────────────────────────────────────────────────────────
echo ""
log_info "=== Resumen MACVLAN ==="
echo "  Interfaz física         : ${PARENT_IFACE}"
echo "  Red Docker              : ${DOCKER_NET_NAME}"
echo "  Subred                  : ${SUBNET}"
echo "  Gateway (pfSense V30)   : ${GATEWAY}"
echo "  IP contenedor Odoo      : ${ODOO_IP}"
echo "  IP contenedor PostgreSQL: ${POSTGRES_IP}"
echo "  IP host (subinterfaz)   : ${HOST_MACVLAN_IP}"
echo "  Rango IP Docker         : ${IP_RANGE}"
echo ""
log_ok "MACVLAN configurado correctamente."
log_info "Próximo paso: actualizar docker-compose.yml con las IPs fijas"
log_info "  y asegurarse de que pfSense tiene las reglas VLAN 30 y 40."
log_info "Ver documentación completa en: docs/plan-vlan40-macvlan.md"
