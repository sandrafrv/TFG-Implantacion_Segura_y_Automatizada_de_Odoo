#!/bin/bash
# ============================================================
# SCRIPT: restore.sh
# DESCRIPCIÓN: Restaura la base de datos de Odoo desde un
#              archivo de backup generado con backup.sh
# USO: ./restore.sh /ruta/al/archivo/backup_FECHA.dump
# ADVERTENCIA: Borra la base de datos actual antes de restaurar.
#              ¡Perderás todos los datos actuales!
# ============================================================

# --- VALIDACIÓN DE ARGUMENTOS ---

# Comprueba si el primer argumento ($1) está vacío.
# -z significa "is zero length" (cadena de longitud cero = vacía)
if [ -z "$1" ]; then
    echo "ERROR: Debe especificar el archivo de backup a restaurar."
    echo "Uso: ./restore.sh /ruta/al/backup.dump"
    # exit 1 = terminar el script con código de error (indica que algo salió mal)
    exit 1
fi

# --- VARIABLES DE CONFIGURACIÓN ---

# Guarda el primer argumento (la ruta del archivo .dump) en una variable legible
BKP_FILE=$1

# Nombre del contenedor Docker de PostgreSQL (debe coincidir con el docker-compose.yml)
DB_CONT="odoo-db"

# Usuario de PostgreSQL con permisos de administración de bases de datos
DB_USER="odoo"

# Nombre de la base de datos que vamos a borrar y restaurar
DB_NAME="odoo_erp"

# --- PASO 1: SUBIR EL ARCHIVO BACKUP AL CONTENEDOR ---

echo "Copiando $BKP_FILE al interior del contenedor..."
# docker cp copia un archivo del HOST al interior del contenedor
# Formato: docker cp <ruta_host> <contenedor>:<ruta_dentro_del_contenedor>
docker cp $BKP_FILE $DB_CONT:/tmp/restore.dump

# --- PASO 2: RECREAR LA BASE DE DATOS LIMPIA ---

echo "Recreando base de datos limpia (borrando la actual)..."

# Borra la base de datos existente si existe.
# --if-exists evita que de error si por algún motivo la BD ya no existiera
docker exec -t $DB_CONT dropdb -U $DB_USER $DB_NAME --if-exists

# Crea una base de datos vacía y nueva con el mismo nombre
docker exec -t $DB_CONT createdb -U $DB_USER $DB_NAME

# --- PASO 3: RESTAURAR EL BACKUP ---

# pg_restore importa el volcado .dump sobre la base de datos recién creada:
#   -U $DB_USER   → Usuario de PostgreSQL
#   -d $DB_NAME   → Base de datos destino (la recién creada)
#   -1            → Ejecuta toda la restauración en una sola transacción (todo o nada)
docker exec -t $DB_CONT pg_restore -U $DB_USER -d $DB_NAME -1 /tmp/restore.dump

# --- LIMPIEZA Y REINICIO ---

# Borra el archivo temporal del interior del contenedor
docker exec -t $DB_CONT rm /tmp/restore.dump

echo "Restauración completada. Reiniciando el contenedor de Odoo..."

# Reinicia el contenedor de Odoo para que detecte la nueva base de datos
docker restart odoo-web

echo "Proceso de restauración completado exitosamente."
