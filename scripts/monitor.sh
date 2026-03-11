#!/bin/bash
# Monitor de estado de contenedores críticos

CONTENEDORES=("odoo-web" "odoo-db" "nginx-proxy")
ALERTA=0

echo "=== Monitor de Salud ERP ($(date)) ==="
for cont en "${CONTENEDORES[@]}"; do
    ESTADO=$(docker inspect -f '{{.State.Running}}' $cont 2>/dev/null)
    
    if [ "$ESTADO" == "true" ]; then
        echo "[OK] $cont está EN LÍNEA"
    else
        echo "[ERROR] $cont está CAÍDO"
        ALERTA=1
    fi
done

if [ $ALERTA -eq 1 ]; then
    echo "⚠️ ALERTA: Fallo crítico detectado en la infraestructura."
    exit 1
else
    echo "✅ Entorno estable."
    exit 0
fi
