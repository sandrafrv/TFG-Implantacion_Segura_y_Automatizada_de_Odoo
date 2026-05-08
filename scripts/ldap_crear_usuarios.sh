#!/usr/bin/env bash
# ============================================================
# SCRIPT: ldap_crear_usuarios.sh
# DESCRIPCIÓN: Script interactivo para crear usuarios en el
#              servidor OpenLDAP del TFG (contenedor odoo-ldap).
#              Permite añadir varios usuarios en bucle.
# USO: bash scripts/ldap_crear_usuarios.sh
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
title() { echo -e "\n${BOLD}${CYAN}$*${NC}"; echo "────────────────────────────────────────────"; }

# ── Leer .env si existe ──────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/docker/.env"

LDAP_CONTAINER="odoo-ldap"
BASE_DN="dc=tfg,dc=com"
BIND_DN="cn=admin,dc=tfg,dc=com"
USERS_OU="ou=usuarios,dc=tfg,dc=com"
BIND_PASSWORD=""

if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    BIND_PASSWORD=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)
fi

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     Gestión de Usuarios LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Verificar que el contenedor LDAP está activo ─────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONTAINER}$"; then
    error "El contenedor '$LDAP_CONTAINER' no está en ejecución."
    error "Arráncalo con: docker compose -f docker/docker-compose.yml up -d odoo-ldap"
    exit 1
fi
ok "Contenedor $LDAP_CONTAINER activo."

# ── Pedir credenciales de conexión ───────────────────────────
title "⚙  Configuración de conexión al servidor LDAP"

read -r -p "  DN de administrador [${BIND_DN}]: " input_binddn
BIND_DN="${input_binddn:-$BIND_DN}"

if [[ -z "$BIND_PASSWORD" ]]; then
    read -r -s -p "  Contraseña del administrador LDAP: " BIND_PASSWORD
    echo ""
else
    info "Contraseña cargada desde $ENV_FILE."
fi

read -r -p "  OU de usuarios [${USERS_OU}]: " input_ou
USERS_OU="${input_ou:-$USERS_OU}"

# ── Verificar que la OU de usuarios existe, si no crearla ────
OU_EXISTS=$(docker exec "$LDAP_CONTAINER" ldapsearch \
    -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
    -b "$BASE_DN" "(objectClass=organizationalUnit)" dn 2>/dev/null | grep -c "dn: $USERS_OU" || true)

if [[ "$OU_EXISTS" -eq 0 ]]; then
    warn "La OU '$USERS_OU' no existe. Creándola..."
    docker exec -i "$LDAP_CONTAINER" ldapadd \
        -x -D "$BIND_DN" -w "$BIND_PASSWORD" <<EOF
dn: $USERS_OU
objectClass: organizationalUnit
ou: usuarios
EOF
    ok "OU '$USERS_OU' creada."
fi

# ── Bucle de creación de usuarios ────────────────────────────
while true; do
    title "➕  Datos del nuevo usuario LDAP"

    read -r -p "  uid (login, ej: jsmith): " UID_USER
    if [[ -z "$UID_USER" ]]; then
        warn "El uid no puede estar vacío."
        continue
    fi

    # Comprobar si el usuario ya existe
    EXISTS=$(docker exec "$LDAP_CONTAINER" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
        -b "$USERS_OU" "(uid=${UID_USER})" dn 2>/dev/null | grep -c "dn:" || true)

    if [[ "$EXISTS" -gt 0 ]]; then
        warn "El usuario '$UID_USER' ya existe en LDAP. Saltando..."
    else
        read -r -p "  Nombre completo (cn, ej: John Smith): " CN_USER
        read -r -p "  Apellido (sn, ej: Smith): " SN_USER
        read -r -p "  Email (mail, ej: jsmith@tfg.com): " MAIL_USER
        read -r -s -p "  Contraseña para el usuario: " USER_PASS
        echo ""

        # Generar el LDIF e importarlo directamente
        docker exec -i "$LDAP_CONTAINER" ldapadd \
            -x -D "$BIND_DN" -w "$BIND_PASSWORD" <<EOF
dn: uid=${UID_USER},${USERS_OU}
objectClass: inetOrgPerson
uid: ${UID_USER}
cn: ${CN_USER}
sn: ${SN_USER}
mail: ${MAIL_USER}
userPassword: ${USER_PASS}
EOF

        # Verificar que se creó correctamente
        VERIFY=$(docker exec "$LDAP_CONTAINER" ldapsearch \
            -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
            -b "$USERS_OU" "(uid=${UID_USER})" uid 2>/dev/null | grep -c "uid:" || true)

        if [[ "$VERIFY" -gt 0 ]]; then
            ok "Usuario '${UID_USER}' (${CN_USER}) creado correctamente en LDAP. ✅"
        else
            error "No se pudo verificar la creación del usuario '${UID_USER}'."
        fi
    fi

    echo ""
    read -r -p "  ¿Añadir otro usuario? [s/N]: " OTRO
    if [[ ! "${OTRO,,}" =~ ^s ]]; then
        break
    fi
done

title "✅  Resumen de usuarios actuales en LDAP"
docker exec "$LDAP_CONTAINER" ldapsearch \
    -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
    -b "$USERS_OU" "(objectClass=inetOrgPerson)" uid cn mail 2>/dev/null \
    | grep -E "^(dn|uid|cn|mail):" | sed 's/^/  /'

echo ""
ok "Operación finalizada. Los usuarios ya pueden autenticarse en Odoo vía LDAP."
echo ""
