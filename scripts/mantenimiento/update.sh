#!/bin/bash
# ============================================================
# SCRIPT: update.sh
# DESCRIPCIÓN: Actualiza las imágenes Docker y recrea solo los
#       contenedores que hayan cambiado. Los volúmenes
#       (datos) se conservan intactos.
# USO: bash scripts/mantenimiento/update.sh
# NOTA: Requiere que .env exista en /opt/erp-odoo/.env (raíz).
# ============================================================

set -e

PROJECT_DIR="/opt/erp-odoo"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"

echo "Comprobando Docker..."
docker info &>/dev/null || { echo "[ERROR] Docker no está activo."; exit 1; }

[ ! -f "$ENV_FILE" ] && { echo "[ERROR] No existe $ENV_FILE. Ejecuta configure.sh primero."; exit 1; }

# Advertir si hay poco espacio
ESPACIO=$(df -BG /opt | awk 'NR==2 {gsub("G","",$4); print $4}')
if [ "$ESPACIO" -lt 2 ]; then
  echo "[WARNING] Poco espacio (${ESPACIO}GB). ¿Continuar? (s/N)"
  read -r r; [[ "${r,,}" != "s" ]] && exit 1
fi

cd "$PROJECT_DIR"

echo "Descargando nuevas versiones de imágenes..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull

echo "Recreando contenedores actualizados..."
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d

echo "Limpiando imágenes antiguas..."
docker image prune -f

echo "[OK] Actualización completada."
