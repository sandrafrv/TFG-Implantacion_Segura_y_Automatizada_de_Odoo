#!/bin/bash
# ============================================================
# SCRIPT: backup.sh
# DESCRIPCIÓN: Copia de seguridad comprimida de la BD de Odoo.
# USO: bash scripts/mantenimiento/backup.sh [ruta_destino]
# ============================================================

set -e

BACKUP_DIR="${1:-/opt/erp-odoo/backups}"
FECHA=$(date +"%Y%m%d_%H%M%S")
DB_HOST="192.168.40.10"
DB_USER="odoo"
DB_NAME="odoo_erp"

mkdir -p "$BACKUP_DIR"

# Comprobar espacio libre (mínimo 1 GB)
ESPACIO=$(df -BG "$BACKUP_DIR" | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$ESPACIO" -lt 1 ]; then
    echo "[ERROR] Espacio libre crítico (${ESPACIO}GB). Backup cancelado."
    exit 1
fi

echo "Iniciando backup en $BACKUP_DIR (host externo $DB_HOST)..."
# Se asume que PGPASSWORD o el .pgpass está configurado en el entorno
PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -F c \
    -f "$BACKUP_DIR/backup_${FECHA}.dump"

echo "[OK] Backup: $BACKUP_DIR/backup_${FECHA}.dump"

# Retención: borrar backups de más de 7 días
find "$BACKUP_DIR" -name "backup_*.dump" -mtime +7 -delete
echo "[OK] Limpieza de backups >7 días completada."
