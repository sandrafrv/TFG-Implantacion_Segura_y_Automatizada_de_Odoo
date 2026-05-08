#!/bin/bash
# ============================================================
# SCRIPT: odoo_crear_usuarios.sh
# DESCRIPCIÓN: Automatiza la creación de usuarios en Odoo 17
#              usando la API XML-RPC de Odoo y curl.
#              Lee las credenciales del archivo docker/.env
#              para no hardcodear contraseñas.
#
# USO:
#   ./scripts/odoo_crear_usuarios.sh
#   (Ejecutar desde /opt/erp-odoo o desde la raíz del proyecto)
#
# REQUISITOS:
#   - Contenedores activos: odoo-web y odoo_erp
#   - curl instalado en el servidor Debian
#   - Archivo docker/.env con las variables del proyecto
#
# BASADO EN: docs/mas_info/informe_erp.md
#   - Semana 4  → Roles: Administrador, Becario, Ventas, Dirección
#   - Semana 8  → Usuario API para XML-RPC (api.user@spikatech.com)
#   - Semana 9  → Importación masiva con usuario de servicio
#   - Semana 12 → Cuadro de credenciales final
# ============================================================

set -euo pipefail

# ── Colores (igual que el resto de scripts del proyecto) ──────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
ok()      { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[AVISO]${NC}   $*"; }
error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; }

# ── Ruta base del proyecto ────────────────────────────────────
# El script puede ejecutarse desde cualquier directorio
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/docker/.env"

# ── Leer variables del .env ───────────────────────────────────
if [[ ! -f "$ENV_FILE" ]]; then
    error "No se encontró el archivo de variables: $ENV_FILE"
    error "Copia docker/.env.example a docker/.env y rellena las credenciales."
    exit 1
fi

# Exportar solo las variables necesarias (sin ejecutar líneas de comentario)
# shellcheck source=/dev/null
set -a
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +a

# ── Configuración de conexión (arquitectura TFG) ───────────────
#
# Odoo 17 en contenedor Docker (docker-compose.yml)
#   contenedor odoo:  odoo-web     (puerto 8069 solo en red interna odoo_net)
#   contenedor db:    odoo_erp     (postgres:16, puerto 5432 solo en red interna)
#   nginx:            nginx-proxy  (puertos 80/443 expuestos al host Debian)
#
# Desde el propio servidor Debian, Odoo es accesible en:
#   http://localhost:8069   → acceso directo al contenedor odoo-web
#
# Credenciales leídas de docker/.env:
#   BD: odoo_erp   (POSTGRES_DB)
#   Usuario admin Odoo → se configura en el primer arranque del ERP

ODOO_URL="http://localhost:8069"
ODOO_DB="${POSTGRES_DB:-odoo_erp}"

# Credenciales del administrador de Odoo
# ⚠️  Cambia estos valores por los del usuario administrador que creaste
# en el asistente de Odoo al crear la base de datos por primera vez.
ADMIN_LOGIN="admin"
ADMIN_PASS="${ODOO_MASTER_PASSWORD:-cambia_esto}"   # Úsala como referencia inicial

# ── Función: llamada XML-RPC genérica con curl ─────────────────
#
# Odoo expone dos endpoints XML-RPC (informe_erp.md - Semana 8, línea 2531):
#   /xmlrpc/2/common  → autenticación (authenticate)
#   /xmlrpc/2/object  → operaciones sobre modelos (execute_kw)
#
xmlrpc_call() {
    local endpoint="$1"
    local body="$2"
    curl -s --max-time 30 \
        -H "Content-Type: text/xml" \
        -d "$body" \
        "${ODOO_URL}${endpoint}"
}

# ── Función: autenticar y obtener el UID ──────────────────────
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

    # Extraer el UID numérico de la respuesta XML
    # Si la autenticación falla, Odoo devuelve <boolean>0</boolean>
    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}

# ── Función: comprobar si un usuario ya existe ────────────────
usuario_existe() {
    local uid="$1"
    local pass="$2"
    local login_buscar="$3"

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

    # Si hay algún <int> en la respuesta, el usuario existe
    if echo "$respuesta" | grep -q '<int>'; then
        return 0   # existe
    else
        return 1   # no existe
    fi
}

# ── Función: crear un usuario ─────────────────────────────────
crear_usuario() {
    local uid="$1"
    local pass="$2"
    local nombre="$3"
    local login="$4"
    local password_nuevo="$5"

    local respuesta
    respuesta=$(xmlrpc_call "/xmlrpc/2/object" "<?xml version='1.0'?>
<methodCall>
  <methodName>execute_kw</methodName>
  <params>
    <param><value><string>${ODOO_DB}</string></value></param>
    <param><value><int>${uid}</int></value></param>
    <param><value><string>${pass}</string></value></param>
    <param><value><string>res.users</string></value></param>
    <param><value><string>create</string></value></param>
    <param><value><array><data>
      <value><struct>
        <member>
          <name>name</name>
          <value><string>${nombre}</string></value>
        </member>
        <member>
          <name>login</name>
          <value><string>${login}</string></value>
        </member>
        <member>
          <name>password</name>
          <value><string>${password_nuevo}</string></value>
        </member>
        <member>
          <name>lang</name>
          <value><string>es_ES</string></value>
        </member>
        <member>
          <name>tz</name>
          <value><string>Europe/Madrid</string></value>
        </member>
        <member>
          <name>sel_groups_1_10_11</name>
          <value><int>1</int></value>
        </member>
      </struct></value>
    </data></array></value></param>
    <param><value><struct/></value></param>
  </params>
</methodCall>")

    # El ID del nuevo usuario está en la primera <int> de la respuesta
    echo "$respuesta" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}

# ═════════════════════════════════════════════════════════════
# MAIN
# ═════════════════════════════════════════════════════════════

echo ""
echo "============================================================"
echo "  Creación automática de usuarios en Odoo 17"
echo "  URL: ${ODOO_URL}  |  BD: ${ODOO_DB}"
echo "============================================================"
echo ""

# ── 1. Verificar que el contenedor Odoo está activo ───────────
if ! docker ps --format '{{.Names}}' | grep -q '^odoo-web$'; then
    error "El contenedor 'odoo-web' no está en ejecución."
    error "Arráncalo con: docker compose -f docker/docker-compose.yml up -d"
    exit 1
fi
ok "Contenedor odoo-web activo."

# ── 2. Verificar que Odoo responde ───────────────────────────
if ! curl -sf --max-time 10 "${ODOO_URL}/web/health" > /dev/null 2>&1; then
    error "Odoo no responde en ${ODOO_URL}."
    error "Espera a que el contenedor termine de arrancar (puede tardar ~90s)."
    error "Comprueba el estado con: docker logs odoo-web --tail 30"
    exit 1
fi
ok "Odoo responde correctamente."

# ── 3. Autenticar como administrador ─────────────────────────
info "Autenticando como '${ADMIN_LOGIN}' en la BD '${ODOO_DB}'..."
ADMIN_UID=$(odoo_autenticar "$ADMIN_LOGIN" "$ADMIN_PASS")

if [[ -z "$ADMIN_UID" || "$ADMIN_UID" == "0" ]]; then
    error "No se pudo autenticar. Revisa ADMIN_LOGIN y ADMIN_PASS en este script."
    error "Si acabas de crear la BD, el usuario admin tiene la contraseña que"
    error "pusiste en el asistente de creación de base de datos de Odoo."
    exit 1
fi
ok "Autenticado correctamente. UID administrador = ${ADMIN_UID}"

# ── 4. Lista de usuarios a crear ─────────────────────────────
#
# Formato de cada entrada: "nombre|login|contraseña"
#
# Roles documentados en informe_erp.md:
#   - Admin    → Semana 6 y 12: administrador del ERP
#   - API      → Semana 8 y 9:  scripts XML-RPC de integración
#   - Técnico  → Semana 1 y 4:  técnico de implantación
#   - Ventas   → Semana 7:      pipeline CRM Lead→Contacto→Demo→Cierre
#   - Dirección→ Semana 4:      visibilidad global
#   - Becario  → Semana 4:      acceso restringido
#
# ⚠️  CAMBIA TODAS LAS CONTRASEÑAS antes de ejecutar en producción.
#    Usa: openssl rand -base64 16
#
declare -a USUARIOS=(
    "Usuario API|api.user@erp.odoo.tfg.com|$(openssl rand -base64 16)"
    "Tecnico VR|tecnico@erp.odoo.tfg.com|$(openssl rand -base64 16)"
    "Responsable Ventas|ventas@erp.odoo.tfg.com|$(openssl rand -base64 16)"
    "Direccion|direccion@erp.odoo.tfg.com|$(openssl rand -base64 16)"
    "Becario|becario@erp.odoo.tfg.com|$(openssl rand -base64 16)"
)

# ── 5. Crear los usuarios ─────────────────────────────────────
CREADOS=0
OMITIDOS=0
ERRORES=0

# Guardar las contraseñas generadas para mostrarlas al final
declare -a RESUMEN=()

echo ""
info "Procesando usuarios..."
echo ""

for entrada in "${USUARIOS[@]}"; do
    IFS='|' read -r nombre login password_nuevo <<< "$entrada"

    if usuario_existe "$ADMIN_UID" "$ADMIN_PASS" "$login"; then
        warn "OMITIDO   '${nombre}' (${login}) — ya existe en Odoo."
        OMITIDOS=$((OMITIDOS + 1))
        continue
    fi

    nuevo_id=$(crear_usuario "$ADMIN_UID" "$ADMIN_PASS" "$nombre" "$login" "$password_nuevo")

    if [[ -n "$nuevo_id" && "$nuevo_id" =~ ^[0-9]+$ ]]; then
        ok "CREADO    '${nombre}' (${login}) → ID: ${nuevo_id}"
        RESUMEN+=("${nombre}|${login}|${password_nuevo}|${nuevo_id}")
        CREADOS=$((CREADOS + 1))
    else
        error "ERROR     '${nombre}' (${login}) — no se pudo crear."
        ERRORES=$((ERRORES + 1))
    fi
done

# ── 6. Resumen final ──────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────────"
echo "  Resumen: ${CREADOS} creados | ${OMITIDOS} ya existían | ${ERRORES} errores"
echo "────────────────────────────────────────────────────────────"

if [[ ${#RESUMEN[@]} -gt 0 ]]; then
    echo ""
    warn "⚠  CONTRASEÑAS GENERADAS — GUÁRDALAS AHORA (no se vuelven a mostrar):"
    echo ""
    printf "  %-25s %-35s %-25s %s\n" "NOMBRE" "LOGIN" "CONTRASEÑA" "ID"
    printf "  %-25s %-35s %-25s %s\n" "─────────────────────────" \
           "───────────────────────────────────" \
           "─────────────────────────" "──────"
    for linea in "${RESUMEN[@]}"; do
        IFS='|' read -r n l p i <<< "$linea"
        printf "  %-25s %-35s %-25s %s\n" "$n" "$l" "$p" "$i"
    done
    echo ""
fi

echo ""
