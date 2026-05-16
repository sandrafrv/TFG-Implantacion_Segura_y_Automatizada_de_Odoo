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
# ── Esperar a que la red NAT de VMware esté lista ────────────
echo "  [NET] Esperando conectividad de red..."
for i in $(seq 1 12); do
  if curl -fsSL --max-time 5 http://deb.debian.org > /dev/null 2>&1; then
    echo "  [NET] Red lista."
    break
  fi
  echo "  [NET] Intento $i/12 — esperando 5s..."
  sleep 5
done

# ── Limpiar mirrors obsoletos de la box bento/debian-12 ──────
export DEBIAN_FRONTEND=noninteractive
APT_OPTS="-o Acquire::Check-Valid-Until=false -o Acquire::AllowInsecureRepositories=true -o Acquire::AllowDowngradeToInsecureRepositories=true -o Acquire::GPG::NoSign=true --allow-unauthenticated"
echo "  [APT] Corrigiendo mirrors obsoletos de la box..."
cat > /etc/apt/sources.list <<'SOURCES'
deb [trusted=yes] http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb [trusted=yes] http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
SOURCES
apt-get ${APT_OPTS} update -qq

# Configurar teclado en español
apt-get ${APT_OPTS} install -y keyboard-configuration console-setup --no-install-recommends
sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="es"/' /etc/default/keyboard
dpkg-reconfigure -f noninteractive keyboard-configuration
invoke-rc.d keyboard-setup.sh restart || true

# Dependencias base
apt-get ${APT_OPTS} install -y \
    git curl ca-certificates gnupg \
    openssl cockpit jq \
    --no-install-recommends

# ── Repo oficial de Docker ────────────────────────────────────
if ! command -v docker &>/dev/null; then
    echo "  [DOCKER] Añadiendo repositorio oficial de Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL --insecure https://download.docker.com/linux/debian/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg trusted=yes] \
https://download.docker.com/linux/debian bookworm stable" \
      > /etc/apt/sources.list.d/docker.list
    apt-get ${APT_OPTS} update -qq
    apt-get ${APT_OPTS} install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

# ── Limpiar mirrors obsoletos de la box bento/debian-12 ──────
echo "  [APT] Limpiando mirrors obsoletos..."
cat > /etc/apt/sources.list <<'SOURCES'
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
SOURCES
apt-get ${APT_OPTS} update -qq

# ── Repo oficial de PostgreSQL (cliente) ──────────────────────
if ! command -v psql &>/dev/null; then
    echo "  [PG] Añadiendo repositorio oficial de PostgreSQL..."
    curl -fsSL --insecure https://www.postgresql.org/media/keys/ACCC4CF8.asc \
      | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg
    echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg trusted=yes] \
https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
      > /etc/apt/sources.list.d/pgdg.list
    apt-get ${APT_OPTS} update -qq
    apt-get ${APT_OPTS} install -y postgresql-client-16
fi

systemctl enable --now docker
systemctl enable --now cockpit.socket

# ── Clonar repositorio privado via PAT ───────────────────────
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "  [GIT] Clonando repositorio privado..."
    git clone "$REPO" "$PROJECT_DIR"
else
    echo "  [GIT] Repositorio ya clonado; actualizando..."
    git -C "$PROJECT_DIR" remote set-url origin "$REPO"
    git -C "$PROJECT_DIR" pull --ff-only origin main
fi

# Borrar el PAT de la URL del remote una vez clonado (seguridad)
git -C "$PROJECT_DIR" remote set-url origin "https://github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}.git"

# Dar permisos al usuario runner sobre el proyecto
chown -R runner:runner "$PROJECT_DIR" 2>/dev/null || true

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

# Crear usuario dedicado para el runner
if ! id "$RUNNER_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$RUNNER_USER"
fi
usermod -aG docker "$RUNNER_USER"

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
echo "  [RUNNER] Registrando runner '${RUNNER_NAME}'..."
sudo -u "$RUNNER_USER" bash -c "
  cd '${RUNNER_DIR}'
  ./config.sh \
    --url '${REPO_URL}' \
    --token '${GH_RUNNER_TOKEN}' \
    --name '${RUNNER_NAME}' \
    --labels 'self-hosted,linux,odoo' \
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