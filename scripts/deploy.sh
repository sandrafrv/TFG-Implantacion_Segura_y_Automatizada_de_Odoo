#!/bin/bash
# ============================================================
# SCRIPT: deploy.sh
# DESCRIPCIÓN: Despliega toda la infraestructura de contenedores
#              Docker por primera vez (o la levanta si estaba parada).
# USO: ./deploy.sh
# ============================================================

# --- VARIABLES ---

# Ruta raíz del proyecto en el servidor Debian.
PROJECT_DIR="/opt/erp-odoo"

# --- DESPLIEGUE ---

echo "Cambiando al directorio raíz del proyecto: $PROJECT_DIR"
# Nos movemos a la raíz del proyecto para que las rutas relativas de los volúmenes sean correctas.
# El "|| exit 1" hace que el script se detenga si el cd falla (directorio no existe).
cd "$PROJECT_DIR" || exit 1

echo "Desplegando infraestructura Docker Compose..."
# docker compose up: lee el archivo yml y levanta todos los servicios definidos.
# -f especifica la ruta al archivo de configuración.
# -d (detached) arranca los contenedores en segundo plano.
docker compose -f docker/docker-compose.yml up -d

# --- VERIFICACIÓN ---

echo ""
echo "Estado actual de los contenedores:"
# Muestra el estado de todos los contenedores de este proyecto (UP, DOWN, etc.)
docker compose -f docker/docker-compose.yml ps
