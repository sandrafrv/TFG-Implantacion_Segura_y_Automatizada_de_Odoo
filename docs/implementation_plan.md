# Plan de Implementación — Infraestructura como Código
## TFG: Implantación Segura y Automatizada de Odoo
### GitHub como Plataforma Central de Despliegue

**Proyecto:** TFG — Implantación Segura y Automatizada de Odoo
**Repositorio:** [sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo](https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo)
**Autores:** Sandra Fradejas Avedillo · Mario García García · Javier Córdoba Del Valle
**Centro:** IES Cañaveral — ASIR 2025/2026

---

## Resumen ejecutivo

Este documento describe la arquitectura completa de la infraestructura del TFG, donde **GitHub actúa como fuente de verdad y plataforma central de despliegue**. Todo el estado deseado del sistema — scripts de configuración, red MACVLAN, hardening SSH, roles de Odoo y el propio stack Docker — está versionado en el repositorio. El servidor Debian no decide nada por sí mismo: aplica exactamente lo que hay en la rama `main` cada vez que el pipeline de CI/CD se dispara.

El enfoque seguido es **Infrastructure as Code (IaC)**: si el servidor se pierde o hay que replicar el entorno, basta con registrar un nuevo runner y hacer un push a `main` para restaurar todo el sistema automáticamente.

---

## 1. Arquitectura general

### 1.1 Principio de funcionamiento

```
Desarrollador / Admin
       │
       │  git push → rama feature/...
       ▼
┌─────────────────────────────────────────────┐
│              GitHub                         │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │  CI Validator (ci.yml)               │   │
│  │  ├── ShellCheck scripts/*.sh         │   │
│  │  ├── Validar docker-compose.yml      │   │
│  │  └── Lint Markdown                   │   │
│  └──────────────────────────────────────┘   │
│            │ (solo si pasa)                 │
│  ┌──────────────────────────────────────┐   │
│  │  CD Deploy (deploy.yml)              │   │
│  │  runs-on: self-hosted                │   │
│  │  ├── git reset --hard origin/main    │   │
│  │  ├── Fase 1: Preparación host        │   │
│  │  ├── Fase 2: Red MACVLAN             │   │
│  │  ├── Fase 3: Hardening SSH + DBA     │   │
│  │  ├── Fase 4: Docker stack up         │   │
│  │  └── Fase 5: Roles Odoo             │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
       │  self-hosted runner (corre en el propio servidor)
       ▼
┌─────────────────────────────────────────────┐
│         Servidor Debian (192.168.30.10)     │
│  ├── Contenedor Odoo    (192.168.30.21)     │
│  └── Contenedor PostgreSQL (192.168.30.22) │
└─────────────────────────────────────────────┘
```

### 1.2 Regla fundamental

> **Nunca se ejecuta nada manualmente en el servidor en producción.**
> Cualquier cambio se hace en el repositorio, pasa por CI, y se despliega automáticamente.
> La única excepción es la instalación inicial del runner (`setup_runner.sh`), que se hace una sola vez.

### 1.3 Topología de red

| Elemento | IP | VLAN | Rol |
|---|---|---|---|
| pfSense (gateway LAN) | 192.168.10.1 | VLAN 10 | Firewall / enrutador |
| pfSense (gateway DMZ) | 192.168.30.1 | VLAN 30 | Firewall / enrutador |
| pfSense (gateway Admin) | 192.168.40.1 | **VLAN 40** | Firewall / enrutador |
| Servidor Debian (host) | 192.168.30.10 | VLAN 30 | Self-hosted runner + Docker host |
| Contenedor Odoo | 192.168.30.21 | VLAN 30 | Aplicación ERP (MACVLAN) |
| Contenedor PostgreSQL | 192.168.30.22 | VLAN 30 | Base de datos (MACVLAN) |
| Subinterfaz host MACVLAN | 192.168.30.23 | VLAN 30 | Comunicación host ↔ contenedores |
| Máquina Admin | 192.168.40.11 | **VLAN 40** | Administración SSH |
| Máquina DBA | 192.168.40.12 | **VLAN 40** | Acceso PostgreSQL vía túnel SSH |
| Clientes Odoo | 192.168.10.x | VLAN 10 | Acceso web HTTPS |

> **Por qué VLAN 40 separada:** Si un atacante compromete Odoo (VLAN 30), no puede alcanzar las máquinas de administración. Las reglas de pfSense `VLAN30→VLAN40 BLOCK` y `VLAN10→VLAN40 BLOCK` garantizan ese aislamiento.

---

## 2. Estructura del repositorio

```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
│
├── .github/
│   └── workflows/
│       ├── ci.yml              ← Validación automática (ShellCheck, YAML, Markdown)
│       └── deploy.yml          ← Despliegue automático (self-hosted runner)
│
├── scripts/
│   ├── setup_runner.sh         ← [EXISTENTE] Instala el runner de GitHub Actions
│   ├── deploy.sh               ← [EXISTENTE] Levanta el stack Docker
│   ├── backup.sh               ← [EXISTENTE] Backup de PostgreSQL
│   ├── restore.sh              ← [EXISTENTE] Restauración de backup
│   ├── monitor.sh              ← [EXISTENTE] Monitorización del stack
│   ├── update.sh               ← [EXISTENTE] Actualización de imágenes Docker
│   ├── configure.sh            ← [EXISTENTE] Configuración post-despliegue
│   ├── install_cron.sh         ← [EXISTENTE] Configura tareas programadas
│   │
│   ├── headless_check.sh       ← [NUEVO] Configura Debian sin interfaz gráfica
│   ├── ssh_hardening.sh        ← [NUEVO] Restringe SSH a Admin y DBA + UFW
│   ├── dba_user_setup.sh       ← [NUEVO] Crea usuario sistema DBA (solo túneles)
│   ├── macvlan_setup.sh        ← [NUEVO] Crea red Docker MACVLAN
│   └── odoo_init_roles.sh      ← [NUEVO] Crea departamentos y roles en Odoo
│
├── docker/
│   └── docker-compose.yml      ← Stack Odoo + PostgreSQL + Nginx con IPs MACVLAN
│
├── nginx/
│   └── odoo.conf               ← Configuración reverse proxy
│
├── .env.example                ← Variables de entorno (sin secretos reales)
└── README.md
```

---

## 3. Pipeline CI/CD detallado

### 3.1 Fase CI — `ci.yml`

Se ejecuta en cada push o Pull Request a `main`. Valida:
- Sintaxis YAML de `docker-compose.yml` con `yamllint` y `docker compose config -q`.
- Todos los scripts `.sh` con **ShellCheck**.
- Documentación Markdown con `markdownlint`.

### 3.2 Fase CD — `deploy.yml` ampliado

```yaml
name: CD Deploy (Self-Hosted)

on:
  workflow_run:
    workflows: ["CI Validator"]
    types:
      - completed
    branches:
      - main

jobs:

  deploy:
    name: Desplegar Stack en Servidor Debian
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: self-hosted

    steps:

      - name: Verificar entorno del servidor
        run: |
          echo "============================================="
          echo " Iniciando despliegue automático"
          echo " Servidor: $(hostname)"
          echo " Fecha:    $(date '+%Y-%m-%d %H:%M:%S')"
          echo " Docker:   $(docker --version)"
          echo "============================================="

      - name: Marcar directorio del proyecto como seguro para Git
        run: git config --global --add safe.directory /opt/erp-odoo

      # ── FASE 0: Sincronización ───────────────────────────────────────────
      - name: Sincronizar repositorio (git pull)
        working-directory: /opt/erp-odoo
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          git remote set-url origin https://x-access-token:${GH_TOKEN}@github.com/${{ github.repository }}.git
          git fetch origin
          git reset --hard origin/main
          echo "Repositorio actualizado al commit: $(git rev-parse --short HEAD)"

      # ── FASE 1: Preparación del host ─────────────────────────────────────
      - name: "[1/5] Configurar modo headless"
        working-directory: /opt/erp-odoo
        run: sudo bash scripts/headless_check.sh

      # ── FASE 2: Red MACVLAN ──────────────────────────────────────────────
      - name: "[2/5] Configurar red MACVLAN"
        working-directory: /opt/erp-odoo
        env:
          PARENT_IFACE: ${{ vars.PARENT_IFACE }}
          SUBNET: ${{ vars.SUBNET }}
          GATEWAY: ${{ vars.GATEWAY }}
          ODOO_IP: ${{ vars.ODOO_IP }}
          POSTGRES_IP: ${{ vars.POSTGRES_IP }}
          HOST_MACVLAN_IP: ${{ vars.HOST_MACVLAN_IP }}
        run: sudo -E bash scripts/macvlan_setup.sh

      # ── FASE 3: Hardening SSH + usuario DBA ──────────────────────────────
      - name: "[3/5] SSH hardening y usuario DBA"
        working-directory: /opt/erp-odoo
        env:
          ADMIN_IP: ${{ secrets.ADMIN_IP }}
          DBA_IP: ${{ secrets.DBA_IP }}
          DBA_PUBKEY: ${{ secrets.DBA_PUBKEY }}
        run: |
          sudo -E bash scripts/ssh_hardening.sh
          sudo -E bash scripts/dba_user_setup.sh

      # ── FASE 4: Despliegue Docker ─────────────────────────────────────────
      - name: "[4/5] Descargar imágenes Docker"
        run: |
          docker pull postgres:16
          docker pull odoo:17
          docker pull nginx:alpine

      - name: "[4/5] Ejecutar deploy.sh"
        working-directory: /opt/erp-odoo
        run: bash scripts/deploy.sh

      # ── FASE 5: Postconfiguración Odoo ───────────────────────────────────
      - name: "[5/5] Inicializar departamentos y roles en Odoo"
        working-directory: /opt/erp-odoo
        run: |
          echo "Esperando a que Odoo esté disponible..."
          sleep 20
          bash scripts/odoo_init_roles.sh

      # ── VERIFICACIÓN FINAL ────────────────────────────────────────────────
      - name: Verificar estado del stack
        working-directory: /opt/erp-odoo
        run: |
          echo "Estado final de los contenedores:"
          docker compose -f docker/docker-compose.yml ps
          echo ""
          echo "[OK] Despliegue completado con éxito."
```

---

## 4. Secrets y variables en GitHub

### 4.1 Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Descripción | Valor |
|---|---|---|
| `ADMIN_IP` | IP máquina administración | `192.168.40.11` (VLAN 40) |
| `DBA_IP` | IP máquina DBA | `192.168.40.12` (VLAN 40) |
| `DBA_PUBKEY` | Clave pública SSH del usuario DBA | `ssh-rsa AAAA...` |
| `ODOO_ADMIN_PASSWORD` | Contraseña del administrador de Odoo | — |
| `POSTGRES_PASSWORD` | Contraseña de PostgreSQL | — |

### 4.2 Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Valor ejemplo | Descripción |
|---|---|---|
| `PARENT_IFACE` | `eth0` | Interfaz de red física del servidor |
| `SUBNET` | `192.168.30.0/24` | Subred VLAN DMZ |
| `GATEWAY` | `192.168.30.1` | pfSense gateway DMZ |
| `ODOO_IP` | `192.168.30.21` | IP fija contenedor Odoo |
| `POSTGRES_IP` | `192.168.30.22` | IP fija contenedor PostgreSQL |
| `HOST_MACVLAN_IP` | `192.168.30.23` | IP subinterfaz MACVLAN del host |
| `ODOO_DB` | `odoo` | Nombre de la base de datos |
| `ODOO_URL` | `http://localhost:8069` | URL interna de Odoo |

---

## 5. Scripts nuevos — Código completo

### 5.1 `scripts/headless_check.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# SCRIPT: headless_check.sh
# DESCRIPCIÓN: Verifica que el servidor Debian no tenga entorno
#              gráfico instalado y lo configura en modo headless.
# USO: sudo bash scripts/headless_check.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "Ejecutar como root: sudo bash $0"; exit 1
fi

log_info "=== Verificación y configuración del modo headless ==="

GRAPHICAL_PACKAGES="xorg xserver-xorg gnome kde-plasma-desktop xfce4 lxde mate-desktop-environment"
DISPLAY_MANAGERS="gdm gdm3 lightdm sddm xdm"
FOUND_PACKAGES=""

for pkg in $GRAPHICAL_PACKAGES $DISPLAY_MANAGERS; do
    if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
        FOUND_PACKAGES="$FOUND_PACKAGES $pkg"
    fi
done

if [ -n "$FOUND_PACKAGES" ]; then
    log_warn "Paquetes gráficos encontrados:$FOUND_PACKAGES"
    if [ -t 0 ]; then
        read -r -p "¿Eliminar? [s/N]: " CONFIRM
        [ "$CONFIRM" = "s" ] || [ "$CONFIRM" = "S" ] || { log_warn "Omitido."; exit 0; }
    fi
    # shellcheck disable=SC2086
    apt-get purge -y $FOUND_PACKAGES
    apt-get autoremove -y && apt-get autoclean
    log_ok "Paquetes gráficos eliminados."
else
    log_ok "No se encontraron paquetes de entorno gráfico."
fi

for dm in $DISPLAY_MANAGERS; do
    if systemctl is-enabled "$dm" 2>/dev/null | grep -q "enabled"; then
        systemctl disable "$dm" --now || true
        log_ok "$dm deshabilitado."
    fi
done

systemctl set-default multi-user.target
CURRENT_TARGET=$(systemctl get-default)
if [ "$CURRENT_TARGET" = "multi-user.target" ]; then
    log_ok "Servidor configurado en modo headless (multi-user.target)."
else
    log_error "Target incorrecto: ${CURRENT_TARGET}"; exit 1
fi
```

---

### 5.2 `scripts/ssh_hardening.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# SCRIPT: ssh_hardening.sh
# DESCRIPCIÓN: Restringe acceso SSH al servidor únicamente
#              desde la IP Admin (VLAN 40) y la IP DBA (VLAN 40).
#              Configura UFW con política de denegación por defecto.
# USO: ADMIN_IP=192.168.40.11 DBA_IP=192.168.40.12 sudo -E bash scripts/ssh_hardening.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "Ejecutar como root: sudo -E bash $0"; exit 1
fi

if [ -z "${ADMIN_IP:-}" ]; then
    read -r -p "IP de la máquina Admin (VLAN 40): " ADMIN_IP
fi
[ -z "${ADMIN_IP:-}" ] && { log_error "ADMIN_IP no definida."; exit 1; }

DBA_IP="${DBA_IP:-}"

log_info "=== SSH Hardening — Admin: ${ADMIN_IP} (VLAN 40) | DBA: ${DBA_IP:-no definido} (VLAN 40) ==="

command -v ufw > /dev/null 2>&1 || apt-get install -y ufw

BACKUP_FILE="/etc/ssh/sshd_config.bak.$(date +%Y%m%d_%H%M%S)"
cp /etc/ssh/sshd_config "$BACKUP_FILE"
log_ok "Backup: ${BACKUP_FILE}"

sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
grep -q "^PermitRootLogin"        /etc/ssh/sshd_config || echo "PermitRootLogin no"        >> /etc/ssh/sshd_config
grep -q "^PubkeyAuthentication"   /etc/ssh/sshd_config || echo "PubkeyAuthentication yes"  >> /etc/ssh/sshd_config
log_ok "Configuración SSH aplicada."

ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# SSH solo desde VLAN 40 (administración)
ufw allow from "$ADMIN_IP" to any port 22 proto tcp comment "SSH Admin - VLAN40"
log_ok "SSH permitido desde Admin: ${ADMIN_IP} (VLAN 40)"

if [ -n "$DBA_IP" ]; then
    ufw allow from "$DBA_IP" to any port 22 proto tcp comment "SSH DBA túnel - VLAN40"
    log_ok "SSH permitido desde DBA: ${DBA_IP} (VLAN 40)"
fi

ufw allow 443/tcp comment "HTTPS Odoo"
ufw --force enable

systemctl restart sshd
log_ok "UFW activo. SSH reiniciado."

echo ""
log_info "=== Resumen ==="
echo "  PasswordAuthentication : no"
echo "  PermitRootLogin        : no"
echo "  SSH Admin              : ${ADMIN_IP} (VLAN 40) → ALLOW"
echo "  SSH DBA                : ${DBA_IP:-no configurado} (VLAN 40)"
echo "  Puerto 443 HTTPS       : ABIERTO"
echo "  Todo lo demás          : BLOQUEADO"
log_warn "Verifica acceso desde Admin (VLAN 40) antes de cerrar esta sesión."
```

---

### 5.3 `scripts/dba_user_setup.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# SCRIPT: dba_user_setup.sh
# DESCRIPCIÓN: Crea usuario de sistema 'odoo-dba' con acceso
#              SSH restringido exclusivamente a túneles TCP.
#              Sin shell interactiva, sin sudo.
#              El DBA se conecta desde VLAN 40 (192.168.40.12).
# USO: DBA_PUBKEY="ssh-rsa AAAA..." sudo -E bash scripts/dba_user_setup.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "Ejecutar como root: sudo bash $0"; exit 1
fi

DBA_USER="odoo-dba"
DBA_HOME="/home/${DBA_USER}"
DBA_SSH_DIR="${DBA_HOME}/.ssh"
DBA_PUBKEY="${DBA_PUBKEY:-}"

log_info "=== Configuración usuario DBA: ${DBA_USER} ==="

if id "$DBA_USER" > /dev/null 2>&1; then
    log_warn "Usuario '${DBA_USER}' ya existe."
else
    useradd --create-home --shell /usr/sbin/nologin \
        --comment "DBA Odoo - solo SSH tunnel desde VLAN 40" "$DBA_USER"
    log_ok "Usuario '${DBA_USER}' creado (sin shell interactiva)."
fi

mkdir -p "$DBA_SSH_DIR"
chmod 700 "$DBA_SSH_DIR"
chown "${DBA_USER}:${DBA_USER}" "$DBA_SSH_DIR"

if [ -n "$DBA_PUBKEY" ]; then
    echo "$DBA_PUBKEY" > "${DBA_SSH_DIR}/authorized_keys"
    chmod 600 "${DBA_SSH_DIR}/authorized_keys"
    chown "${DBA_USER}:${DBA_USER}" "${DBA_SSH_DIR}/authorized_keys"
    log_ok "Clave pública DBA registrada."
else
    log_warn "DBA_PUBKEY no definida. Añade la clave manualmente en:"
    log_warn "  ${DBA_SSH_DIR}/authorized_keys"
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
MARKER="# dba_user_setup — bloque DBA"

if grep -q "$MARKER" "$SSHD_CONFIG"; then
    log_warn "Bloque DBA ya existe en sshd_config."
else
    cat >> "$SSHD_CONFIG" << SSHBLOCK

${MARKER}
Match User ${DBA_USER}
    AllowTcpForwarding yes
    X11Forwarding no
    PermitTTY no
    ForceCommand /bin/false
    PasswordAuthentication no
    PubkeyAuthentication yes
SSHBLOCK
    log_ok "Bloque SSH restrictivo DBA añadido."
fi

systemctl restart sshd
log_ok "SSH reiniciado."

echo ""
log_info "=== Resumen usuario DBA ==="
echo "  Usuario             : ${DBA_USER}"
echo "  Shell               : /usr/sbin/nologin"
echo "  Túneles TCP         : PERMITIDOS"
echo "  Shell remota        : DENEGADA (ForceCommand /bin/false)"
echo "  Autenticación       : solo clave pública"
echo "  Acceso desde        : VLAN 40 (192.168.40.12)"
echo ""
log_info "Cómo conectarse desde la máquina DBA (VLAN 40):"
log_info "  ssh -N -L 5433:192.168.30.22:5432 odoo-dba@192.168.30.10"
log_info "  psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp"
```

---

### 5.4 `scripts/macvlan_setup.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# SCRIPT: macvlan_setup.sh
# DESCRIPCIÓN: Crea la red Docker MACVLAN para que los
#              contenedores tengan IP propia en la red física.
#              Crea subinterfaz en el host para comunicación
#              host ↔ contenedores.
# USO: sudo -E bash scripts/macvlan_setup.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [ "$(id -u)" -ne 0 ]; then
    log_error "Ejecutar como root: sudo -E bash $0"; exit 1
fi

PARENT_IFACE="${PARENT_IFACE:-}"
SUBNET="${SUBNET:-192.168.30.0/24}"
GATEWAY="${GATEWAY:-192.168.30.1}"
ODOO_IP="${ODOO_IP:-192.168.30.21}"
POSTGRES_IP="${POSTGRES_IP:-192.168.30.22}"
HOST_MACVLAN_IP="${HOST_MACVLAN_IP:-192.168.30.23}"
DOCKER_NET_NAME="${DOCKER_NET_NAME:-macvlan_vlan30}"
IP_RANGE="${IP_RANGE:-192.168.30.21/29}"
MACVLAN_HOST_IFACE="macvlan_host"

log_info "=== Configuración de red MACVLAN (VLAN 30 - DMZ) ==="

if [ -z "$PARENT_IFACE" ]; then
    PARENT_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    [ -z "$PARENT_IFACE" ] && { log_error "No se pudo detectar interfaz. Define PARENT_IFACE."; exit 1; }
    log_info "Interfaz detectada: ${PARENT_IFACE}"
fi

command -v docker > /dev/null 2>&1 || { log_error "Docker no instalado."; exit 1; }

if docker network inspect "$DOCKER_NET_NAME" > /dev/null 2>&1; then
    log_warn "Red '${DOCKER_NET_NAME}' ya existe."
else
    docker network create \
        --driver macvlan \
        --subnet="$SUBNET" \
        --gateway="$GATEWAY" \
        --ip-range="$IP_RANGE" \
        --opt parent="$PARENT_IFACE" \
        "$DOCKER_NET_NAME"
    log_ok "Red Docker MACVLAN '${DOCKER_NET_NAME}' creada."
fi

if ip link show "$MACVLAN_HOST_IFACE" > /dev/null 2>&1; then
    log_warn "Subinterfaz ${MACVLAN_HOST_IFACE} ya existe."
else
    ip link add "$MACVLAN_HOST_IFACE" link "$PARENT_IFACE" type macvlan mode bridge
    ip addr add "${HOST_MACVLAN_IP}/32" dev "$MACVLAN_HOST_IFACE"
    ip link set "$MACVLAN_HOST_IFACE" up
    ip route add "$ODOO_IP/32"      dev "$MACVLAN_HOST_IFACE"
    ip route add "$POSTGRES_IP/32"  dev "$MACVLAN_HOST_IFACE"
    log_ok "Subinterfaz ${MACVLAN_HOST_IFACE} activa con IP ${HOST_MACVLAN_IP}."
fi

RC_LOCAL="/etc/rc.local"
MARKER="# macvlan_setup — TFG"
if ! grep -q "$MARKER" "$RC_LOCAL" 2>/dev/null; then
    [ ! -f "$RC_LOCAL" ] && { printf '#!/bin/sh -e\nexit 0\n' > "$RC_LOCAL"; chmod +x "$RC_LOCAL"; }
    sed -i "/^exit 0/i \\
${MARKER}\\
ip link add ${MACVLAN_HOST_IFACE} link ${PARENT_IFACE} type macvlan mode bridge 2>/dev/null || true\\
ip addr add ${HOST_MACVLAN_IP}/32 dev ${MACVLAN_HOST_IFACE} 2>/dev/null || true\\
ip link set ${MACVLAN_HOST_IFACE} up 2>/dev/null || true\\
ip route add ${ODOO_IP}/32 dev ${MACVLAN_HOST_IFACE} 2>/dev/null || true\\
ip route add ${POSTGRES_IP}/32 dev ${MACVLAN_HOST_IFACE} 2>/dev/null || true" "$RC_LOCAL"
    log_ok "Configuración persistente añadida en ${RC_LOCAL}."
fi

echo ""
log_info "=== Resumen MACVLAN ==="
echo "  Interfaz física       : ${PARENT_IFACE}"
echo "  Red Docker            : ${DOCKER_NET_NAME}"
echo "  IP contenedor Odoo    : ${ODOO_IP}"
echo "  IP contenedor Postgres: ${POSTGRES_IP}"
echo "  IP host (subinterfaz) : ${HOST_MACVLAN_IP}"
log_ok "MACVLAN configurado. Actualiza docker-compose.yml con las IPs fijas."
```

---

### 5.5 `scripts/odoo_init_roles.sh`

```bash
#!/usr/bin/env bash
# ============================================================
# SCRIPT: odoo_init_roles.sh
# DESCRIPCIÓN: Crea departamentos, perfiles y usuarios en Odoo
#              mediante API XML-RPC. Solo usa curl.
# USO: bash scripts/odoo_init_roles.sh
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
[ -f "$ENV_FILE" ] || { log_error ".env no encontrado en ${ENV_FILE}"; exit 1; }
# shellcheck disable=SC1090
. "$ENV_FILE"

ODOO_URL="${ODOO_URL:-http://localhost:8069}"
ODOO_DB="${ODOO_DB:-odoo}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
[ -z "$ADMIN_PASSWORD" ] && { log_error "ADMIN_PASSWORD no definida en .env"; exit 1; }

log_info "Verificando disponibilidad de Odoo en ${ODOO_URL}..."
MAX_RETRIES=12; RETRY=0
until curl -s --max-time 5 "${ODOO_URL}/web/database/selector" > /dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    [ "$RETRY" -ge "$MAX_RETRIES" ] && { log_error "Odoo no disponible tras ${MAX_RETRIES} intentos."; exit 1; }
    log_warn "Reintento ${RETRY}/${MAX_RETRIES}..."; sleep 5
done
log_ok "Odoo disponible."

xmlrpc_call() {
    curl -s -X POST -H "Content-Type: text/xml" --data "$2" "${ODOO_URL}/${1}"
}

AUTH_XML="<?xml version='1.0'?>
<methodCall><methodName>authenticate</methodName><params>
  <param><value><string>${ODOO_DB}</string></value></param>
  <param><value><string>${ADMIN_USER}</string></value></param>
  <param><value><string>${ADMIN_PASSWORD}</string></value></param>
  <param><value><struct></struct></value></param>
</params></methodCall>"

UID=$(xmlrpc_call "xmlrpc/2/common" "$AUTH_XML" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1)
[ -z "$UID" ] || [ "$UID" = "0" ] && { log_error "Autenticación fallida."; exit 1; }
log_ok "Autenticado. UID: ${UID}"

odoo_create() {
    local model="$1"; local fields_xml="$2"
    local call_xml="<?xml version='1.0'?>
<methodCall><methodName>execute_kw</methodName><params>
  <param><value><string>${ODOO_DB}</string></value></param>
  <param><value><int>${UID}</int></value></param>
  <param><value><string>${ADMIN_PASSWORD}</string></value></param>
  <param><value><string>${model}</string></value></param>
  <param><value><string>create</string></value></param>
  <param><value><array><data><value><struct>${fields_xml}</struct></value></data></array></value></param>
  <param><value><struct></struct></value></param>
</params></methodCall>"
    xmlrpc_call "xmlrpc/2/object" "$call_xml" | grep -oP '(?<=<int>)\d+(?=</int>)' | head -1
}

create_dept() {
    local name="$1"
    local id; id=$(odoo_create "hr.department" "<member><name>name</name><value><string>${name}</string></value></member>")
    [ -n "$id" ] && log_ok "Departamento '${name}' → ID ${id}" || log_warn "No se pudo crear '${name}'"
    echo "$id"
}

log_info "=== Creando departamentos ==="
create_dept "Ventas"
create_dept "Almacén"
create_dept "Recursos Humanos"
create_dept "Contabilidad"
create_dept "IT / Administración"

create_user() {
    local fullname="$1"; local login="$2"; local pass="$3"; local gid="$4"
    local fields="
      <member><name>name</name><value><string>${fullname}</string></value></member>
      <member><name>login</name><value><string>${login}</string></value></member>
      <member><name>password</name><value><string>${pass}</string></value></member>
      <member><name>groups_id</name><value><array><data>
        <value><array><data><value><int>4</int></value><value><int>${gid}</int></value></data></array></value>
      </data></array></value></member>"
    local uid; uid=$(odoo_create "res.users" "$fields")
    [ -n "$uid" ] && log_ok "Usuario '${login}' → ID ${uid}" || log_warn "No se pudo crear '${login}'"
}

log_info "=== Creando usuarios ==="
create_user "Usuario Ventas"       "ventas.usuario"      "Ventas2024!"   "2"
create_user "Responsable Ventas"   "ventas.responsable"  "Ventas2024!"   "2"
create_user "Operario Almacén"     "almacen.operario"    "Almacen2024!"  "2"
create_user "Responsable Almacén"  "almacen.responsable" "Almacen2024!"  "2"
create_user "Usuario RRHH"         "rrhh.usuario"        "RRHH2024!"     "2"
create_user "Responsable RRHH"     "rrhh.responsable"    "RRHH2024!"     "2"
create_user "Contable"             "conta.contable"      "Conta2024!"    "2"
create_user "Responsable Conta"    "conta.responsable"   "Conta2024!"    "2"
create_user "Administrador IT"     "it.admin"            "ITAdmin2024!"  "2"

echo ""
log_ok "========================================"
log_ok "  Inicialización de roles completada"
log_ok "========================================"
log_warn "Cambia las contraseñas antes de producción."
log_info "Gestión de usuarios: ${ODOO_URL}/odoo/settings/users"
```

---

## 6. Cambios en `docker-compose.yml`

```yaml
networks:
  internal:
    driver: bridge
    internal: true

  macvlan_vlan30:
    external: true
    name: macvlan_vlan30

services:
  odoo:
    networks:
      internal:
      macvlan_vlan30:
        ipv4_address: 192.168.30.21

  db:
    networks:
      internal:    # Solo accesible desde Odoo, nunca desde fuera
```

---

## 7. Perfiles de acceso al sistema

| Perfil | IP | VLAN | Acceso SSH | Acceso PostgreSQL | Acceso Odoo web |
|---|---|---|---|---|---|
| Admin técnico | 192.168.40.11 | **VLAN 40** | ✅ Shell + sudo | ✅ Por `docker exec` | ✅ Puerto 8069 |
| DBA | 192.168.40.12 | **VLAN 40** | ✅ Solo túnel TCP | ✅ Vía túnel SSH (127.0.0.1:5433) | ❌ |
| Usuarios Odoo | 192.168.10.x | VLAN 10 | ❌ | ❌ | ✅ HTTPS 443 |
| GitHub Actions runner | localhost | VLAN 30 | N/A | ❌ | ❌ |
| Cualquier otro | — | — | ❌ UFW DENY | ❌ | ❌ |

---

## 8. Cómo usar PostgreSQL como DBA

```bash
# Desde la máquina DBA (192.168.40.12 — VLAN 40)

# 1. Abrir túnel SSH
ssh -N -L 5433:192.168.30.22:5432 -i ~/.ssh/dba_key odoo-dba@192.168.30.10

# 2. Conectar con psql (en otra terminal)
psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp

# O con pgAdmin / DBeaver:
#   host=127.0.0.1  puerto=5433  usuario=odoo  bd=odoo_erp
```

El contenedor PostgreSQL **nunca tiene el puerto 5432 expuesto** en la red. El túnel SSH desde la VLAN 40 es el único camino de acceso.

---

## 9. Reglas pfSense

| Regla | Origen | Destino | Puerto | Acción |
|---|---|---|---|---|
| SSH Admin | 192.168.40.11/32 (VLAN 40) | 192.168.30.10 | 22/TCP | ALLOW |
| SSH DBA | 192.168.40.12/32 (VLAN 40) | 192.168.30.10 | 22/TCP | ALLOW |
| HTTPS clientes → Odoo | 192.168.10.0/24 | 192.168.30.21 | 443/TCP | ALLOW |
| Admin → Odoo debug | 192.168.40.11/32 | 192.168.30.21 | 8069/TCP | ALLOW |
| Bloquear PostgreSQL | Cualquiera | 192.168.30.22 | 5432/TCP | BLOCK |
| **VLAN 30 → VLAN 40** | **192.168.30.0/24** | **192.168.40.0/24** | **any** | **BLOCK** |
| **VLAN 10 → VLAN 40** | **192.168.10.0/24** | **192.168.40.0/24** | **any** | **BLOCK** |
| SSH resto | Cualquiera | 192.168.30.10 | 22/TCP | BLOCK |
| Todo lo demás | Cualquiera | Cualquiera | — | DENY |

---

## 10. Checklist de puesta en marcha

### Primera vez — pfSense (antes que todo)

- [ ] Crear VLAN 40 en pfSense (Interfaces → VLANs → Add, tag 40).
- [ ] Asignar y habilitar OPT2 con IP `192.168.40.1/24`.
- [ ] Configurar reservas DHCP: Admin `192.168.40.11`, DBA `192.168.40.12`.
- [ ] Añadir reglas de firewall en OPT2 (ver sección 9).
- [ ] Añadir reglas de bloqueo inter-VLAN en OPT1 y LAN.

### Primera vez — Máquinas Admin y DBA

- [ ] Reconectar Admin a la VLAN 40 (IP `192.168.40.11`, gateway `192.168.40.1`).
- [ ] Reconectar DBA a la VLAN 40 (IP `192.168.40.12`, gateway `192.168.40.1`).
- [ ] Verificar que Admin puede hacer SSH al servidor desde la nueva IP.

### Primera vez — GitHub y servidor

- [ ] Actualizar Secrets en GitHub: `ADMIN_IP=192.168.40.11`, `DBA_IP=192.168.40.12`.
- [ ] Ejecutar `scripts/setup_runner.sh` para registrar el self-hosted runner.
- [ ] Copiar `.env.example` a `.env` en el servidor y rellenar valores reales.

### Despliegue automático (cada push a `main`)

- [ ] CI Validator pasa (ShellCheck, YAML, Markdown).
- [ ] CD Deploy ejecuta las 5 fases automáticamente en el servidor.
- [ ] Verificar en la pestaña Actions de GitHub que todos los pasos están en verde.

---

## 11. Notas de seguridad

- Los Secrets de GitHub (contraseñas, IPs, claves) **nunca se almacenan en el repositorio**.
- Las contraseñas de ejemplo de `odoo_init_roles.sh` deben cambiarse antes de producción.
- La IP del Admin y del DBA deben ser **estáticas** en pfSense (reserva DHCP o IP fija).
- El puerto 5432 de PostgreSQL **nunca se expone** en la red física.
- La VLAN 40 es inalcanzable desde VLAN 10 y VLAN 30 por reglas pfSense explícitas.
- El acceso SSH ya **no se expone por WAN** — solo desde la VLAN 40 interna.

---

## 12. Verificaciones detalladas por componente

### 12.1 Debian headless

```bash
systemctl get-default
# Esperado: multi-user.target
```

### 12.2 SSH y UFW

```bash
ufw status verbose

# Desde Admin (192.168.40.11, VLAN 40) — debe funcionar
ssh adminodoo@192.168.30.10

# Desde VLAN 10 o VLAN 30 — debe rechazarse
ssh adminodoo@192.168.30.10
# Esperado: Connection refused

# Verificar aislamiento VLAN 40 desde el servidor
ping 192.168.40.11
# Esperado: sin respuesta (bloqueado por pfSense)
```

### 12.3 Red MACVLAN

```bash
docker network ls | grep macvlan
docker inspect odoo-web | grep '"IPAddress"'
ping -c 2 192.168.30.21
ping -c 2 192.168.30.22
```

### 12.4 Usuario DBA

```bash
getent passwd odoo-dba
# Esperado: /usr/sbin/nologin

# Desde DBA (192.168.40.12, VLAN 40)
ssh -N -L 5433:192.168.30.22:5432 -i ~/.ssh/dba_key odoo-dba@192.168.30.10 &
psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp -c "SELECT version();"
```

### 12.5 Roles en Odoo

1. `ventas.usuario` → solo CRM, Ventas, Contactos.
2. `almacen.operario` → solo Inventario.
3. `it.admin` → todos los módulos + Configuración técnica.
4. Ningún usuario no-admin debe ver **Configuración → Técnico**.

### 12.6 Aislamiento VLAN 40

```bash
# Desde un PC de la VLAN 10 — no debe llegar a VLAN 40
ping 192.168.40.11
# Esperado: sin respuesta

# Desde el servidor Debian (VLAN 30) — no debe llegar a VLAN 40
ping 192.168.40.11
# Esperado: sin respuesta

# Desde Admin (VLAN 40) — sí debe llegar al servidor
ping 192.168.30.10
# Esperado: respuesta OK
```

### 12.7 Pipeline GitHub Actions

1. Ir a la pestaña **Actions** del repositorio en GitHub.
2. Verificar que `CI Validator` pasa en verde.
3. Verificar que `CD Deploy (Self-Hosted)` se lanza automáticamente.
4. Los pasos `[1/5]` hasta `[5/5]` deben estar en verde.
