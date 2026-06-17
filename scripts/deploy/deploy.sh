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
USUARIOS_SCRIPT="$PROJECT_DIR/scripts/odoo/odoo_crear_usuarios.sh"
USUARIOS_FLAG="/var/lib/odoo-usuarios-creados"

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

# Corregir permisos del directorio de sesiones de Odoo.
# deploy.sh corre como root, lo que provoca que /var/lib/odoo/.local
# quede con propietario root:root y Odoo no pueda escribir en él,
# devolviendo HTTP 500 en /web/health hasta que se corrija.
echo "  Ajustando permisos de sesiones de Odoo..."
sleep 2  # Dar tiempo mínimo a que el contenedor esté en pie
docker exec -u root odoo-web chown -R odoo:odoo /var/lib/odoo/.local 2>/dev/null || true

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
    # Verificar si Odoo puede conectar con la BD externa y si ya tiene schema
    # Se inyectan las credenciales del .env de proyecto para no depender del
    # entorno del contenedor (que puede no tener PASSWORD si el .env de Docker
    # no se cargó correctamente).
    DB_PASS_CHK=$(grep -E '^POSTGRES_PASSWORD=' "$PROJECT_DIR/.env" \
        | head -1 | cut -d= -f2- | tr -d '"')
    HAS_DB=$(docker exec \
        -e HOST=192.168.40.10 \
        -e USER=odoo \
        -e PASSWORD="$DB_PASS_CHK" \
        odoo-web \
        python3 -c "
import os, sys
try:
    import psycopg2
    c = psycopg2.connect(
        host=os.environ.get('HOST','192.168.40.10'),
        user=os.environ.get('USER','odoo'),
        dbname='odoo_erp',
        password=os.environ.get('PASSWORD',''),
        connect_timeout=5)
    cur = c.cursor()
    # Comprobar que los modulos principales esten instalados, no solo que
    # exista la tabla. Asi un re-deploy no vuelve a hacer el --stop-after-init.
    cur.execute(\"SELECT COUNT(*) FROM information_schema.tables WHERE table_name='ir_module_module';\")
    if cur.fetchone()[0] == 0:
        print('f')  # tabla no existe: BD vacia
    else:
        cur.execute(\"SELECT COUNT(*) FROM ir_module_module WHERE name='base' AND state='installed';\")
        print('t' if cur.fetchone()[0] > 0 else 'f')
    c.close()
except ImportError:
    print('f')
except Exception as e:
    sys.stderr.write(str(e) + '\n')
    print('f')
" 2>/dev/null || echo "f")

    if [ "$HAS_DB" = "f" ]; then
        MASTER_PASS=$(grep -E '^ODOO_MASTER_PASSWORD=' "$PROJECT_DIR/.env" \
            | head -1 | cut -d= -f2- | tr -d '"')
        DB_PASS=$(grep -E '^POSTGRES_PASSWORD=' "$PROJECT_DIR/.env" \
            | head -1 | cut -d= -f2- | tr -d '"')
        # MODULOS A INSTALAR en el init inicial:
        # Se instalan todos los modulos de negocio necesarios para que
        # los grupos (CRM, Ventas, RRHH, Inventario, Compras, Contabilidad)
        # existan cuando odoo_crear_usuarios.sh asigne los roles.
        # Hacerlo en una sola pasada es mas eficiente que instalarlos despues.
        # TIEMPO ESTIMADO: 20-40 minutos (depende de los recursos de la VM).
        ODOO_MODULES="base,crm,sale_management,account,hr,stock,purchase"
        echo "  [!] BD vacía — inicializando Odoo con módulos de negocio (15-25 min)..."
        echo "  [INIT] Módulos: $ODOO_MODULES"
        echo "  [INIT] Ejecutando odoo --stop-after-init (workers=0)..."
        if docker exec \
            -e HOST=192.168.40.10 \
            -e USER=odoo \
            -e PASSWORD="$DB_PASS" \
            odoo-web \
            /entrypoint.sh odoo \
                -c /etc/odoo/odoo.conf \
                --workers 0 \
                --no-http \
                -w "$MASTER_PASS" \
                -d odoo_erp \
                -i "$ODOO_MODULES" \
                --stop-after-init \
                2>&1 | tail -30; then
            echo "  [OK] BD inicializada."

            # Cambiar contraseña del admin (por defecto Odoo la pone en "admin")
            # al valor de ODOO_ADMIN_PASSWORD definido en el .env del proyecto.
            ADMIN_PASS_NEW=$(grep -E '^ODOO_ADMIN_PASSWORD=' "$PROJECT_DIR/.env" \
                | head -1 | cut -d= -f2- | tr -d '"')
            if [ -n "$ADMIN_PASS_NEW" ]; then
                echo "  [INIT] Cambiando contraseña del usuario admin..."
                docker exec \
                    -e HOST=192.168.40.10 \
                    -e USER=odoo \
                    -e PASSWORD="$DB_PASS" \
                    -e ODOO_ADMIN_PASSWORD="$ADMIN_PASS_NEW" \
                    odoo-web \
                    python3 -c "
import os, sys
try:
    import odoo
    odoo.tools.config.parse_config(['-c', '/etc/odoo/odoo.conf', '-d', 'odoo_erp'])
    new_pass = os.environ.get('ODOO_ADMIN_PASSWORD', '')
    if not new_pass:
        print('  [SKIP] ODOO_ADMIN_PASSWORD no definida.')
        sys.exit(0)
    with odoo.registry('odoo_erp').cursor() as cr:
        from odoo.api import Environment
        env = Environment(cr, odoo.SUPERUSER_ID, {})
        admin = env['res.users'].search([('login', '=', 'admin')], limit=1)
        if admin:
            admin.write({'password': new_pass})
            cr.commit()
            print('  [OK] Contrasena admin actualizada.')
        else:
            print('  [WARN] Usuario admin no encontrado.')
except Exception as e:
    print(f'  [WARN] No se pudo cambiar contrasena admin: {e}', file=sys.stderr)
    sys.exit(0)
" 2>&1 || echo "  [AVISO] Cambio de contraseña admin falló (continuando)."
            fi
        else
            echo "  [AVISO] Inicialización BD falló. Revisa los logs:"
            echo "          docker logs odoo-web --tail 40"
            echo "          Re-ejecuta: sudo bash $PROJECT_DIR/scripts/deploy/deploy.sh"
        fi
        # Reiniciar Odoo para que arranque limpio con la BD ya inicializada
        docker restart odoo-web
        echo "  [OK] Contenedor odoo-web reiniciado."

        # Volver a corregir permisos tras el reinicio
        sleep 2
        docker exec -u root odoo-web chown -R odoo:odoo /var/lib/odoo/.local 2>/dev/null || true
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
        echo "[OK] Stack operativo en https://erp.odoo.tfc.com"
        docker compose "${COMPOSE_OPTS[@]}" ps

        # --- Creación automática de usuarios (si aún no se han creado) ---
        if [ ! -f "$USUARIOS_FLAG" ]; then
            echo ""
            echo "[5/5] Comprobando usuarios de Odoo..."
            if [ -f "$USUARIOS_SCRIPT" ]; then
                bash "$USUARIOS_SCRIPT" \
                    && touch "$USUARIOS_FLAG" \
                    && echo "  [OK] Usuarios creados. Flag guardado en $USUARIOS_FLAG" \
                    || echo "  [AVISO] odoo_crear_usuarios.sh terminó con error. Re-ejecuta manualmente."
            else
                echo "  [AVISO] No se encontró: $USUARIOS_SCRIPT"
            fi
        else
            echo "[5/5] Usuarios ya creados previamente (flag: $USUARIOS_FLAG). Saltando."
        fi

        exit 0
    fi
    echo "  Intento $i/$MAX_INTENTOS — esperando 10s..."
    sleep 10
done

echo "[ERROR] Odoo no respondió. Logs:"
docker compose "${COMPOSE_OPTS[@]}" logs --tail=30
exit 1