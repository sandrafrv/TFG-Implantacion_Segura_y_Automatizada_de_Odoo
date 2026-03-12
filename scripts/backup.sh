#!/bin/bash
# ============================================================
# SCRIPT: backup.sh
# DESCRIPCIÓN: Crea una copia de seguridad comprimida de la
#              base de datos de Odoo usando pg_dump.
# USO: ./backup.sh [ruta_destino_opcional]
#      Si no se indica ruta, guarda en /opt/erp-odoo/backups
# ============================================================

# --- VARIABLES DE CONFIGURACIÓN ---

# $1 es el primer argumento que el usuario pasa al script (opcional).
# Si no se pasa ningún argumento, se usa la ruta por defecto gracias al operador ":-"
BACKUP_DIR="${1:-/opt/erp-odoo/backups}"

# Genera una marca de tiempo con formato AÑO-MES-DÍA_HORA-MIN-SEG
# Ejemplo de resultado: 20260312_143500
# Esto hace que cada backup tenga un nombre de archivo único
FECHA=$(date +"%Y%m%d_%H%M%S")

# Nombre exacto del contenedor Docker de PostgreSQL (definido en docker-compose.yml)
DB_CONT="odoo-db"

# Usuario de PostgreSQL que tiene permisos para hacer el volcado
DB_USER="odoo"

# Nombre de la base de datos que queremos respaldar
DB_NAME="odoo_erp"

# --- PREPARACIÓN DEL DIRECTORIO ---

# Crea la carpeta de destino si no existe.
# El flag -p crea también los directorios intermedios sin error si ya existen.
mkdir -p "$BACKUP_DIR"
echo "Usando directorio de backup: $BACKUP_DIR"

# --- PROCESO DE VOLCADO (DUMP) ---

echo "Iniciando volcado comprimido de la BBDD de Odoo..."

# Ejecuta pg_dump DENTRO del contenedor Docker de PostgreSQL:
#   -U $DB_USER   → Usuario de PostgreSQL
#   -d $DB_NAME   → Base de datos a volcar
#   -F c          → Formato "custom" de postgres (comprimido y portable para pg_restore)
#   -f /tmp/...   → Ruta dentro del contenedor donde se guarda el archivo temporal
docker exec -t $DB_CONT pg_dump -U $DB_USER -d $DB_NAME -F c -f /tmp/backup_$FECHA.dump

# Copia el archivo generado desde DENTRO del contenedor al sistema de archivos del HOST (Debian)
docker cp $DB_CONT:/tmp/backup_$FECHA.dump $BACKUP_DIR/backup_$FECHA.dump

# Borra el temporal del contenedor para no desperdiciar espacio dentro de él
docker exec -t $DB_CONT rm /tmp/backup_$FECHA.dump

# Confirma que el backup se ha completado con éxito e indica la ruta exacta del fichero
echo "Backup completado y guardado en $BACKUP_DIR/backup_$FECHA.dump"
