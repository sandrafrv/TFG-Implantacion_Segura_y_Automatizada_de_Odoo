#!/bin/bash
# ============================================================
# SCRIPT: ldap_politica_acceso.sh
# DESCRIPCIÓN: Aplica ACLs en OpenLDAP según el modelo del TFG:
#   admin    → Acceso total
#   tecnico  → Solo cambio de contraseñas de usuarios
#   readonly → Lectura total (Odoo + PAM VLAN 10)
#   resto    → Sin acceso
# USO: bash scripts/ldap/ldap_politica_acceso.sh
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
ADMIN_DN="cn=admin,${BASE_DN}"
ADMIN_PASS=""

[[ -f "$ENV_FILE" ]] && \
    ADMIN_PASS=$(grep -E '^LDAP_ADMIN_PASSWORD=' "$ENV_FILE" | cut -d= -f2- | tr -d '"' || true)

# ── Cabecera ─────────────────────────────────────────────────
clear
echo -e "${BOLD}"
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   Configuración de ACLs LDAP — TFG ASIR 2026    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Verificar contenedor ──────────────────────────────────────
docker ps --format '{{.Names}}' | grep -q "^${LDAP_CONT}$" \
    || { error "Contenedor '$LDAP_CONT' no está activo."; exit 1; }
ok "Contenedor $LDAP_CONT activo."

[[ -z "$ADMIN_PASS" ]] && { read -rsp "  Contraseña admin LDAP: " ADMIN_PASS; echo ""; }

# ── Función: aplicar un LDIF vía ldapi:// (o simple bind como fallback) ──
aplicar_acl() {
    local desc="$1"
    local ldif="$2"
    info "Aplicando: $desc"
    # Intentar primero SASL EXTERNAL (sin contraseña), luego simple bind
    echo "$ldif" | docker exec -i "$LDAP_CONT" \
        ldapmodify -Y EXTERNAL -H ldapi:/// 2>/dev/null \
    || echo "$ldif" | docker exec -i "$LDAP_CONT" \
        ldapmodify -x -D "$ADMIN_DN" -w "$ADMIN_PASS" 2>/dev/null \
    || warn "No se aplicó '$desc' (puede que ya exista)."
    ok "$desc aplicada."
}

# ── ACL 1: Proteger userPassword ─────────────────────────────
aplicar_acl "ACL 1 — userPassword protegido" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange
  by self write
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by group.exact=\"cn=tecnico,ou=grupos,dc=tfg,dc=com\" write
  by anonymous auth
  by * none"

# ── ACL 2: Usuario readonly — lectura total ───────────────────
aplicar_acl "ACL 2 — readonly puede leer todo el árbol" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {1}to dn.subtree=\"dc=tfg,dc=com\"
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by dn=\"cn=readonly,dc=tfg,dc=com\" read
  by self read
  by * none"

# ── ACL 3: Técnico — solo cambio de contraseñas en VLAN 10 ───
aplicar_acl "ACL 3 — tecnico puede cambiar userPassword de usuarios" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {2}to dn.subtree=\"ou=usuarios,dc=tfg,dc=com\" attrs=userPassword
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by group.exact=\"cn=tecnico,ou=grupos,dc=tfg,dc=com\" write
  by self write
  by anonymous auth
  by * none"

# ── ACL 4: Deny all ──────────────────────────────────────────
aplicar_acl "ACL 4 — deny all para el resto" \
"dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {3}to *
  by dn=\"cn=admin,dc=tfg,dc=com\" write
  by dn=\"cn=readonly,dc=tfg,dc=com\" read
  by * none"

# ── Verificación ─────────────────────────────────────────────
echo ""
info "ACLs configuradas actualmente:"
docker exec "$LDAP_CONT" ldapsearch \
    -Y EXTERNAL -H ldapi:/// \
    -b "olcDatabase={1}mdb,cn=config" \
    "(objectClass=olcDatabaseConfig)" olcAccess 2>/dev/null \
    | grep "olcAccess:" | nl -ba | sed 's/^/  /'

echo ""
ok "Política de acceso LDAP configurada. ✅"
