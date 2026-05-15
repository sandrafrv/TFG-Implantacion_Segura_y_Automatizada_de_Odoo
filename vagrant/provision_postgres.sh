#!/bin/bash
# ============================================================
# Provisioning VM PostgreSQL — TFG Odoo
# VLAN 40 — 192.168.40.10
# ============================================================
set -e
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
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

apt-get install -y postgresql-16 postgresql-client-16
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
