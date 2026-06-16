#!/bin/bash
# ============================================================
# SCRIPT: odoo_crear_usuarios.sh
# DESCRIPCIÓN: Automatiza la creación de usuarios en Odoo 17
#              con sus grupos de acceso por rol, usando la API
#              XML-RPC de Odoo y curl.
#
# ROLES Y ACCESO EN ODOO (Capa A + B del modelo de seguridad):
#
#   VLAN 10 — Usuarios internos del ERP:
#   ┌──────────────┬────────────────────────────────────────────┐
#   │ Rol          │ Módulos accesibles en Odoo                 │
#   ├──────────────┼────────────────────────────────────────────┤
#   │ becario      │ Solo CRM (lectura), sin borrar             │
#   │ ventas       │ CRM, Ventas, Contactos, Facturas           │
#   │ rrhh         │ RRHH, Empleados, Nóminas                   │
#   │ almacen      │ Inventario, Compras                        │
#   │ tecnico      │ Inventario, Soporte técnico                │
#   │ jefe_ventas  │ Ventas completo + aprobaciones             │
#   │ jefe_rrhh    │ RRHH completo + aprobaciones               │
#   │ jefe_almacen │ Almacén completo + aprobaciones            │
#   └──────────────┴────────────────────────────────────────────┘
#
#   VLAN 40 — Gestión del servidor (sin acceso ERP usuario):
#   ┌──────────────┬────────────────────────────────────────────┐
#   │ api          │ Solo XML-RPC (sin interfaz web visible)    │
#   │ admin        │ Administrador total de Odoo                │
#   └──────────────┴────────────────────────────────────────────┘
#
# CAPA B — Tipo de usuario (campo sel_groups_1_10_11):
#   1  → Portal (clientes externos al portal /my/)
#   10 → Usuario interno (todos los roles de VLAN 10)
#   11 → Administrador (admin)
#
# USO:
#   ./scripts/odoo/odoo_crear_usuarios.sh
#   (Ejecutar desde /opt/erp-odoo o desde la raíz del proyecto)
#
# REQUISITOS:
#   - Contenedores activos: odoo-web y odoo_erp
#   - curl instalado en el servidor Debian
#   - .env en la raíz del proyecto (generado por provision_debian.sh)
#     o en docker/.env como alternativa
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

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[AVISO]${NC}   $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; }
title()   { echo -e "\n${BOLD}${CYAN}$*${NC}"; echo "────────────────────────────────────────────"; }

# ── Ruta base del proyecto ────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# El .env principal lo genera provision_debian.sh en la raíz del proyecto.
# El docker/.env es opcional y puede tener variables adicionales.
# Buscamos en este orden: raíz del proyecto → docker/ → error.
if [[ -f "$PROJECT_DIR/.env" ]]; then
    ENV_FILE="$PROJECT_DIR/.env"
elif [[ -f "$PROJECT_DIR/docker/.env" ]]; then
    ENV_FILE="$PROJECT_DIR/docker/.env"
else
    error "No se encontró ningún .env en:"
    error "  $PROJECT_DIR/.env"
    error "  $PROJECT_DIR/docker/.env"
    error "Asegúrate de que provision_debian.sh ha ejecutado correctamente."
    exit 1
fi

# ── Leer variables del .env ───────────────────────────────────
set -a
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +a

# ── Configuración de conexión ─────────────────────────────────
ODOO_URL="https://localhost"
ODOO_DB="${POSTGRES_DB:-odoo_erp}"
ADMIN_LOGIN="admin"
ADMIN_PASS="${ODOO_MASTER_PASSWORD:-cambia_esto}"

# ── Función: llamada XML-RPC con curl ─────────────────────────
xmlrpc_call() {
    local endpoint="$1"
    local body="$2"
    curl -s -k --max-time 30 \
        -H "Content-Type: text/xml" \
        -d "$body" \
        "${ODOO_URL}${endpoint}"
}

# ── Función: autenticar y obtener UID ─────────────────────────
odoo_autenticar() {
    local login="$1"
    local pass="$2"
    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/common" "<?xml version='1.0'?>
<methodCall>
  <methodName>authenticate</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><string>${login}</string></value></param>
    <param><value><string>${pass}</string></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")
    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1 || true
}

# ── Función: comprobar si un usuario ya existe ────────────────
usuario_existe() {
    local uid="$1"; local pass="$2"; local login_buscar="$3"
    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${uid}</int></value></param>
    <param><value><string>${pass}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>search</string></value></param>
    <param><value><array><data>
      <value><array><data>
        <value><array><data>
          <value><string>login</string></value>
          <value><string>=</string></value>
          <value><string>${login_buscar}</string></value>
        </data></array></value>
      </data></array></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")
    (echo "$respuesta" | grep -q '<int>') && return 0 || return 1
}

# ── Función: obtener ID numérico de un grupo por XML-ID ───────
#
# Odoo identifica los grupos con XML-IDs como "crm.group_crm_salesperson".
# Esta función resuelve ese ID al número entero interno necesario para
# asignar el grupo en la creación del usuario.
#
obtener_grupo_id() {
    local xml_id="$1"
    local modulo="${xml_id%%.*}"
    local nombre="${xml_id##*.}"

    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${ADMIN_UID}</int></value></param>
    <param><value><string>${ADMIN_PASS}</string></value></param>
    <param><value><string>ir.model.data</string></value></param>
    <param><value><string>search_read</string></value></param>
    <param><value><array><data>
      <value><array><data>
        <value><array><data>
          <value><string>module</string></value>
          <value><string>=</string></value>
          <value><string>${modulo}</string></value>
        </data></array></value>
        <value><array><data>
          <value><string>name</string></value>
          <value><string>=</string></value>
          <value><string>${nombre}</string></value>
        </data></array></value>
      </data></array></value>
    </data></array></value></param>
    <param><value><struct>
      <member><name>fields</name><value><array><data>
        <value><string>res_id</string></value>
      </data></array></value></member>
      <member><name>limit</name><value><int>1</int></value></member>
    </struct></value></param>
  </params>
</methodCall>")

    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1 || true
}

# ── Función: crear usuario con tipo interno (Capa B) ──────────
#
# sel_groups_1_10_11:
#   1  → Portal   (clientes externos al portal /my/)
#   10 → Interno  (todos los usuarios de empresa — VLAN 10)
#   11 → Admin    (administrador total — VLAN 40)
#
crear_usuario() {
    local nombre="$1"; local login="$2"
    local password_nuevo="$3"; local tipo_usuario="$4"

    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${ADMIN_UID}</int></value></param>
    <param><value><string>${ADMIN_PASS}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>create</string></value></param>
    <param><value><array><data>
      <value><struct>
        <member><name>name</name><value><string>${nombre}</string></value></member>
        <member><name>login</name><value><string>${login}</string></value></member>
        <member><name>password</name><value><string>${password_nuevo}</string></value></member>
      </struct></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")

    if echo "$respuesta" | grep -q "<fault>"; then
        echo ""
    else
        echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1 || true
    fi
}

# ── Función: asignar grupos adicionales a un usuario ──────────
#
# Odoo usa el comando [(4, id)] para añadir un grupo sin reemplazar
# los ya existentes. Cada llamada añade un grupo al usuario.
#
asignar_grupo() {
    local user_id="$1"
    local grupo_xml_id="$2"

    local grupo_id
    grupo_id=$(obtener_grupo_id "$grupo_xml_id")

    if [[ -z "$grupo_id" || ! "$grupo_id" =~ ^[0-9]+$ ]]; then
        warn "No se encontró el grupo '${grupo_xml_id}' (puede no estar instalado el módulo)."
        return 0
    fi

    xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${ADMIN_UID}</int></value></param>
    <param><value><string>${ADMIN_PASS}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>write</string></value></param>
    <param><value><array><data>
      <value><array><data>
        <value><int>${user_id}</int></value>
      </data></array></value>
      <value><struct>
        <member>
          <name>groups_id</name>
          <value><array><data>
            <value><array><data>
              <value><int>4</int></value>
              <value><int>${grupo_id}</int></value>
            </data></array></value>
          </data></array></value>
        </member>
      </struct></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>" > /dev/null
    ok "  Grupo asignado: ${grupo_xml_id} (ID: ${grupo_id})"
}

# ── Función: mapeo rol → grupos Odoo (Capa A) ─────────────────
#
# Para cada rol se devuelven los XML-IDs de grupos de Odoo que
# determinan qué módulos y acciones puede realizar el usuario.
#
# Documentación Odoo 17 grupos:
#   base.group_user                → Usuario interno (base)
#   crm.group_crm_salesperson      → CRM: vendedor
#   crm.group_crm_manager          → CRM: manager (aprobaciones)
#   sales_team.group_sale_salesman → Ventas: vendedor
#   sales_team.group_sale_manager  → Ventas: manager
#   account.group_account_invoice  → Facturas: usuario
#   hr.group_hr_user               → RRHH: usuario
#   hr.group_hr_manager            → RRHH: manager
#   stock.group_stock_user         → Inventario: usuario
#   stock.group_stock_manager      → Inventario: manager
#   purchase.group_purchase_user   → Compras: usuario
#   purchase.group_purchase_manager→ Compras: manager
#
grupos_por_rol() {
    local rol="$1"
    case "$rol" in
        becario)
            # Solo CRM lectura — sin permisos de escritura adicionales
            # El botón "Eliminar" no aparece para usuarios sin grupos manager
            echo "base.group_user"
            ;;
        ventas)
            echo "base.group_user"
            echo "crm.group_crm_salesperson"
            echo "sales_team.group_sale_salesman"
            echo "account.group_account_invoice"
            ;;
        rrhh)
            echo "base.group_user"
            echo "hr.group_hr_user"
            ;;
        almacen)
            echo "base.group_user"
            echo "stock.group_stock_user"
            echo "purchase.group_purchase_user"
            ;;
        tecnico)
            echo "base.group_user"
            echo "stock.group_stock_user"
            ;;
        jefe_ventas)
            echo "base.group_user"
            echo "crm.group_crm_manager"
            echo "sales_team.group_sale_manager"
            echo "account.group_account_invoice"
            ;;
        jefe_rrhh)
            echo "base.group_user"
            echo "hr.group_hr_manager"
            ;;
        jefe_almacen)
            echo "base.group_user"
            echo "stock.group_stock_manager"
            echo "purchase.group_purchase_manager"
            ;;
        api)
            # Solo acceso XML-RPC. Sin grupos extra para limitar la UI.
            echo "base.group_user"
            ;;
        *)
            echo "base.group_user"
            ;;
    esac
}

# tipo_usuario_por_rol: devuelve el valor de sel_groups_1_10_11
tipo_usuario_por_rol() {
    local rol="$1"
    case "$rol" in
        admin) echo "11" ;;    # Administrador
        *)     echo "10" ;;    # Usuario interno (VLAN 10 y API)
    esac
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Creación automática de usuarios en Odoo 17"
echo "  URL: ${ODOO_URL}  |  BD: ${ODOO_DB}"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ── 1. Verificar contenedor ───────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q '^odoo-web$'; then
    error "El contenedor 'odoo-web' no está en ejecución."
    exit 1
fi
ok "Contenedor odoo-web activo."

# ── 2. Verificar que Odoo responde ───────────────────────────
if ! curl -sf -k --max-time 10 "${ODOO_URL}/web/health" > /dev/null 2>&1; then
    error "Odoo no responde en ${ODOO_URL}. Espera ~90s al arranque."
    exit 1
fi
ok "Odoo responde correctamente."

# ── 3. Autenticar como administrador ─────────────────────────
info "Autenticando como '${ADMIN_LOGIN}' en BD '${ODOO_DB}'..."
ADMIN_UID=$(odoo_autenticar "$ADMIN_LOGIN" "$ADMIN_PASS")

if [[ -z "$ADMIN_UID" || "$ADMIN_UID" == "0" ]]; then
    error "No se pudo autenticar. Revisa ADMIN_LOGIN y ADMIN_PASS."
    exit 1
fi
ok "Autenticado. UID administrador = ${ADMIN_UID}"

# ── 4. Lista de usuarios a crear ─────────────────────────────
#
# Formato: "nombre|login|contraseña|rol"
#
# Los roles disponibles (mapean a grupos Odoo + tipo de usuario):
#   becario | ventas | rrhh | almacen | tecnico
#   jefe_ventas | jefe_rrhh | jefe_almacen | api
#
# ⚠ CAMBIA LAS CONTRASEÑAS antes de ejecutar en producción.
#   Usa: openssl rand -base64 16
#
declare -a USUARIOS=(
    "Usuario API|api.user@erp.odoo.tfg.com|$(openssl rand -base64 16)|api"
    "Becario Ejemplo|becario@erp.odoo.tfg.com|$(openssl rand -base64 16)|becario"
    "Agente Ventas|ventas@erp.odoo.tfg.com|$(openssl rand -base64 16)|ventas"
    "Responsable RRHH|rrhh@erp.odoo.tfg.com|$(openssl rand -base64 16)|rrhh"
    "Operario Almacen|almacen@erp.odoo.tfg.com|$(openssl rand -base64 16)|almacen"
    "Tecnico Sistema|tecnico@erp.odoo.tfg.com|$(openssl rand -base64 16)|tecnico"
    "Jefe de Ventas|jefe.ventas@erp.odoo.tfg.com|$(openssl rand -base64 16)|jefe_ventas"
    "Jefe de RRHH|jefe.rrhh@erp.odoo.tfg.com|$(openssl rand -base64 16)|jefe_rrhh"
    "Jefe de Almacen|jefe.almacen@erp.odoo.tfg.com|$(openssl rand -base64 16)|jefe_almacen"
)

# ── 5. Crear usuarios con sus grupos ─────────────────────────
CREADOS=0; OMITIDOS=0; ERRORES=0
declare -a RESUMEN=()

echo ""
title "Procesando usuarios..."
echo ""

for entrada in "${USUARIOS[@]}"; do
    IFS='|' read -r nombre login password_nuevo rol <<< "$entrada"

    if usuario_existe "$ADMIN_UID" "$ADMIN_PASS" "$login"; then
        warn "OMITIDO   '${nombre}' (${login}) — ya existe."
        OMITIDOS=$((OMITIDOS + 1))
        continue
    fi

    # Determinar tipo de usuario (Capa B)
    tipo=$(tipo_usuario_por_rol "$rol")

    # Crear el usuario base
    nuevo_id=$(crear_usuario "$nombre" "$login" "$password_nuevo" "$tipo")

    if [[ -n "$nuevo_id" && "$nuevo_id" =~ ^[0-9]+$ ]]; then
        ok "CREADO    '${nombre}' (${login}) → ID: ${nuevo_id} | tipo: ${tipo} | rol: ${rol}"

        # Asignar grupos específicos del rol (Capa A)
        info "Asignando grupos para rol '${rol}'..."
        while IFS= read -r grupo_xml_id; do
            [[ -n "$grupo_xml_id" ]] && asignar_grupo "$nuevo_id" "$grupo_xml_id"
        done < <(grupos_por_rol "$rol")

        RESUMEN+=("${nombre}|${login}|${password_nuevo}|${nuevo_id}|${rol}")
        CREADOS=$((CREADOS + 1))
    else
        error "ERROR     '${nombre}' (${login}) — no se pudo crear."
        ERRORES=$((ERRORES + 1))
    fi
    echo ""
done

# ── 6. Resumen final ──────────────────────────────────────────
echo "────────────────────────────────────────────────────────────"
echo "  Resumen: ${CREADOS} creados | ${OMITIDOS} ya existían | ${ERRORES} errores"
echo "────────────────────────────────────────────────────────────"

if [[ ${#RESUMEN[@]} -gt 0 ]]; then
    echo ""
    warn "⚠  CONTRASEÑAS GENERADAS — GUÁRDALAS AHORA (no se vuelven a mostrar):"
    echo ""
    printf "  %-22s %-35s %-22s %-8s %s\n" "NOMBRE" "LOGIN" "CONTRASEÑA" "ID" "ROL"
    printf "  %-22s %-35s %-22s %-8s %s\n" \
        "──────────────────────" "───────────────────────────────────" \
        "──────────────────────" "────────" "───────────────"
    for linea in "${RESUMEN[@]}"; do
        IFS='|' read -r n l p i r <<< "$linea"
        printf "  %-22s %-35s %-22s %-8s %s\n" "$n" "$l" "$p" "$i" "$r"
    done
    echo ""
fi

echo ""
