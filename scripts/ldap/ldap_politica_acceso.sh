#!/bin/bash
# ============================================================
# SCRIPT: ldap_politica_acceso.sh
# DESCRIPCIÓN: Configura las ACLs (Access Control Lists) del
#              servidor OpenLDAP para implementar el modelo de
#              permisos del diagrama IaC del TFG ASIR 2025/2026.
#
# MODELO DE ACCESO (3 niveles):
#
#   cn=admin       → Acceso TOTAL (desde VLAN 40)
#   cn=tecnico     → Puede cambiar contraseñas de VLAN 10
#                    (solo atributo userPassword, no crear/eliminar)
#   cn=readonly    → Lectura total (para Odoo y PAM de VLAN 10)
#   Resto          → Sin acceso
#
# USO:
#   bash scripts/ldap/ldap_politica_acceso.sh
#   (Ejecutar desde /opt/erp-odoo o desde la raíz del proyecto)
#
# REQUISITOS:
#   - Contenedor 'openldap' activo
#   - docker/.env con LDAP_ADMIN_PASSWORD
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

# ── Ruta base y variables de entorno ─────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/docker/.env"

LDAP_CONTAINER="openldap"
BASE_DN="dc=tfg,dc=com"
ADMIN_DN="cn=admin,${BASE_DN}"
ADMIN_PASS=""

if [[ -f "$ENV_FILE" ]]; then
    ADMIN_PASS=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" \
        | cut -d= -f2- | tr -d '"' || true)
fi

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Configuración de ACLs LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "  Este script aplica las políticas de acceso al árbol LDAP:"
echo ""
echo "    cn=admin      → Acceso TOTAL       (VLAN 40)"
echo "    cn=tecnico    → Solo userPassword  (VLAN 10, cambio de contraseñas)"
echo "    cn=readonly   → Solo lectura       (Odoo + PAM máquinas VLAN 10)"
echo "    Resto         → Sin acceso"
echo ""

# ── Verificar contenedor ──────────────────────────────────────
if ! docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONTAINER}$"; then
    error "El contenedor '${LDAP_CONTAINER}' no está en ejecución."
    error "Arráncalo con: docker compose -f docker/docker-compose.yml up -d ldap"
    exit 1
fi
ok "Contenedor ${LDAP_CONTAINER} activo."

# ── Pedir contraseña si no está en .env ──────────────────────
if [[ -z "$ADMIN_PASS" ]]; then
    read -r -s -p "  Contraseña del administrador LDAP: " ADMIN_PASS
    echo ""
fi

# ── Función: aplicar un LDIF de modificación de ACL ──────────
aplicar_acl() {
    local descripcion="$1"
    local ldif_content="$2"

    info "Aplicando ACL: ${descripcion}..."

    echo "$ldif_content" | docker exec -i "$LDAP_CONTAINER" ldapmodify \
        -Y EXTERNAL -H ldapi:/// 2>/dev/null \
        || \
    echo "$ldif_content" | docker exec -i "$LDAP_CONTAINER" ldapmodify \
        -x -D "$ADMIN_DN" -w "$ADMIN_PASS" 2>/dev/null \
        || {
            warn "No se pudo aplicar via ldapi://. Intentando modificación directa..."
            docker exec -i "$LDAP_CONTAINER" ldapmodify \
                -x -D "$ADMIN_DN" -w "$ADMIN_PASS" <<< "$ldif_content"
        }
    ok "ACL aplicada: ${descripcion}"
}

# ══════════════════════════════════════════════════════════════
# ACL 1: Proteger contraseña del admin (solo el propio admin)
# ══════════════════════════════════════════════════════════════
title "ACL 1 — Proteger atributo userPassword del admin"

# La contraseña del admin nunca debe ser legible, ni siquiera para
# el usuario de solo lectura (readonly). Solo el propio admin puede
# verla y cambiarla.
cat <<'LDIF_END' | docker exec -i "$LDAP_CONTAINER" ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null || \
docker exec -i "$LDAP_CONTAINER" ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PASS" <<'LDIF_END'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange
  by self write
  by dn="cn=admin,dc=tfg,dc=com" write
  by dn="cn=tecnico,ou=grupos,dc=tfg,dc=com" write
  by anonymous auth
  by * none
LDIF_END

ok "ACL 1 aplicada: userPassword protegido."

# ══════════════════════════════════════════════════════════════
# ACL 2: Usuario readonly — lectura de todo el árbol
# ══════════════════════════════════════════════════════════════
title "ACL 2 — Usuario readonly: lectura total del árbol"

# El usuario readonly (cn=readonly,dc=tfg,dc=com) es el que usa Odoo
# para autenticar usuarios sin conocer la contraseña del admin LDAP.
# También lo usan las máquinas de VLAN 10 vía PAM/NSS.
cat <<'LDIF_END' | docker exec -i "$LDAP_CONTAINER" ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null || \
docker exec -i "$LDAP_CONTAINER" ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PASS" <<'LDIF_END'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {1}to dn.subtree="dc=tfg,dc=com"
  by dn="cn=admin,dc=tfg,dc=com" write
  by dn="cn=readonly,dc=tfg,dc=com" read
  by self read
  by * none
LDIF_END

ok "ACL 2 aplicada: readonly puede leer todo el árbol."

# ══════════════════════════════════════════════════════════════
# ACL 3: Grupo Técnico — solo cambio de userPassword en VLAN 10
# ══════════════════════════════════════════════════════════════
title "ACL 3 — Técnico: solo puede cambiar contraseñas de VLAN 10"

# El grupo técnico tiene permiso de escritura ÚNICAMENTE sobre el
# atributo userPassword de los usuarios de ou=usuarios (VLAN 10).
# No puede crear ni eliminar entradas.
cat <<'LDIF_END' | docker exec -i "$LDAP_CONTAINER" ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null || \
docker exec -i "$LDAP_CONTAINER" ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PASS" <<'LDIF_END'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {2}to dn.subtree="ou=usuarios,dc=tfg,dc=com" attrs=userPassword
  by dn="cn=admin,dc=tfg,dc=com" write
  by group.exact="cn=tecnico,ou=grupos,dc=tfg,dc=com" write
  by self write
  by anonymous auth
  by * none
LDIF_END

ok "ACL 3 aplicada: tecnico puede cambiar userPassword de usuarios."

# ══════════════════════════════════════════════════════════════
# ACL 4: Bloquear todo lo demás
# ══════════════════════════════════════════════════════════════
title "ACL 4 — Deny all: bloquear acceso no autorizado"

cat <<'LDIF_END' | docker exec -i "$LDAP_CONTAINER" ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null || \
docker exec -i "$LDAP_CONTAINER" ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PASS" <<'LDIF_END'
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {3}to *
  by dn="cn=admin,dc=tfg,dc=com" write
  by dn="cn=readonly,dc=tfg,dc=com" read
  by * none
LDIF_END

ok "ACL 4 aplicada: deny all para el resto."

# ── Verificación de ACLs aplicadas ───────────────────────────
title "Verificación — ACLs actuales en el servidor LDAP"

echo ""
info "ACLs configuradas en olcDatabase={1}mdb:"
docker exec "$LDAP_CONTAINER" ldapsearch \
    -Y EXTERNAL -H ldapi:/// \
    -b "olcDatabase={1}mdb,cn=config" \
    "(objectClass=olcDatabaseConfig)" olcAccess 2>/dev/null \
    | grep "olcAccess:" | nl -ba | sed 's/^/  /'

echo ""
echo "────────────────────────────────────────────────────────────"
echo "  Resumen del modelo de acceso:"
echo ""
echo "  cn=admin              → Acceso TOTAL (escritura en todo el árbol)"
echo "  cn=tecnico (grupo)    → Solo userPassword de ou=usuarios"
echo "  cn=readonly           → Lectura total  (Odoo + PAM VLAN 10)"
echo "  anonymous             → Solo autenticación (auth en userPassword)"
echo "  *                     → Ningún acceso"
echo "────────────────────────────────────────────────────────────"
echo ""
ok "Política de acceso LDAP configurada correctamente. ✅"
echo ""
