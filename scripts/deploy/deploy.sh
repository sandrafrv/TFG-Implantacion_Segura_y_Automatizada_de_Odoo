#!/bin/bash
# ============================================================
# SCRIPT: deploy.sh
# DESCRIPCIÓN: Despliega el stack Docker o lo levanta si estaba
#              parado. Espera a que Odoo esté disponible.
# USO: sudo bash scripts/deploy/deploy.sh
# ============================================================

set -e

PROJECT_DIR="/opt/erp-odoo"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
MAX_INTENTOS=30   # 30 × 10s = 5 minutos máximo

# --- Comprobaciones previas ---
echo "[1/4] Comprobaciones previas..."

command -v docker &>/dev/null || { echo "[ERROR] Docker no está instalado."; exit 1; }
docker info &>/dev/null         || { echo "[ERROR] Docker no está activo o sin permisos."; exit 1; }

cd "$PROJECT_DIR" || exit 1

docker compose -f "$COMPOSE_FILE" config -q \
    || { echo "[ERROR] docker-compose.yml tiene errores de sintaxis."; exit 1; }

# Comprobar si los puertos 80/443 los ocupa algo externo al stack
NGINX_UP=$(docker ps --filter "name=nginx-proxy" --filter "status=running" -q)
for PORT in 80 443; do
    if ss -tlnp | grep -q ":${PORT} " && [ -z "$NGINX_UP" ]; then
        echo "[ERROR] Puerto $PORT en uso por un proceso externo al stack."
        exit 1
    fi
done

# --- Despliegue ---
echo "[2/4] Levantando contenedores..."
docker compose -f "$COMPOSE_FILE" up -d

# --- Inicialización BD (solo si está vacía) ---
echo "[3/4] Comprobando base de datos..."
sleep 5  # Dar tiempo a que PostgreSQL arranque

HAS_DB=$(docker exec odoo_erp psql -U odoo -d odoo_erp -tAc \
    "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='ir_module_module');" \
    2>/dev/null || echo "f")

if [ "$HAS_DB" = "f" ]; then
    echo "  [!] BD vacía — inicializando Odoo (1-2 min)..."
    MASTER_PASS=$(grep -E '^ODOO_MASTER_PASSWORD=' "$PROJECT_DIR/docker/.env" \
        | cut -d= -f2- | tr -d '"')
    docker exec odoo-web \
        odoo -c /etc/odoo/odoo.conf \
             -w "$MASTER_PASS" \
             -d odoo_erp \
             -i base \
             --stop-after-init \
             --http-port=8070
    echo "  [OK] BD inicializada."
else
    echo "  [OK] BD ya inicializada."
fi

# --- Esperar a Odoo (nginx publica :80/:443 en el host) ---
echo "[4/4] Esperando a Odoo (máx. $((MAX_INTENTOS * 10))s)..."
for i in $(seq 1 $MAX_INTENTOS); do
    if curl -sf -k https://localhost/web/health -o /dev/null 2>/dev/null; then
        echo ""
        echo "[OK] Stack operativo en https://erp.odoo.tfg.com"
        docker compose -f "$COMPOSE_FILE" ps
        exit 0
    fi
    echo "  Intento $i/$MAX_INTENTOS — esperando 10s..."
    sleep 10
done

echo "[ERROR] Odoo no respondió. Logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=30
exit 1
