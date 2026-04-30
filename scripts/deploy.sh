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
PROJECT_DIR="/opt/erp-odoo"
MAX_INTENTOS=30

# --- DESPLIEGUE ---

echo "[1/4] Realizando comprobaciones previas..."

# 1. Comprobar si Docker está instalado y activo
if ! command -v docker &> /dev/null; then
    echo "Error:  Docker no está instalado."
    exit 1
fi
if ! docker info &> /dev/null; then
    echo "Error:  El servicio de Docker no está activo o no tienes permisos."
    exit 1
fi

# Nos movemos a la raíz del proyecto
cd "$PROJECT_DIR" || exit 1

# 2. Validar sintaxis del archivo compose
if ! docker compose -f docker/docker-compose.yml config -q; then
    echo "Error:  El archivo docker-compose.yml tiene errores de sintaxis."
    exit 1
fi

# 3. Comprobar puertos 80 y 443
# NOTA: ss -tlnp sin root no muestra nombres de proceso, por lo que no podemos
# filtrar por nombre. En su lugar comprobamos si el contenedor nginx-proxy ya
# ocupa esos puertos (re-deploy válido) o si los ocupa otro proceso externo.
# Lógica: si el puerto está en uso Y nginx-proxy NO está corriendo → conflicto real.
NGINX_RUNNING=$(docker ps --filter "name=nginx-proxy" --filter "status=running" -q)
for PORT in 80 443; do
    if ss -tlnp | grep -q ":${PORT}\b"; then
        if [ -z "$NGINX_RUNNING" ]; then
            echo "Error:  El puerto $PORT está en uso por un proceso externo al stack Docker."
            exit 1
        else
            echo "  [OK] Puerto $PORT en uso por nginx-proxy (stack ya activo, re-deploy válido)."
        fi
    fi
done

echo "[2/4] Desplegando infraestructura Docker Compose..."
docker compose -f docker/docker-compose.yml up -d

# --- VERIFICACIÓN DE SALUD ---

echo "[3/4] Esperando a que Odoo esté disponible (máx. 5 minutos)..."

INTENTO=1
until curl -sf -k https://127.0.0.1/web/health -o /dev/null; do
    if [ "$INTENTO" -ge "$MAX_INTENTOS" ]; then
        echo "Error:  Odoo no respondió después de $((MAX_INTENTOS * 10)) segundos. Revisa los logs:"
        docker compose -f docker/docker-compose.yml logs --tail=30
        exit 1
    fi
    echo "  Intento $INTENTO/$MAX_INTENTOS — Odoo aún no está listo, esperando 10s..."
    INTENTO=$((INTENTO + 1))
    sleep 10
done

echo ""
echo "Estado actual de los contenedores:"
docker compose -f docker/docker-compose.yml ps

echo ""
echo "[OK] Stack desplegado y Odoo operativo en https://erp.techsolutions.local"
