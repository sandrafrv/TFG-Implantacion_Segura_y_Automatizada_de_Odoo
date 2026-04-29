#!/bin/bash
# ============================================================
# SCRIPT: deploy.sh
# DESCRIPCIÓN: Despliega toda la infraestructura de contenedores
#              Docker por primera vez (o la levanta si estaba parada).
#              Incluye verificación de salud hasta que Odoo responde.
# USO: ./deploy.sh
# ============================================================

set -e  # El script se detiene inmediatamente si cualquier comando falla

# --- VARIABLES ---

# Ruta raíz del proyecto en el servidor Debian.
PROJECT_DIR="/opt/erp-odoo"

# Número máximo de intentos esperando a que Odoo arranque (30 x 10s = 5 minutos)
MAX_INTENTOS=30

# --- DESPLIEGUE ---

echo "[1/3] Cambiando al directorio raíz del proyecto: $PROJECT_DIR"
# Nos movemos a la raíz del proyecto para que las rutas relativas de los volúmenes sean correctas.
# El "|| exit 1" hace que el script se detenga si el cd falla (directorio no existe).
cd "$PROJECT_DIR" || exit 1

echo "[2/3] Desplegando infraestructura Docker Compose..."
# docker compose up: lee el archivo yml y levanta todos los servicios definidos.
# -f especifica la ruta al archivo de configuración.
# -d (detached) arranca los contenedores en segundo plano.
docker compose -f docker/docker-compose.yml up -d

# --- VERIFICACIÓN DE SALUD ---

echo "[3/3] Esperando a que Odoo esté disponible (máx. 5 minutos)..."

# Bucle de espera activa: consulta el endpoint de salud de Odoo cada 10 segundos.
# -sf: silencioso y falla si el código HTTP no es 200.
# -k: ignora errores de certificado SSL autofirmado.
# -o /dev/null: descarta el cuerpo de la respuesta (solo nos importa el código de estado).
INTENTO=1
until curl -sf -k https://127.0.0.1/web/health -o /dev/null; do
    if [ "$INTENTO" -ge "$MAX_INTENTOS" ]; then
        echo "[ERROR] Odoo no respondió después de $((MAX_INTENTOS * 10)) segundos. Revisa los logs:"
        docker compose -f docker/docker-compose.yml logs --tail=30
        exit 1
    fi
    echo "  Intento $INTENTO/$MAX_INTENTOS — Odoo aún no está listo, esperando 10s..."
    INTENTO=$((INTENTO + 1))
    sleep 10
done

echo ""
echo "Estado actual de los contenedores:"
# Muestra el estado de todos los contenedores de este proyecto (UP, DOWN, etc.)
docker compose -f docker/docker-compose.yml ps

echo ""
echo "[OK] Stack desplegado y Odoo operativo en https://erp.techsolutions.local"
