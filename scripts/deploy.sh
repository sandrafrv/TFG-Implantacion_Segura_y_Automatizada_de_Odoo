#!/bin/bash
# Despliega la infraestructura de contenedores en segundo plano
COMPOSE_DIR="/opt/erp-odoo"

echo "Desplegando infraestructura Docker Compose..."
cd $COMPOSE_DIR
docker-compose up -d

echo "Estado actual:"
docker-compose ps
