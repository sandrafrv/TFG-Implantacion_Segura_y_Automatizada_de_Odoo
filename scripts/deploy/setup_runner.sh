#!/bin/bash
# ============================================================
# SCRIPT: setup_runner.sh
# DESCRIPCIÓN: Registra el servidor Debian como Self-Hosted
#              Runner de GitHub Actions.
#              Solo se ejecuta UNA VEZ en el servidor Debian.
#
# PRE-REQUISITOS:
#   1. Tener acceso a GitHub → tu repo → Settings → Actions
#      → Runners → "New self-hosted runner" → Linux.
#   2. Tener a mano la URL del repositorio y el token que
#      aparece en esa pantalla (caduca en 1 hora).
#   3. Ejecutar como el usuario administrador (NO como root).
#
# USO:
#   chmod +x scripts/deploy/setup_runner.sh
#   ./scripts/deploy/setup_runner.sh
#
# SEGURIDAD: Este script NO almacena el token en ningún archivo.
#            Se solicita de forma interactiva y solo vive en
#            memoria durante la ejecución.
# ============================================================

set -e

# --- VARIABLES ---

# Nombre con el que aparecerá el runner en GitHub (debe coincidir con el deploy.yml)
RUNNER_NAME="debian-dmz"

# Carpeta donde se instalará el agente del runner
RUNNER_DIR="$HOME/actions-runner"

# --- ENTRADA INTERACTIVA SEGURA ---
# Los datos sensibles se piden por teclado y nunca se escriben en disco.

echo "============================================="
echo " Configuración de GitHub Actions Self-Hosted Runner"
echo "============================================="
echo ""
echo "Necesitas los siguientes datos de GitHub:"
echo "  Ruta: tu repo → Settings → Actions → Runners → New self-hosted runner → Linux"
echo ""

# Pedir la URL del repositorio
read -rp "Introduce la URL del repositorio (ej: https://github.com/usuario/TFG-ASIRB): " REPO_URL

# Pedir el token sin mostrarlo en pantalla (como una contraseña)
read -rsp "Introduce el token de registro de GitHub (no se mostrará): " GITHUB_TOKEN
echo ""  # Salto de línea tras el input silencioso

# Validación básica para evitar errores por campos vacíos
if [ -z "$REPO_URL" ] || [ -z "$GITHUB_TOKEN" ]; then
    echo "[ERROR] La URL del repositorio y el token son obligatorios."
    exit 1
fi

# --- INSTALACIÓN ---

echo "============================================="
echo " Configuración de GitHub Actions Self-Hosted Runner"
echo " Servidor: $(hostname)"
echo " Runner:   $RUNNER_NAME"
echo " Repo:     $REPO_URL"
echo "============================================="

# Crear directorio de trabajo del runner
echo "[1/5] Creando directorio del runner en $RUNNER_DIR..."
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Descargar el agente del runner de GitHub (versión actual estable)
echo "[2/5] Descargando el agente de GitHub Actions..."
# Detecta la arquitectura del sistema automáticamente (x64 o arm64)
ARCH=$(dpkg --print-architecture)
if [ "$ARCH" = "amd64" ]; then
    RUNNER_ARCH="x64"
elif [ "$ARCH" = "arm64" ]; then
    RUNNER_ARCH="arm64"
else
    echo "[ERROR] Arquitectura no soportada: $ARCH"
    exit 1
fi

# Obtiene la última versión disponible del runner y la descarga
# Usamos || true para que set -e no aborte el script si grep falla por un límite de la API de GitHub
RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/' || true)

# Si la API falla (ej. por rate limit), usamos una versión fija conocida
if [ -z "$RUNNER_VERSION" ]; then
    echo "[AVISO] No se pudo obtener la última versión de la API (posible Rate Limit). Usando versión 2.322.0."
    RUNNER_VERSION="2.322.0"
fi

curl -sLO "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

echo "  → Versión descargada: v${RUNNER_VERSION} (${RUNNER_ARCH})"

# Extraer el paquete
echo "[3/5] Extrayendo el paquete del runner..."
tar xzf "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"
rm "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

# Instalar dependencias del sistema necesarias para el runner
echo "[4/5] Instalando dependencias del sistema..."
sudo ./bin/installdependencies.sh

# Registrar el runner en el repositorio de GitHub
# --url: el repositorio que controlará este runner
# --token: el token de registro temporal de GitHub
# --name: nombre identificativo del runner (debe coincidir con deploy.yml)
# --labels: etiquetas para filtrar en qué jobs se usa (debe coincidir con deploy.yml)
# --unattended: no hace preguntas interactivas
echo "[5/5] Registrando el runner en GitHub..."
./config.sh \
    --url "$REPO_URL" \
    --token "$GITHUB_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "self-hosted,debian-dmz,linux" \
    --work "_work" \
    --unattended

echo ""
echo "============================================="
echo " Runner configurado correctamente."
echo " Instalando como servicio systemd..."
echo "============================================="

# Instalar el runner como servicio systemd para que arranque automáticamente con el sistema
sudo ./svc.sh install
sudo ./svc.sh start

echo ""
echo "Estado del servicio del runner:"
sudo ./svc.sh status

echo ""
echo "[OK] El runner '$RUNNER_NAME' está activo y escuchando jobs de GitHub."
echo "     Puedes verificarlo en: $REPO_URL/settings/actions/runners"
