#!/bin/bash
# ====================================================================
# SCRIPT: erp.sh
# DESCRIPCIÓN: Orquestador central del stack Odoo.
#              Menú interactivo para gestionar todos los aspectos
#              del ciclo de vida del ERP desde un único punto.
# USO: sudo ./erp.sh
# AUTOR: Sandra Fradejas Avedillo — TFG ASIR 2025/2026
# ====================================================================

# --- CONFIGURACIÓN ---
PROJECT_DIR="/opt/erp-odoo"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
LOG_FILE="/var/log/erp-odoo/erp.log"

# --- COLORES ANSI ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- FUNCIONES AUXILIARES ---

log() {
    local nivel="$1"; shift
    local mensaje="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] [$nivel] $mensaje" >> "$LOG_FILE"
}

ok()   { echo -e "${GREEN}  [OK]${NC} $*"; log "OK" "$*"; }
warn() { echo -e "${YELLOW}  [!]${NC}  $*"; log "WARN" "$*"; }
error(){ echo -e "${RED}  [ERROR]${NC} $*"; log "ERROR" "$*"; }
info() { echo -e "${CYAN}  [i]${NC}  $*"; log "INFO" "$*"; }

pausa() {
    echo ""
    read -rp "  Pulsa ENTER para volver al menú..."
}

requerir_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script debe ejecutarse como root o con sudo."
        exit 1
    fi
}

estado_contenedores() {
    echo -e "${BOLD}\n  Estado actual de los contenedores:${NC}"
    docker compose -f "$COMPOSE_FILE" ps --format \
        "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
        docker compose -f "$COMPOSE_FILE" ps
}

# --- CABECERA ---

cabecera() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║         GESTOR ERP ODOO — TFG ASIR 2025/2026            ║"
    echo "  ║         TechSolutions S.L. — Servidor DMZ               ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${CYAN}Nginx${NC}  → https://192.168.30.20"
    echo -e "  ${CYAN}Odoo${NC}   → https://192.168.30.21"
    echo -e "  ${CYAN}Logs${NC}   → $LOG_FILE"
    echo ""
}

# --- OPCIONES DEL MENÚ ---

opcion_estado() {
    cabecera
    echo -e "${BOLD}  ── Estado del Stack ──────────────────────────────────────${NC}"
    estado_contenedores
    echo ""
    info "Uso de recursos Docker:"
    docker stats --no-stream --format \
        "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null
    pausa
}

opcion_iniciar() {
    cabecera
    echo -e "${BOLD}  ── Iniciar Stack ─────────────────────────────────────────${NC}"
    info "Levantando contenedores..."
    log "INFO" "Iniciando stack Docker Compose"
    if docker compose -f "$COMPOSE_FILE" up -d; then
        ok "Stack iniciado correctamente."
        estado_contenedores
    else
        error "Fallo al iniciar el stack. Revisa los logs con la opción 7."
    fi
    pausa
}

opcion_parar() {
    cabecera
    echo -e "${BOLD}  ── Parar Stack ───────────────────────────────────────────${NC}"
    warn "Se van a detener todos los contenedores del stack."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Parando stack Docker Compose"
        docker compose -f "$COMPOSE_FILE" stop
        ok "Stack detenido."
    else
        info "Operación cancelada."
    fi
    pausa
}

opcion_reiniciar() {
    cabecera
    echo -e "${BOLD}  ── Reiniciar Stack ───────────────────────────────────────${NC}"
    warn "Se van a reiniciar todos los contenedores."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Reiniciando stack Docker Compose"
        docker compose -f "$COMPOSE_FILE" restart
        ok "Stack reiniciado."
        estado_contenedores
    else
        info "Operación cancelada."
    fi
    pausa
}

opcion_backup() {
    cabecera
    echo -e "${BOLD}  ── Backup de Base de Datos ───────────────────────────────${NC}"
    info "Ejecutando backup.sh..."
    log "INFO" "Lanzando backup.sh"
    if bash "$PROJECT_DIR/scripts/mantenimiento/backup.sh"; then
        ok "Backup completado."
    else
        error "El backup falló. Revisa $LOG_FILE para más detalles."
    fi
    pausa
}

opcion_restaurar() {
    cabecera
    echo -e "${BOLD}  ── Restaurar Base de Datos ───────────────────────────────${NC}"
    warn "ATENCIÓN: Esta operación sobreescribe la base de datos actual."
    echo ""
    info "Backups disponibles:"
    ls -lh /opt/erp-odoo/backups/*.dump 2>/dev/null || \
        warn "No se encontraron archivos .dump en /opt/erp-odoo/backups/"
    echo ""
    read -rp "  Introduce el nombre del archivo .dump a restaurar: " dump_file
    if [ -f "/opt/erp-odoo/backups/$dump_file" ]; then
        log "INFO" "Restaurando desde $dump_file"
        bash "$PROJECT_DIR/scripts/mantenimiento/restore.sh" "/opt/erp-odoo/backups/$dump_file"
    else
        error "Archivo no encontrado: /opt/erp-odoo/backups/$dump_file"
    fi
    pausa
}

opcion_actualizar() {
    cabecera
    echo -e "${BOLD}  ── Actualizar Imágenes Docker ────────────────────────────${NC}"
    warn "Se descargarán las últimas imágenes y se recrearán los contenedores."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Lanzando update.sh"
        bash "$PROJECT_DIR/scripts/mantenimiento/update.sh"
    else
        info "Operación cancelada."
    fi
    pausa
}

opcion_logs() {
    cabecera
    echo -e "${BOLD}  ── Logs de Contenedores ──────────────────────────────────${NC}"
    echo ""
    echo "  ¿De qué contenedor quieres ver los logs?"
    echo "  1) nginx-proxy"
    echo "  2) odoo-web"
    echo "  3) odoo_erp (PostgreSQL)"
    echo "  4) Todos (últimas 50 líneas)"
    echo ""
    read -rp "  Opción: " log_op
    case $log_op in
        1) docker logs nginx-proxy --tail 50 -f ;;
        2) docker logs odoo-web --tail 50 -f ;;
        3) docker logs odoo_erp --tail 50 -f ;;
        4) docker compose -f "$COMPOSE_FILE" logs --tail 50 -f ;;
        *) warn "Opción no válida." ;;
    esac
    pausa
}

opcion_monitor() {
    cabecera
    echo -e "${BOLD}  ── Monitor de Salud ──────────────────────────────────────${NC}"
    log "INFO" "Lanzando monitor.sh"
    bash "$PROJECT_DIR/scripts/mantenimiento/monitor.sh"
    pausa
}

opcion_despliegue_completo() {
    cabecera
    echo -e "${BOLD}  ── Despliegue Completo (Primera vez) ────────────────────${NC}"
    warn "Esto ejecuta deploy.sh — despliegue inicial con verificación de salud."
    read -rp "  ¿Confirmas? (s/N): " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        log "INFO" "Lanzando deploy.sh"
        bash "$SCRIPTS_DIR/deploy.sh"
    else
        info "Operación cancelada."
    fi
    pausa
}

# --- MENÚ PRINCIPAL ---

menu_principal() {
    while true; do
        cabecera
        echo -e "${BOLD}  ── Gestión del Stack ─────────────────────────────────────${NC}"
        echo "  1) Estado de contenedores y recursos"
        echo "  2) Iniciar stack"
        echo "  3) Parar stack"
        echo "  4) Reiniciar stack"
        echo ""
        echo -e "${BOLD}  ── Base de Datos ─────────────────────────────────────────${NC}"
        echo "  5) Hacer backup"
        echo "  6) Restaurar backup"
        echo ""
        echo -e "${BOLD}  ── Mantenimiento ─────────────────────────────────────────${NC}"
        echo "  7) Ver logs de contenedores"
        echo "  8) Monitor de salud"
        echo "  9) Actualizar imágenes Docker"
        echo " 10) Despliegue completo (primera vez / re-deploy)"
        echo ""
        echo -e "  ${RED}0) Salir${NC}"
        echo ""
        read -rp "  Selecciona una opción [0-10]: " opcion

        case $opcion in
            1)  opcion_estado ;;
            2)  opcion_iniciar ;;
            3)  opcion_parar ;;
            4)  opcion_reiniciar ;;
            5)  opcion_backup ;;
            6)  opcion_restaurar ;;
            7)  opcion_logs ;;
            8)  opcion_monitor ;;
            9)  opcion_actualizar ;;
            10) opcion_despliegue_completo ;;
            0)  echo -e "\n  ${GREEN}Hasta luego.${NC}\n"; log "INFO" "Sesión erp.sh cerrada"; exit 0 ;;
            *)  warn "Opción no válida. Elige entre 0 y 10."; sleep 1 ;;
        esac
    done
}

# --- ENTRADA ---

requerir_root
menu_principal
