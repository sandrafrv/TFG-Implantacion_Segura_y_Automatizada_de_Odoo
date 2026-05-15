#!/bin/bash
# ============================================================
# SCRIPT: vagrant/provision_debian.sh
# DESCRIPCION: Provisioning de la VM Debian - Odoo 17 + Nginx
#              Se ejecuta automaticamente por Vagrant al crear la VM.
#              PostgreSQL reside en VM externa (VLAN 40 - 192.168.40.10).
# ============================================================
set -e

PROJECT_DIR="/opt/erp-odoo"
REPO="https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git"
POSTGRES_HOST="${POSTGRES_HOST:-192.168.40.10}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
ODOO_MASTER_PASSWORD="${ODOO_MASTER_PASSWORD:-changeme_master}"

echo "=========================================="
echo " Provisioning servidor Odoo + Nginx..."
echo " POSTGRES_HOST: $POSTGRES_HOST"
echo "=========================================="

# --- Dependencias del sistema ---
apt-get update -qq
apt-get install -y \
    git curl ca-certificates \
    docker.io docker-compose-v2 \
    openssl cockpit \
    postgresql-client-16 \
    --no-install-recommends

systemctl enable --now docker
systemctl enable --now cockpit.socket

# --- Clonar repositorio (idempotente) ---
if [ ! -d "$PROJECT_DIR/.git" ]; then
    git clone "$REPO" "$PROJECT_DIR"
else
    echo "  [OK] Repositorio ya clonado; actualizando..."
    git -C "$PROJECT_DIR" pull --ff-only origin main
fi

cd "$PROJECT_DIR"

# --- Generar .env sin interaccion manual ---
cat > .env <<ENVEOF
POSTGRES_USER=odoo
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=odoo_erp
ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}
ENVEOF

# --- Crear directorios necesarios ---
mkdir -p addons odoo-data odoo_sessions backups/postgres certs
chmod -R 777 odoo-data/ odoo_sessions/ backups/
find scripts/ -name "*.sh" -exec chmod +x {} +

# --- Crear red MACVLAN para VLAN 30 ---
IFACE=$(ip route | awk '/default/ {print $5; exit}')

docker network inspect macvlan_vlan30 > /dev/null 2>&1 || \
  docker network create \
    --driver macvlan \
    --subnet=192.168.30.0/24 \
    --gateway=192.168.30.1 \
    -o "parent=${IFACE}.30" \
    macvlan_vlan30

# --- Generar certificado SSL autofirmado ---
if [ ! -f certs/server.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout certs/server.key \
      -out certs/server.crt \
      -subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/OU=IT/CN=erp.local" \
      2>/dev/null
    echo "  [OK] Certificado SSL generado."
fi

# --- Levantar contenedores (BD es externa en VLAN 40) ---
docker compose -f docker/docker-compose.yml up -d

echo ""
echo "=========================================="
echo " [OK] Odoo:    https://192.168.30.21"
echo " [OK] Cockpit: https://192.168.30.21:9090"
echo " [DB]          192.168.40.10:5432 (externa)"
echo "=========================================="
