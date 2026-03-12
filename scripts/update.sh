#!/bin/bash
# ============================================================
# SCRIPT: update.sh
# DESCRIPCIÓN: Actualiza el entorno Docker descargando las
#              últimas versiones de las imágenes base y
#              recreando los contenedores que hayan cambiado.
#              NO borra los datos (los volúmenes se conservan).
# USO: ./update.sh
# ============================================================

# --- VARIABLES ---

# Ruta raíz del proyecto en el servidor Debian.
PROJECT_DIR="/opt/erp-odoo"

# --- ACTUALIZACIÓN ---

echo "Cambiando al directorio raíz del proyecto..."
# El "|| exit 1" detiene el script si el directorio no existe.
cd "$PROJECT_DIR" || exit 1

echo "Buscando nuevas versiones de las imágenes Docker en Docker Hub..."
# docker compose pull: descarga las últimas versiones disponibles de todas las imágenes.
# Solo descarga si hay versión nueva; si no, no hace nada para esa imagen.
docker compose -f docker/docker-compose.yml pull

echo "Aplicando cambios y recreando solo los contenedores actualizados..."
# Volvemos a hacer 'up -d'. Docker Compose detecta qué imágenes han cambiado
# y solo recrea los contenedores afectados. Los que siguen igual se dejan intactos.
docker compose -f docker/docker-compose.yml up -d

echo "Limpiando imágenes huérfanas o versiones antiguas..."
# 'prune' borra de disco las imágenes viejas que ya no usan ningún contenedor.
# El flag -f (force) omite la confirmación manual del usuario.
docker image prune -f

echo "Actualización completada. El entorno está limpio y actualizado."
