#!/bin/bash
# ============================================================
# SCRIPT: install.sh
# DESCRIPCIÓN: Instalador todo-en-uno para desplegar el ERP
#              en un servidor Debian 12 limpio.
# USO: sudo ./install.sh
# ============================================================

set -e

# --- VARIABLES ---
PROJECT_DIR="/opt/erp-odoo"
REPO_URL="https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git" 

# --- VERIFICACIÓN ---
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Este script debe ejecutarse como root (sudo ./install.sh)"
    exit 1
fi

echo "=== Iniciando instalación de Odoo ERP ==="

# 1. Instalar paquetes base
echo "[1/6] Instalando dependencias del sistema..."
apt-get update
apt-get install -y git curl openssl cockpit docker.io docker-compose

# 2. Habilitar servicios base
systemctl enable --now cockpit.socket
systemctl enable --now docker

# 3. Clonar el repositorio
echo "[2/6] Preparando el directorio del proyecto..."
if [ ! -d "$PROJECT_DIR/.git" ]; then
    echo "Clonando repositorio en $PROJECT_DIR..."
    # Si la carpeta existe pero está vacía o no es git, clonamos temporalmente y movemos
    git clone "$REPO_URL" "${PROJECT_DIR}_temp"
    cp -rn "${PROJECT_DIR}_temp/." "$PROJECT_DIR/"
    rm -rf "${PROJECT_DIR}_temp"
    cd "$PROJECT_DIR"
else
    echo "El repositorio ya existe en $PROJECT_DIR. Actualizando..."
    cd "$PROJECT_DIR"
    git fetch --all
    git reset --hard origin/main
fi

cd "$PROJECT_DIR"

# 4. Crear estructura de directorios y permisos
echo "[3/6] Creando estructura de directorios..."
mkdir -p data/postgres data/odoo_addons data/odoo_web backups certs docker
# Dar permisos universales a las carpetas montadas para evitar Permission denied (Errno 13)
# ya que los contenedores usan usuarios no-root internamente (ej. uid 101 para odoo)
chmod -R 777 data/ backups/
chmod +x scripts/*.sh

# 5. Generar certificados SSL autofirmados
echo "[4/6] Configurando certificados SSL..."
if [ ! -f "certs/server.crt" ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout certs/server.key -out certs/server.crt \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/OU=IT/CN=erp.techsolutions.local"
    echo "Certificados autofirmados generados en certs/"
else
    echo "Los certificados ya existen. Omitiendo."
fi

# 6. Configuración interactiva del entorno
echo "[5/6] Configurando entorno (.env)..."
./scripts/configure.sh

# 7. Despliegue y Cron
echo "[6/6] Desplegando Docker e instalando tareas programadas..."
./scripts/deploy.sh
./scripts/install_cron.sh

echo "=== Instalación completada con éxito ==="
echo "Accede a Cockpit en: https://[IP_SERVIDOR]:9090"
echo "Accede a Odoo en: https://[IP_SERVIDOR]"
