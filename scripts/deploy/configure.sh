#!/bin/bash
# ============================================================
# SCRIPT: configure.sh
# DESCRIPCIÓN: Configura interactivamente las contraseñas del
#              entorno usando la plantilla .env.example.
# USO: ./scripts/deploy/configure.sh
# ============================================================

# Rutas
PROJECT_DIR="/opt/erp-odoo"
ENV_TEMPLATE="$PROJECT_DIR/.env.example"
ENV_FILE="$PROJECT_DIR/docker/.env"

echo "=== Configuración del Entorno de Odoo ==="

# Verifica si la plantilla existe
if [ ! -f "$ENV_TEMPLATE" ]; then
    echo "[ERROR] No se encuentra la plantilla $ENV_TEMPLATE"
    exit 1
fi

# Crea el directorio docker si no existe
mkdir -p "$PROJECT_DIR/docker"

# Copia la plantilla si el .env no existe
if [ ! -f "$ENV_FILE" ]; then
    echo "Creando archivo .env a partir de la plantilla..."
    cp "$ENV_TEMPLATE" "$ENV_FILE"
else
    echo "El archivo $ENV_FILE ya existe. ¿Deseas sobreescribirlo? (y/n)"
    read -r respuesta
    if [ "$respuesta" = "y" ]; then
        cp "$ENV_TEMPLATE" "$ENV_FILE"
    else
        echo "Usando configuración existente."
        exit 0
    fi
fi

# Pide contraseñas por consola
echo "Por favor, introduce las contraseñas para el entorno de producción:"

# Postgres Password
echo -n "Contraseña de PostgreSQL (POSTGRES_PASSWORD): "
read -rs pg_pass
echo ""

# Odoo Master Password
echo -n "Contraseña Maestra de Odoo (ODOO_MASTER_PASSWORD): "
read -rs odoo_pass
echo ""

# Reemplaza en el archivo
# Usamos sed seguro para sustituir.
sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$pg_pass/" "$ENV_FILE"
sed -i "s/^ODOO_MASTER_PASSWORD=.*/ODOO_MASTER_PASSWORD=$odoo_pass/" "$ENV_FILE"

echo "[OK] Archivo $ENV_FILE configurado correctamente."
chmod 600 "$ENV_FILE" # Solo lectura/escritura para el dueño por seguridad
