#!/bin/bash
# ============================================================
# SCRIPT: erp.sh
# DESCRIPCIÓN: Script orquestador "todo en uno" para gestionar
#              el entorno de Odoo ERP de forma sencilla.
# USO: ./erp.sh [comando]
# ============================================================

# Cambia al directorio del script para evitar problemas de rutas
cd "$(dirname "$0")" || exit 1
PROJECT_DIR=$(pwd)
SCRIPTS_DIR="$PROJECT_DIR/scripts"

mostrar_ayuda() {
    echo "================================================="
    echo " Odoo ERP - Gestor de Entorno (TFG ASIR)"
    echo "================================================="
    echo "Uso: ./erp.sh [comando]"
    echo ""
    echo "Comandos disponibles:"
    echo "  deploy    - Levanta toda la infraestructura (Docker Compose)"
    echo "  backup    - Crea una copia de seguridad manual de la Base de Datos"
    echo "  restore   - Restaura la BD desde un archivo .dump"
    echo "  update    - Busca nuevas versiones de las imágenes Docker y actualiza"
    echo "  monitor   - Ejecuta el chequeo de salud y reinicia contenedores caídos"
    echo "  status    - Muestra el estado actual de los contenedores"
    echo "  logs      - Muestra los últimos logs de Docker y del monitor cron"
    echo "  help      - Muestra este menú de ayuda"
    echo "================================================="
}

case "$1" in
    deploy)
        bash "$SCRIPTS_DIR/deploy.sh"
        ;;
    backup)
        bash "$SCRIPTS_DIR/backup.sh"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "[ERROR] Faltan parámetros."
            echo "Uso: ./erp.sh restore <archivo.dump>"
            exit 1
        fi
        bash "$SCRIPTS_DIR/restore.sh" "$2"
        ;;
    update)
        bash "$SCRIPTS_DIR/update.sh"
        ;;
    monitor)
        bash "$SCRIPTS_DIR/monitor.sh"
        ;;
    status)
        echo "=== Estado de los contenedores Docker ==="
        docker compose -f "$PROJECT_DIR/docker/docker-compose.yml" ps
        ;;
    logs)
        echo "=== Últimos logs de contenedores (Docker) ==="
        docker compose -f "$PROJECT_DIR/docker/docker-compose.yml" logs --tail=20
        echo ""
        echo "=== Últimos eventos del Monitor (Cron) ==="
        tail -n 10 /var/log/erp_monitor.log 2>/dev/null || echo "No hay logs de monitor todavía."
        ;;
    help|--help|-h|"")
        mostrar_ayuda
        ;;
    *)
        echo "[ERROR] Comando desconocido: $1"
        mostrar_ayuda
        exit 1
        ;;
esac
