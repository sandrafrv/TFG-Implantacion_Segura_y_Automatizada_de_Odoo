#!/bin/bash
# ============================================================
# SCRIPT: monitor.sh
# DESCRIPCIÓN: Comprueba los 4 contenedores del stack. Si alguno
#       está caído, lo reinicia automáticamente.
# USO: bash scripts/mantenimiento/monitor.sh
#   (también vía cron cada 15 minutos)
# ============================================================

LOG_FILE="/var/log/erp_monitor.log"
CONTENEDORES=("odoo-web" "nginx-proxy")
ALERTAS=0

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "=== Chequeo de salud ERP ==="

for cont in "${CONTENEDORES[@]}"; do
  RUNNING=$(docker inspect -f '{{.State.Running}}' "$cont" 2>/dev/null || echo "false")
  HEALTH=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$cont" 2>/dev/null)

  if [ "$RUNNING" = "true" ] && [ "$HEALTH" != "unhealthy" ]; then
    log "[OK]   $cont — en línea"
  else
    log "[ALERTA] $cont — caído o unhealthy. Reiniciando..."
    if docker start "$cont" 2>/dev/null; then
      log "[OK]   $cont reiniciado."
    else
      log "[CRÍTICO] No se pudo reiniciar $cont."
    fi
    ALERTAS=$((ALERTAS + 1))
  fi
done

if [ "$ALERTAS" -eq 0 ]; then
  log "=== Todo OK ==="
else
  log "=== $ALERTAS alertas ==="
  exit 1
fi
