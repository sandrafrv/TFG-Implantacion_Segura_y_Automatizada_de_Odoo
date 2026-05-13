#!/bin/bash
# ============================================================
# SCRIPT: configure.sh
# DESCRIPCIÓN: Crea el archivo docker/.env con las contraseñas
#              del entorno a partir de la plantilla .env.example.
# USO: bash scripts/deploy/configure.sh
# ============================================================

set -euo pipefail

PROJECT_DIR="/opt/erp-odoo"
ENV_TEMPLATE="$PROJECT_DIR/.env.example"
ENV_FILE="$PROJECT_DIR/docker/.env"

[ ! -f "$ENV_TEMPLATE" ] && { echo "[ERROR] No existe $ENV_TEMPLATE"; exit 1; }

mkdir -p "$PROJECT_DIR/docker"

if [ -f "$ENV_FILE" ]; then
    read -rp "El archivo $ENV_FILE ya existe. ¿Sobreescribir? (y/N): " r
    [[ "${r,,}" != "y" ]] && { echo "Usando configuración existente."; exit 0; }
fi

cp "$ENV_TEMPLATE" "$ENV_FILE"

echo "Introduce las contraseñas del entorno:"
read -rsp "POSTGRES_PASSWORD:      " PG;      echo ""
read -rsp "ODOO_MASTER_PASSWORD:   " ODOO;    echo ""
read -rsp "LDAP_ADMIN_PASSWORD:    " LDAP_A;  echo ""
read -rsp "LDAP_READONLY_PASSWORD: " LDAP_R;  echo ""

# Función segura para sed (soporta /, & y \ en contraseñas)
set_var() {
    local key="$1" val="$2"
    local escaped; escaped=$(printf '%s' "$val" | sed 's/[\/&]/\\&/g')
    sed -i "s|^${key}=.*|${key}=${escaped}|" "$ENV_FILE"
}

set_var POSTGRES_PASSWORD      "$PG"
set_var ODOO_MASTER_PASSWORD   "$ODOO"
set_var LDAP_ADMIN_PASSWORD    "$LDAP_A"
set_var LDAP_READONLY_PASSWORD "$LDAP_R"

chmod 600 "$ENV_FILE"
echo "[OK] $ENV_FILE configurado (permisos 600)."
