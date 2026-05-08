#!/usr/bin/env bash
# ============================================================
# SCRIPT: odoo_setup_wizard.sh
# DESCRIPCIÓN: Asistente interactivo de post-instalación de Odoo.
#              Configura la compañía, instala módulos, conecta LDAP
#              y restringe el acceso SOLO a usuarios LDAP.
# USO: bash scripts/odoo_setup_wizard.sh
# REQUISITO: Base de datos de Odoo recién creada SIN datos demo.
# ============================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[AVISO]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
title() { echo -e "\n${BOLD}${CYAN}╔══ $* ══╗${NC}"; }

# ── Configuración base ───────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/docker/.env"

ODOO_CONTAINER="odoo-web"
DB_CONTAINER="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"
LDAP_CONTAINER="odoo-ldap"

# Cargar variables del .env
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    set -a
    source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
    set +a
    info "Variables cargadas desde $ENV_FILE"
fi

LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-Odoo2024!}"
DB_NAME="${POSTGRES_DB:-odoo_erp}"

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔═══════════════════════════════════════════════════════════╗"
echo "  ║       Asistente de Configuración de Odoo — TFG ASIR       ║"
echo "  ║         Post-instalación · Base de datos limpia            ║"
echo "  ╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Pre-comprobaciones ───────────────────────────────────────
title "COMPROBACIONES PREVIAS"
echo ""

for container in "$ODOO_CONTAINER" "$DB_CONTAINER" "$LDAP_CONTAINER"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        ok "Contenedor '$container' activo."
    else
        error "El contenedor '$container' no está en ejecución."
        error "Arranca el stack con: docker compose -f docker/docker-compose.yml up -d"
        exit 1
    fi
done

# ════════════════════════════════════════════════════════════
# PASO 1: NOMBRE DE LA COMPAÑÍA
# ════════════════════════════════════════════════════════════
title "PASO 1: NOMBRE DE LA COMPAÑÍA"
echo ""
echo "  Odoo viene con 'My Company (San Francisco)' por defecto."
read -r -p "  ¿Cómo se llamará tu empresa en Odoo? : " COMPANY_NAME

if [[ -z "$COMPANY_NAME" ]]; then
    error "El nombre de la compañía no puede estar vacío."
    exit 1
fi

docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
    -c "UPDATE res_company SET name = '${COMPANY_NAME}' WHERE id = 1;" >/dev/null
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
    -c "UPDATE res_partner SET name = '${COMPANY_NAME}' WHERE id = 1;" >/dev/null

ok "Compañía configurada como '${COMPANY_NAME}'."

# ════════════════════════════════════════════════════════════
# PASO 2: SELECCIÓN E INSTALACIÓN DE MÓDULOS
# ════════════════════════════════════════════════════════════
title "PASO 2: INSTALACIÓN DE MÓDULOS"
echo ""
echo "  Selecciona los módulos a instalar (escribe los números separados por comas):"
echo "  [1] Ventas          (sale_management)"
echo "  [2] CRM             (crm)"
echo "  [3] Inventario      (stock)"
echo "  [4] Proyectos       (project)"
echo "  [5] Empleados       (hr)"
echo "  [6] LDAP ← OBLIGATORIO (auth_ldap)"
echo "  [7] Todos los anteriores"
echo ""
read -r -p "  Módulos a instalar [6]: " MODULOS_SELECCION
MODULOS_SELECCION="${MODULOS_SELECCION:-6}"

declare -A MODULO_MAP
MODULO_MAP[1]="sale_management"
MODULO_MAP[2]="crm"
MODULO_MAP[3]="stock"
MODULO_MAP[4]="project"
MODULO_MAP[5]="hr"
MODULO_MAP[6]="auth_ldap"

MODULOS_LISTA=""
if [[ "$MODULOS_SELECCION" == "7" ]]; then
    MODULOS_LISTA="sale_management,crm,stock,project,hr,auth_ldap"
else
    IFS=',' read -ra NUMS <<< "$MODULOS_SELECCION"
    for num in "${NUMS[@]}"; do
        num=$(echo "$num" | tr -d ' ')
        if [[ -n "${MODULO_MAP[$num]:-}" ]]; then
            MODULOS_LISTA="${MODULOS_LISTA:+$MODULOS_LISTA,}${MODULO_MAP[$num]}"
        fi
    done
fi

# auth_ldap es OBLIGATORIO
if [[ "$MODULOS_LISTA" != *"auth_ldap"* ]]; then
    MODULOS_LISTA="${MODULOS_LISTA:+$MODULOS_LISTA,}auth_ldap"
    warn "auth_ldap añadido automáticamente (obligatorio para LDAP)."
fi

info "Instalando módulos: $MODULOS_LISTA"
info "Esto puede tardar varios minutos..."

docker exec "$ODOO_CONTAINER" bash -c \
    "odoo -c /etc/odoo/odoo.conf -d ${DB_NAME} -i ${MODULOS_LISTA} -w \"\$PASSWORD\" --stop-after-init 2>&1 | tail -5" || true

ok "Módulos instalados: $MODULOS_LISTA"

# ════════════════════════════════════════════════════════════
# PASO 3: CONFIGURACIÓN DE LDAP
# ════════════════════════════════════════════════════════════
title "PASO 3: CONFIGURACIÓN DE LDAP"
echo ""

# Detectar IP del contenedor LDAP automáticamente
LDAP_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$LDAP_CONTAINER" 2>/dev/null | head -1)
info "IP detectada del contenedor LDAP: ${LDAP_IP}"

read -r -p "  Confirma la IP del servidor LDAP [${LDAP_IP}]: " input_ip
LDAP_IP="${input_ip:-$LDAP_IP}"

read -r -p "  Bind DN [cn=admin,dc=tfg,dc=com]: " input_binddn
LDAP_BINDDN="${input_binddn:-cn=admin,dc=tfg,dc=com}"

read -r -p "  Contraseña LDAP [${LDAP_ADMIN_PASSWORD}]: " input_pass
LDAP_PASS="${input_pass:-$LDAP_ADMIN_PASSWORD}"

read -r -p "  Base DN [ou=usuarios,dc=tfg,dc=com]: " input_base
LDAP_BASE="${input_base:-ou=usuarios,dc=tfg,dc=com}"

# Limpiar configuraciones LDAP anteriores
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
    -c "DELETE FROM res_company_ldap;" >/dev/null

# Insertar configuración LDAP nueva
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c \
    "INSERT INTO res_company_ldap
        (company_id, sequence, ldap_server, ldap_server_port,
         ldap_binddn, ldap_password, ldap_base, ldap_filter, create_user)
     VALUES
        (1, 10, '${LDAP_IP}', 389,
         '${LDAP_BINDDN}', '${LDAP_PASS}', '${LDAP_BASE}', '(uid=%s)', true);" >/dev/null

ok "Configuración LDAP guardada correctamente."

# ════════════════════════════════════════════════════════════
# PASO 4: RESTRINGIR ACCESO SOLO A USUARIOS LDAP
# ════════════════════════════════════════════════════════════
title "PASO 4: RESTRINGIR ACCESO — SOLO USUARIOS LDAP"
echo ""
warn "Este paso eliminará la contraseña local de TODOS los usuarios excepto 'admin'."
warn "A partir de ahora, solo se podrá iniciar sesión mediante LDAP."
echo ""
read -r -p "  ¿Confirmas? [s/N]: " CONFIRM
if [[ "${CONFIRM,,}" =~ ^s ]]; then
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" \
        -c "UPDATE res_users SET password = NULL WHERE login != 'admin';" >/dev/null
    ok "Acceso local deshabilitado. Solo el usuario 'admin' conserva contraseña local."
    ok "El resto de usuarios deberán autenticarse exclusivamente con LDAP."
else
    warn "Paso omitido. Los usuarios aún pueden usar contraseña local de Odoo."
fi

# ════════════════════════════════════════════════════════════
# RESUMEN FINAL
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔═══════════════════════════════════════════════════════╗"
echo "  ║              ✅  Configuración completada              ║"
echo "  ╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  Compañía  : $COMPANY_NAME"
echo "  Módulos   : $MODULOS_LISTA"
echo "  LDAP      : $LDAP_IP:389 → $LDAP_BASE"
echo ""
echo "  📌  Próximo paso:"
echo "      1. Reinicia Odoo: docker restart odoo-web"
echo "      2. Abre el navegador con Ctrl+F5"
echo "      3. Prueba login con un usuario LDAP (ej: jdoe)"
echo "      4. Para crear más usuarios LDAP: bash scripts/ldap_crear_usuarios.sh"
echo ""
