#!/bin/bash
# ============================================================
# Provisioning VM Debian - Odoo 17 + Nginx
# ARQUITECTURA:
#   eth0 → NAT VMware (Internet)
#   eth1 → VMnet2 (192.168.30.0/24 — DMZ)
#          pfSense es MANUAL: puede estar apagado durante el provision.
#          La ruta a la BD (192.168.40.0/24) se configura si pfSense
#          responde, pero NO bloquea el provision si está apagado.
# ============================================================
set -euo pipefail

PROJECT_DIR="/opt/erp-odoo"
GH_REPO_OWNER="sandrafrv"
GH_REPO_NAME="TFG-Implantacion_Segura_y_Automatizada_de_Odoo"
REPO="https://${GH_PAT}@github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}.git"
REPO_URL="https://github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}"

POSTGRES_HOST="${POSTGRES_HOST:-192.168.40.10}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
ODOO_MASTER_PASSWORD="${ODOO_MASTER_PASSWORD:-changeme_master}"
RUNNER_NAME="${RUNNER_NAME:-odoo-runner}"
RUNNER_USER="runner"
RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"
RUNNER_VERSION="2.317.0"

NAT_IFACE="eth0"
VLAN_IFACE="eth1"
VLAN_IP="192.168.30.10"
VLAN_NETMASK="255.255.255.0"
VLAN_GW="192.168.30.1"

echo "=========================================="
echo " Provisioning servidor Odoo + Nginx..."
echo " POSTGRES_HOST : $POSTGRES_HOST"
echo " RUNNER_NAME   : $RUNNER_NAME"
echo "=========================================="

if [ -z "${GH_PAT:-}" ]; then
  echo "[ERROR] GH_PAT no está definido. Abortando." >&2; exit 1
fi
if [ -z "${GH_RUNNER_TOKEN:-}" ]; then
  echo "[ERROR] GH_RUNNER_TOKEN no está definido. Abortando." >&2; exit 1
fi

#— PASO 0: Configurar red y DNS ———————————————————————————————
cat > /etc/resolv.conf << 'DNSEOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
DNSEOF

# ── PASO 1: IP estática eth1 SIN gateway ────────────────────
mkdir -p /etc/network/interfaces.d
cat > /etc/network/interfaces.d/eth1.cfg << NETEOF
auto ${VLAN_IFACE}
iface ${VLAN_IFACE} inet static
    address ${VLAN_IP}
    netmask ${VLAN_NETMASK}
NETEOF

ip link set "${VLAN_IFACE}" up
ip addr flush dev "${VLAN_IFACE}" 2>/dev/null || true
ip addr add "${VLAN_IP}/24" dev "${VLAN_IFACE}" 2>/dev/null || true
ip addr show "${VLAN_IFACE}"

# ── PASO 2: Ruta a BD vía pfSense (no bloqueante) ───────────
# pfSense es MANUAL: puede no estar encendido durante el provision.
# Se intenta añadir la ruta si pfSense responde; si no, el provision continúa.
ip route del default via "${VLAN_GW}" dev "${VLAN_IFACE}" 2>/dev/null || true
if ping -c 2 -W 3 "${VLAN_GW}" > /dev/null 2>&1; then
    echo "  [NET] pfSense alcanzable → añadiendo ruta 192.168.40.0/24."
    ip route add 192.168.40.0/24 via "${VLAN_GW}" dev "${VLAN_IFACE}" 2>/dev/null || true
else
    echo "  [AVISO] pfSense apagado o no disponible en ${VLAN_GW}."
    echo "          La ruta a 192.168.40.0/24 se activará al encender pfSense"
    echo "          (script persistente en /etc/network/if-up.d/)."
fi
ip route

# ── PASO 4: Esperar Internet por eth0 ────────────────────────
echo "  [NET] Esperando conectividad Internet..."
for i in $(seq 1 10); do
  if curl -fsSL --max-time 5 https://deb.debian.org > /dev/null 2>&1; then
    echo "  [NET] Internet OK."; break
  fi
  echo "  [NET] Intento $i/10 — esperando 10s..."
  sleep 10
done

# ── PASO 5: APT ──────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive

# FIX: forzar IPv4 — VMware NAT no enruta IPv6 y APT agota timeout
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4

# FIX: descargas secuenciales — evita saturar NAT con conexiones paralelas
cat > /etc/apt/apt.conf.d/99parallel << 'APTEOF'
Acquire::Queue-Mode "access";
Acquire::http::Pipeline-Depth "0";
Acquire::Retries "3";
APTEOF

APT_OPTS=(
  -o Acquire::Check-Valid-Until=false
  -o Acquire::AllowInsecureRepositories=true
  -o Acquire::AllowDowngradeToInsecureRepositories=true
  --allow-unauthenticated
)

# Detectar codename real del SO (bookworm para Debian 12, trixie para Debian 13, etc.)
OS_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
echo "  [APT] Codename detectado: ${OS_CODENAME}"

cat > /etc/apt/sources.list << SOURCES
deb [trusted=yes] https://deb.debian.org/debian ${OS_CODENAME} main contrib non-free non-free-firmware
deb [trusted=yes] https://deb.debian.org/debian ${OS_CODENAME}-updates main contrib non-free non-free-firmware
deb [trusted=yes] https://deb.debian.org/debian-security ${OS_CODENAME}-security main contrib non-free non-free-firmware
SOURCES

apt-get "${APT_OPTS[@]}" update -qq || true
apt-get install -y -qq "${APT_OPTS[@]}" \
  nginx git curl wget htop vim ca-certificates gnupg \
  lsb-release apt-transport-https software-properties-common || true

# ── PASO 6: Docker CE ────────────────────────────────────────
# Idempotente: si docker ya está instalado (re-provisioning), saltar.
if command -v docker &>/dev/null && docker compose version &>/dev/null; then
  echo "  [DOCKER] Docker ya instalado — saltando instalación."
else
  apt-get remove -y -qq docker docker-engine docker.io containerd runc 2>/dev/null || true
  install -m 0755 -d /etc/apt/keyrings

  # --batch --yes: evita que gpg intente abrir /dev/tty en modo no interactivo
  curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg

  # Para Debian 13 (Trixie) Docker CE aún no tiene rama oficial → usar bookworm como fallback
  DOCKER_CODENAME="${OS_CODENAME}"
  if [ "${OS_CODENAME}" = "trixie" ]; then
    echo "  [DOCKER] Trixie detectado — usando repositorio bookworm de Docker CE como fallback."
    DOCKER_CODENAME="bookworm"
  fi

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  ${DOCKER_CODENAME} stable" \
    > /etc/apt/sources.list.d/docker.list

  apt-get "${APT_OPTS[@]}" update -qq || true
  apt-get install -y -qq "${APT_OPTS[@]}" \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin || {
    echo "[ERROR] No se pudo instalar docker-ce." >&2; exit 1
  }

  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json << 'DOCKEREOF'
{
  "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
}
DOCKEREOF

  systemctl enable docker && systemctl restart docker
fi

docker compose version || { echo "[ERROR] docker compose no encontrado." >&2; exit 1; }


# ── PASO 7: Clonar repo ──────────────────────────────────────
mkdir -p "${PROJECT_DIR}"
if [ ! -d "${PROJECT_DIR}/.git" ]; then
  git clone "${REPO}" "${PROJECT_DIR}" || {
    echo "  [AVISO] No se pudo clonar repo."
    mkdir -p "${PROJECT_DIR}/docker"
  }
fi

# ── PASO 8: .env Odoo (en RAÍZ del proyecto, no en docker/) ─
# docker compose busca el .env en el directorio de trabajo (/opt/erp-odoo)
mkdir -p "${PROJECT_DIR}"
cat > "${PROJECT_DIR}/.env" << ENVEOF
POSTGRES_HOST=${POSTGRES_HOST}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}
ENVEOF
chmod 640 "${PROJECT_DIR}/.env"

# ── PASO 9: docker compose up ────────────────────────────────
# NOTAS:
#   - --env-file explícito para que POSTGRES_PASSWORD se cargue desde .env
#   - nginx del sistema se para antes del up (ocupa el puerto 80)
#   - MACVLAN eliminado: VMware host-only no admite promiscuous mode
#     → los contenedores MACVLAN no son accesibles desde el host/red.
#     El acceso a Odoo es vía port mapping: https://192.168.30.10

COMPOSE_FILE="${PROJECT_DIR}/docker/docker-compose.yml"
ENV_FILE="${PROJECT_DIR}/.env"
COMPOSE_BASE="docker compose -p erp-odoo --env-file ${ENV_FILE} -f ${COMPOSE_FILE}"

# ── SSL: generar certs ANTES del compose up ──────────────────
# nginx-proxy monta ../certs:/etc/ssl/certs_local y espera server.crt/server.key.
# Si no existen cuando nginx arranca → crash loop. Generarlos aquí,
# antes del compose up, garantiza que el volumen esté poblado.
mkdir -p "${PROJECT_DIR}/certs"
if [ ! -f "${PROJECT_DIR}/certs/server.crt" ]; then
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "${PROJECT_DIR}/certs/server.key" \
    -out    "${PROJECT_DIR}/certs/server.crt" \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=TFG/OU=ASIR/CN=odoo.tfg" 2>/dev/null
  echo "  [SSL] Certificado autofirmado generado."
else
  echo "  [SSL] Certificado ya existe, reutilizando."
fi

if [ -f "${COMPOSE_FILE}" ]; then
  echo "  [DOCKER] Esperando que Docker Hub sea accesible..."
  for i in $(seq 1 10); do
    if docker pull hello-world > /dev/null 2>&1; then
      echo "  [DOCKER] Docker Hub accesible."; break
    fi
    echo "  [DOCKER] Intento $i/10 — esperando 15s..."; sleep 15
  done
  docker rmi hello-world 2>/dev/null || true

  echo "  [DOCKER] Descargando imágenes..."
  ${COMPOSE_BASE} pull || echo "  [AVISO] Pull fallido."

  # Bajar contenedores anteriores (idempotencia en re-provisioning)
  ${COMPOSE_BASE} down --remove-orphans 2>/dev/null || true

  # Liberar puerto 80: nginx del sistema lo ocupa al arrancar la VM
  echo "  [NET] Parando nginx del sistema para liberar puerto 80..."
  systemctl stop nginx 2>/dev/null || true
  systemctl disable nginx 2>/dev/null || true

  ${COMPOSE_BASE} up -d --pull never || \
    echo "  [AVISO] docker compose up falló. Re-ejecuta: vagrant provision odoo-server"

  docker ps --filter "name=odoo" \
    --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true
else
  echo "  [AVISO] ${COMPOSE_FILE} no encontrado. Saltando."
fi

# ── PASO 10: Nginx del sistema (solo config, SSL ya generado) ─
# El nginx del sistema está desactivado (el contenedor nginx-proxy
# gestiona HTTPS). Esta config queda como referencia/fallback.
cat > /etc/nginx/sites-available/odoo << 'NGINX_EOF'
server {
    listen 443 ssl;
    server_name odoo.tfg;
    ssl_certificate     /opt/erp-odoo/certs/server.crt;
    ssl_certificate_key /opt/erp-odoo/certs/server.key;
    location / {
        proxy_pass         http://127.0.0.1:8069;
        proxy_set_header   Host            $host;
        proxy_set_header   X-Real-IP       $remote_addr;
        proxy_read_timeout 720s;
    }
    location /longpolling {
        proxy_pass http://127.0.0.1:8072;
    }
}
server {
    listen 80;
    server_name odoo.tfg;
    return 301 https://$server_name$request_uri;
}
NGINX_EOF

ln -sf /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo
rm -f /etc/nginx/sites-enabled/default || true
nginx -t && systemctl restart nginx || echo "  [AVISO] Nginx no arrancó."

# ── PASO 11: Runner ──────────────────────────────────────────
if ! id "${RUNNER_USER}" &>/dev/null; then useradd -m -s /bin/bash "${RUNNER_USER}"; fi
usermod -aG docker "${RUNNER_USER}" || true
mkdir -p "${RUNNER_DIR}"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"

cd "${RUNNER_DIR}"
if [ ! -f "./config.sh" ]; then
  RUNNER_TAR="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  curl -fsSL \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}" \
    -o "/tmp/${RUNNER_TAR}" || echo "  [AVISO] No se pudo descargar runner."
  [ -f "/tmp/${RUNNER_TAR}" ] && tar xzf "/tmp/${RUNNER_TAR}" && rm -f "/tmp/${RUNNER_TAR}" && \
    chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"
fi

if [ -f "${RUNNER_DIR}/config.sh" ] && [ -n "${GH_RUNNER_TOKEN:-}" ]; then
  su -c "
    cd '${RUNNER_DIR}'
    ./config.sh --url '${REPO_URL}' --token '${GH_RUNNER_TOKEN}' \
      --name '${RUNNER_NAME}' --labels 'self-hosted,linux,odoo' \
      --work '_work' --unattended --replace
  " "${RUNNER_USER}" || echo "  [AVISO] No se pudo registrar runner."
  cd "${RUNNER_DIR}"
  # Idempotente: solo instalar el servicio si no existe ya
  if ! systemctl list-units --full -all 2>/dev/null | grep -q "actions.runner"; then
    ./svc.sh install "${RUNNER_USER}" || true
  fi
  ./svc.sh start 2>/dev/null || true
fi

# ── PASO 12: Persistir red ───────────────────────────────────
# (eth1.cfg ya creado en PASO 1 — solo añadimos script de ruta BD)
cat > /etc/network/if-up.d/vlan30-bd-route << 'ROUTE_EOF'
#!/bin/bash
if [ "$IFACE" = "eth1" ] || [ "$IFACE" = "--all" ]; then
    if ping -c 1 -W 2 192.168.30.1 > /dev/null 2>&1; then
        ip route add 192.168.40.0/24 via 192.168.30.1 dev eth1 2>/dev/null || true
        echo "[NET] Ruta BD activa via pfSense."
    else
        echo "[NET] pfSense no disponible. Ruta BD no añadida."
    fi
fi
ROUTE_EOF
chmod +x /etc/network/if-up.d/vlan30-bd-route

# ── PASO 13: Cockpit ─────────────────────────────────────────
apt-get install -y -qq "${APT_OPTS[@]}" cockpit || echo "  [AVISO] Cockpit no instalado."
systemctl enable cockpit.socket || true && systemctl start cockpit.socket || true

echo ""
echo "=========================================="
echo " [OK] Odoo    → https://${VLAN_IP}"
echo " [OK] Cockpit → https://${VLAN_IP}:9090"
echo " [DB] ${POSTGRES_HOST}:5432 (via pfSense ${VLAN_GW})"
echo " [RUNNER] '${RUNNER_NAME}'"
echo "=========================================="