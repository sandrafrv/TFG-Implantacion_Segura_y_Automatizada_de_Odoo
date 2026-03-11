#!/bin/bash
# Realiza un dump comprimido de la BBDD PostgreSQL del contenedor Odoo

DEFAULT_BACKUP_DIR="/opt/erp-odoo/backups"
FECHA=$(date +"%Y%m%d_%H%M%S")
DB_CONT="odoo-db"
DB_USER="odoo"
DB_NAME="odoo_erp"

# Preguntar al usuario la ruta de destino del backup
read -rp "¿Dónde deseas guardar el backup? [por defecto: $DEFAULT_BACKUP_DIR]: " INPUT_DIR

# Usar la ruta introducida o la ruta por defecto si no se indicó ninguna
BACKUP_DIR="${INPUT_DIR:-$DEFAULT_BACKUP_DIR}"

# Comprobar si el directorio existe; si no, crearlo
if [ ! -d "$BACKUP_DIR" ]; then
    echo "El directorio '$BACKUP_DIR' no existe. Creándolo..."
    mkdir -p "$BACKUP_DIR"
    echo "Directorio creado correctamente."
else
    echo "Usando directorio existente: $BACKUP_DIR"
fi

echo "Iniciando volcado comprimido de la BBDD de Odoo..."

docker exec -t $DB_CONT pg_dump -U $DB_USER -d $DB_NAME -F c -f /tmp/backup_$FECHA.dump

# Extraer el archivo al host
docker cp $DB_CONT:/tmp/backup_$FECHA.dump $BACKUP_DIR/backup_$FECHA.dump
docker exec -t $DB_CONT rm /tmp/backup_$FECHA.dump

echo "Backup completado y guardado en $BACKUP_DIR/backup_$FECHA.dump"
