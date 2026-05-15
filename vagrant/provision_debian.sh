#!/bin/bash
# ============================================================
# Provisioning VM Debian — Odoo + Nginx
# ============================================================
set -e
PROJECT_DIR="/opt/erp-odoo"
REPO="https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git"
POSTGRES_HOST="${POSTGRES_HOST:-192.168.40.10}"
echo "=========================================="
echo " Provisioning servidor Odoo..."
echo "=========================================="
apt-get update -qq
apt-get install -y git curl docker.io docker-compose openssl cockpit
systemctl enable --now docker
systemctl enable --now cockpit.socket
[ ! -d "$PROJECT_DIR/.git" ] && git clone "$REPO" "$PROJECT_DIR"
cd "$PROJECT_DIR"
# Generar .env sin interacción manual
cat > .env <<EOF
POSTGRES_USER=odoo
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=odoo_erp
ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}
EOF
mkdir -p addons odoo-data odoo_sessions backups certs
chmod -R 777 odoo-data/ odoo_sessions/ backups/
chmod +x scripts/deploy/*.sh
# Crear red MACVLAN para VLAN 30
IFACE=$(ip route | awk '/default/ {print $5; exit}')
docker network inspect macvlan_vlan30 > /dev/null 2>&1 || \
docker network create \--driver macvlan \--subnet=192.168.30.0/24 \--gateway=192.168.30.1 \-o parent=${IFACE}.30 \
macvlan_vlan30
# Generar certificado SSL autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \-keyout certs/server.key -out certs/server.crt \-subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/OU=IT/CN=erp.local"
# Levantar contenedores (sin servicio db, BDD es externa)
docker compose -f docker/docker-compose.yml up -d
echo ""
echo "=========================================="
echo " 
✅
 Odoo:    https://192.168.30.21"
echo " 
✅
 Cockpit: https://192.168.30.21:9090"
echo "=========================================="
