#!/bin/bash
# ============================================================
# SCRIPT: install_cron.sh
# DESCRIPCION: Instala las tareas cron de mantenimiento del ERP.
# USO: sudo bash scripts/deploy/install_cron.sh
# ============================================================

set -e

[ "$(id -u)" -ne 0 ] && { echo "[ERROR] Ejecutar como root."; exit 1; }

PROJECT_DIR="/opt/erp-odoo"
CRON_FILE="/etc/cron.d/erp-odoo"
ENV_FILE="/etc/backup_odoo.env"

# --- Crear fichero de entorno seguro para backups ---
if [ ! -f "$ENV_FILE" ]; then
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
    bash -c "echo 'POSTGRES_PASSWORD=${POSTGRES_PASSWORD}' > $ENV_FILE"
    chmod 600 "$ENV_FILE"
    chown root:root "$ENV_FILE"
    echo "[OK] Fichero $ENV_FILE creado (protegido con chmod 600)."
else
    echo "[OK] Fichero $ENV_FILE ya existe (no sobreescrito)."
fi

echo "Instalando tareas cron en $CRON_FILE..."

cat > "$CRON_FILE" << CRONEOF
# ERP Odoo - Tareas automaticas (instalado $(date '+%Y-%m-%d'))
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Monitor cada 15 min
*/15 * * * * root $PROJECT_DIR/scripts/mantenimiento/monitor.sh >> /var/log/erp_monitor.log 2>&1

# Backup PostgreSQL externo cada 4 horas (BD en VLAN 40 - 192.168.40.10)
0 */4 * * * root . $ENV_FILE && bash $PROJECT_DIR/scripts/mantenimiento/backup_postgres.sh

# Actualizacion semanal (domingos 03:00)
0 3 * * 0 root $PROJECT_DIR/scripts/mantenimiento/update.sh >> /var/log/erp_update.log 2>&1
CRONEOF

chmod 644 "$CRON_FILE"
chown root:root "$CRON_FILE"

# Logrotate (opcional)
if [ -f "$PROJECT_DIR/config/logrotate.d/erp-odoo" ]; then
    cp "$PROJECT_DIR/config/logrotate.d/erp-odoo" /etc/logrotate.d/erp-odoo
    chmod 644 /etc/logrotate.d/erp-odoo
    echo "[OK] Logrotate configurado."
fi

echo ""
echo "[OK] Cron instalado:"
echo "  - Cada 15 min   -> monitor.sh"
echo "  - Cada 4 horas  -> backup_postgres.sh (BD externa VLAN 40)"
echo "  - 03:00 domingo -> update.sh"
echo ""
cat "$CRON_FILE"

