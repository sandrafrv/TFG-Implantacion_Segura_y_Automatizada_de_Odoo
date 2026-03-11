#!/bin/bash
# Actualiza las imágenes y recrea contenedores
COMPOSE_DIR="/opt/erp-odoo"

echo "Buscando nuevas actualizaciones de imágenes..."
cd $COMPOSE_DIR
docker-compose pull

echo "Aplicando cambios y recreando contenedores afectados..."
docker-compose up -d

echo "Limpiando imágenes huérfanas o antiguas..."
docker image prune -f

echo "Actualización completada y entorno limpio."
