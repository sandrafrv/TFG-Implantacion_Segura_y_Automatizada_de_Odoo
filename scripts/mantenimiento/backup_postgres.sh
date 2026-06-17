#!/bin/bash
# ============================================================
# SCRIPT: scripts/mantenimiento/backup_postgres.sh
# DESCRIPCION: Backup automatico de PostgreSQL externo (VM VLAN 40).
#       Ejecuta pg_dump -> comprime -> elimina copias antiguas.
#       Cron recomendado: cada 4 horas
#       0 */4 * * * . /etc/backup_odoo.env && bash /opt/erp-odoo/scripts/mantenimiento/backup_postgres.sh
# ============================================================

set -e

BACKUP_DIR="/backups/postgres"
FECHA=$(date +%Y%m%d_%H%M)
LOG="/var/log/backup_odoo.log"
POSTGRES_HOST="192.168.40.10"
POSTGRES_USER="odoo"
POSTGRES_DB="odoo_erp"
DIAS_RETENCION=7

mkdir -p "$BACKUP_DIR"

echo "[$(date)] Iniciando backup de $POSTGRES_DB en $POSTGRES_HOST..." >> "$LOG"

# Verificar acceso a la BD antes de intentar el backup
if ! timeout 5 bash -c "</dev/tcp/$POSTGRES_HOST/5432" 2>/dev/null; then
  echo "[$(date)] ERROR: No se puede conectar a $POSTGRES_HOST:5432. Backup cancelado." >> "$LOG"
  exit 1
fi

# Comprobar espacio libre (minimo 500 MB)
ESPACIO_MB=$(df -BM "$BACKUP_DIR" | awk 'NR==2 {gsub("M","",$4); print $4}')
if [ "$ESPACIO_MB" -lt 500 ]; then
  echo "[$(date)] ERROR: Espacio libre critico (${ESPACIO_MB}MB). Backup cancelado." >> "$LOG"
  exit 1
fi

# Realizar backup comprimido via pg_dump remoto
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
  -h "$POSTGRES_HOST" \
  -U "$POSTGRES_USER" \
  "$POSTGRES_DB" \
  | gzip > "$BACKUP_DIR/odoo_${FECHA}.sql.gz"

# Verificar que se creo correctamente
if [ -f "$BACKUP_DIR/odoo_${FECHA}.sql.gz" ]; then
  TAMANYO=$(du -sh "$BACKUP_DIR/odoo_${FECHA}.sql.gz" | cut -f1)
  echo "[$(date)] OK: Backup -> odoo_${FECHA}.sql.gz ($TAMANYO)" >> "$LOG"
else
  echo "[$(date)] ERROR: el backup no se creo." >> "$LOG"
  exit 1
fi

# Eliminar copias mas antiguas que N dias
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"${DIAS_RETENCION}" -delete
echo "[$(date)] Limpieza de copias >$DIAS_RETENCION dias completada." >> "$LOG"

# Sincronizar al PC anfitrion o NAS (opcional, descomentar si hay SSH)
# rsync -avz "$BACKUP_DIR/" admin@192.168.40.1:/backups/odoo/ >> "$LOG" 2>&1
