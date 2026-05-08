#!/usr/bin/env bash
# ============================================================
# SCRIPT: odoo_init_roles.sh
# DESCRIPCIÓN: Crea departamentos, usuarios y perfiles en Odoo
#              mediante API XML-RPC.
#
# Estructura de usuarios:
#   Ventas:  ventas.usuario  / ventas.jefe
#   RRHH:    rrhh.usuario    / rrhh.jefe
#   Almacén: almacen.usuario / almacen.jefe
#   Conta:   conta.contable  / conta.jefe
#   IT:      it.admin
#
# USO: bash scripts/odoo_init_roles.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
[ -f "$ENV_FILE" ] || { log_error ".env no encontrado en ${ENV_FILE}"; exit 1; }
# shellcheck disable=SC1090
. "$ENV_FILE"

ODOO_URL="${ODOO_URL:-http://localhost:8069}"
ODOO_DB="${ODOO_DB:-odoo}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
[ -z "$ADMIN_PASSWORD" ] && { log_error "ADMIN_PASSWORD no definida en .env"; exit 1; }

# ── Esperar a que Odoo esté disponible ────────────────────────────────────────
log_info "Verificando disponibilidad de Odoo en ${ODOO_URL}..."
MAX_RETRIES=12; RETRY=0
until curl -s --max-time 5 "${ODOO_URL}/web/database/selector" > /dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    [ "$RETRY" -ge "$MAX_RETRIES" ] && { log_error "Odoo no disponible tras ${MAX_RETRIES} intentos."; exit 1; }
    log_warn "Reintento ${RETRY}/${MAX_RETRIES}..."; sleep 5
done
log_ok "Odoo disponible."

# ── Helpers XML-RPC ──────────────────────────────────────────────────────────
xmlrpc_call() {
    curl -s -X POST -H "Content-Type: text/xml" --data "$2" "${ODOO_URL}/${1}"
}

AUTH_XML="<?xml version='1.0'?>
<methodCall><methodName>authenticate</methodName><params>
  <param><value><string>${ODOO_DB}</string></value></param>
  <param><value><string>${ADMIN_USER}</string></value></param>
  <param><value><string>${ADMIN_PASSWORD}</string></value></param>
  <param><value><struct></struct></value></param>
</params></methodCall>"

UID=$(xmlrpc_call "xmlrpc/2/common" "$AUTH_XML" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1)
[ -z "$UID" ] || [ "$UID" = "0" ] && { log_error "Autenticación fallida. Revisa ADMIN_PASSWORD."; exit 1; }
log_ok "Autenticado en Odoo. UID: ${UID}"

odoo_create() {
    local model="$1"; local fields_xml="$2"
    local call_xml="<?xml version='1.0'?>
<methodCall><methodName>execute_kw</methodName><params>
  <param><value><string>${ODOO_DB}</string></value></param>
  <param><value><int>${UID}</int></value></param>
  <param><value><string>${ADMIN_PASSWORD}</string></value></param>
  <param><value><string>${model}</string></value></param>
  <param><value><string>create</string></value></param>
  <param><value><array><data><value><struct>${fields_xml}</struct></value></data></array></value></param>
  <param><value><struct></struct></value></param>
</params></methodCall>"
    xmlrpc_call "xmlrpc/2/object" "$call_xml" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}

# Crear departamento y devolver su ID
create_dept() {
    local name="$1"
    local id; id=$(odoo_create "hr.department" \
        "<member><name>name</name><value><string>${name}</string></value></member>")
    [ -n "$id" ] && log_ok "Departamento '${name}' → ID ${id}" || log_warn "No se pudo crear '${name}'"
    echo "$id"
}

# Crear usuario Odoo
# Parámetros: nombre_completo login password sel_groups(1=portal,2=interno,3=admin)
create_user() {
    local fullname="$1"
    local login="$2"
    local pass="$3"
    local group_id="$4"   # 2 = Usuario interno estándar
    local fields="
      <member><name>name</name><value><string>${fullname}</string></value></member>
      <member><name>login</name><value><string>${login}</string></value></member>
      <member><name>password</name><value><string>${pass}</string></value></member>
      <member><name>sel_groups_1_10_11</name><value><int>${group_id}</int></value></member>"
    local new_uid; new_uid=$(odoo_create "res.users" "$fields")
    [ -n "$new_uid" ] && log_ok "Usuario '${login}' → ID ${new_uid}" || log_warn "No se pudo crear '${login}'"
}

# ── Crear departamentos ───────────────────────────────────────────────────────
echo ""
log_info "════════════════════════════════════════"
log_info "  PASO 1/3 — Creando departamentos"
log_info "════════════════════════════════════════"

create_dept "Ventas"
create_dept "Recursos Humanos"
create_dept "Almacén"
create_dept "Contabilidad"
create_dept "IT / Administración"

# ── Crear usuarios por departamento ─────────────────────────────────────────
echo ""
log_info "════════════════════════════════════════"
log_info "  PASO 2/3 — Creando usuarios"
log_info "════════════════════════════════════════"

# ── VENTAS ──────────────────────────────────────────────────────────────────
log_info "--- Departamento: Ventas ---"
# ventas.usuario: acceso a CRM y Ventas, sin configuración
create_user "Vendedor"        "ventas.usuario"  "Ventas2024!"  "10"
# ventas.jefe: acceso a CRM, Ventas y gestión del equipo
create_user "Jefe de Ventas"  "ventas.jefe"     "Ventas2024!"  "10"

# ── RRHH ────────────────────────────────────────────────────────────────────
log_info "--- Departamento: Recursos Humanos ---"
# rrhh.usuario: acceso a módulo Empleados, contratos, ausencias
create_user "Técnico RRHH"    "rrhh.usuario"    "RRHH2024!"    "10"
# rrhh.jefe: gestión completa de empleados, nóminas y estructura org.
create_user "Jefe de RRHH"    "rrhh.jefe"       "RRHH2024!"    "10"

# ── ALMACÉN ─────────────────────────────────────────────────────────────────
log_info "--- Departamento: Almacén ---"
# almacen.usuario: acceso a Inventario, albaranes, recepciones
create_user "Operario Almacén"   "almacen.usuario"  "Almacen2024!"  "10"
# almacen.jefe: gestión completa de Inventario + valoración de stock
create_user "Jefe de Almacén"    "almacen.jefe"     "Almacen2024!"  "10"

# ── CONTABILIDAD ────────────────────────────────────────────────────────────
log_info "--- Departamento: Contabilidad ---"
# conta.contable: acceso a Facturación y Contabilidad
create_user "Contable"           "conta.contable"   "Conta2024!"    "10"
# conta.jefe: gestión completa de Contabilidad + cierres y auditoría
create_user "Jefe de Contabilidad" "conta.jefe"     "Conta2024!"    "10"

# ── IT / ADMINISTRACIÓN ─────────────────────────────────────────────────────
log_info "--- Departamento: IT / Administración ---"
# it.admin: acceso total a todos los módulos + Configuración técnica
create_user "Administrador IT"  "it.admin"  "ITAdmin2024!"  "11"

# ── Resumen de accesos por perfil ────────────────────────────────────────────
echo ""
log_info "════════════════════════════════════════"
log_info "  PASO 3/3 — Resumen de perfiles"
log_info "════════════════════════════════════════"
echo ""
echo "  VENTAS"
echo "    ventas.usuario → CRM, Ventas, Contactos (solo lectura/creación)"
echo "    ventas.jefe    → CRM, Ventas, Contactos + gestión equipo + informes"
echo ""
echo "  RECURSOS HUMANOS"
echo "    rrhh.usuario   → Empleados, Ausencias, Contratos"
echo "    rrhh.jefe      → Empleados, Nóminas, Estructura organizativa"
echo ""
echo "  ALMACÉN"
echo "    almacen.usuario → Inventario, Albaranes, Recepciones"
echo "    almacen.jefe    → Inventario completo + Valoración de stock"
echo ""
echo "  CONTABILIDAD"
echo "    conta.contable  → Facturación, Apuntes contables"
echo "    conta.jefe      → Contabilidad completa + Cierres + Auditoría"
echo ""
echo "  IT"
echo "    it.admin        → Acceso total + Configuración técnica"
echo ""
log_ok "════════════════════════════════════════"
log_ok "  Inicialización de roles completada"
log_ok "════════════════════════════════════════"
log_warn "⚠️  Cambia TODAS las contraseñas antes de pasar a producción."
log_warn "⚠️  Ajusta los permisos de módulo por usuario en:"
log_info "    ${ODOO_URL}/odoo/settings/users"
