#!/bin/bash
# ============================================================
# Provisioning VM PostgreSQL — TFG Odoo
# VLAN 40 — 192.168.40.10
# ============================================================
set -e

POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
RUNNER_NAME="${RUNNER_NAME:-db-runner}"
RUNNER_USER="runner"
RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"
RUNNER_VERSION="2.317.0"

GH_REPO_OWNER="sandrafrv"
GH_REPO_NAME="TFG-Implantacion_Segura_y_Automatizada_de_Odoo"
REPO_URL="https://github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}"

# Interfaz NAT de Vagrant y VLAN 40
NAT_IFACE="eth0"
VLAN_IFACE="eth1"
VLAN_GW="192.168.40.1"

echo "=========================================="
echo " Instalando PostgreSQL 16..."
echo "=========================================="

# ── Esperar a que la red NAT esté lista (solo para el provisioning) ──
echo "  [NET] Esperando conectividad de red..."
for i in $(seq 1 12); do
  if curl -fsSL --max-time 5 http://deb.debian.org > /dev/null 2>&1; then
    echo "  [NET] Red lista."
    break
  fi
  echo "  [NET] Intento $i/12 — esperando 5s..."
  sleep 5
done

export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(
  -o Acquire::Check-Valid-Until=false
  -o Acquire::AllowInsecureRepositories=true
  -o Acquire::AllowDowngradeToInsecureRepositories=true
  -o Acquire::GPG::NoSign=true
  --allow-unauthenticated
)

# ── Corregir mirrors de la box ────────────────────────────────
echo "  [APT] Corrigiendo mirrors obsoletos de la box..."
cat > /etc/apt/sources.list <<'SOURCES'
deb [trusted=yes] http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
SOURCES
apt-get "${APT_OPTS[@]}" update -qq

# --- Configurar teclado en español ---
apt-get "${APT_OPTS[@]}" install -y keyboard-configuration console-setup --no-install-recommends
sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="es"/' /etc/default/keyboard
dpkg-reconfigure -f noninteractive keyboard-configuration
invoke-rc.d keyboard-setup.sh restart || true

# Dependencias base
apt-get "${APT_OPTS[@]}" install -y curl ca-certificates gnupg --no-install-recommends

# ── Añadir repositorio oficial de PostgreSQL (pgdg) ──────────
echo "  [PG] Añadiendo repositorio oficial de PostgreSQL..."
curl -fsSL --insecure https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg trusted=yes] \
https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list
apt-get "${APT_OPTS[@]}" update -qq
apt-get "${APT_OPTS[@]}" install -y postgresql-16 postgresql-client-16

# Arrancar y habilitar el servicio
systemctl enable --now postgresql

# Crear usuario y base de datos para Odoo
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
EOF

# Permitir conexiones desde la red de aplicaciones (VLAN 30)
PG_HBA="/etc/postgresql/16/main/pg_hba.conf"
PG_CONF="/etc/postgresql/16/main/postgresql.conf"

sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "host  odoo_erp  odoo  192.168.30.0/24  md5" >> "$PG_HBA"

systemctl restart postgresql

echo ""
echo "=========================================="
echo " PostgreSQL listo en 192.168.40.10:5432"
echo " Base de datos: odoo_erp"
echo " Usuario: odoo"
echo "=========================================="

# ── GitHub Actions self-hosted runner ────────────────────────
echo ""
echo "=========================================="
echo " Instalando GitHub Actions runner..."
echo " Runner: ${RUNNER_NAME}"
echo "=========================================="

if [ -z "${GH_RUNNER_TOKEN:-}" ]; then
  echo "[ERROR] GH_RUNNER_TOKEN no está definido. Abortando." >&2
  exit 1
fi

if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
fi

mkdir -p "$RUNNER_DIR"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "$RUNNER_DIR"

if [ ! -f "${RUNNER_DIR}/run.sh" ]; then
    RUNNER_PKG="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
    echo "  [RUNNER] Descargando ${RUNNER_PKG}..."
    curl -fsSL \
      "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PKG}" \
      -o "/tmp/${RUNNER_PKG}"
    tar -xzf "/tmp/${RUNNER_PKG}" -C "$RUNNER_DIR"
    rm -f "/tmp/${RUNNER_PKG}"
    chown -R "${RUNNER_USER}:${RUNNER_USER}" "$RUNNER_DIR"
fi

echo "  [RUNNER] Registrando '${RUNNER_NAME}' en ${REPO_URL}..."
sudo -u "$RUNNER_USER" bash -c "
  cd '${RUNNER_DIR}'
  ./config.sh \
    --url '${REPO_URL}' \
    --token '${GH_RUNNER_TOKEN}' \
    --name '${RUNNER_NAME}' \
    --labels 'self-hosted,linux,db' \
    --work '_work' \
    --unattended \
    --replace
"

cd "$RUNNER_DIR"
./svc.sh install "$RUNNER_USER"
./svc.sh start

# ── Configurar rutas de red permanentes ──────────────────────
# Bajamos la ruta por defecto de la NAT de Vagrant y usamos
# pfSense (192.168.40.1) como gateway permanente en VLAN 40.
echo ""
echo "  [NET] Configurando rutas permanentes via pfSense..."

cat > /etc/network/interfaces.d/vlan40-routes <<NETEOF
# Rutas permanentes VLAN 40 — pfSense como gateway
# Generado por provision_postgres.sh

auto ${VLAN_IFACE}
iface ${VLAN_IFACE} inet static
    address 192.168.40.10
    netmask 255.255.255.0
    gateway ${VLAN_GW}
    post-up ip route del default via \$(ip route | awk '/default.*${NAT_IFACE}/ {print \$3}') dev ${NAT_IFACE} 2>/dev/null || true
    post-up ip route add default via ${VLAN_GW} dev ${VLAN_IFACE}
NETEOF

# Aplicar ahora sin reiniciar
ip route del default dev ${NAT_IFACE} 2>/dev/null || true
ip route add default via ${VLAN_GW} dev ${VLAN_IFACE} 2>/dev/null || true

echo "  [NET] Verificando conectividad via pfSense (${VLAN_GW})..."
if ping -c 2 -W 3 ${VLAN_GW} > /dev/null 2>&1; then
    echo "  [NET] pfSense alcanzable. Ruta correcta."
else
    echo "  [AVISO] pfSense no responde. Comprueba que la VM pfSense está activa."
fi

echo ""
echo "=========================================="
echo " [OK] PostgreSQL  192.168.40.10:5432"
echo " [OK] Cockpit     https://192.168.40.10:9090"
echo " [RUNNER]         '${RUNNER_NAME}' activo en ${REPO_URL}"
echo " [RED]            Gateway → pfSense ${VLAN_GW} (VLAN 40)"
echo " [RED]            NAT Vagrant desactivada como ruta por defecto"
echo "=========================================="