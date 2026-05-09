# Plan de Implantación — Infraestructura como Código (IaC)
## TFG: Implantación Segura y Automatizada de Odoo

**Repositorio:** [sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo](https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo)  
**Autores:** Sandra Fradejas Avedillo · Mario García García · Javier Córdoba Del Valle  
**Centro:** IES Cañaveral — ASIR 2025/2026

---

## Resumen ejecutivo

GitHub actúa como **fuente de verdad** y plataforma central de despliegue. Todo el estado deseado del sistema — scripts de configuración, red MACVLAN, hardening SSH, roles de Odoo y el stack Docker — está versionado en el repositorio. El servidor Debian aplica exactamente lo que hay en `main` cada vez que el pipeline CI/CD se dispara.

Enfoque **Infrastructure as Code (IaC)**: si el servidor se pierde o hay que replicar el entorno, basta con registrar un nuevo runner y hacer un `push` a `main` para restaurar todo automáticamente.

> **Nota de contexto:** Este documento cubre las nuevas funcionalidades añadidas al TFG:
> servidor headless, acceso SSH restringido por máquina, redes MACVLAN, perfil DBA para
> PostgreSQL, roles y departamentos en Odoo, y GitHub como plataforma central de despliegue.

---

## Orden de implementación

> ⚠️ **Este es el orden obligatorio de implantación.**

| Orden | Fase | Estado |
|-------|------|--------|
| 1 | **VLAN + MACVLAN** — Red segmentada y contenedores con IP física | ✅ Completada 08/05/2026 |
| 2 | **LDAP** — Autenticación centralizada en Odoo | ⏳ Pendiente |
| 3 | **Debian Headless** — Eliminar GUI + SSH endurecido | ⏳ Pendiente |
| 4 | **IaC / GitHub Actions** — Pipeline CI/CD completo | ⏳ Pendiente |

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
│  CI Validator (ci.yml)                      │
│  ├── ShellCheck scripts/*.sh                │
│  ├── Validar docker-compose.yml             │
│  └── Lint Markdown                          │
│            │ (solo si pasa)                 │
│  CD Deploy (deploy.yml)                     │
│  runs-on: self-hosted                       │
│  ├── git reset --hard origin/main           │
│  ├── Fase 1: Preparación host               │
│  ├── Fase 2: Red MACVLAN                    │
│  ├── Fase 3: Hardening SSH + DBA            │
│  ├── Fase 4: Docker stack up                │
│  └── Fase 5: Roles Odoo                     │
└─────────────────────────────────────────────┘
       │  self-hosted runner (en el servidor)
       ▼
┌─────────────────────────────────────────────┐
│    Servidor Debian (192.168.30.10)          │
│  ├── Contenedor Odoo    (192.168.30.21)     │
│  └── Contenedor PostgreSQL (192.168.30.22)  │
└─────────────────────────────────────────────┘
```

### 1.2 Regla fundamental

> **Nunca se ejecuta nada manualmente en el servidor en producción.**
> Cualquier cambio se hace en el repositorio, pasa por CI, y se despliega automáticamente.
> La única excepción es la instalación inicial del runner (`setup_runner.sh`).

### 1.3 Topología de red

| Elemento | IP | Rol |
|----------|----|-----|
| pfSense (gateway) | `192.168.30.1` | Firewall / enrutador |
| Servidor Debian (host) | `192.168.30.10` | Runner + Docker host |
| Contenedor Odoo | `192.168.30.21` | Aplicación ERP (MACVLAN) ✅ |
| Contenedor Nginx | `192.168.30.20` | Proxy inverso HTTPS (MACVLAN) ✅ |
| Contenedor PostgreSQL | `172.19.0.x` | Base de datos (solo red bridge) |
| Máquina Admin | `192.168.30.11` | Administración SSH |
| Máquina DBA | `192.168.30.12` | Acceso PostgreSQL vía túnel SSH |
| Clientes Odoo | `192.168.10.x` | Acceso web HTTPS |

---

## 2. Estado actual de la red (08/05/2026)

### Red bridge interna (`docker_odoo_net`)

| Contenedor | IP bridge | Rol |
|------------|-----------|-----|
| `nginx-proxy` | `172.19.0.2` | Proxy inverso |
| `odoo_erp` | `172.19.0.3` | PostgreSQL |
| `odoo-web` | `172.19.0.4` | Odoo 17 |

### Red MACVLAN (`macvlan_vlan30`) — `ens36` — ✅ Activa

| Contenedor | IP MACVLAN | Justificación |
|------------|------------|---------------|
| `nginx-proxy` | `192.168.30.20` | Entrada HTTPS con IP física |
| `odoo-web` | `192.168.30.21` | ERP con IP física |
| `odoo_erp` | ❌ Excluido | Seguridad: BD no expuesta |

Verificación rápida del estado actual:

```bash
docker network inspect macvlan_vlan30 \
  --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
```

---

## 3. Estructura del repositorio

```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
│
├── .github/workflows/
│   ├── ci.yml              ← Validación automática (ShellCheck, YAML, Markdown)
│   └── deploy.yml          ← Despliegue automático (self-hosted runner)
│
├── scripts/
│   ├── setup_runner.sh     ← [EXISTENTE] Instala el runner de GitHub Actions
│   ├── deploy.sh           ← [EXISTENTE] Levanta el stack Docker
│   ├── backup.sh           ← [EXISTENTE] Backup de PostgreSQL
│   ├── restore.sh          ← [EXISTENTE] Restauración de backup
│   ├── monitor.sh          ← [EXISTENTE] Monitorización del stack
│   ├── update.sh           ← [EXISTENTE] Actualización de imágenes Docker
│   ├── configure.sh        ← [EXISTENTE] Configuración post-despliegue
│   ├── install_cron.sh     ← [EXISTENTE] Configura tareas programadas
│   │
│   ├── headless_check.sh   ← [PENDIENTE] Configura Debian sin GUI
│   ├── ssh_hardening.sh    ← [PENDIENTE] Restringe SSH + UFW
│   ├── dba_user_setup.sh   ← [PENDIENTE] Usuario sistema DBA (túneles)
│   ├── macvlan_setup.sh    ← [PENDIENTE] Crea red Docker MACVLAN
│   └── odoo_init_roles.sh  ← [PENDIENTE] Departamentos y roles en Odoo
│
├── docker/
│   └── docker-compose.yml  ← Stack con IPs MACVLAN (actualizado ✅)
│
└── .env.example            ← Variables de entorno (sin secretos reales)
```

---

## 4. Fase pendiente: LDAP

### Objetivo
Centralizar autenticación de usuarios de Odoo contra un directorio LDAP.

### 4.1 Añadir OpenLDAP al stack Docker

Añadir al `docker-compose.yml`:

```yaml
  ldap:
    image: osixia/openldap:1.5.0
    container_name: odoo-ldap
    restart: always
    environment:
      LDAP_ORGANISATION: "TFG ASIR"
      LDAP_DOMAIN: "tfg.com"
      LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
    volumes:
      - ../data/ldap_data:/var/lib/ldap
      - ../data/ldap_config:/etc/ldap/slapd.d
    networks:
      odoo_net:
```

Añadir al `.env`:
```bash
LDAP_ADMIN_PASSWORD=<contraseña_segura>
```

```bash
# Levantar el nuevo servicio
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d ldap
docker ps | grep ldap
```

### 4.2 Crear usuarios de prueba (LDIF)

```bash
cat << 'EOF' > /tmp/usuarios_tfg.ldif
dn: ou=usuarios,dc=tfg,dc=com
objectClass: organizationalUnit
ou: usuarios

dn: uid=jdoe,ou=usuarios,dc=tfg,dc=com
objectClass: inetOrgPerson
uid: jdoe
cn: John Doe
sn: Doe
mail: jdoe@tfg.com
userPassword: Odoo2024!
EOF

# Importar
docker exec odoo-ldap ldapadd \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -f /tmp/usuarios_tfg.ldif

# Verificar
docker exec odoo-ldap ldapsearch \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```

### 4.3 Configurar LDAP en Odoo (interfaz web)

**Ajustes → Técnico → Autenticación LDAP → Nuevo servidor LDAP:**

| Campo | Valor |
|-------|-------|
| Servidor LDAP | `odoo-ldap` |
| Puerto | `389` |
| TLS | No |
| DN base | `ou=usuarios,dc=tfg,dc=com` |
| Filtro LDAP | `(uid=%s)` |
| DN de bind | `cn=admin,dc=tfg,dc=com` |
| Contraseña de bind | `${LDAP_ADMIN_PASSWORD}` |
| Crear usuario si no existe | ✅ Sí |

### 4.4 Validación LDAP

```bash
# Test conexión desde contenedor Odoo
docker exec odoo-web ldapsearch \
  -H ldap://odoo-ldap:389 \
  -x -D "cn=admin,dc=tfg,dc=com" \
  -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```

- [ ] `ldapsearch` devuelve `uid=jdoe`
- [ ] Login en Odoo con `jdoe` + contraseña LDAP → OK
- [ ] Odoo crea automáticamente el perfil del usuario LDAP
- [ ] Audit trigger registra el usuario en `asir_audit_log`

---

## 5. Fase pendiente: Debian Headless

> ⚠️ **Hacer esta fase la última.** Con GUI es más fácil diagnosticar errores previos.

### 5.1 Cambiar target de arranque

```bash
sudo systemctl set-default multi-user.target
systemctl get-default   # → multi-user.target
```

### 5.2 Eliminar entorno gráfico

```bash
dpkg -l | grep -E "gnome|kde|xfce|lxde"
sudo apt remove --purge gnome* x11* xorg* -y
sudo apt autoremove --purge -y && sudo apt clean
```

### 5.3 Script `headless_check.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

[ "$(id -u)" -ne 0 ] && { log_error "Ejecutar como root."; exit 1; }

GRAPHICAL="xorg xserver-xorg gnome kde-plasma-desktop xfce4 lxde"
DISPLAY_MGR="gdm gdm3 lightdm sddm xdm"
FOUND=""

for pkg in $GRAPHICAL $DISPLAY_MGR; do
    dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && FOUND="$FOUND $pkg"
done

if [ -n "$FOUND" ]; then
    log_warn "Paquetes gráficos:$FOUND"
    # shellcheck disable=SC2086
    apt-get purge -y $FOUND && apt-get autoremove -y
    log_ok "Paquetes eliminados."
else
    log_ok "Sin entorno gráfico instalado."
fi

for dm in $DISPLAY_MGR; do
    systemctl is-enabled "$dm" 2>/dev/null | grep -q "enabled" && systemctl disable "$dm" --now || true
done

systemctl set-default multi-user.target
[ "$(systemctl get-default)" = "multi-user.target" ] && log_ok "Modo headless activo." \
    || { log_error "Target incorrecto."; exit 1; }
```

### 5.4 Script `ssh_hardening.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

[ "$(id -u)" -ne 0 ] && { log_error "Ejecutar como root."; exit 1; }
[ -z "${ADMIN_IP:-}" ] && read -r -p "IP Admin: " ADMIN_IP
[ -z "${ADMIN_IP:-}" ] && { log_error "ADMIN_IP requerida."; exit 1; }
DBA_IP="${DBA_IP:-}"

command -v ufw > /dev/null 2>&1 || apt-get install -y ufw

cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%Y%m%d_%H%M%S)"

sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/'               /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/'    /etc/ssh/sshd_config
grep -q "^PasswordAuthentication" /etc/ssh/sshd_config || echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
grep -q "^PermitRootLogin"        /etc/ssh/sshd_config || echo "PermitRootLogin no"        >> /etc/ssh/sshd_config

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow from "$ADMIN_IP" to any port 22 proto tcp comment "SSH Admin"
[ -n "$DBA_IP" ] && ufw allow from "$DBA_IP" to any port 22 proto tcp comment "SSH DBA"
ufw allow 443/tcp comment "HTTPS Odoo"
ufw allow 9090/tcp comment "Cockpit"
ufw --force enable

systemctl restart sshd
log_ok "Hardening SSH + UFW aplicado."
log_warn "Verifica acceso desde Admin antes de cerrar sesión."
```

### 5.5 Script `dba_user_setup.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

DBA_USER="odoo-dba"
DBA_HOME="/home/${DBA_USER}"
DBA_SSH_DIR="${DBA_HOME}/.ssh"
DBA_PUBKEY="${DBA_PUBKEY:-}"

[ "$(id -u)" -ne 0 ] && { echo "Ejecutar como root."; exit 1; }

id "$DBA_USER" > /dev/null 2>&1 || \
    useradd --create-home --shell /usr/sbin/nologin \
        --comment "DBA Odoo - solo SSH tunnel" "$DBA_USER"

mkdir -p "$DBA_SSH_DIR"
chmod 700 "$DBA_SSH_DIR"
chown "${DBA_USER}:${DBA_USER}" "$DBA_SSH_DIR"

if [ -n "$DBA_PUBKEY" ]; then
    echo "$DBA_PUBKEY" > "${DBA_SSH_DIR}/authorized_keys"
    chmod 600 "${DBA_SSH_DIR}/authorized_keys"
    chown "${DBA_USER}:${DBA_USER}" "${DBA_SSH_DIR}/authorized_keys"
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
grep -q "Match User ${DBA_USER}" "$SSHD_CONFIG" || cat >> "$SSHD_CONFIG" << SSHBLOCK

# dba_user_setup — TFG
Match User ${DBA_USER}
    AllowTcpForwarding yes
    X11Forwarding no
    PermitTTY no
    ForceCommand /bin/false
    PasswordAuthentication no
    PubkeyAuthentication yes
SSHBLOCK

systemctl restart sshd
echo "[OK] Usuario DBA '${DBA_USER}' configurado."
echo "     Túnel: ssh -N -L 5433:172.19.0.3:5432 odoo-dba@192.168.30.10"
echo "     psql:  psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp"
```

### 5.6 Validación headless

```bash
systemctl get-default                         # multi-user.target
echo $DISPLAY                                 # vacío
systemctl is-active docker                    # active
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps  # 3 Up
curl -k -I https://erp.odoo.tfg.com          # 200/302
ufw status verbose                            # activo
ssh server@192.168.30.10                      # acceso OK desde Admin
```

---

## 6. Pipeline CI/CD — `deploy.yml` completo

```yaml
name: CD Deploy (Self-Hosted)

on:
  workflow_run:
    workflows: ["CI Validator"]
    types: [completed]
    branches: [main]

jobs:
  deploy:
    name: Desplegar Stack en Servidor Debian
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: self-hosted

    steps:

      - name: Verificar entorno del servidor
        run: |
          echo "Servidor: $(hostname) | Docker: $(docker --version) | $(date)"

      - name: Marcar directorio como seguro para Git
        run: git config --global --add safe.directory /opt/erp-odoo

      - name: "[0] Sincronizar repositorio"
        working-directory: /opt/erp-odoo
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          git remote set-url origin https://x-access-token:${GH_TOKEN}@github.com/${{ github.repository }}.git
          git fetch origin
          git reset --hard origin/main

      - name: "[1/5] Configurar modo headless"
        working-directory: /opt/erp-odoo
        run: sudo bash scripts/headless_check.sh

      - name: "[2/5] Configurar red MACVLAN"
        working-directory: /opt/erp-odoo
        env:
          PARENT_IFACE: ${{ vars.PARENT_IFACE }}
          SUBNET:       ${{ vars.SUBNET }}
          GATEWAY:      ${{ vars.GATEWAY }}
          ODOO_IP:      ${{ vars.ODOO_IP }}
          POSTGRES_IP:  ${{ vars.POSTGRES_IP }}
          HOST_MACVLAN_IP: ${{ vars.HOST_MACVLAN_IP }}
        run: sudo -E bash scripts/macvlan_setup.sh

      - name: "[3/5] SSH hardening + usuario DBA"
        working-directory: /opt/erp-odoo
        env:
          ADMIN_IP:   ${{ secrets.ADMIN_IP }}
          DBA_IP:     ${{ secrets.DBA_IP }}
          DBA_PUBKEY: ${{ secrets.DBA_PUBKEY }}
        run: |
          sudo -E bash scripts/ssh_hardening.sh
          sudo -E bash scripts/dba_user_setup.sh

      - name: "[4/5] Desplegar stack Docker"
        working-directory: /opt/erp-odoo
        run: bash scripts/deploy.sh

      - name: "[5/5] Inicializar roles en Odoo"
        working-directory: /opt/erp-odoo
        run: |
          sleep 20
          bash scripts/odoo_init_roles.sh

      - name: Verificación final
        working-directory: /opt/erp-odoo
        run: |
          docker compose -f docker/docker-compose.yml ps
          echo "[OK] Despliegue completado."
```

---

## 7. Secrets y Variables en GitHub

### Secrets (`Settings → Secrets → Actions`)

| Secret | Descripción |
|--------|-------------|
| `ADMIN_IP` | IP máquina de administración |
| `DBA_IP` | IP máquina del DBA |
| `DBA_PUBKEY` | Clave pública SSH del DBA |
| `POSTGRES_PASSWORD` | Contraseña PostgreSQL |
| `ODOO_ADMIN_PASSWORD` | Contraseña admin Odoo |
| `LDAP_ADMIN_PASSWORD` | Contraseña admin LDAP |

### Variables (`Settings → Variables → Actions`)

| Variable | Valor ejemplo |
|----------|--------------|
| `PARENT_IFACE` | `ens36` |
| `SUBNET` | `192.168.30.0/24` |
| `GATEWAY` | `192.168.30.1` |
| `ODOO_IP` | `192.168.30.21` |
| `POSTGRES_IP` | `192.168.30.22` |
| `HOST_MACVLAN_IP` | `192.168.30.23` |
| `ODOO_DB` | `odoo_erp` |
| `ODOO_URL` | `http://localhost:8069` |

---

## 8. Perfiles de acceso al sistema

| Perfil | IP | SSH | PostgreSQL | Odoo web |
|--------|----|-----|------------|----------|
| Admin técnico | `192.168.30.11` | ✅ Shell + sudo | ✅ `docker exec` | ✅ Puerto 8069 |
| DBA | `192.168.30.12` | ✅ Solo túnel TCP | ✅ Túnel SSH `.5433` | ❌ |
| Usuarios Odoo | `192.168.10.x` | ❌ | ❌ | ✅ HTTPS 443 |
| GitHub Actions | localhost | N/A | ❌ | ❌ |
| Cualquier otro | — | ❌ UFW DENY | ❌ | ❌ |

### Acceso DBA a PostgreSQL

```bash
# 1. Abrir túnel SSH desde la máquina DBA
ssh -N -L 5433:172.19.0.3:5432 -i ~/.ssh/dba_key odoo-dba@192.168.30.10

# 2. Conectar con psql (en otra terminal)
psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp
```

---

## 9. Reglas pfSense

| Regla | Origen | Destino | Puerto | Acción |
|-------|--------|---------|--------|--------|
| SSH Admin | `192.168.30.11/32` | `192.168.30.10` | `22/TCP` | ALLOW |
| SSH DBA | `192.168.30.12/32` | `192.168.30.10` | `22/TCP` | ALLOW |
| HTTPS clientes → Odoo | `192.168.10.0/24` | `192.168.30.20` | `443/TCP` | ALLOW |
| Admin → Odoo debug | `192.168.30.11/32` | `192.168.30.21` | `8069/TCP` | ALLOW |
| Bloquear PostgreSQL | Cualquiera | `192.168.30.22` | `5432/TCP` | BLOCK |
| SSH resto | Cualquiera | `192.168.30.10` | `22/TCP` | BLOCK |
| Todo lo demás | Cualquiera | Cualquiera | — | DENY |

---

## 10. Checklist de puesta en marcha

### Primera vez — manual (solo una vez)

- [ ] Instalar Debian Server sin entorno gráfico
- [ ] Ejecutar `scripts/setup_runner.sh` para registrar el runner en GitHub
- [ ] Añadir Secrets y Variables en GitHub Actions
- [ ] Copiar `.env.example` → `.env` y rellenar valores reales
- [ ] Configurar reglas pfSense (sección 9)

### Despliegue automático (cada push a `main`)

- [ ] CI Validator pasa (ShellCheck, YAML, Markdown)
- [ ] CD Deploy ejecuta las 5 fases en el servidor
- [ ] Verificar pestaña Actions → todos los pasos en verde

---

## 11. Verificaciones por componente

### MACVLAN (✅ ya hecho)

```bash
docker network inspect macvlan_vlan30 \
  --format '{{range .Containers}}{{.Name}}: {{.IPv4Address}}{{"\n"}}{{end}}'
# nginx-proxy: 192.168.30.20/24
# odoo-web:    192.168.30.21/24
```

### LDAP (⏳ pendiente)

```bash
docker exec odoo-ldap ldapsearch \
  -x -D "cn=admin,dc=tfg,dc=com" -w "${LDAP_ADMIN_PASSWORD}" \
  -b "dc=tfg,dc=com" "(uid=jdoe)"
```

### Headless (⏳ pendiente)

```bash
systemctl get-default          # multi-user.target
ufw status verbose             # activo
systemctl is-active docker     # active
```

### Usuario DBA (⏳ pendiente)

```bash
getent passwd odoo-dba
grep -A6 "Match User odoo-dba" /etc/ssh/sshd_config
```

### Pipeline GitHub Actions (⏳ pendiente)

1. Ir a pestaña **Actions** del repositorio en GitHub
2. CI Validator → verde ✅
3. CD Deploy → pasos [1/5]–[5/5] en verde ✅

---

## 12. Notas de seguridad

- Los **Secrets de GitHub** nunca se almacenan en el repositorio
- Las contraseñas de ejemplo en `odoo_init_roles.sh` deben cambiarse antes de producción
- El backup de `sshd_config` queda en `/etc/ssh/sshd_config.bak.*`
- Las IPs Admin y DBA deben ser estáticas (reserva DHCP en pfSense o IP fija)
- El puerto `5432` de PostgreSQL **nunca se expone** en la red física — solo vía túnel SSH
- La red `macvlan_vlan30` en Docker está declarada como `external: true` y es creada por `macvlan_setup.sh`
