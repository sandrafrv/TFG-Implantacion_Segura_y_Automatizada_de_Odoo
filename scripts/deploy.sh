#!/bin/bash
# ============================================================
# SCRIPT: deploy.sh
# DESCRIPCIÓN: Despliega toda la infraestructura de contenedores
#              Docker por primera vez (o la levanta si estaba parada).
# USO: ./deploy.sh
# ============================================================

# --- VARIABLES ---

# Ruta raíz del proyecto en el servidor Debian.
# Todos los archivos del repositorio deberían estar aquí.
PROJECT_DIR="/opt/erp-odoo"

# --- DESPLIEGUE ---

echo "Cambiando al directorio raíz del proyecto: $PROJECT_DIR"
# Nos movemos a la raíz del proyecto para que las rutas relativas de los volúmenes sean correctas
cd $PROJECT_DIR

echo "Desplegando infraestructura Docker Compose..."
# docker-compose up: lee el archivo yml y levanta todos los servicios definidos
#   -f docker/docker-compose.yml → especifica la ruta al archivo de configuración
#   -d (detached)               → arranca los contenedores en segundo plano (no bloquea la terminal)
docker-compose -f docker/docker-compose.yml up -d

# --- VERIFICACIÓN ---

echo ""
echo "Estado actual de los contenedores:"
# Muestra el estado de todos los contenedores de este proyecto (UP, DOWN, etc.)
docker-compose -f docker/docker-compose.yml ps
