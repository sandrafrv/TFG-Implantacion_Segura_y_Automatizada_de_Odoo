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

# --- COMPROBACIONES PREVIAS ---
echo "Realizando comprobaciones previas..."

# 1. Comprobar Docker
if ! docker info &> /dev/null; then
    echo "[ERROR] El servicio de Docker no está activo o no tienes permisos."
    exit 1
fi

# 2. Espacio libre en disco
ESPACIO_LIBRE=$(df -BG /opt | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$ESPACIO_LIBRE" -lt 2 ]; then
    echo "[WARNING] Espacio en disco bajo (${ESPACIO_LIBRE}GB libres). La actualización podría fallar si las imágenes son grandes."
    echo "¿Deseas continuar? (y/n)"
    read -r respuesta
    if [ "$respuesta" != "y" ]; then
        exit 1
    fi
fi

# 3. Cambiando de directorio y validando compose
echo "Cambiando al directorio raíz del proyecto..."
cd "$PROJECT_DIR" || exit 1

if ! docker compose -f docker/docker-compose.yml config -q; then
    echo "[ERROR] El archivo docker-compose.yml tiene errores de sintaxis. Abortando actualización."
    exit 1
fi

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
