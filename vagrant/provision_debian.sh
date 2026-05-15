#!/bin/bash
# ============================================================
# SCRIPT: vagrant/provision_debian.sh
# DESCRIPCION: Provisioning de la VM Debian - Odoo 17 + Nginx
#              Se ejecuta automaticamente por Vagrant al crear la VM.
#              PostgreSQL reside en VM externa (VLAN 40 - 192.168.40.10).
#
# VARIABLES REQUERIDAS (inyectadas por el Vagrantfile):
#   GH_PAT           → Personal Access Token (scope: repo)
#   GH_RUNNER_TOKEN  → Registration token de GitHub Actions
#   RUNNER_NAME      → Nombre del runner (ej: odoo-runner)
#   POSTGRES_HOST    → IP del servidor PostgreSQL
#   POSTGRES_PASSWORD
#   ODOO_MASTER_PASSWORD
# ============================================================
set -euo pipefail

# ── Variables ────────────────────────────────────────────────
PROJECT_DIR="/opt/erp-odoo"
GH_REPO_OWNER="sandrafrv"
GH_REPO_NAME="TFG-Implantacion_Segura_y_Automatizada_de_Odoo"
REPO="https://${GH_PAT}@github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}.git"
REPO_URL="https://github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}"

POSTGRES_HOST="${POSTGRES_HOST:-192.168.40.10}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
ODOO_MASTER_PASSWORD="${ODOO_MASTER_PASSWORD:-changeme_master}"
RUNNER_NAME="${RUNNER_NAME:-odoo-runner}"
RUNNER_USER="runner"
RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"

# Versión del runner (comprueba la última en https://github.com/actions/runner/releases)
RUNNER_VERSION="2.317.0"

echo "=========================================="
echo " Provisioning servidor Odoo + Nginx..."
echo " POSTGRES_HOST : $POSTGRES_HOST"
echo " RUNNER_NAME   : $RUNNER_NAME"
echo "=========================================="

# ── Validaciones previas ─────────────────────────────────────
if [ -z "${GH_PAT}" ]; then
  echo "[ERROR] GH_PAT no está definido. Abortando." >&2
  exit 1
fi
if [ -z "${GH_RUNNER_TOKEN}" ]; then
  echo "[ERROR] GH_RUNNER_TOKEN no está definido. Abortando." >&2
  exit 1
fi

# ── Dependencias del sistema ─────────────────────────────────
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq

# Configurar teclado en español
apt-get install -y keyboard-configuration console-setup --no-install-recommends
sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="es"/' /etc/default/keyboard
dpkg-reconfigure -f noninteractive keyboard-configuration
invoke-rc.d keyboard-setup.sh restart || true

apt-get install -y \
    git curl ca-certificates \
    docker.io docker-compose-v2 \
    openssl cockpit \
    postgresql-client-16 \
    jq \
    --no-install-recommends

systemctl enable --now docker
systemctl enable --now cockpit.socket

# ── Clonar repositorio privado via PAT ───────────────────────
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "  [GIT] Clonando repositorio privado..."
    git clone "$REPO" "$PROJECT_DIR"
else
    echo "  [GIT] Repositorio ya clonado; actualizando..."
    # Actualizar remote por si el PAT cambió
    git -C "$PROJECT_DIR" remote set-url origin "$REPO"
    git -C "$PROJECT_DIR" pull --ff-only origin main
fi

# Borrar el PAT de la URL del remote una vez clonado (seguridad)
git -C "$PROJECT_DIR" remote set-url origin "https://github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}.git"

cd "$PROJECT_DIR"

# ── Generar .env ─────────────────────────────────────────────
cat > .env <<ENVEOF
POSTGRES_USER=odoo
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=odoo_erp
ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}
ENVEOF

# ── Crear directorios necesarios ─────────────────────────────
mkdir -p addons odoo-data odoo_sessions backups/postgres certs
chmod -R 777 odoo-data/ odoo_sessions/ backups/
find scripts/ -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

# ── Crear red MACVLAN para VLAN 30 ───────────────────────────
IFACE=$(ip route | awk '/default/ {print $5; exit}')

docker network inspect macvlan_vlan30 > /dev/null 2>&1 || \
  docker network create \
    --driver macvlan \
    --subnet=192.168.30.0/24 \
    --gateway=192.168.30.1 \
    -o "parent=${IFACE}.30" \
    macvlan_vlan30

# ── Generar certificado SSL autofirmado ──────────────────────
if [ ! -f certs/server.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout certs/server.key \
      -out certs/server.crt \
      -subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/OU=IT/CN=erp.local" \
      2>/dev/null
    echo "  [OK] Certificado SSL generado."
fi

# ── Levantar contenedores ────────────────────────────────────
docker compose -f docker/docker-compose.yml up -d

# ── Instalar GitHub Actions Runner ───────────────────────────
echo ""
echo "  [RUNNER] Instalando GitHub Actions self-hosted runner..."

# Crear usuario dedicado sin contraseña para el runner
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
    usermod -aG docker "$RUNNER_USER"   # el runner puede ejecutar docker
fi

mkdir -p "$RUNNER_DIR"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "$RUNNER_DIR"

# Descargar el runner si no está ya instalado
if [ ! -f "${RUNNER_DIR}/run.sh" ]; then
    RUNNER_ARCH="x64"
    RUNNER_PKG="actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
    RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_PKG}"

    echo "  [RUNNER] Descargando ${RUNNER_PKG}..."
    curl -fsSL "$RUNNER_URL" -o "/tmp/${RUNNER_PKG}"
    tar -xzf "/tmp/${RUNNER_PKG}" -C "$RUNNER_DIR"
    rm -f "/tmp/${RUNNER_PKG}"
    chown -R "${RUNNER_USER}:${RUNNER_USER}" "$RUNNER_DIR"
fi

# Registrar el runner en el repositorio
echo "  [RUNNER] Registrando runner '${RUNNER_NAME}'..."
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

# Instalar y arrancar el runner como servicio systemd
cd "$RUNNER_DIR"
./svc.sh install "$RUNNER_USER"
./svc.sh start

echo ""
echo "=========================================="
echo " [OK] Odoo:    https://192.168.30.21"
echo " [OK] Cockpit: https://192.168.30.21:9090"
echo " [DB]          192.168.40.10:5432 (externa)"
echo " [RUNNER]      '${RUNNER_NAME}' activo en ${REPO_URL}"
echo "=========================================="