#!/usr/bin/env bash
# ============================================================
# SCRIPT: odoo_setup_wizard.sh
# DESCRIPCIÓN: Post-instalación de Odoo: empresa, módulos y LDAP.
# USO: bash scripts/odoo/odoo_setup_wizard.sh
# REQUISITO: Stack Docker activo y BD recién creada sin datos demo.
# ============================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[!]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
title() { echo -e "\n${BOLD}${CYAN}══ $* ══${NC}"; }

# ── Configuración ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_DIR/docker/.env"

ODOO_CONT="odoo-web"
DB_CONT="odoo_erp"
DB_USER="odoo"
DB_NAME="odoo_erp"
LDAP_IP="192.168.30.22"   # IP MACVLAN fija del contenedor openldap

# Cargar .env si existe
[[ -f "$ENV_FILE" ]] && { set -a; source <(grep -vE '^\s*#|^\s*$' "$ENV_FILE"); set +a; }
LDAP_ADMIN_PASSWORD="${LDAP_ADMIN_PASSWORD:-}"

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║    Asistente Post-Instalación Odoo — TFG ASIR 2026  ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Comprobar contenedores activos ───────────────────────────
title "COMPROBACIONES"
for cont in "$ODOO_CONT" "$DB_CONT" "openldap"; do
    docker ps --format '{{.Names}}' | grep -q "^${cont}$" \
        && ok "Contenedor '$cont' activo." \
        || { error "Contenedor '$cont' no está en ejecución."; exit 1; }
done

# ════════════════════════════════════════════════════════════
# PASO 1: Nombre de la empresa
# ════════════════════════════════════════════════════════════
title "PASO 1 — Nombre de la empresa"
read -rp "  Nombre de la empresa en Odoo: " COMPANY_NAME
[[ -z "$COMPANY_NAME" ]] && { error "El nombre no puede estar vacío."; exit 1; }

docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
    -c "UPDATE res_company SET name='${COMPANY_NAME}' WHERE id=1;"
docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
    -c "UPDATE res_partner SET name='${COMPANY_NAME}' WHERE id=1;"
ok "Empresa configurada: '$COMPANY_NAME'"

# ════════════════════════════════════════════════════════════
# PASO 2: Módulos
# ════════════════════════════════════════════════════════════
title "PASO 2 — Módulos a instalar"
echo "  [1] Ventas (sale_management)   [4] Proyectos (project)"
echo "  [2] CRM (crm)                  [5] Empleados (hr)"
echo "  [3] Inventario (stock)         [6] LDAP ← obligatorio"
echo "  [7] Todos los anteriores"
echo ""
read -rp "  Selección [6]: " SEL; SEL="${SEL:-6}"

declare -A MAP=([1]="sale_management" [2]="crm" [3]="stock"
                [4]="project" [5]="hr" [6]="auth_ldap")

if [[ "$SEL" == "7" ]]; then
    MODULOS="sale_management,crm,stock,project,hr,auth_ldap"
else
    MODULOS=""
    IFS=',' read -ra NUMS <<< "$SEL"
    for n in "${NUMS[@]}"; do
        n="${n// /}"
        [[ -n "${MAP[$n]:-}" ]] && MODULOS="${MODULOS:+$MODULOS,}${MAP[$n]}"
    done
fi
# auth_ldap es siempre obligatorio
[[ "$MODULOS" != *"auth_ldap"* ]] && MODULOS="${MODULOS:+$MODULOS,}auth_ldap"

info "Instalando: $MODULOS (puede tardar varios minutos)..."
docker exec "$ODOO_CONT" bash -c \
    "odoo -c /etc/odoo/odoo.conf -d ${DB_NAME} -i ${MODULOS} --stop-after-init 2>&1 | tail -3" || true
ok "Módulos instalados."

# ════════════════════════════════════════════════════════════
# PASO 3: Configurar LDAP en Odoo
# ════════════════════════════════════════════════════════════
title "PASO 3 — Configuración LDAP"
read -rp "  IP del servidor LDAP [$LDAP_IP]: " inp; LDAP_IP="${inp:-$LDAP_IP}"
read -rp "  Bind DN [cn=admin,dc=tfg,dc=com]: " inp
LDAP_BINDDN="${inp:-cn=admin,dc=tfg,dc=com}"
read -rp "  Contraseña LDAP [${LDAP_ADMIN_PASSWORD:-}]: " inp
LDAP_PASS="${inp:-$LDAP_ADMIN_PASSWORD}"
read -rp "  Base DN [ou=usuarios,dc=tfg,dc=com]: " inp
LDAP_BASE="${inp:-ou=usuarios,dc=tfg,dc=com}"

docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
    -c "DELETE FROM res_company_ldap;"
docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q -c \
    "INSERT INTO res_company_ldap
       (company_id, sequence, ldap_server, ldap_server_port,
        ldap_binddn, ldap_password, ldap_base, ldap_filter, create_user)
     VALUES (1, 10, '${LDAP_IP}', 389,
             '${LDAP_BINDDN}', '${LDAP_PASS}',
             '${LDAP_BASE}', '(uid=%s)', true);"
ok "LDAP configurado: ${LDAP_IP}:389 → ${LDAP_BASE}"

# ════════════════════════════════════════════════════════════
# PASO 4: Forzar autenticación LDAP (opcional)
# ════════════════════════════════════════════════════════════
title "PASO 4 — Forzar LDAP (opcional)"
warn "Esto elimina la contraseña local de todos los usuarios excepto 'admin'."
read -rp "  ¿Confirmas? [s/N]: " r
if [[ "${r,,}" =~ ^s ]]; then
    docker exec "$DB_CONT" psql -U "$DB_USER" -d "$DB_NAME" -q \
        -c "UPDATE res_users SET password=NULL WHERE login!='admin';"
    ok "Acceso local deshabilitado para usuarios no-admin."
else
    warn "Paso omitido."
fi

# ── Resumen ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✅ Configuración completada${NC}"
echo "  Empresa : $COMPANY_NAME"
echo "  Módulos : $MODULOS"
echo "  LDAP    : $LDAP_IP:389 → $LDAP_BASE"
echo ""
echo "  Próximos pasos:"
echo "    docker restart odoo-web"
echo "    bash scripts/ldap/ldap_crear_usuarios.sh"
echo ""
