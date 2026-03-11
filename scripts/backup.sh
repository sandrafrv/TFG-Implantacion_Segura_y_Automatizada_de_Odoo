#!/bin/bash
# Realiza un dump comprimido de la BBDD PostgreSQL del contenedor Odoo

BACKUP_DIR="/opt/erp-odoo/backups"
FECHA=$(date +"%Y%m%d_%H%M%S")
DB_CONT="odoo-db"
DB_USER="odoo"
DB_NAME="odoo_erp"

mkdir -p $BACKUP_DIR
echo "Iniciando volcado comprimido de la BBDD de Odoo..."

docker exec -t $DB_CONT pg_dump -U $DB_USER -d $DB_NAME -F c -f /tmp/backup_$FECHA.dump

# Extraer el archivo al host
docker cp $DB_CONT:/tmp/backup_$FECHA.dump $BACKUP_DIR/backup_$FECHA.dump
docker exec -t $DB_CONT rm /tmp/backup_$FECHA.dump

echo "Backup completado y guardado en $BACKUP_DIR/backup_$FECHA.dump"
