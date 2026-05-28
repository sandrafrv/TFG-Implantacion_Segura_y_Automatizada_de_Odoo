# 📋 Cuaderno de Trabajo — Paso a Paso del TFG

**TFG ASIR 2025/2026 — Implantación Segura y Automatizada de Odoo ERP**
*Sandra Fradejas Avedillo — IES Cañaveral*

> [!NOTE]
> Este documento simula una **página de trabajo** cronológica.
> Recorre el proyecto **desde cero** hasta el estado final, mostrando cada decisión,
> cada paso ejecutado y cada problema resuelto en el camino.

---

## 📌 Índice de Fases

| Fase | Descripción | Estado |
|:----:|:------------|:------:|
| [0](#fase-0--punto-de-partida) | Punto de partida — Idea y decisiones | ✅ Completada |
| [1](#fase-1--preparación-del-entorno) | Preparación del entorno de trabajo | ✅ Completada |
| [2](#fase-2--pfsense--firewall-y-red) | pfSense — Firewall y segmentación de red | ✅ Completada |
| [3](#fase-3--vm-postgresql--base-de-datos-aislada) | VM PostgreSQL — Base de datos aislada | ✅ Completada |
| [4](#fase-4--vm-debian--docker--odoo--nginx) | VM Debian — Docker + Odoo + Nginx | ✅ Completada |
| [5](#fase-5--cicd-con-github-actions) | CI/CD con GitHub Actions | ✅ Completada |
| [6](#fase-6--automatización-con-vagrant-iac) | Automatización con Vagrant (IaC) | ✅ Completada |
| [7](#fase-7--correcciones-de-red-y-bugs) | Correcciones de red y bugs críticos | ✅ Completada |
| [8](#fase-8--hardening-y-securización) | Hardening y securización | ✅ Completada |
| [9](#fase-9--estado-final) | Estado final del proyecto | ✅ Operativo |

---

## Fase 0 — Punto de Partida

### 📍 Situación inicial

```
📂 Escritorio vacío
├── Una idea: "Montar un ERP seguro para una PYME"
├── Requisito del TFG: Administración de Sistemas Informáticos en Red
└── Herramientas disponibles: un PC con Windows y VMware Workstation
```

### 🧠 Decisiones tomadas

#### ¿Qué ERP elegir?

| Criterio | **Odoo 17** | Dolibarr | ERPNext |
|----------|:-----------:|:--------:|:-------:|
| Facilidad de uso | ✅ Alta | Media | Media |
| API REST/XML-RPC | ✅ Madura | Limitada | Alta |
| Consumo de recursos | Moderado | ✅ Ligero | Pesado |
| Cobertura funcional | ✅ Completa | Básica | Muy completa |
| **Veredicto** | ✅ **Elegido** | ❌ | ❌ |

**Decisión:** Odoo 17 CE — API XML-RPC madura, documentación oficial extensa, versión Community gratuita.

#### ¿Qué sistema operativo?

**Elegido: Debian 13 (Trixie)** — Ciclos de soporte largos, sin snaps, sistema de referencia de Odoo.

#### ¿Qué arquitectura de red?

```
📝 Diseño inicial en papel:
┌─────────────────────────────────────────────────────────┐
│                     pfSense                              │
│  "Un firewall que separe a los empleados del servidor"   │
│                                                          │
│  VLAN 10: Empleados    → Solo acceden a Odoo por HTTPS   │
│  VLAN 30: DMZ          → Servidor Odoo (Docker)          │
│  VLAN 40: Admin + BD   → PostgreSQL + Administradores    │
└─────────────────────────────────────────────────────────┘
```

#### ¿Docker o nativo?

| Servicio | Docker | Nativo | Decisión |
|----------|:------:|:------:|:--------:|
| Odoo 17 | ✅ Imagen oficial | Compilar desde source | **Docker** |
| Nginx (proxy inverso) | ✅ Alpine ligero | Instalar con apt | **Docker** |
| PostgreSQL 16 | Compartía recursos | ✅ Aislamiento real en VM separada | **Nativo** |

---

## Fase 1 — Preparación del Entorno

### 🔧 Paso 1.1 — Instalar herramientas

```powershell
# En el equipo anfitrión (Windows)
winget install HashiCorp.Vagrant
vagrant plugin install vagrant-vmware-desktop
```

### 🔧 Paso 1.2 — Crear la estructura del repositorio

```bash
# Estado inicial del repositorio
mkdir TFG-Implantacion_Segura_y_Automatizada_de_Odoo
cd TFG-Implantacion_Segura_y_Automatizada_de_Odoo
git init
```

```
📂 Estructura inicial (v0.1)
├── docker/
│   ├── docker-compose.yml    ← 3 servicios: PostgreSQL + Odoo + Nginx
│   └── odoo.conf
├── sql/
│   └── audit_triggers.sql
├── .github/workflows/
│   └── ci.yml
└── README.md
```

> [!IMPORTANT]
> En este punto, el `docker-compose.yml` incluía PostgreSQL **como contenedor**.
> Más adelante (Fase 3) se sacó a una VM independiente.

### 🔧 Paso 1.3 — Descargar ISOs necesarias

```
📥 ISOs descargadas:
├── debian-13.3.0-amd64-netinst.iso     (790 MB)
└── netgate-installer-v1.1.1-RELEASE-amd64.iso  (1 GB)
```

---

## Fase 2 — pfSense — Firewall y Red

### 📍 Objetivo
Crear el corazón de la infraestructura: un firewall con 4 interfaces que segmente toda la red.

### 🔧 Paso 2.1 — Crear la VM pfSense en VMware

| Parámetro | Valor |
|:----------|:------|
| Nombre | `TFG-pfSense` |
| Tipo | FreeBSD 14 64-bit |
| RAM | 1024 MB |
| CPU | 1 core |
| Disco | 8 GB |

**4 adaptadores de red:**

| Adaptador | Modo VMware | Rol en pfSense |
|:---------:|:-----------:|:---------------|
| NIC 1 | NAT | WAN → Internet |
| NIC 2 | Host-only/LAN Segment | LAN → VLAN 10 Clientes (192.168.10.0/24) |
| NIC 3 | Host-only/LAN Segment | OPT1 → VLAN 30 DMZ (192.168.30.0/24) |
| NIC 4 | Host-only/LAN Segment | OPT2 → VLAN 40 Admin+BD (192.168.40.0/24) |

### 🔧 Paso 2.2 — Instalar pfSense

```
1. Arrancar VM con ISO → Install pfSense
2. Keymap → Spanish
3. Partitioning → Auto (ZFS)
4. Esperar ~3 min → Reboot
5. ⚠️ Expulsar ISO antes del reinicio
```

### 🔧 Paso 2.3 — Asignar interfaces (primera consola)

```
Should VLANs be set up now? → n
Enter the WAN interface name:      em0
Enter the LAN interface name:      em1
Enter the Optional 1 interface:    em2
Enter the Optional 2 interface:    em3
Do you want to proceed? → y
```

### 🔧 Paso 2.4 — Configurar IPs desde consola (Opción 2)

| Interfaz | IP | Máscara | DHCP |
|:---------|:---|:--------|:----:|
| LAN (em1) | `192.168.10.1` | /24 | Sí: 100–200 |
| OPT1 (em2) | `192.168.30.1` | /24 | No (IPs estáticas) |
| OPT2 (em3) | `192.168.40.1` | /24 | Sí: 10–50 |
| WAN (em0) | DHCP automático | — | — |

### 🔧 Paso 2.5 — Configuración web (panel pfSense)

```
URL:      https://192.168.10.1  (o 192.168.40.1 tras mover el admin)
Usuario:  admin
Password: pfsense → CAMBIAR en el primer login
```

**Acciones realizadas en el panel web:**

```
☐ → ✅  Interfaces configuradas (4 interfaces con IPs y descripciones)
☐ → ✅  DHCP habilitado en LAN y OPT2
☐ → ✅  DNS Resolver: erp.odoo.tfg.com → 192.168.30.20
☐ → ✅  Aliases creados (6 aliases para simplificar reglas)
☐ → ✅  NAT Port Forward:
         ├── WAN:80  → 192.168.30.20:80
         ├── WAN:443 → 192.168.30.20:443
         ├── LAN DNS:53  → 192.168.10.1  (forzar DNS interno)
         └── OPT2 DNS:53 → 192.168.40.1  (forzar DNS interno)
☐ → ✅  Reglas Firewall (32 reglas en total):
         ├── WAN:  5 reglas (block private/bogon + pass 80/443 + deny all)
         ├── LAN:  9 reglas (bloqueos + Odoo HTTPS + Internet + deny all)
         ├── OPT1: 8 reglas (anti-pivoting + Odoo→PG:5432 + deny all)
         └── OPT2: 10 reglas (panel pfSense + SSH/Cockpit + deny all)
☐ → ✅  Anti-Lockout desactivado (tras confirmar acceso VLAN 40)
```

> [!WARNING]
> **Principio crítico del firewall:** Los bloqueos van SIEMPRE **antes** que los permisos.
> pfSense evalúa de arriba a abajo y aplica la primera regla que coincide.

### 📊 Resultado de la Fase 2

```
✅ pfSense operativo con 4 interfaces
✅ Segmentación de red: VLAN 10 / 30 / 40
✅ Panel de administración accesible SOLO desde VLAN 40
✅ DNS interno resolviendo erp.odoo.tfg.com
```

---

## Fase 3 — VM PostgreSQL — Base de Datos Aislada

### 📍 Objetivo
Sacar PostgreSQL fuera del servidor Docker para aislamiento real en VLAN 40.

> [!NOTE]
> **Decisión clave:** Inicialmente PostgreSQL era un contenedor Docker dentro del
> mismo servidor que Odoo. Se movió a una VM independiente para:
> 1. Aislamiento de red real (VLAN 40 separada)
> 2. No compartir recursos CPU/RAM con Odoo y Nginx
> 3. Control de acceso a nivel de firewall pfSense

### 🔧 Paso 3.1 — Crear VM Debian para PostgreSQL

| Campo | Valor |
|:------|:------|
| Nombre | `TFG-DB-Server` |
| Box Vagrant | `bento/debian-12` |
| RAM | 2048 MB |
| CPU | 1 core |
| IP estática | `192.168.40.10` (VLAN 40) |

### 🔧 Paso 3.2 — Instalar PostgreSQL 16

```bash
# Añadir repositorio oficial de PostgreSQL
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

apt update && apt install -y postgresql-16 postgresql-client-16
```

### 🔧 Paso 3.3 — Crear usuario y base de datos

```sql
-- En la VM PostgreSQL (192.168.40.10)
CREATE USER odoo WITH PASSWORD '<contraseña_segura>';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
```

### 🔧 Paso 3.4 — Configurar acceso remoto

```bash
# postgresql.conf
listen_addresses = '*'   # Antes: 'localhost'

# pg_hba.conf — aceptar conexiones desde la DMZ
host  all  odoo  192.168.30.0/24  md5
```

```bash
sudo systemctl restart postgresql
```

### 🔧 Paso 3.5 — Verificar conectividad

```bash
# Desde vm-odoo (192.168.30.10) → debe funcionar
nc -zv 192.168.40.10 5432   # → Connection succeeded ✅

# Desde VLAN 10 (clientes) → debe FALLAR
nc -zv 192.168.40.10 5432   # → Timeout ✅ (bloqueado por pfSense)
```

### 📊 Resultado de la Fase 3

```
✅ PostgreSQL 16 nativo en 192.168.40.10:5432
✅ Base de datos odoo_erp creada
✅ Acceso restringido: solo desde 192.168.30.0/24 (DMZ)
✅ VLAN 10 bloqueada → clientes no tocan la BD
```

---

## Fase 4 — VM Debian — Docker + Odoo + Nginx

### 📍 Objetivo
Servidor de aplicación con Odoo y Nginx en contenedores Docker, conectado a PostgreSQL externo.

### 🔧 Paso 4.1 — Crear VM Debian

| Campo | Valor |
|:------|:------|
| Nombre | `TFG-Odoo-Server` |
| Box Vagrant | `bento/debian-12` |
| RAM | 4096 MB |
| CPU | 2 cores |
| IP estática | `192.168.30.10` (VLAN 30 — DMZ) |

### 🔧 Paso 4.2 — Instalar Docker CE

```bash
# Dependencias
apt install -y ca-certificates curl gnupg

# Clave GPG oficial de Docker
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Repositorio Docker (usando bookworm como fallback para Trixie)
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian bookworm stable" \
  > /etc/apt/sources.list.d/docker.list

apt update && apt install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

systemctl enable docker && systemctl start docker
docker --version && docker compose version
```

### 🔧 Paso 4.3 — Clonar el repositorio

```bash
git clone https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git \
  /opt/erp-odoo
cd /opt/erp-odoo
```

### 🔧 Paso 4.4 — Configurar credenciales (.env)

```bash
cp .env.example .env
nano .env   # Editar con contraseñas reales
chmod 600 .env
```

```bash
# Contenido del .env
POSTGRES_HOST=192.168.40.10
POSTGRES_PASSWORD=<contraseña_segura>
ODOO_MASTER_PASSWORD=<contraseña_maestra_odoo>
```

> [!CAUTION]
> **Nunca hagas `git add .env`**. Está en `.gitignore`, pero verifica siempre.

### 🔧 Paso 4.5 — Generar certificados SSL

```bash
mkdir -p /opt/erp-odoo/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/erp-odoo/certs/server.key \
  -out    /opt/erp-odoo/certs/server.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=TFG/OU=ASIR/CN=odoo.tfg"
```

### 🔧 Paso 4.6 — Levantar el stack Docker

**Evolución del `docker-compose.yml`:**

```
📝 ANTES (v1.0) — 3 contenedores:
├── odoo_erp   (PostgreSQL 16)   ← Eliminado → movido a VM propia
├── odoo-web   (Odoo 17 CE)
└── nginx-proxy (Nginx Alpine)

📝 DESPUÉS (estado actual) — 2 contenedores:
├── odoo-web    → Odoo 17 CE (se conecta a 192.168.40.10:5432)
└── nginx-proxy → Nginx Alpine (proxy inverso SSL)
```

```bash
cd /opt/erp-odoo
docker compose -p erp-odoo --env-file .env -f docker/docker-compose.yml up -d

# Verificar (deben ser exactamente 2 contenedores)
docker compose -f docker/docker-compose.yml ps
```

```
NAME          IMAGE          STATUS
odoo-web      odoo:17        Up (healthy)
nginx-proxy   nginx:alpine   Up (healthy)
```

### 🔧 Paso 4.7 — Post-instalación de Odoo

```bash
# Renombrar empresa
bash scripts/odoo/odoo_setup_wizard.sh
# "My Company" → "TechSolutions S.L."
# Instala módulos: CRM, Ventas, RRHH, Inventario

# Crear usuarios con roles
bash scripts/odoo/odoo_crear_usuarios.sh
```

| Usuario | Rol | Módulos visibles |
|:--------|:----|:-----------------|
| `becario@erp.odoo.tfg.com` | Becario | Solo CRM (lectura) |
| `ventas@erp.odoo.tfg.com` | Ventas | CRM + Ventas + Facturas |
| `rrhh@erp.odoo.tfg.com` | RRHH | RRHH + Empleados |
| `almacen@erp.odoo.tfg.com` | Almacén | Inventario + Compras |
| `tecnico@erp.odoo.tfg.com` | Técnico | Inventario + Soporte |
| `jefe.ventas@erp.odoo.tfg.com` | Jefe Ventas | Ventas completo + aprobaciones |
| `jefe.rrhh@erp.odoo.tfg.com` | Jefe RRHH | RRHH completo + aprobaciones |
| `jefe.almacen@erp.odoo.tfg.com` | Jefe Almacén | Almacén completo + aprobaciones |
| `api.user@erp.odoo.tfg.com` | API | Solo XML-RPC |
| `dba@erp.odoo.tfg.com` | DBA | Sin UI (solo BD) |

### 🔧 Paso 4.8 — Auditoría SQL

```bash
# Aplicar triggers de auditoría en PostgreSQL externo
psql -h 192.168.40.10 -U odoo -d odooerp < /opt/erp-odoo/sql/audit_triggers.sql

# Verificar
psql -h 192.168.40.10 -U odoo -d odooerp -c "SELECT * FROM v_audit_resumen;"
```

Cada usuario creado en `res_users` genera automáticamente un registro de auditoría en `asir_audit_log` (JSONB).

### 🔧 Paso 4.9 — Instalar Cockpit

```bash
apt install -y cockpit
systemctl enable cockpit.socket && systemctl start cockpit.socket
# Acceso desde VLAN 40: https://192.168.30.10:9090
```

### 📊 Resultado de la Fase 4

```
✅ Docker + Docker Compose operativos
✅ 2 contenedores healthy: odoo-web + nginx-proxy
✅ Odoo accesible en https://192.168.30.10
✅ Empresa: TechSolutions S.L. con módulos y usuarios
✅ Auditoría SQL activa en PostgreSQL externo
✅ Cockpit accesible desde VLAN 40
```

---

## Fase 5 — CI/CD con GitHub Actions

### 📍 Objetivo
Automatizar la validación de código (CI) y el despliegue en producción (CD).

### 🔧 Paso 5.1 — Pipeline CI (validación)

```yaml
# .github/workflows/ci.yml
# Se ejecuta en cada push/PR
# Comprueba:
#   - ShellCheck en todos los scripts (scripts/ + vagrant/)
#   - YAML lint en workflows
#   - docker compose config -q (sintaxis del compose)
#   - Genera y valida config.xml de pfSense
```

### 🔧 Paso 5.2 — Instalar self-hosted runner

```bash
# En vm-odoo (192.168.30.10)
mkdir /opt/actions-runner && cd /opt/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
tar xzf actions-runner-linux-x64-2.317.0.tar.gz
./config.sh --url https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo \
  --token <TOKEN> --name odoo-runner --labels 'self-hosted,linux,odoo'
sudo ./svc.sh install runner && sudo ./svc.sh start
```

### 🔧 Paso 5.3 — Pipeline CD (despliegue automático)

```
Flujo CD:
git push → CI (ShellCheck + YAML + Docker) → ✅ pasa → CD se dispara
                                                          │
                                                          ▼
                                              Runner en vm-odoo ejecuta:
                                              1. git pull (sincronizar repo)
                                              2. docker pull (imágenes nuevas)
                                              3. deploy.sh:
                                                 ├── Verifica PostgreSQL externo
                                                 ├── docker compose down
                                                 ├── docker compose up -d
                                                 └── Healthcheck Odoo
                                              4. Verificación final
```

### 🔧 Paso 5.4 — Permisos especiales para el runner

```bash
# El runner necesita permisos especiales:
# /etc/sudoers.d/runner-deploy
runner ALL=(root) NOPASSWD: /usr/bin/chown -R runner /opt/erp-odoo
runner ALL=(root) NOPASSWD: /usr/bin/chown -R 101:101 /opt/erp-odoo/odoo-data /opt/erp-odoo/odoo_sessions /opt/erp-odoo/addons
```

### 📊 Resultado de la Fase 5

```
✅ CI: ShellCheck + YAML lint + Docker validate en cada push
✅ CD: Despliegue automático tras CI exitosa
✅ Self-hosted runners activos (odoo-runner + db-runner)
✅ Flujo completo: git push → CI ✅ → CD ✅ → stack operativo
```

---

## Fase 6 — Automatización con Vagrant (IaC)

### 📍 Objetivo
Reproducir toda la infraestructura con un solo comando: `vagrant up`.

### 🔧 Paso 6.1 — Crear el Vagrantfile

```ruby
# Vagrantfile — Define 2 VMs (pfSense es manual)
Vagrant.configure("2") do |config|
  # VM 1: db-server (PostgreSQL 16)
  config.vm.define "db-server" do |db|
    db.vm.box      = "bento/debian-12"
    db.vm.hostname = "db-server-tfg"
    db.vm.network "private_network", ip: "192.168.40.10"
    # Provisioning: vagrant/provision_postgres.sh
  end

  # VM 2: odoo-server (Debian + Docker + Odoo + Nginx)
  config.vm.define "odoo-server" do |deb|
    deb.vm.box      = "bento/debian-12"
    deb.vm.hostname = "odoo-server-tfg"
    deb.vm.network "private_network", ip: "192.168.30.10"
    # Provisioning: vagrant/provision_debian.sh
  end
end
```

### 🔧 Paso 6.2 — Scripts de provisioning

| Script | VM | Qué hace |
|:-------|:---|:---------|
| `vagrant/provision_postgres.sh` | db-server | PostgreSQL 16 + Cockpit + Runner + Red VLAN 40 |
| `vagrant/provision_debian.sh` | odoo-server | Docker + Repo + .env + SSL + Compose up + Runner + Cockpit |

### 🔧 Paso 6.3 — Variables de entorno necesarias

```powershell
# Antes de vagrant up (en PowerShell):
$env:GH_PAT="ghp_tutoken"                   # Personal Access Token
$env:GH_RUNNER_TOKEN_ODOO="AXXXXX"           # Runner token para odoo-server
$env:GH_RUNNER_TOKEN_DB="AYYYYY"             # Runner token para db-server
$env:POSTGRES_PASSWORD="tu_password_seguro"
```

### 🔧 Paso 6.4 — Flujo de arranque

```powershell
# ORDEN OBLIGATORIO:
# 1. Encender pfSense manualmente en VMware
# 2. Luego:
vagrant up db-server        # SIEMPRE primero (BD debe existir antes que Odoo)
vagrant up odoo-server      # Después (se conecta a la BD ya levantada)
```

### 📊 Resultado de la Fase 6

```
✅ Infraestructura como Código (IaC)
✅ vagrant up → despliega las 2 VMs automáticamente
✅ Provisioning idempotente (re-ejecutable sin romper nada)
✅ Triggers de cleanup: desregistran runners de GitHub al destruir VMs
```

---

## Fase 7 — Correcciones de Red y Bugs

### 📍 Problemas encontrados y resueltos

Durante las pruebas de `vagrant up` se detectaron **6 bugs críticos** de red y configuración:

### 🐛 Bug 1 — Gateway al final del provisioning (CRÍTICO)

```diff
- # Gateway configurado al final del script (~línea 240)
- # → APT, Docker, git clone fallaban sin Internet
+ # Gateway configurado AL INICIO (~línea 66)
+ # → Todas las descargas funcionan desde el primer momento
```

**Impacto:** Sin esto, el provisioning fallaba al 100%.

### 🐛 Bug 2 — `set -e` incompleto en provision_postgres.sh

```diff
- set -e
+ set -euo pipefail    # Detectar variables no definidas + fallos en pipes
```

### 🐛 Bug 3 — MACVLAN con parent incorrecto

```diff
- -o "parent=${VLAN_IFACE}.30"    # Buscaba eth1.30 (no existe sin VLAN tagging)
+ -o "parent=${VLAN_IFACE}"       # Usa eth1 directamente
```

> [!NOTE]
> **Nota posterior:** MACVLAN fue finalmente descartado.
> VMware host-only no permite promiscuous mode → los contenedores MACVLAN no son alcanzables.
> El acceso a Odoo es vía port mapping: `https://192.168.30.10`.

### 🐛 Bug 4 — Cockpit no instalado en VM PostgreSQL

```diff
- apt install -y curl ca-certificates gnupg
+ apt install -y curl ca-certificates gnupg cockpit
+ systemctl enable --now cockpit.socket
```

### 🐛 Bug 5 — Vagrant ignora `gateway:` y `netmask:`

```diff
- deb.vm.network "private_network", ip: "192.168.30.10",
-   netmask: "255.255.255.0",
-   gateway: "192.168.30.1"          # ← IGNORADO por vagrant-vmware-desktop
+ deb.vm.network "private_network", ip: "192.168.30.10",
+   auto_config: false               # provision_debian.sh gestiona la red
```

### 🐛 Bug 6 — Adaptadores en Custom en lugar de LAN Segment

**Problema:** VMware conectaba las NICs como `Custom (VMnetX)` en vez de `LAN Segment`. Las VMs no podían comunicarse entre sí.

**Solución:** Usar PVN IDs (Private Virtual Network IDs) en el Vagrantfile:

```ruby
# Todas las VMs con el mismo PVN ID → mismo LAN Segment
PVNID_VLAN10 = "52 54 AB 10 00 00 00 00-00 00 00 00 00 00 00 10"
PVNID_VLAN30 = "52 54 AB 30 00 00 00 00-00 00 00 00 00 00 00 30"
PVNID_VLAN40 = "52 54 AB 40 00 00 00 00-00 00 00 00 00 00 00 40"
```

### 🐛 Decisión posterior — Red sin pfSense durante provisioning

**Problema real descubierto:** pfSense es una VM manual. Durante `vagrant up`, pfSense puede estar apagado.

**Solución adoptada (estado actual del código):**

```
┌──────────────────────────────────────────────────────────────┐
│  ESTRATEGIA DE RED: "PROVISIONAR SIN DEPENDER DE PFSENSE"    │
│                                                               │
│  eth0 (NAT VMware) → Internet directo para descargas          │
│  eth1 (VLAN)       → IP estática SIN gateway                  │
│                                                               │
│  Si pfSense responde → se añade ruta a la otra VLAN           │
│  Si pfSense NO responde → el provisioning continúa normal     │
│                                                               │
│  Script persistente en /etc/network/if-up.d/ añade las        │
│  rutas automáticamente cuando pfSense arranque después.       │
└──────────────────────────────────────────────────────────────┘
```

### 📊 Resultado de la Fase 7

```
✅ 6 bugs de red corregidos
✅ Provisioning funciona con o sin pfSense encendido
✅ Red persistente tras reinicios
✅ Commits: 17bdb5b → 0662990 → 2ae1e17 → b034487
```

---

## Fase 8 — Hardening y Securización

### 📍 Objetivo
Endurecer la seguridad del servidor una vez que todo funciona.

> [!CAUTION]
> **SIEMPRE hacer hardening AL FINAL.** Es mucho más fácil diagnosticar
> problemas con acceso completo. Una vez en modo headless, el único acceso
> es SSH (clave pública) o Cockpit.

### 🔧 Paso 8.1 — Firewall local (UFW)

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirige a HTTPS)
sudo ufw allow 443/tcp   # HTTPS Nginx
sudo ufw allow 9090/tcp  # Cockpit
sudo ufw enable
```

### 🔧 Paso 8.2 — SSH por clave pública

```bash
# Desde el PC de administración (VLAN 40)
ssh-keygen -t ed25519 -C "admin-tfg" -f ~/.ssh/tfg_admin
ssh-copy-id -i ~/.ssh/tfg_admin.pub servidor@192.168.30.10

# Verificar que funciona CON clave
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # ✅

# SOLO DESPUÉS de verificar — deshabilitar contraseñas
sudo nano /etc/ssh/sshd_config
```

```ini
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
LoginGraceTime 30
AllowUsers servidor
MaxAuthTries 3
```

> [!CAUTION]
> **NO cerrar la sesión SSH actual** hasta confirmar que puedes entrar con la clave
> desde OTRA ventana. Si configuras `PasswordAuthentication no` sin clave copiada,
> **perderás el acceso permanentemente**.

### 🔧 Paso 8.3 — Modo headless (sin GUI)

```bash
sudo systemctl set-default multi-user.target
sudo apt remove --purge gnome* x11* xorg* -y
sudo apt autoremove --purge -y && sudo apt clean
sudo reboot
```

### 🔧 Paso 8.4 — Verificar tras reboot

```bash
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10

systemctl get-default               # → multi-user.target ✅
sudo ufw status                     # → Status: active ✅
systemctl is-active docker          # → active ✅
systemctl is-active cockpit.socket  # → active ✅
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps
# odoo-web    → Up (healthy) ✅
# nginx-proxy → Up (healthy) ✅
```

### 📊 Resultado de la Fase 8

```
✅ UFW activo: solo 22/80/443/9090
✅ SSH: solo clave pública, sin root, sin contraseña
✅ Modo headless: multi-user.target (sin GUI)
✅ Servidor seguro y operativo
```

---

## Fase 9 — Estado Final

### 🏗️ Arquitectura Final Completa

```
                        Internet (WAN)
                            │
                            │ NAT 80/443
                            ▼
                    ┌──────────────┐
                    │   pfSense    │  ← VM manual (VMware)
                    │  4 interfaces │
                    └──┬─────┬────┬┘
                       │     │    │
              VLAN 10  │  VLAN30  │  VLAN 40
          192.168.10.x │ (DMZ)    │ 192.168.40.x
                       │     │    │
                PCs    │     │    │  Admins + DBAs
             Empleados │     │    │
                       │     ▼    │
                       │  ┌──────────────────────────┐
                       │  │  vm-odoo (Debian 12)      │
                       │  │  192.168.30.10            │
                       │  │  ┌──────┐ ┌──────────┐   │
                       │  │  │nginx │→│ odoo-web │   │
                       │  │  │proxy │  │ Odoo 17  │   │
                       │  │  │:80/443│ │ :8069    │   │
                       │  │  └──────┘ └────┬─────┘   │
                       │  │  Cockpit :9090  │         │
                       │  │  Runner CI/CD   │         │
                       │  └────────────────┼─────────┘
                       │                    │ TCP :5432
                       │                    ▼
                       │          ┌────────────────────┐
                       │          │  vm-postgres        │
                       │          │  192.168.40.10      │
                       │          │  PostgreSQL 16      │
                       │          │  Cockpit :9090      │
                       │          │  Runner CI/CD       │
                       │          └────────────────────┘
                       │
                       └────── HTTPS :443 ───────────────┘
                          (Empleados acceden a Odoo)
```

### 📊 Checklist Final Completo

```
FASE 1 — Red (pfSense)
  ✅ 4 interfaces activas: WAN + VLAN 10 + VLAN 30 + VLAN 40
  ✅ DHCP: VLAN 10 (192.168.10.100–200) + VLAN 40 (192.168.40.10–50)
  ✅ DNS Resolver: erp.odoo.tfg.com → 192.168.30.20
  ✅ NAT Port Forward: WAN 80/443 → nginx-proxy
  ✅ 32 reglas de firewall: anti-pivoting + permisos mínimos
  ✅ Panel pfSense: solo VLAN 40
  ✅ Anti-Lockout desactivado

FASE 2 — PostgreSQL (VM independiente)
  ✅ vm-postgres: IP estática 192.168.40.10
  ✅ PostgreSQL 16 nativo (sin Docker)
  ✅ Base de datos: odoo_erp, usuario: odoo
  ✅ pg_hba.conf: solo acepta desde 192.168.30.0/24
  ✅ Cockpit activo en :9090

FASE 3 — Servidor Odoo (VM Docker)
  ✅ vm-odoo: IP estática 192.168.30.10
  ✅ Docker + Docker Compose operativos
  ✅ 2 contenedores healthy: odoo-web + nginx-proxy
  ✅ SSL autofirmado (renovable)
  ✅ Cockpit activo en :9090

FASE 4 — Odoo (aplicación)
  ✅ Empresa: TechSolutions S.L.
  ✅ Módulos: CRM, Ventas, RRHH, Inventario
  ✅ 10 usuarios con roles por departamento
  ✅ Auditoría SQL: trigger activo en res_users

FASE 5 — CI/CD
  ✅ 2 runners activos (odoo-runner + db-runner)
  ✅ CI: ShellCheck + YAML lint + Docker validate
  ✅ CD: Despliegue automático tras CI exitosa
  ✅ Pipeline: git push → CI ✅ → CD ✅

FASE 6 — Seguridad
  ✅ UFW: deny-all + 22/80/443/9090
  ✅ SSH: solo clave pública, sin root
  ✅ Debian headless: multi-user.target

FASE 7 — Backups
  ✅ Cron cada 4h: pg_dump remoto a 192.168.40.10
  ✅ Retención: 7 días
  ✅ Log: /var/log/backup_odoo.log (rotado por logrotate)

FASE 8 — Automatización (Vagrant)
  ✅ vagrant up → despliega las 2 VMs automáticamente
  ✅ Provisioning idempotente
  ✅ Scripts de red resilientes (funcionan con/sin pfSense)
```

### 📦 Estructura Final del Repositorio

```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
├── Vagrantfile                    # IaC: Define las 2 VMs Debian
├── .env.example                   # Plantilla de variables (sin secretos)
├── .gitignore                     # Excluye .env, *.box, ISOs, datos Docker
│
├── vagrant/                       # Scripts de aprovisionamiento
│   ├── provision_debian.sh        # vm-odoo: Docker + Nginx + Odoo + SSL + Runner
│   ├── provision_postgres.sh      # vm-postgres: PostgreSQL 16 + Cockpit + Runner
│   └── Vagrantfile.pfsense-box    # Config para empaquetar pfSense como .box
│
├── docker/                        # Stack Docker (2 servicios)
│   ├── docker-compose.yml         # odoo-web + nginx-proxy (SIN PostgreSQL)
│   ├── odoo.conf                  # db_host = 192.168.40.10
│   └── .env                       # Variables runtime (generado por provisioning)
│
├── config_nginx/                  # Configuración del proxy inverso
├── certs/                         # Certificados SSL (generados automáticamente)
│
├── scripts/
│   ├── deploy/
│   │   ├── deploy.sh              # Script de despliegue (usado por CD)
│   │   └── generate_pfsense_config.sh  # Genera config.xml para pfSense
│   ├── mantenimiento/
│   │   ├── backup_postgres.sh     # pg_dump remoto a 192.168.40.10
│   │   ├── monitor.sh             # Health check cada 15 min
│   │   └── update.sh              # Actualizar imágenes Docker
│   ├── odoo/
│   │   ├── odoo_setup_wizard.sh   # Renombrar empresa + instalar módulos
│   │   └── odoo_crear_usuarios.sh # Crear los 10 usuarios con roles
│   └── ldap/                      # ⚠️ DEPRECADO (material de referencia)
│
├── sql/
│   └── audit_triggers.sql         # Tabla + trigger + vista de auditoría
│
├── extras/ldap/                   # LDAP como mejora futura
│
├── .github/workflows/
│   ├── ci.yml                     # CI: ShellCheck + YAML lint + Docker validate
│   └── deploy.yml                 # CD: Despliegue automático en vm-odoo
│
├── docs/                          # 📚 Documentación técnica completa
│   ├── INSTALACION_COMPLETA.md    # Punto de entrada único
│   ├── CONTROL_ACCESO.md          # Modelo de seguridad en 3 capas
│   ├── reglas_pfsense.md          # Referencia completa de reglas
│   ├── diagrama_red.md            # Diagramas Mermaid de la arquitectura
│   ├── HISTORIAL_IMPLEMENTACION.md# Historia del desarrollo
│   └── guias/                     # Sub-guías detalladas
│       ├── GUIA_COMPLETA.md             ← Guía técnica unificada
│       └── GUIA_TRABAJO_PASO_A_PASO.md  ← ESTE DOCUMENTO
│
└── screenshots/                   # Capturas para la memoria del TFG
```

### 🔍 Evolución del proyecto — Línea temporal

```
Abril 2026
├── 29/04: Investigación y decisiones de diseño
├── 29/04: v1.0 — Infraestructura base (3 contenedores Docker)
├── 30/04: v1.1 — install.sh, .env, healthchecks
├── 30/04: v1.2 — Auditoría SQL en producción
└── 30/04: v1.3 — Pipeline CI/CD completo

Mayo 2026
├── 06/05: v1.4 — Fix .env ausente tras limpieza
├── 06/05: Fase C — LDAP implementado → ⚠️ RETIRADO posteriormente
├── 08/05: Fase A — Verificación de aislamiento VLAN
├── 08/05: Fase B — MACVLAN para IPs físicas en contenedores
├── 15/05: v1.7 — Vagrant IaC (3 VMs, PostgreSQL nativo, sin LDAP)
├── 23/05: 6 bugs de red corregidos (gateway, MACVLAN, PVN IDs)
├── 27/05: Correcciones Vagrant + pfSense refactoring
└── 28/05: Documentación final y guía de trabajo
```

### 💡 Decisiones clave que cambiaron el proyecto

| Decisión | Antes | Después | Por qué |
|:---------|:------|:--------|:--------|
| PostgreSQL | Contenedor Docker | VM nativa (VLAN 40) | Aislamiento real de red y recursos |
| LDAP | Contenedor Docker | ❌ Descartado | Complejidad operativa vs beneficio |
| Red Docker | MACVLAN | Bridge + Port mapping | VMware no soporta promiscuous mode |
| Vagrant red | `vmware__vmnet` | PVN ID (LAN Segments) | Vagrant-vmware ignora gateway/netmask |
| pfSense | Provisioning automático | VM manual | FreeBSD no se provisiona igual que Linux |
| Internet provision | Vía pfSense | Vía eth0 NAT directo | pfSense puede no estar encendido |

---

## 📚 Referencias Rápidas

| Documento | Para qué sirve |
|:----------|:---------------|
| [`INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md) | Punto de entrada único |
| [`GUIA_COMPLETA.md`](GUIA_COMPLETA.md) | Guía técnica unificada — pfSense + PostgreSQL + Odoo + CI/CD + Hardening |
| [`../CONTROL_ACCESO.md`](../CONTROL_ACCESO.md) | Modelo de seguridad en 3 capas |
| [`../reglas_pfsense.md`](../reglas_pfsense.md) | Referencia completa de reglas firewall |
| [`../diagrama_red.md`](../diagrama_red.md) | Diagramas de topología (Mermaid) |

---

*TFG ASIR 2025/2026 — IES Cañaveral*
*Sandra Fradejas Avedillo*
