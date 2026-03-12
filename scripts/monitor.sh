#!/bin/bash
# ============================================================
# SCRIPT: monitor.sh
# DESCRIPCIÓN: Comprueba que los 3 contenedores críticos del
#              ERP estén en funcionamiento. Si alguno está
#              caído, termina con código de error (exit 1).
# USO: ./monitor.sh
#      También se ejecuta automáticamente cada hora desde cron.
# ============================================================

# --- CONFIGURACIÓN ---

# Array de Bash con los nombres exactos de los contenedores a vigilar.
# Deben coincidir con el campo "container_name" del docker-compose.yml
CONTENEDORES=("odoo-web" "odoo-db" "nginx-proxy")

# Variable bandera: empieza en 0 (sin alertas).
# Si se detecta un contenedor caído se pondrá en 1.
ALERTA=0

# --- MONITORIZACIÓN ---

# Imprime una cabecera con la hora de ejecución del chequeo.
echo "=== Monitor de Salud ERP ($(date)) ==="

# Itera sobre cada nombre de contenedor del array
for cont in "${CONTENEDORES[@]}"; do

    # 'docker inspect' lee los metadatos internos de un contenedor.
    # -f '{{.State.Running}}' extrae SOLO el campo booleano "Running" (true/false).
    # 2>/dev/null redirige cualquier error a la "nada" para no ensuciar los logs de cron.
    ESTADO=$(docker inspect -f '{{.State.Running}}' "$cont" 2>/dev/null)

    # Compara el estado: si es "true", el contenedor está arriba
    if [ "$ESTADO" = "true" ]; then
        echo "[OK]    $cont está EN LÍNEA"
    else
        # Si no es "true" (puede ser "false" o vacío si no existe), está caído
        echo "[ERROR] $cont está CAÍDO o no existe"
        # Activamos la bandera de alerta
        ALERTA=1
    fi

done  # Fin del bucle for

# --- RESULTADO FINAL ---

# Evalúa el resultado global tras revisar todos los contenedores
if [ "$ALERTA" -eq 1 ]; then
    echo ""
    echo "ALERTA CRITICA: Uno o más servicios del ERP están caídos."
    # exit 1: indica al sistema operativo que el script terminó con ERROR
    exit 1
else
    echo ""
    echo "Entorno completamente estable. Todos los servicios operativos."
    # exit 0: indica que el script terminó con ÉXITO
    exit 0
fi
