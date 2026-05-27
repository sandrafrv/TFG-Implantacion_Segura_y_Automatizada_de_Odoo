#!/bin/bash
# ============================================================
# Provisioning VM PostgreSQL — TFG Odoo
# ARQUITECTURA:
#   eth0 → NAT VMware (Internet)
#   eth1 → VMnet3 (192.168.40.0/24 — VLAN Admin/BD)
#          pfSense es MANUAL: eth1 tiene solo IP estática,
#          el gateway pfSense se activa si está encendido.
# ============================================================
set -euo pipefail

POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
RUNNER_NAME="${RUNNER_NAME:-db-runner}"
RUNNER_USER="runner"
RUNNER_DIR="/home/${RUNNER_USER}/actions-runner"
RUNNER_VERSION="2.317.0"

GH_REPO_OWNER="sandrafrv"
GH_REPO_NAME="TFG-Implantacion_Segura_y_Automatizada_de_Odoo"
REPO_URL="https://github.com/${GH_REPO_OWNER}/${GH_REPO_NAME}"

NAT_IFACE="eth0"
VLAN_IFACE="eth1"
VLAN_IP="192.168.40.10"
VLAN_NETMASK="255.255.255.0"
VLAN_GW="192.168.40.1"

echo ""
echo "=========================================="
echo " Instalando PostgreSQL 16..."
echo "=========================================="

export DEBIAN_FRONTEND=noninteractive
APT_OPTS=(
  -o Acquire::Check-Valid-Until=false
  -o Acquire::AllowInsecureRepositories=true
  -o Acquire::AllowDowngradeToInsecureRepositories=true
  # FIX #3: eliminada opción inexistente Acquire::GPG::NoSign=true
  --allow-unauthenticated
)

# ── Configurar IP estática en eth1 ──────────────────────────
echo "  [NET] Configurando ${VLAN_IFACE} → ${VLAN_IP}..."
mkdir -p /etc/network/interfaces.d
# FIX #2: fichero eth1.cfg (no vlan40-routes) para no duplicar 'auto eth1'
# FIX #1: SIN gateway — si pfSense está apagado la VM mantiene Internet por eth0
cat > /etc/network/interfaces.d/eth1.cfg << NETEOF
auto ${VLAN_IFACE}
iface ${VLAN_IFACE} inet static
    address ${VLAN_IP}
    netmask ${VLAN_NETMASK}
NETEOF

ip link set "${VLAN_IFACE}" up 2>/dev/null || true
ip addr flush dev "${VLAN_IFACE}" 2>/dev/null || true
ip addr add "${VLAN_IP}/24" dev "${VLAN_IFACE}" 2>/dev/null || true
ip addr show "${VLAN_IFACE}"

# ── Verificar Internet por eth0 ──────────────────────────────
for i in $(seq 1 6); do
  if curl -fsSL --max-time 8 https://deb.debian.org > /dev/null 2>&1; then
    echo "  [NET] Internet OK."; break
  fi
  echo "  [NET] Intento $i/6 — esperando 5s..."; sleep 5
  if [ "$i" -eq 6 ]; then
    echo "[ERROR] Sin Internet por ${NAT_IFACE}. Abortando." >&2; exit 1
  fi
done

# ── APT ──────────────────────────────────────────────────────
OS_CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
echo "  [APT] Codename detectado: ${OS_CODENAME}"

cat > /etc/apt/sources.list << SOURCES
deb [trusted=yes] https://deb.debian.org/debian ${OS_CODENAME} main contrib non-free non-free-firmware
deb [trusted=yes] https://deb.debian.org/debian ${OS_CODENAME}-updates main contrib non-free non-free-firmware
deb [trusted=yes] https://deb.debian.org/debian-security ${OS_CODENAME}-security main contrib non-free non-free-firmware
SOURCES

apt-get "${APT_OPTS[@]}" update || true
apt-get install -y "${APT_OPTS[@]}" curl ca-certificates gnupg || true

# ── PostgreSQL 16 ─────────────────────────────────────────────
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

# pgdg siempre usa bookworm como base estable para Debian 12/13
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg trusted=yes] \
https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

apt-get "${APT_OPTS[@]}" update || true
apt-get install -y "${APT_OPTS[@]}" postgresql-16 postgresql-client-16 || {
  echo "[ERROR] No se pudo instalar PostgreSQL 16." >&2; exit 1
}

systemctl enable postgresql && systemctl start postgresql

sudo -u postgres psql << SQLEOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'odoo') THEN
    CREATE USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
  ELSE
    ALTER USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
  END IF;
END
\$\$;
SELECT 'CREATE DATABASE odoo_erp OWNER odoo'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'odoo_erp')
\gexec
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
SQLEOF

PG_CONF="/etc/postgresql/16/main/postgresql.conf"
PG_HBA="/etc/postgresql/16/main/pg_hba.conf"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "${PG_CONF}"
sed -i "s/^listen_addresses = 'localhost'/listen_addresses = '*'/"  "${PG_CONF}"
grep -q "192.168.30.0/24" "${PG_HBA}" || \
  echo "host  odoo_erp  odoo  192.168.30.0/24  md5" >> "${PG_HBA}"
systemctl restart postgresql

# ── Cockpit ───────────────────────────────────────────────────
apt-get install -y "${APT_OPTS[@]}" cockpit || echo "  [AVISO] Cockpit no instalado."
systemctl enable cockpit.socket 2>/dev/null || true
systemctl start  cockpit.socket 2>/dev/null || true

# ── GitHub Actions Runner ─────────────────────────────────────
if ! id "${RUNNER_USER}" &>/dev/null; then useradd -m -s /bin/bash "${RUNNER_USER}"; fi
mkdir -p "${RUNNER_DIR}"
chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"

if [ ! -f "${RUNNER_DIR}/config.sh" ]; then
  RUNNER_TAR="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"
  curl -fsSL \
    "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_TAR}" \
    -o "/tmp/${RUNNER_TAR}" || echo "  [AVISO] No se pudo descargar runner."
  [ -f "/tmp/${RUNNER_TAR}" ] && \
    tar xzf "/tmp/${RUNNER_TAR}" -C "${RUNNER_DIR}" && \
    rm -f "/tmp/${RUNNER_TAR}" && \
    chown -R "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"
fi

if [ -f "${RUNNER_DIR}/config.sh" ] && [ -n "${GH_RUNNER_TOKEN:-}" ]; then
  sudo -u "${RUNNER_USER}" bash -c "
    cd '${RUNNER_DIR}'
    ./config.sh --url '${REPO_URL}' --token '${GH_RUNNER_TOKEN}' \
      --name '${RUNNER_NAME}' --labels 'self-hosted,linux,db' \
      --work '_work' --unattended --replace
  " || echo "  [AVISO] No se pudo registrar el runner."
  cd "${RUNNER_DIR}" && ./svc.sh install "${RUNNER_USER}" || true
  ./svc.sh start || true
fi

# ── Persistir red — FIX #1: gateway pfSense solo si responde ─
cat > /etc/network/interfaces.d/eth1.cfg << NETEOF
auto ${VLAN_IFACE}
iface ${VLAN_IFACE} inet static
    address ${VLAN_IP}
    netmask ${VLAN_NETMASK}
NETEOF

cat > /etc/network/if-up.d/vlan40-pfsense-gw << UPEOF
#!/bin/bash
if [ "\$IFACE" = "${VLAN_IFACE}" ] || [ "\$IFACE" = "--all" ]; then
  if ping -c 1 -W 2 ${VLAN_GW} > /dev/null 2>&1; then
    ip route add default via ${VLAN_GW} dev ${VLAN_IFACE} 2>/dev/null || true
    echo "[NET] pfSense activo → gateway ${VLAN_GW}"
  else
    echo "[NET] pfSense no disponible → Internet por eth0"
  fi
fi
UPEOF
chmod +x /etc/network/if-up.d/vlan40-pfsense-gw

echo ""
echo "=========================================="
echo " [OK] PostgreSQL  → ${VLAN_IP}:5432"
echo " [OK] Cockpit     → https://${VLAN_IP}:9090"
echo " [OK] Runner      → '${RUNNER_NAME}'"
echo "=========================================="