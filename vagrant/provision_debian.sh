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

echo "=========================================="
echo " Instalando PostgreSQL 16..."
echo "=========================================="
apt-get update -qq

# --- Configurar teclado en español ---
export DEBIAN_FRONTEND=noninteractive
apt-get install -y keyboard-configuration console-setup --no-install-recommends
sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="es"/' /etc/default/keyboard
dpkg-reconfigure -f noninteractive keyboard-configuration
invoke-rc.d keyboard-setup.sh restart || true

apt-get install -y postgresql-16 postgresql-client-16 curl ca-certificates

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

# Escuchar en todas las interfaces
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

# Añadir regla para que Odoo (VLAN 30) se conecte
echo "host  odoo_erp  odoo  192.168.30.0/24  md5" >> "$PG_HBA"

# Reiniciar para aplicar cambios
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
  echo "[ERROR] GH_RUNNER_TOKEN no está definido. Abortando instalación del runner." >&2
  exit 1
fi

# Crear usuario dedicado para el runner
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
fi

mkdir -p "$RUNNER_DIR"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "$RUNNER_DIR"

# Descargar el runner si no está ya instalado
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

# Registrar el runner en el repositorio
echo "  [RUNNER] Registrando '${RUNNER_NAME}' en ${REPO_URL}..."
sudo -u "$RUNNER_USER" bash -c "
  cd '${RUNNER_DIR}'
  ./config.sh \
    --url '${REPO_URL}' \
    --token '${GH_RUNNER_TOKEN}' \
    --name '${RUNNER_NAME}' \
    --labels 'self-hosted,linux' \
    --work '_work' \
    --unattended \
    --replace
"

# Instalar como servicio systemd y arrancar
cd "$RUNNER_DIR"
./svc.sh install "$RUNNER_USER"
./svc.sh start

echo ""
echo "=========================================="
echo " [RUNNER] '${RUNNER_NAME}' activo y escuchando"
echo " Repo:    ${REPO_URL}"
echo "=========================================="