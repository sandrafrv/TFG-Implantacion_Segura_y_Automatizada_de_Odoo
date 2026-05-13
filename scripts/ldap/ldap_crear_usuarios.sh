#!/usr/bin/env bash
# ============================================================
# SCRIPT: ldap_crear_usuarios.sh
# DESCRIPCIÓN: Crea usuarios en OpenLDAP y los asigna a su
#              grupo departamental.
# USO: bash scripts/ldap/ldap_crear_usuarios.sh
#
# Grupos VLAN 10: becarios ventas rrhh almacen tecnico
#                 jefe_ventas jefe_rrhh jefe_almacen
# Grupos VLAN 40: admin dba
# ============================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info()  { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[!]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Configuración ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENV_FILE="$PROJECT_DIR/docker/.env"

LDAP_CONT="openldap"
BASE_DN="dc=tfg,dc=com"
USERS_OU="ou=usuarios,${BASE_DN}"
GROUPS_OU="ou=grupos,${BASE_DN}"
BIND_DN="cn=admin,${BASE_DN}"
BIND_PASS=""

# Cargar contraseña del .env si existe
[[ -f "$ENV_FILE" ]] && \
    BIND_PASS=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)

# Grupos válidos
GRUPOS_VALIDOS="becarios ventas rrhh almacen tecnico jefe_ventas jefe_rrhh jefe_almacen admin dba"

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     Gestión de Usuarios LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Verificar contenedor ──────────────────────────────────────
docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONT}$" \
    || { error "Contenedor '$LDAP_CONT' no está activo."; exit 1; }
ok "Contenedor $LDAP_CONT activo."

# ── Credenciales ──────────────────────────────────────────────
read -rp "  DN admin [${BIND_DN}]: " inp; BIND_DN="${inp:-$BIND_DN}"
if [[ -z "$BIND_PASS" ]]; then
    read -rsp "  Contraseña admin LDAP: " BIND_PASS; echo ""
else
    info "Contraseña cargada desde .env"
fi

# ── Función: crear OU si no existe ───────────────────────────
asegurar_ou() {
    local ou_dn="$1"
    local ou_name="${ou_dn%%,*}"; ou_name="${ou_name#ou=}"
    local exists
    exists=$(docker exec "$LDAP_CONT" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASS" \
        -b "$ou_dn" -s base "(objectClass=*)" dn 2>/dev/null | grep -c "^dn:" || true)
    if [[ "$exists" -eq 0 ]]; then
        warn "OU '$ou_dn' no existe. Creando..."
        docker exec -i "$LDAP_CONT" ldapadd -x -D "$BIND_DN" -w "$BIND_PASS" <<EOF
dn: ${ou_dn}
objectClass: organizationalUnit
ou: ${ou_name}
EOF
        ok "OU '$ou_dn' creada."
    fi
}

asegurar_ou "$USERS_OU"
asegurar_ou "$GROUPS_OU"

# ── Función: añadir usuario a grupo ──────────────────────────
aniadir_grupo() {
    local uid="$1" grupo="$2"
    docker exec -i "$LDAP_CONT" ldapmodify \
        -x -D "$BIND_DN" -w "$BIND_PASS" <<EOF 2>/dev/null && return
dn: cn=${grupo},${GROUPS_OU}
changetype: modify
add: member
member: uid=${uid},${USERS_OU}
EOF
    warn "No se pudo añadir '$uid' al grupo '$grupo'."
}

# ── Bucle de creación ─────────────────────────────────────────
while true; do
    echo ""
    echo -e "${BOLD}  ── Nuevo usuario ──────────────────────────────────────${NC}"

    read -rp "  uid (login): " UID_USER
    [[ -z "$UID_USER" ]] && { warn "El uid no puede estar vacío."; continue; }

    # Comprobar si ya existe
    EXISTS=$(docker exec "$LDAP_CONT" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASS" \
        -b "$USERS_OU" "(uid=${UID_USER})" dn 2>/dev/null | grep -c "^dn:" || true)
    if [[ "$EXISTS" -gt 0 ]]; then
        warn "El usuario '$UID_USER' ya existe."; continue
    fi

    read -rp "  Nombre completo (cn): " CN_USER
    read -rp "  Apellido (sn): "         SN_USER
    read -rp "  Email: "                  MAIL_USER
    read -rsp "  Contraseña: "            USER_PASS; echo ""
    echo "  Grupos: $GRUPOS_VALIDOS"
    read -rp "  Grupo: " GRUPO_USER

    # Validar grupo
    if ! grep -qw "$GRUPO_USER" <<< "$GRUPOS_VALIDOS"; then
        warn "Grupo '$GRUPO_USER' no reconocido. Usuario sin grupo."; GRUPO_USER=""
    fi

    # Crear usuario
    docker exec -i "$LDAP_CONT" ldapadd -x -D "$BIND_DN" -w "$BIND_PASS" <<EOF
dn: uid=${UID_USER},${USERS_OU}
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: ${UID_USER}
cn: ${CN_USER}
sn: ${SN_USER}
mail: ${MAIL_USER}
userPassword: ${USER_PASS}
uidNumber: $(shuf -i 2000-9999 -n 1)
gidNumber: 2000
homeDirectory: /home/${UID_USER}
loginShell: /bin/bash
EOF

    ok "Usuario '$UID_USER' creado."
    [[ -n "$GRUPO_USER" ]] && aniadir_grupo "$UID_USER" "$GRUPO_USER" && ok "Añadido al grupo '$GRUPO_USER'."

    read -rp "  ¿Añadir otro usuario? [s/N]: " otro
    [[ ! "${otro,,}" =~ ^s ]] && break
done

# ── Resumen final ─────────────────────────────────────────────
echo ""
echo -e "${BOLD}  Usuarios en LDAP:${NC}"
docker exec "$LDAP_CONT" ldapsearch \
    -x -D "$BIND_DN" -w "$BIND_PASS" \
    -b "$USERS_OU" "(objectClass=inetOrgPerson)" uid cn 2>/dev/null \
    | grep -E "^(dn|uid|cn):" | sed 's/^/  /'

ok "Operación finalizada. ✅"
