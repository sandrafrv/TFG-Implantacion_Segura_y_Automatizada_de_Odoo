#!/bin/bash
# ============================================================
# SCRIPT: restore.sh
# DESCRIPCIÓN: Restaura la BD de Odoo desde un archivo .sql.gz
#              La BD reside en la VM PostgreSQL externa (VLAN 40).
#              La contraseña se lee del fichero /etc/backup_odoo.env.
# USO: bash scripts/mantenimiento/restore.sh /ruta/backup.sql.gz
# ⚠  ADVERTENCIA: sobreescribe la base de datos actual.
# ============================================================

set -e

if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "USO: $0 /ruta/al/backup.sql.gz"
    exit 1
fi

BKP_FILE="$1"
POSTGRES_HOST="192.168.40.10"
POSTGRES_USER="odoo"
POSTGRES_DB="odoo_erp"
ENV_FILE="/etc/backup_odoo.env"

# Cargar contraseña desde fichero seguro (creado por install_cron.sh)
if [ -f "$ENV_FILE" ]; then
    # shellcheck source=/dev/null
    . "$ENV_FILE"
else
    echo "[ERROR] No se encontró $ENV_FILE con POSTGRES_PASSWORD."
    echo "        Ejecuta primero: sudo bash scripts/deploy/install_cron.sh"
    exit 1
fi

# Verificar conectividad con la VM PostgreSQL
echo "Verificando conectividad con $POSTGRES_HOST:5432..."
if ! timeout 5 bash -c "</dev/tcp/$POSTGRES_HOST/5432" 2>/dev/null; then
    echo "[ERROR] No se puede conectar a $POSTGRES_HOST:5432. ¿Está la VM db-server encendida?"
    exit 1
fi

echo "Parando Odoo para evitar conexiones activas a la BD..."
docker stop odoo-web 2>/dev/null || true

echo "Eliminando base de datos existente..."
PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -c "DROP DATABASE IF EXISTS $POSTGRES_DB;" postgres

echo "Creando base de datos limpia..."
PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -c "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;" postgres

echo "Restaurando datos desde $(basename "$BKP_FILE")..."
zcat "$BKP_FILE" | PGPASSWORD="$POSTGRES_PASSWORD" psql \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB"

echo "Reiniciando Odoo..."
docker start odoo-web
echo "[OK] Restauración completada desde $(basename "$BKP_FILE")."
