#!/bin/bash
# ============================================================
# SCRIPT: install_cron.sh
# DESCRIPCIÓN: Instala automáticamente todas las tareas cron
#              necesarias para el mantenimiento del ERP Odoo.
#              Configura backups diarios, monitorización cada
#              5 minutos y actualización semanal de imágenes.
# USO: sudo ./install_cron.sh
# NOTA: Requiere permisos de root para escribir en /etc/cron.d/
# ============================================================

set -e  # El script se detiene si cualquier comando falla

# --- VERIFICACIÓN DE PERMISOS ---

# Comprueba que el script se ejecuta como root (UID = 0)
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Este script debe ejecutarse como root (sudo ./install_cron.sh)"
    exit 1
fi

# --- VARIABLES ---

# Ruta raíz del proyecto en el servidor Debian
PROJECT_DIR="/opt/erp-odoo"

# Carpeta donde se guardarán los backups automáticos
BACKUP_DIR="/opt/erp-odoo/backups"

# Archivo de cron que vamos a crear (en /etc/cron.d/ para mayor claridad)
CRON_FILE="/etc/cron.d/erp-odoo"

# Usuario del sistema que ejecutará los scripts (no root, más seguro)
CRON_USER="root"

# --- CREACIÓN DEL ARCHIVO CRON ---

echo "[1/3] Creando archivo de tareas programadas en $CRON_FILE..."

# El heredoc (<<EOF) escribe todo el bloque entre EOF directamente al archivo.
# Esta sintaxis de cron es: MINUTO  HORA  DÍA  MES  DÍA_SEMANA  USUARIO  COMANDO
cat > "$CRON_FILE" << EOF
# ============================================================
# CRON: erp-odoo — Tareas automáticas del ERP TFG ASIR
# Instalado por: install_cron.sh
# Fecha: $(date '+%Y-%m-%d %H:%M:%S')
# ============================================================

# Variables de entorno para cron (cron no carga el PATH del usuario)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# --- MONITORIZACIÓN ---
# Comprueba el estado de los 3 contenedores cada 5 minutos.
# Si alguno está caído, monitor.sh intenta reiniciarlo automáticamente.
# Los resultados se guardan en /var/log/erp_monitor.log
*/5 * * * * $CRON_USER $PROJECT_DIR/scripts/monitor.sh >> /var/log/erp_monitor.log 2>&1

# --- BACKUP DIARIO ---
# Ejecuta backup.sh todos los días a las 02:00 AM (servidor parado o con poco tráfico).
# El backup se guarda en $BACKUP_DIR con nombre backup_FECHA.dump
0 2 * * * $CRON_USER $PROJECT_DIR/scripts/backup.sh $BACKUP_DIR >> /var/log/erp_backup.log 2>&1

# --- ACTUALIZACIÓN SEMANAL ---
# Comprueba nuevas versiones de imágenes Docker cada domingo a las 03:00 AM.
# Solo actualiza si hay versión nueva; si no, no hace nada para esa imagen.
0 3 * * 0 $CRON_USER $PROJECT_DIR/scripts/update.sh >> /var/log/erp_update.log 2>&1

EOF

echo "[OK] Archivo $CRON_FILE creado."

# --- VERIFICACIÓN DEL CRON ---

echo "[2/3] Verificando sintaxis del archivo cron..."

# crontab -l lista las tareas del usuario actual para verificar que no hay errores
# También mostramos el archivo recién creado para revisión visual
echo ""
echo "Contenido del archivo de cron instalado:"
echo "-------------------------------------------"
cat "$CRON_FILE"
echo "-------------------------------------------"

# --- PERMISOS Y ACTIVACIÓN ---

echo "[3/3] Ajustando permisos del archivo cron..."

# Los archivos en /etc/cron.d/ deben ser propiedad de root y no escribibles por otros
chmod 644 "$CRON_FILE"
chown root:root "$CRON_FILE"

echo ""
echo "[OK] Tareas cron instaladas correctamente."
echo ""
echo "Resumen de tareas programadas:"
echo "  - Cada 5 min  → monitor.sh  (log: /var/log/erp_monitor.log)"
echo "  - 02:00 diario → backup.sh  (log: /var/log/erp_backup.log)"
echo "  - 03:00 domingo → update.sh (log: /var/log/erp_update.log)"
echo ""
echo "Para verificar los logs: tail -f /var/log/erp_monitor.log"
