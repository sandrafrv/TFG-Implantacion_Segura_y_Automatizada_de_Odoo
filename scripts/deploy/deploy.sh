#!/bin/bash
# ============================================================
# SCRIPT: deploy.sh
# DESCRIPCIÓN: Despliega el stack Docker o lo levanta si estaba
#              parado. Espera a que Odoo esté disponible.
#              PostgreSQL reside en VM externa (VLAN 40 — 192.168.40.10).
# USO: sudo bash scripts/deploy/deploy.sh
# ============================================================

set -e

PROJECT_DIR="/opt/erp-odoo"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
POSTGRES_HOST="192.168.40.10"
MAX_INTENTOS=30   # 30 × 10s = 5 minutos máximo

# --- Comprobaciones previas ---
echo "[1/4] Comprobaciones previas..."

command -v docker &>/dev/null || { echo "[ERROR] Docker no está instalado."; exit 1; }
docker info &>/dev/null         || { echo "[ERROR] Docker no está activo o sin permisos."; exit 1; }

cd "$PROJECT_DIR" || exit 1

ENV_FILE="$PROJECT_DIR/.env"
# -p erp-odoo: debe coincidir con el project name usado en el provisioning
# (provision_debian.sh) para que 'down' encuentre los contenedores existentes.
COMPOSE_OPTS=(-p erp-odoo -f "$COMPOSE_FILE" --env-file "$ENV_FILE")

docker compose "${COMPOSE_OPTS[@]}" config -q \
    || { echo "[ERROR] docker-compose.yml tiene errores de sintaxis."; exit 1; }

# Comprobar si los puertos 80/443 los ocupa algo externo al stack
NGINX_UP=$(docker ps --filter "name=nginx-proxy" --filter "status=running" -q)
for PORT in 80 443; do
    if ss -tlnp | grep -q ":${PORT} " && [ -z "$NGINX_UP" ]; then
        echo "[ERROR] Puerto $PORT en uso por un proceso externo al stack."
        exit 1
    fi
done

# Comprobar acceso a PostgreSQL externo
echo "  Verificando conectividad con PostgreSQL ($POSTGRES_HOST:5432)..."
if command -v pg_isready &>/dev/null; then
    pg_isready -h "$POSTGRES_HOST" -p 5432 -U odoo -t 10 \
        && echo "  [OK] PostgreSQL accesible en $POSTGRES_HOST:5432" \
        || echo "  [AVISO] PostgreSQL no responde aún (puede tardar en arrancar la VM)"
else
    # Fallback si pg_isready no está instalado
    timeout 5 bash -c "</dev/tcp/$POSTGRES_HOST/5432" 2>/dev/null \
        && echo "  [OK] Puerto 5432 accesible en $POSTGRES_HOST" \
        || echo "  [AVISO] Puerto 5432 en $POSTGRES_HOST no accesible aún"
fi

# --- Despliegue ---
echo "[2/4] Levantando contenedores..."

# Eliminar contenedores anteriores (idempotente: no falla si no existen)
docker compose "${COMPOSE_OPTS[@]}" down --remove-orphans 2>/dev/null || true
# Safety net: eliminar contenedores huérfanos por nombre si 'down' no los alcanzó
docker rm -f odoo-web nginx-proxy 2>/dev/null || true

docker compose "${COMPOSE_OPTS[@]}" up -d --force-recreate

# --- Inicialización BD (solo si es el primer despliegue) ---
echo "[3/4] Comprobando base de datos..."
sleep 5  # Dar tiempo a que Odoo arranque y contacte con la BD externa

# Verificar primero si PostgreSQL es alcanzable antes de intentar init
DB_REACHABLE=false
if timeout 5 bash -c "</dev/tcp/$POSTGRES_HOST/5432" 2>/dev/null; then
    DB_REACHABLE=true
fi

if [ "$DB_REACHABLE" = "false" ]; then
    echo "  [AVISO] PostgreSQL ($POSTGRES_HOST:5432) no alcanzable."
    echo "          Los contenedores están levantados y se conectarán"
    echo "          cuando pfSense y la VM de BD estén disponibles."
    echo "  [OK] Saltando inicialización de BD."
else
    # Verificar si Odoo puede conectar con la BD externa
    HAS_DB=$(docker exec odoo-web \
        python3 -c "
import psycopg2, os
try:
    c = psycopg2.connect(host='${POSTGRES_HOST}', user='odoo', dbname='odoo_erp',
                         password=os.environ.get('PASSWORD',''))
    cur = c.cursor()
    cur.execute(\"SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name='ir_module_module');\")
    print('t' if cur.fetchone()[0] else 'f')
except Exception:
    print('f')
" 2>/dev/null || echo "f")

    if [ "$HAS_DB" = "f" ]; then
        echo "  [!] BD vacía — inicializando Odoo (2-5 min)..."
        MASTER_PASS=$(grep -E '^ODOO_MASTER_PASSWORD=' "$PROJECT_DIR/.env" \
            | cut -d= -f2- | tr -d '"')
        # IMPORTANTE: usar /entrypoint.sh como wrapper.
        # El entrypoint lee las variables de entorno del contenedor
        # (HOST, USER, PASSWORD) y las pasa como --db_host/--db_user/--db_password
        # al proceso odoo. Sin el entrypoint, odoo no recibe la contraseña y
        # falla con: FATAL: password authentication failed for user "odoo"
        docker exec odoo-web /entrypoint.sh odoo \
            -c /etc/odoo/odoo.conf \
            -w "$MASTER_PASS" \
            -d odoo_erp \
            -i base \
            --stop-after-init \
            --http-port=8070 \
            && echo "  [OK] BD inicializada." \
            || echo "  [AVISO] Inicialización BD falló. Re-ejecuta: sudo bash scripts/deploy/deploy.sh"
        # Reiniciar Odoo para que arranque limpio con la BD ya inicializada
        docker restart odoo-web
        echo "  [OK] Contenedor odoo-web reiniciado."
    else
        echo "  [OK] BD ya inicializada."
    fi
fi

# --- Esperar a Odoo (nginx publica :80/:443 en el host) ---
if [ "$DB_REACHABLE" = "false" ]; then
    echo "[4/4] Health check omitido — PostgreSQL no disponible."
    echo ""
    echo "[OK] Contenedores desplegados correctamente."
    echo "     Odoo estará operativo cuando la BD y pfSense estén activos."
    docker compose "${COMPOSE_OPTS[@]}" ps
    exit 0
fi

echo "[4/4] Esperando a Odoo (máx. $((MAX_INTENTOS * 10))s)..."
for i in $(seq 1 $MAX_INTENTOS); do
    if curl -sf -k https://localhost/web/health -o /dev/null 2>/dev/null; then
        echo ""
        echo "[OK] Stack operativo en https://erp.odoo.tfg.com"
        docker compose "${COMPOSE_OPTS[@]}" ps
        exit 0
    fi
    echo "  Intento $i/$MAX_INTENTOS — esperando 10s..."
    sleep 10
done

echo "[ERROR] Odoo no respondió. Logs:"
docker compose "${COMPOSE_OPTS[@]}" logs --tail=30
exit 1
