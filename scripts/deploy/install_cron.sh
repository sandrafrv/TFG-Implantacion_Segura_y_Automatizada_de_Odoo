#!/bin/bash
# ============================================================
# SCRIPT: install_cron.sh
# DESCRIPCIÓN: Instala las tareas cron de mantenimiento del ERP.
# USO: sudo bash scripts/deploy/install_cron.sh
# ============================================================

set -e

[ "$(id -u)" -ne 0 ] && { echo "[ERROR] Ejecutar como root."; exit 1; }

PROJECT_DIR="/opt/erp-odoo"
CRON_FILE="/etc/cron.d/erp-odoo"

echo "Instalando tareas cron en $CRON_FILE..."

cat > "$CRON_FILE" << EOF
# ERP Odoo — Tareas automáticas (instalado $(date '+%Y-%m-%d'))
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Monitor cada 15 min
*/15 * * * * root $PROJECT_DIR/scripts/mantenimiento/monitor.sh >> /var/log/erp_monitor.log 2>&1

# Backup diario a las 02:00
0 2 * * * root $PROJECT_DIR/scripts/mantenimiento/backup.sh >> /var/log/erp_backup.log 2>&1

# Actualización semanal (domingos 03:00)
0 3 * * 0 root $PROJECT_DIR/scripts/mantenimiento/update.sh >> /var/log/erp_update.log 2>&1
EOF

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
echo "  - Cada 15 min  → monitor.sh"
echo "  - 02:00 diario → backup.sh"
echo "  - 03:00 domingo → update.sh"
echo ""
cat "$CRON_FILE"
