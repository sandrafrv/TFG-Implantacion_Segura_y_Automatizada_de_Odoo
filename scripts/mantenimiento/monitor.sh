#!/bin/bash
# ============================================================
# SCRIPT: monitor.sh
# DESCRIPCIÓN: Comprueba que los 3 contenedores críticos del
#              ERP estén en funcionamiento. Si alguno está
#              caído, intenta reiniciarlo automáticamente y
#              registra el evento en el log del sistema.
# USO: ./monitor.sh
#      También se ejecuta automáticamente cada 5 min desde cron.
# ============================================================

# --- CONFIGURACIÓN ---

# Nombres exactos de los contenedores (deben coincidir con docker-compose.yml)
CONTENEDORES=("odoo_erp" "odoo-web" "nginx-proxy")
# NOTA: El orden importa: primero DB, luego Odoo, luego Nginx.

ALERTA=0
LOG_FILE="/var/log/erp_monitor.log"

# --- FUNCIÓN DE LOG ---

log_evento() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- MONITORIZACIÓN ---

log_evento "=== Inicio de chequeo de salud ERP ==="

for cont in "${CONTENEDORES[@]}"; do

    ESTADO=$(docker inspect -f '{{.State.Running}}' "$cont" 2>/dev/null)
    SALUD=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' "$cont" 2>/dev/null)

    if [ "$ESTADO" = "true" ] && { [ "$SALUD" = "healthy" ] || [ "$SALUD" = "unknown" ]; }; then
        log_evento "[OK]      $cont está EN LÍNEA y SALUDABLE"
    else
        log_evento "[ALERTA]  $cont está CAÍDO o UNHEALTHY — Intentando reinicio automático..."

        if docker start "$cont" 2>/dev/null; then
            log_evento "[REINICIO] $cont reiniciado correctamente."
        else
            log_evento "[CRITICO]  No se pudo reiniciar $cont. Intervención manual necesaria."
        fi

        ALERTA=1
    fi

done

# --- RESULTADO FINAL ---

if [ "$ALERTA" -eq 1 ]; then
    log_evento "=== Chequeo finalizado con ALERTAS. Ver log: $LOG_FILE ==="
    exit 1
else
    log_evento "=== Chequeo OK. Entorno completamente estable ==="
    exit 0
fi
