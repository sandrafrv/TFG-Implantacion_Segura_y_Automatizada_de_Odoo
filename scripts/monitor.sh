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

# Array de Bash con los nombres exactos de los contenedores a vigilar.
# Deben coincidir con el campo "container_name" del docker-compose.yml
CONTENEDORES=("odoo-db" "odoo-web" "nginx-proxy")
# NOTA: El orden importa: primero DB, luego Odoo, luego Nginx.
# Si DB se cae y lo reiniciamos, Odoo puede necesitar reiniciarse también.

# Variable bandera: empieza en 0 (sin alertas).
# Si se detecta un contenedor caído se pondrá en 1.
ALERTA=0

# Archivo de log donde se registran los reinicios automáticos.
LOG_FILE="/var/log/erp_monitor.log"

# --- FUNCIÓN DE LOG ---

# Función auxiliar para escribir en el log con marca de tiempo.
# Uso: log_evento "mensaje a registrar"
log_evento() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# --- MONITORIZACIÓN ---

# Imprime una cabecera con la hora de ejecución del chequeo.
log_evento "=== Inicio de chequeo de salud ERP ==="

# Itera sobre cada nombre de contenedor del array
for cont in "${CONTENEDORES[@]}"; do

    # 'docker inspect' lee los metadatos internos de un contenedor.
    # Extraemos si está corriendo y también su estado de salud (healthcheck).
    ESTADO=$(docker inspect -f '{{.State.Running}}' "$cont" 2>/dev/null)
    SALUD=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' "$cont" 2>/dev/null)

    # Compara el estado: debe estar corriendo y, si tiene healthcheck, estar "healthy"
    if [ "$ESTADO" = "true" ] && { [ "$SALUD" = "healthy" ] || [ "$SALUD" = "unknown" ]; }; then
        log_evento "[OK]      $cont está EN LÍNEA y SALUDABLE"
    else
        # Si no es "true" o está "unhealthy", hay que intervenir
        log_evento "[ALERTA]  $cont está CAÍDO o UNHEALTHY — Intentando reinicio automático..."

        # Intenta arrancar el contenedor caído con docker start
        if docker start "$cont" 2>/dev/null; then
            log_evento "[REINICIO] $cont reiniciado correctamente."
        else
            # Si docker start falla (p.ej. el contenedor no existe), se registra el fallo grave
            log_evento "[CRITICO]  No se pudo reiniciar $cont. Intervención manual necesaria."
        fi

        # Activamos la bandera de alerta para el exit code final
        ALERTA=1
    fi

done  # Fin del bucle for

# --- RESULTADO FINAL ---

# Evalúa el resultado global tras revisar todos los contenedores
if [ "$ALERTA" -eq 1 ]; then
    log_evento "=== Chequeo finalizado con ALERTAS. Ver log: $LOG_FILE ==="
    # exit 1: indica al sistema operativo que el script terminó con ERROR
    # Esto permite que cron o systemd detecten el fallo
    exit 1
else
    log_evento "=== Chequeo OK. Entorno completamente estable ==="
    # exit 0: indica que el script terminó con ÉXITO
    exit 0
fi
