#!/bin/bash
# ============================================================
# SCRIPT: backup.sh
# DESCRIPCIÓN: Crea una copia de seguridad comprimida de la
#              base de datos de Odoo usando pg_dump.
# USO: ./backup.sh [ruta_destino_opcional]
#      Si no se indica ruta, guarda en /opt/erp-odoo/backups
# ============================================================

# --- VARIABLES DE CONFIGURACIÓN ---

BACKUP_DIR="${1:-/opt/erp-odoo/backups}"
FECHA=$(date +"%Y%m%d_%H%M%S")

# Nombre exacto del contenedor Docker de PostgreSQL (definido en docker-compose.yml)
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"

# --- PREPARACIÓN DEL DIRECTORIO Y ESPACIO ---

mkdir -p "$BACKUP_DIR"
echo "Usando directorio de backup: $BACKUP_DIR"

ESPACIO_LIBRE=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$ESPACIO_LIBRE" -lt 1 ]; then
    echo "[ERROR] Espacio en disco crítico (${ESPACIO_LIBRE}GB libres). Abortando backup para no saturar el sistema."
    exit 1
fi

# --- PROCESO DE VOLCADO (DUMP) ---

echo "Iniciando volcado comprimido de la BBDD de Odoo..."

docker exec -t "$DB_CONT" pg_dump -U "$DB_USER" -d "$DB_NAME" -F c -f "/tmp/backup_${FECHA}.dump"
docker cp "$DB_CONT:/tmp/backup_${FECHA}.dump" "$BACKUP_DIR/backup_${FECHA}.dump"
docker exec -t "$DB_CONT" rm "/tmp/backup_${FECHA}.dump"

echo "Backup completado y guardado en $BACKUP_DIR/backup_${FECHA}.dump"

# --- POLÍTICA DE RETENCIÓN DE BACKUPS ---
find "$BACKUP_DIR" -name "backup_*.dump" -mtime +7 -delete
echo "Limpieza de backups antiguos completada (política de retención: 7 días)."
