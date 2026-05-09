#!/usr/bin/env bash
# ============================================================
# SCRIPT: ldap_crear_usuarios.sh
# DESCRIPCIÓN: Crea usuarios en OpenLDAP y los asigna a su
#              grupo departamental según el diagrama IaC del TFG.
#
# GRUPOS DISPONIBLES (VLAN 10 — Usuarios ERP):
#   becarios     → Solo lectura en Odoo, no pueden eliminar
#   ventas       → CRM, pipeline, facturas
#   rrhh         → RRHH, empleados, nóminas
#   almacen      → Inventario, compras
#   tecnico      → Soporte + puede cambiar contraseñas LDAP
#   jefe_ventas  → Manager de ventas
#   jefe_rrhh    → Manager de RRHH
#   jefe_almacen → Manager de almacén
#
# GRUPOS (VLAN 40 — Gestión del servidor):
#   admin        → Acceso total al servidor
#   dba          → Solo base de datos PostgreSQL
#
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

# ── Leer .env ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/docker/.env"

LDAP_CONTAINER="openldap"
BASE_DN="dc=tfg,dc=com"
BIND_DN="cn=admin,${BASE_DN}"
USERS_OU="ou=usuarios,${BASE_DN}"
GROUPS_OU="ou=grupos,${BASE_DN}"
BIND_PASSWORD=""

# Grupos válidos y su VLAN de pertenencia
declare -A GRUPOS_VLAN=(
    [becarios]="VLAN 10"
    [ventas]="VLAN 10"
    [rrhh]="VLAN 10"
    [almacen]="VLAN 10"
    [tecnico]="VLAN 10"
    [jefe_ventas]="VLAN 10"
    [jefe_rrhh]="VLAN 10"
    [jefe_almacen]="VLAN 10"
    [admin]="VLAN 40"
    [dba]="VLAN 40"
)

if [[ -f "$ENV_FILE" ]]; then
    BIND_PASSWORD=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" \
        | cut -d= -f2- | tr -d '"' || true)
fi

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║     Gestión de Usuarios LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo "  Grupos disponibles:"
echo "  VLAN 10: becarios | ventas | rrhh | almacen | tecnico"
echo "           jefe_ventas | jefe_rrhh | jefe_almacen"
echo "  VLAN 40: admin | dba"
echo ""

# ── Verificar contenedor ──────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONTAINER}$"; then
    error "El contenedor '${LDAP_CONTAINER}' no está en ejecución."
    error "Arráncalo con: docker compose -f docker/docker-compose.yml up -d ldap"
    exit 1
fi
ok "Contenedor ${LDAP_CONTAINER} activo."

# ── Pedir credenciales ────────────────────────────────────────
title "⚙  Configuración de conexión"

read -r -p "  DN de administrador [${BIND_DN}]: " input_binddn
BIND_DN="${input_binddn:-$BIND_DN}"

if [[ -z "$BIND_PASSWORD" ]]; then
    read -r -s -p "  Contraseña del administrador LDAP: " BIND_PASSWORD
    echo ""
else
    info "Contraseña cargada desde $ENV_FILE."
fi

# ── Verificar/crear OUs ───────────────────────────────────────
title "📁  Verificando estructura del árbol LDAP"

for OU_DN in "$USERS_OU" "$GROUPS_OU" "ou=servicios,${BASE_DN}"; do
    EXISTS=$(docker exec "$LDAP_CONTAINER" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
        -b "$OU_DN" -s base "(objectClass=organizationalUnit)" dn 2>/dev/null \
        | grep -c "dn:" || true)

    if [[ "$EXISTS" -eq 0 ]]; then
        warn "OU '${OU_DN}' no encontrada. Creándola..."
        OU_NAME="${OU_DN%%,*}"; OU_NAME="${OU_NAME#ou=}"
        docker exec -i "$LDAP_CONTAINER" ldapadd \
            -x -D "$BIND_DN" -w "$BIND_PASSWORD" <<EOF
dn: ${OU_DN}
objectClass: organizationalUnit
objectClass: top
ou: ${OU_NAME}
EOF
        ok "OU '${OU_DN}' creada."
    else
        ok "OU '${OU_DN}' existe."
    fi
done

# ── Función: añadir usuario a su grupo ───────────────────────
aniadir_a_grupo() {
    local uid_user="$1"
    local grupo="$2"
    local grupo_dn="cn=${grupo},${GROUPS_OU}"
    local user_dn="uid=${uid_user},${USERS_OU}"

    docker exec -i "$LDAP_CONTAINER" ldapmodify \
        -x -D "$BIND_DN" -w "$BIND_PASSWORD" <<EOF 2>/dev/null && return 0 || true
dn: ${grupo_dn}
changetype: modify
add: member
member: ${user_dn}
EOF
    warn "No se pudo añadir al grupo '${grupo}'."
}

# ── Bucle de creación ─────────────────────────────────────────
while true; do
    title "➕  Datos del nuevo usuario LDAP"

    read -r -p "  uid (login, ej: jsmith): " UID_USER
    [[ -z "$UID_USER" ]] && { warn "El uid no puede estar vacío."; continue; }

    EXISTS=$(docker exec "$LDAP_CONTAINER" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
        -b "$USERS_OU" "(uid=${UID_USER})" dn 2>/dev/null | grep -c "dn:" || true)

    if [[ "$EXISTS" -gt 0 ]]; then
        warn "El usuario '${UID_USER}' ya existe. Saltando..."
    else
        read -r -p "  Nombre completo (cn): " CN_USER
        read -r -p "  Apellido (sn): " SN_USER
        read -r -p "  Email (mail): " MAIL_USER
        read -r -s -p "  Contraseña: " USER_PASS
        echo ""

        echo ""
        echo "  Grupos: becarios|ventas|rrhh|almacen|tecnico|jefe_ventas|jefe_rrhh|jefe_almacen|admin|dba"
        read -r -p "  Grupo del usuario: " GRUPO_USER

        if [[ -z "${GRUPOS_VLAN[$GRUPO_USER]+_}" ]]; then
            warn "Grupo '${GRUPO_USER}' no reconocido. Usuario sin grupo."
            GRUPO_USER=""
        else
            info "Grupo: ${GRUPO_USER} (${GRUPOS_VLAN[$GRUPO_USER]})"
        fi

        # Crear el usuario en LDAP
        docker exec -i "$LDAP_CONTAINER" ldapadd \
            -x -D "$BIND_DN" -w "$BIND_PASSWORD" <<EOF
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

        VERIFY=$(docker exec "$LDAP_CONTAINER" ldapsearch \
            -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
            -b "$USERS_OU" "(uid=${UID_USER})" uid 2>/dev/null | grep -c "uid:" || true)

        if [[ "$VERIFY" -gt 0 ]]; then
            ok "Usuario '${UID_USER}' (${CN_USER}) creado. ✅"
            if [[ -n "$GRUPO_USER" ]]; then
                aniadir_a_grupo "$UID_USER" "$GRUPO_USER"
                ok "Añadido al grupo '${GRUPO_USER}' (${GRUPOS_VLAN[$GRUPO_USER]})."
            fi
        else
            error "No se pudo verificar la creación de '${UID_USER}'."
        fi
    fi

    echo ""
    read -r -p "  ¿Añadir otro usuario? [s/N]: " OTRO
    [[ ! "${OTRO,,}" =~ ^s ]] && break
done

# ── Resumen ───────────────────────────────────────────────────
title "✅  Usuarios actuales en LDAP"
docker exec "$LDAP_CONTAINER" ldapsearch \
    -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
    -b "$USERS_OU" "(objectClass=inetOrgPerson)" uid cn mail 2>/dev/null \
    | grep -E "^(dn|uid|cn|mail):" | sed 's/^/  /'

echo ""
title "📋  Miembros por grupo"
for grupo in becarios ventas rrhh almacen tecnico jefe_ventas jefe_rrhh jefe_almacen admin dba; do
    MEMBERS=$(docker exec "$LDAP_CONTAINER" ldapsearch \
        -x -D "$BIND_DN" -w "$BIND_PASSWORD" \
        -b "cn=${grupo},${GROUPS_OU}" "(objectClass=groupOfNames)" member 2>/dev/null \
        | grep "^member:" | grep -v "placeholder" | wc -l || echo "0")
    printf "  %-15s → %s miembro(s)\n" "$grupo" "$MEMBERS"
done

echo ""
ok "Operación finalizada. Los usuarios pueden autenticarse en Odoo vía LDAP. ✅"
echo ""
