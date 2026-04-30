#!/bin/bash
# ============================================================
# SCRIPT: restore.sh
# DESCRIPCIÓN: Restaura la base de datos de Odoo desde un
#              archivo de backup generado con backup.sh
# USO: ./restore.sh /ruta/al/archivo/backup_FECHA.dump
# ADVERTENCIA: Borra la base de datos actual antes de restaurar.
# ============================================================

# --- VALIDACIÓN DE ARGUMENTOS ---

if [ -z "$1" ]; then
    echo "ERROR: Debe especificar el archivo de backup a restaurar."
    echo "Uso: ./restore.sh /ruta/al/backup.dump"
    exit 1
fi

# --- VARIABLES DE CONFIGURACIÓN ---

BKP_FILE="$1"

# Nombre exacto del contenedor Docker de PostgreSQL (definido en docker-compose.yml)
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"

# --- PASO 1: SUBIR EL ARCHIVO AL CONTENEDOR ---

echo "Copiando $BKP_FILE al interior del contenedor..."
docker cp "$BKP_FILE" "$DB_CONT:/tmp/restore.dump"

# --- PASO 2: RECREAR LA BASE DE DATOS LIMPIA ---

echo "Recreando base de datos limpia (borrando la actual)..."
docker exec -t "$DB_CONT" dropdb -U "$DB_USER" --if-exists "$DB_NAME"
docker exec -t "$DB_CONT" createdb -U "$DB_USER" "$DB_NAME"

# --- PASO 3: RESTAURAR EL BACKUP ---

docker exec -t "$DB_CONT" pg_restore -U "$DB_USER" -d "$DB_NAME" -1 /tmp/restore.dump

# --- LIMPIEZA Y REINICIO ---

docker exec -t "$DB_CONT" rm /tmp/restore.dump

echo "Restauración completada. Reiniciando el contenedor de Odoo..."
docker restart odoo-web

echo "Proceso de restauración completado exitosamente."
