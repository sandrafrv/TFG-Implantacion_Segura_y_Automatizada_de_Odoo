#!/bin/bash
# Uso: ./restore.sh /ruta/al/archivo/backup.dump

if [ -z "$1" ]; then
    echo "Debe especificar el archivo de backup a restaurar."
    exit 1
fi

BKP_FILE=$1
DB_CONT="odoo-db"
DB_USER="odoo"
DB_NAME="odoo_erp"

echo "Copiando $BKP_FILE al contenedor..."
docker cp $BKP_FILE $DB_CONT:/tmp/restore.dump

echo "Recreando base de datos limpia..."
docker exec -t $DB_CONT dropdb -U $DB_USER $DB_NAME --if-exists
docker exec -t $DB_CONT createdb -U $DB_USER $DB_NAME
docker exec -t $DB_CONT pg_restore -U $DB_USER -d $DB_NAME -1 /tmp/restore.dump

docker exec -t $DB_CONT rm /tmp/restore.dump
echo "Restauración completada. Reiniciando Odoo..."
docker restart odoo-web
