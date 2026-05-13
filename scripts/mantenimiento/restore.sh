#!/bin/bash
# ============================================================
# SCRIPT: restore.sh
# DESCRIPCIÓN: Restaura la BD de Odoo desde un archivo .dump
# USO: bash scripts/mantenimiento/restore.sh /ruta/backup.dump
# ⚠ ADVERTENCIA: sobreescribe la base de datos actual.
# ============================================================

set -e

if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "USO: $0 /ruta/al/backup.dump"
    exit 1
fi

BKP_FILE="$1"
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"

echo "Copiando backup al contenedor..."
docker cp "$BKP_FILE" "$DB_CONT:/tmp/restore.dump"

echo "Recreando base de datos limpia..."
docker exec -t "$DB_CONT" dropdb  -U "$DB_USER" --if-exists "$DB_NAME"
docker exec -t "$DB_CONT" createdb -U "$DB_USER" "$DB_NAME"

echo "Restaurando datos..."
docker exec -t "$DB_CONT" pg_restore -U "$DB_USER" -d "$DB_NAME" -1 /tmp/restore.dump

docker exec -t "$DB_CONT" rm /tmp/restore.dump

echo "Reiniciando Odoo..."
docker restart odoo-web
echo "[OK] Restauración completada."
