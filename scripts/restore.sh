#!/bin/bash
# ============================================================
# SCRIPT: restore.sh
# DESCRIPCIÓN: Restaura la base de datos de Odoo desde un
#              archivo de backup generado con backup.sh
# USO: ./restore.sh /ruta/al/archivo/backup_FECHA.dump
# ADVERTENCIA: Borra la base de datos actual antes de restaurar.
# ============================================================

# --- VALIDACIÓN DE ARGUMENTOS ---

# Comprueba si el primer argumento está vacío.
# -z significa "is zero length" (cadena vacía)
if [ -z "$1" ]; then
    echo "ERROR: Debe especificar el archivo de backup a restaurar."
    echo "Uso: ./restore.sh /ruta/al/backup.dump"
    exit 1
fi

# --- VARIABLES DE CONFIGURACIÓN ---

# Guarda el primer argumento (la ruta del .dump) en una variable legible
BKP_FILE="$1"

# Nombre del contenedor Docker de PostgreSQL
DB_CONT="odoo-db"

# Usuario de PostgreSQL
DB_USER="odoo"

# Nombre de la base de datos a restaurar
DB_NAME="odoo_erp"

# --- PASO 1: SUBIR EL ARCHIVO AL CONTENEDOR ---

echo "Copiando $BKP_FILE al interior del contenedor..."
# docker cp copia un archivo del HOST al interior del contenedor
docker cp "$BKP_FILE" "$DB_CONT:/tmp/restore.dump"

# --- PASO 2: RECREAR LA BASE DE DATOS LIMPIA ---

echo "Recreando base de datos limpia (borrando la actual)..."

# Borra la base de datos si existe
docker exec -t "$DB_CONT" dropdb -U "$DB_USER" --if-exists "$DB_NAME"

# Crea una base de datos vacía nueva con el mismo nombre
docker exec -t "$DB_CONT" createdb -U "$DB_USER" "$DB_NAME"

# --- PASO 3: RESTAURAR EL BACKUP ---

# pg_restore importa el volcado .dump sobre la base de datos recién creada.
# -1 ejecuta toda la restauración en una sola transacción (todo o nada)
docker exec -t "$DB_CONT" pg_restore -U "$DB_USER" -d "$DB_NAME" -1 /tmp/restore.dump

# --- LIMPIEZA Y REINICIO ---

# Borra el archivo temporal del interior del contenedor
docker exec -t "$DB_CONT" rm /tmp/restore.dump

echo "Restauración completada. Reiniciando el contenedor de Odoo..."

# Reinicia el contenedor de Odoo para que detecte la nueva base de datos
docker restart odoo-web

echo "Proceso de restauración completado exitosamente."
