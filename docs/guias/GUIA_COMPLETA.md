# Guía Técnica Completa — Instalación y Configuración

**TFG ASIR 2025/2026 — Implantación Segura y Automatizada de Odoo ERP**
*Sandra Fradejas Avedillo — IES Cañaveral*

> [!IMPORTANT]
> Este documento contiene **toda la documentación técnica** del proyecto unificada.
> Sigue las partes en orden. Cada sección indica exactamente qué hacer y dónde.
>
> **→ Para la narrativa paso a paso del proyecto:** [`GUIA_TRABAJO_PASO_A_PASO.md`](GUIA_TRABAJO_PASO_A_PASO.md)

---

## Índice

| Parte | Contenido |
|:-----:|:----------|
| [1](#parte-1--red-y-firewall-pfsense) | Red y Firewall (pfSense) — VM, interfaces, DHCP, DNS, aliases, NAT, ACLs |
| [2](#parte-2--vm-postgresql-vlan-40) | VM PostgreSQL — BD aislada en VLAN 40 |
| [3](#parte-3--servidor-debian--docker--odoo) | Servidor Debian + Docker + Odoo + Nginx |
| [4](#parte-4--cicd-con-github-actions) | CI/CD con GitHub Actions |
| [5](#parte-5--hardening) | Hardening — UFW, SSH, headless |
| [A](#apéndice-a--crear-vagrant-box-de-pfsense) | Crear Vagrant Box de pfSense |
| [B](#apéndice-b--correcciones-de-red-vagrant) | Correcciones de red (6 bugs) |
| [C](#apéndice-c--ldap-material-de-referencia) | LDAP — Material de referencia (no activo) |

---

## Prerequisitos

- **VMware Workstation** instalado en Windows
- **Vagrant ≥ 2.3** + plugin `vagrant-vmware-desktop`
- ISOs descargadas: `debian-13.3.0-amd64-netinst.iso` y `netgate-installer-v1.1.1-RELEASE-amd64.iso`
- Variables de entorno para Vagrant:

```powershell
$env:GH_PAT="ghp_tutoken"                   # Personal Access Token (scope: repo)
$env:GH_RUNNER_TOKEN_ODOO="AXXXXX"           # Runner token para odoo-server
$env:GH_RUNNER_TOKEN_DB="AYYYYY"             # Runner token para db-server
$env:POSTGRES_PASSWORD="tu_password_seguro"
```

---

## Arquitectura General

```
Internet (WAN)
     │ NAT 80/443
     ▼
[ pfSense — 4 interfaces ]
     │           │           │
  VLAN 10     VLAN 30     VLAN 40
  192.168.10  192.168.30  192.168.40
  Clientes    DMZ Server  Admin + BD
     │           │           │
  PCs           Debian 13   PCs Admin
                192.168.30.10
                │
    ┌───────────┴──────────────────────┐
    │ nginx-proxy  → :80 :443         │  Docker en odoo-server
    │ odoo-web     → :8069            │
    └──────────────────────────────────┘
                         │ TCP :5432
                 [ db-server — 192.168.40.10 ]
                   PostgreSQL 16 — VM nativa
```

### Tabla de Direccionamiento

| Componente | VLAN | IP | Acceso permitido |
|:-----------|:-----|:---|:----------------|
| pfSense gateway LAN | 10 | 192.168.10.1 | Solo VLAN 40 (panel) |
| pfSense gateway DMZ | 30 | 192.168.30.1 | — |
| pfSense gateway Admin/BD | 40 | 192.168.40.1 | Solo VLAN 40 |
| **odoo-server** — host Debian | DMZ | 192.168.30.10 | SSH/Cockpit solo VLAN 40 |
| **nginx-proxy** | DMZ | 192.168.30.10 | VLAN 10 + 40 + WAN (:443) |
| **odoo-web** | DMZ | 192.168.30.10 | Solo vía Nginx |
| **db-server** — PostgreSQL 16 | BD | 192.168.40.10 | Solo :5432 desde VLAN 30 y VLAN 40 |

---

# PARTE 1 — Red y Firewall (pfSense)

> [!IMPORTANT]
> pfSense debe configurarse **antes** que cualquier otro componente.
> Es el firewall, router, DHCP y servidor DNS de toda la infraestructura.

> [!TIP]
> **¿Quieres automatizar?** El script `scripts/deploy/generate_pfsense_config.sh` genera un
> `config.xml` completo. Impórtalo en **Diagnostics → Backup/Restore** y salta a la [sección 1.11](#111-aislamiento-del-panel--anti-lockout).

---

## 1.1 Crear la VM pfSense en VMware

*File → New Virtual Machine → Custom (Advanced)*

| Parámetro | Valor |
|:----------|:------|
| Compatibility | Workstation 17.x |
| ISO | `netgate-installer-v1.1.1-RELEASE-amd64.iso` |
| Guest OS | Other → **FreeBSD 14 64-bit** |
| VM Name | `TFG-pfSense` |
| Processors | 1 CPU, 1 Core |
| RAM | **1024 MB** |
| Disco | **8 GB**, Single file |

### Añadir 4 adaptadores de red

*VM → Settings → Add → Network Adapter* (añadir 3 veces más)

| Adaptador | Tipo VMware | Rol en pfSense | Subred |
|:---------:|:-----------:|:---------------|:-------|
| NIC 1 | NAT | WAN → Internet | DHCP |
| NIC 2 | Host-only / LAN Segment | LAN → em1 | 192.168.10.0/24 |
| NIC 3 | Host-only / LAN Segment | OPT1 (DMZ) → em2 | 192.168.30.0/24 |
| NIC 4 | Host-only / LAN Segment | OPT2 (Admin) → em3 | 192.168.40.0/24 |

---

## 1.2 Instalar pfSense

1. Arrancar la VM con la ISO
2. **Install pfSense** → aceptar licencia
3. Keymap → **Spanish**
4. Partitioning → **Auto (ZFS)** → `da0` → Aceptar
5. Esperar ~3 min → **Reboot**
6. ⚠️ Expulsar la ISO antes del reinicio

---

## 1.3 Asignación de Interfaces (consola de texto)

Opción **1 (Assign Interfaces)**:

```
Should VLANs be set up now? → n
Enter the WAN interface name:      em0
Enter the LAN interface name:      em1
Enter the Optional 1 interface:    em2
Enter the Optional 2 interface:    em3
Do you want to proceed? → y
```

Opción **2 (Set Interface IP Addresses)**:

| Interfaz | IP | Máscara | DHCP |
|:---------|:---|:--------|:-----|
| **LAN** (em1) | `192.168.10.1` | /24 | Sí: rango 100–200 |
| **OPT1** (em2) | `192.168.30.1` | /24 | No (IPs estáticas) |
| **OPT2** (em3) | `192.168.40.1` | /24 | Sí: rango 10–50 |
| **WAN** (em0) | DHCP automático | — | — |

---

## 1.4 Acceso al Panel Web

```
URL:      https://192.168.10.1 (inicial) ó https://192.168.40.1 (tras mover admin)
Usuario:  admin
Password: pfsense  (cambiar en el primer login)
```

Asistente inicial: hostname `pfsense`, dominio `tfg.com`, timezone `Europe/Madrid`.

---

## 1.5 Configurar Interfaces (panel web)

### WAN — *Interfaces → WAN*

- IPv4 Configuration Type: `DHCP`
- ✅ Block private networks
- ✅ Block bogon networks

### LAN — *Interfaces → LAN*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | `192.168.10.1 / 24` |
| Description | `LAN_CLIENTES` |

### OPT1 — *Interfaces → OPT1*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| IPv4 Address | `192.168.30.1 / 24` |
| Description | `DMZ` |

### OPT2 — *Interfaces → Assignments → añadir em3 → Interfaces → OPT2*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| IPv4 Address | `192.168.40.1 / 24` |
| Description | `VLAN_ADMIN_BD` |

**Save** → **Apply Changes** en cada una.

---

## 1.6 DHCP

### LAN (VLAN 10) — *Services → DHCP Server → LAN*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Range | `192.168.10.100 – 192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |

### OPT2 (VLAN 40) — *Services → DHCP Server → OPT2*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

> La DMZ (OPT1/VLAN 30) **NO tiene DHCP** — IPs estáticas en el servidor Debian y Docker.

---

## 1.7 DNS Resolver

*Services → DNS Resolver → General Settings*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Network Interfaces | LAN, OPT1, OPT2, Localhost |
| Outgoing Interfaces | WAN |
| DNSSEC | ✅ |

### Host Override — Odoo ERP

*Services → DNS Resolver → Host Overrides → + Add*

| Campo | Valor |
|:------|:------|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |
| Description | `nginx-proxy Odoo ERP — DMZ` |

> ⚠️ La IP debe apuntar al host **odoo-server** (`192.168.30.10`), no a ninguna IP de contenedor individual — los contenedores no tienen IP propia en la VLAN (usan port mapping del host).

---

## 1.8 Aliases

*Firewall → Aliases → + Add* (crear uno por uno)

| Nombre | Tipo | Dirección | Descripción |
|:-------|:-----|:----------|:------------|
| `Servidor_Debian` | Host | `192.168.30.10` | Servidor Debian DMZ |
| `Nginx_Proxy` | Host | `192.168.30.10` | Nginx Reverse Proxy |
| `Odoo_Web` | Host | `192.168.30.10` | Odoo ERP |
| `PostgreSQL_VM` | Host | `192.168.40.10` | PostgreSQL 16 VLAN 40 |
| `VLAN_Clientes` | Network | `192.168.10.0/24` | Red VLAN 10 Clientes |
| `VLAN_Admin` | Network | `192.168.40.0/24` | Red VLAN 40 Admin+BD |

---

## 1.9 NAT — Port Forward

*Firewall → NAT → Port Forward → + Add*

### Regla 1 — HTTP público → Nginx

| Campo | Valor |
|:------|:------|
| Interface | WAN |
| Protocol | TCP |
| Source | any |
| Destination | WAN address |
| Destination Port | 80 |
| Redirect Target IP | `192.168.30.10` |
| Redirect Target Port | 80 |
| Description | `HTTP publico - Nginx Odoo` |
| Filter Rule Association | Pass |

### Regla 2 — HTTPS público → Nginx

| Campo | Valor |
|:------|:------|
| Interface | WAN |
| Protocol | TCP |
| Destination Port | 443 |
| Redirect Target IP | `192.168.30.10` |
| Redirect Target Port | 443 |
| Description | `HTTPS publico - Nginx Odoo` |
| Filter Rule Association | Pass |

### Regla 3 — Forzar DNS VLAN 10

| Campo | Valor |
|:------|:------|
| Interface | LAN |
| Protocol | TCP/UDP |
| Source | LAN subnets |
| Destination | any |
| Destination Port | 53 |
| Redirect Target IP | `192.168.10.1` |
| Description | `Forzar DNS VLAN 10 a pfSense` |

### Regla 4 — Forzar DNS VLAN 40

| Campo | Valor |
|:------|:------|
| Interface | OPT2 |
| Protocol | TCP/UDP |
| Source | OPT2 subnets |
| Destination | any |
| Destination Port | 53 |
| Redirect Target IP | `192.168.40.1` |
| Description | `Forzar DNS VLAN 40 a pfSense` |

> **¿Por qué forzar DNS?** Clientes Linux con `systemd-resolved` pueden ignorar el DNS del DHCP
> y consultar a 8.8.8.8. Estas reglas interceptan cualquier consulta DNS y la redirigen a pfSense,
> garantizando que `erp.odoo.com` resuelva siempre a `192.168.30.10`.

### NAT Outbound — *Firewall → NAT → Outbound*

- Mode: **Automatic Outbound NAT** ← dejar así

---

## 1.10 Reglas de Firewall

> [!IMPORTANT]
> El orden de las reglas es **crítico**. pfSense evalúa de arriba a abajo y aplica la **primera que coincide**.
> Los bloqueos siempre van **antes** que los permisos.

### WAN — *Firewall → Rules → WAN*

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | Block | * | RFC 1918 | * | * | Block private networks *(auto)* |
| 2 | Block | * | Bogon | * | * | Block bogon networks *(auto)* |
| **3** | **Pass** | IPv4 TCP | any | WAN address | **80** | HTTP público |
| **4** | **Pass** | IPv4 TCP | any | WAN address | **443** | HTTPS público |
| **5** | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

> Las reglas 1 y 2 se activan en *Interfaces → WAN* marcando "Block private/bogon networks".

**Cómo añadir cada regla Pass:**
1. *Firewall → Rules → WAN → + Add (arriba)*
2. Action: **Pass**, Interface: **WAN**, Protocol: **TCP**
3. Source: **any**, Destination: **WAN address** → puerto 80 (o 443)
4. **Save** → **Apply Changes**

---

### LAN (VLAN 10) — *Firewall → Rules → LAN*

> [!WARNING]
> La **"Default allow LAN to any"** debe estar **desactivada** (editarla → marcar Disabled → Save).

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | **Block** | IPv4 * | LAN | `192.168.40.0/24` | * | **Bloquear VLAN Admin+BD ← PRIMERO** |
| 2 | **Block** | IPv4 TCP | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 | **Block** | IPv4 TCP | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 | **Block** | IPv4 TCP | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 5 | ~~Pass~~ | IPv4 * | LAN | any | * | ~~Default allow~~ **← DESHABILITAR** |
| 6 | **Pass** | IPv4 TCP | LAN | `192.168.30.10` | 80 | Odoo HTTP vía Nginx |
| 7 | **Pass** | IPv4 TCP | LAN | `192.168.30.10` | 443 | Odoo HTTPS vía Nginx |
| 8 | **Pass** | IPv4 * | LAN | any | * | Navegación Internet |
| 9 | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

---

### OPT1 / DMZ (VLAN 30) — *Firewall → Rules → OPT1*

> [!WARNING]
> Los bloqueos anti-pivoting deben ir **ANTES** que cualquier regla de permiso.

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | **Block** | IPv4 * | OPT1 | `192.168.10.0/24` | * | **Anti-pivoting VLAN 10 ← PRIMERO** |
| 2 | **Block** | IPv4 * | OPT1 | `192.168.10.1` | * | DMZ no accede a pfSense LAN |
| 3 | **Pass** | IPv4 TCP | `192.168.30.10` | `192.168.40.10` | 5432 | **Odoo → PostgreSQL ← ANTES del bloqueo VLAN40** |
| 4 | **Block** | IPv4 * | OPT1 | `192.168.40.0/24` | * | Anti-pivoting VLAN Admin |
| 5 | **Pass** | IPv4 TCP | OPT1 | any | 80 | Actualizaciones HTTP |
| 6 | **Pass** | IPv4 TCP | OPT1 | any | 443 | Actualizaciones HTTPS |
| 7 | **Pass** | IPv4 UDP | OPT1 | any | 53 | DNS resolución |
| 8 | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

**Detalle de la regla 3 (crítica):**
1. *Firewall → Rules → OPT1 → + Add*
2. Action: **Pass**, Protocol: **TCP**
3. Source → Single host: `192.168.30.10`
4. Destination → Single host: `192.168.40.10`, Port: `5432`
5. **Save** → colocar en posición 3 → **Apply Changes**

---

### OPT2 / Admin (VLAN 40) — *Firewall → Rules → OPT2*

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | **Pass** | IPv4 TCP | OPT2 | This Firewall | 443 | **Panel pfSense — acceso exclusivo** |
| 2 | **Pass** | IPv4 TCP | OPT2 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 | **Pass** | IPv4 TCP | OPT2 | `192.168.30.10` | 9090 | Cockpit — gestión visual |
| 4 | **Pass** | IPv4 TCP | OPT2 | `192.168.30.10` | 443 | Nginx/Odoo admin |
| 5 | **Pass** | IPv4 TCP | OPT2 | `192.168.40.10` | 5432 | Acceso DBA directo a PostgreSQL |
| 6 | **Pass** | IPv4 TCP | OPT2 | any | 80 | Actualizaciones HTTP |
| 7 | **Pass** | IPv4 TCP | OPT2 | any | 443 | Actualizaciones HTTPS |
| 8 | **Pass** | IPv4 UDP | OPT2 | any | 53 | DNS resolución |
| 9 | **Block** | IPv4 * | OPT2 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 10 | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

**Detalle regla 1 — Panel pfSense:**
1. Action: **Pass**, Interface: **OPT2**, Protocol: **TCP**
2. Source: **OPT2 subnets**
3. Destination: **This Firewall** (seleccionar en el desplegable)
4. Destination Port: `443`

---

## 1.11 Aislamiento del Panel — Anti-Lockout

> [!CAUTION]
> Seguir este orden exacto. Si desactivas la Anti-Lockout sin tener acceso VLAN 40,
> **perderás el acceso al firewall** y tendrás que restaurar desde la consola.

### Paso a paso

**Desde el PC actual (aún en VMnet1/LAN):**

1. Verificar que OPT2 está configurado con IP `192.168.40.1/24` y DHCP activo
2. Verificar que la regla 1 de OPT2 (Pass → This Firewall :443) está creada

**Mover el PC de administración a VMnet3 / LAN Segment VLAN 40:**

3. En VMware: cambiar adaptador del PC admin a `VMnet3`
4. Refrescar IP: `sudo dhclient -r && sudo dhclient` → debe obtener `192.168.40.x`
5. Abrir `https://192.168.40.1` → verificar acceso al panel pfSense
6. Aplicar todas las reglas definitivas de OPT2 (sección 1.10)

**Desactivar Anti-Lockout (solo tras confirmar acceso desde VLAN 40):**

7. *System → Advanced → Admin Access* → marcar **Disable webConfigurator anti-lockout rule** → Save

**Cambiar contraseña admin:**

8. *System → User Manager → Users → admin → Edit* → cambiar `pfsense` por contraseña segura

---

## 1.12 Exportar Configuración

### Opción A — Generador del proyecto (recomendado)

```bash
bash scripts/deploy/generate_pfsense_config.sh
# → Genera config/pfsense_config.xml
```

### Opción B — Exportar desde pfSense

1. *Diagnostics → Backup/Restore*
2. Pestaña **Backup Configuration**
3. Include extra data: ✅
4. **Download configuration as XML** → guardar como `config/pfsense_config.xml`

---

## 1.13 Verificación y Checklist pfSense

```bash
# Desde cliente VLAN 10
nslookup erp.odoo.com          # → 192.168.30.10
curl -k -I https://erp.odoo.com  # → HTTP/2 200

# Desde admin VLAN 40
curl -k https://192.168.40.1       # → Panel pfSense ✅
ssh usuario@192.168.30.10          # → SSH al servidor ✅
psql -h 192.168.40.10 -U odoo -d odoo_erp -c '\l'  # → PostgreSQL ✅

# Estas deben FALLAR (confirma segmentación):
curl -k https://192.168.10.1       # Desde VLAN 10 → Sin respuesta ✅
nc -zv 192.168.40.10 5432          # Desde VLAN 10 → Timeout ✅
```

```
✅ Interfaces: WAN (DHCP) + LAN (10.1/24) + OPT1 (30.1/24) + OPT2 (40.1/24)
✅ DHCP: LAN 100–200, OPT2 10–50
✅ DNS Resolver + Host Override: erp.odoo.com → 192.168.30.10
✅ 6 Aliases creados
✅ NAT: WAN 80/443 → 192.168.30.10, DNS forzado en LAN y OPT2
✅ Reglas: WAN(5) + LAN(9) + OPT1(8) + OPT2(10) = 32 reglas
✅ Anti-Lockout desactivado (tras acceso VLAN 40 confirmado)
✅ Contraseña admin cambiada
✅ config.xml exportado
```

---

# PARTE 2 — VM PostgreSQL (VLAN 40)

## 2.1 Crear la VM

| Campo | Valor |
|:------|:------|
| Nombre | `TFG-DB-Server` |
| Box Vagrant | `bento/debian-13` |
| RAM | **2048 MB** |
| CPU | **1 core** |
| IP estática | `192.168.40.10` (VLAN 40) |

> **Con Vagrant:** `vagrant up db-server` provisiona automáticamente con `vagrant/provision_postgres.sh`.

## 2.2 Instalar PostgreSQL 16

```bash
# Clave GPG y repositorio
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] \
https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

apt update && apt install -y postgresql-16 postgresql-client-16
systemctl enable postgresql && systemctl start postgresql
```

## 2.3 Crear Usuario y Base de Datos

```sql
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD '<contraseña_segura>';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
EOF
```

## 2.4 Configurar Acceso Remoto

```bash
# /etc/postgresql/16/main/postgresql.conf
listen_addresses = '*'

# /etc/postgresql/16/main/pg_hba.conf — añadir al final:
host  all  odoo  192.168.30.0/24  md5
```

```bash
sudo systemctl restart postgresql
```

> **¿Por qué `all` y no `odoo_erp`?** Odoo conecta primero a la base `postgres` para listar y crear BDs (database manager). Sin acceso a `all`, falla con `FATAL: no pg_hba.conf entry`.

## 2.5 Instalar Cockpit

```bash
apt install -y cockpit
systemctl enable cockpit.socket && systemctl start cockpit.socket
# Acceso desde VLAN 40: https://192.168.40.10:9090
```

## 2.6 Verificar

```bash
# Desde odoo-server (192.168.30.10) → debe funcionar
nc -zv 192.168.40.10 5432                    # → Connection succeeded ✅
psql -h 192.168.40.10 -U odoo -d odoo_erp -c '\l'  # → Lista BDs ✅

# Desde VLAN 10 (clientes) → debe FALLAR
nc -zv 192.168.40.10 5432                    # → Timeout ✅ (bloqueado)
```

---

# PARTE 3 — Servidor Debian + Docker + Odoo

> [!IMPORTANT]
> El stack activo contiene **únicamente 2 contenedores**: `odoo-web` y `nginx-proxy`.
> PostgreSQL reside en la **VM externa `db-server`** (`192.168.40.10`, VLAN 40).

## 3.1 Crear la VM

| Campo | Valor |
|:------|:------|
| Nombre | `TFG-Odoo-Server` |
| Box Vagrant | `bento/debian-13` |
| RAM | **4096 MB** |
| CPU | **2 cores** |
| IP estática | `192.168.30.10` (VLAN 30 — DMZ) |

> **Con Vagrant:** `vagrant up odoo-server` provisiona automáticamente con `vagrant/provision_debian.sh`.

## 3.2 Configurar IP Estática

```bash
sudo nano /etc/network/interfaces
```

```
auto ens18
iface ens18 inet static
    address 192.168.30.10
    netmask 255.255.255.0
    gateway 192.168.30.1
    dns-nameservers 192.168.30.1
```

> El nombre de la interfaz puede variar. Compruébalo con `ip link show`.

```bash
sudo systemctl restart networking
ip addr show   # Debe mostrar: inet 192.168.30.10/24
ping -c 3 192.168.30.1   # Gateway pfSense responde
```

## 3.3 Instalar Docker CE

```bash
apt install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Para Debian 13 (Trixie) usar bookworm como fallback
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian bookworm stable" \
  > /etc/apt/sources.list.d/docker.list

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker && systemctl start docker
usermod -aG docker $USER
docker --version && docker compose version
```

## 3.4 Clonar Repositorio y Configurar

```bash
git clone https://github.com/sandrafrv/Implantacion_Segura_y_Automatizada_de_Odoo.git \
  /opt/erp-odoo
cd /opt/erp-odoo
cp .env.example .env
nano .env   # Rellenar con contraseñas reales
chmod 600 .env
```

El `.env` debe contener:

```bash
POSTGRES_HOST=192.168.40.10
POSTGRES_PASSWORD=<contraseña_segura>
ODOO_MASTER_PASSWORD=<contraseña_maestra_odoo>
```

> [!CAUTION]
> **Nunca hagas `git add .env`**. Está en `.gitignore`, pero verifica siempre con `git status`.

## 3.5 Generar Certificados SSL

```bash
mkdir -p /opt/erp-odoo/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /opt/erp-odoo/certs/server.key \
  -out    /opt/erp-odoo/certs/server.crt \
  -subj "/C=ES/ST=Madrid/L=Madrid/O=TFG/OU=ASIR/CN=odoo.tfg"
```

## 3.6 Verificar Conectividad con PostgreSQL

```bash
nc -zv 192.168.40.10 5432   # → Connection succeeded ✅
psql -h 192.168.40.10 -U odoo -d odoo_erp -c '\l'
```

> Si falla, verificar las reglas en pfSense: OPT1 (DMZ) → OPT2 (BD) puerto 5432.

## 3.7 Levantar el Stack Docker

```bash
cd /opt/erp-odoo
docker compose -p erp-odoo --env-file .env -f docker/docker-compose.yml up -d

# Seguir el arranque en tiempo real (Ctrl+C para salir)
docker compose -f docker/docker-compose.yml logs -f
```

> ⏱️ El **primer arranque de Odoo puede tardar 2–5 minutos** mientras inicializa la BD externa.

### Verificar estado

```bash
docker compose -f docker/docker-compose.yml ps
```

Resultado esperado (**2 contenedores**):

```
NAME          IMAGE          STATUS
odoo-web      odoo:17        Up (healthy)
nginx-proxy   nginx:alpine   Up (healthy)
```

## 3.8 Instalar Cockpit

```bash
apt install -y cockpit
systemctl enable cockpit.socket && systemctl start cockpit.socket
# Acceso desde VLAN 40: https://192.168.30.10:9090
```

## 3.9 Post-instalación de Odoo

### Asistente de configuración

```bash
Los usuarios se crean automáticamente vía deploy.sh. La configuración de la empresa (UI) y la instalación de módulos se realizan manualmente tras el primer inicio:
```

Realiza: **Renombrar empresa** → "My Company" → "TechSolutions S.L." | **Instalar módulos** → CRM, Ventas, RRHH, Inventario

### Crear usuarios con roles

```bash
bash /opt/erp-odoo/scripts/odoo/odoo_crear_usuarios.sh
```

| Usuario | Rol | Módulos |
|:--------|:----|:--------|
| `becario@erp.odoo.com` | Becario | Solo CRM (lectura) |
| `ventas@erp.odoo.com` | Ventas | CRM + Ventas + Facturas |
| `rrhh@erp.odoo.com` | RRHH | RRHH + Empleados |
| `almacen@erp.odoo.com` | Almacén | Inventario + Compras |
| `tecnico@erp.odoo.com` | Técnico | Inventario + Soporte |
| `jefe.ventas@erp.odoo.com` | Jefe Ventas | Ventas completo + aprobaciones |
| `jefe.rrhh@erp.odoo.com` | Jefe RRHH | RRHH completo + aprobaciones |
| `jefe.almacen@erp.odoo.com` | Jefe Almacén | Almacén completo + aprobaciones |
| `api.user@erp.odoo.com` | API | Solo XML-RPC |
| `dba@erp.odoo.com` | DBA | Sin UI (solo BD) |

> [!WARNING]
> Las contraseñas se generan aleatoriamente y se muestran **una sola vez**. Guardarlas inmediatamente.

### Auditoría SQL

```bash
psql -h 192.168.40.10 -U odoo -d odoo_erp \
    < /opt/erp-odoo/sql/audit_triggers.sql

# Verificar
psql -h 192.168.40.10 -U odoo -d odoo_erp \
    -c "SELECT * FROM v_audit_resumen;"
```

Crea: tabla `asir_audit_log` (JSONB), trigger `trg_audit_new_odoo_user` en `res_users`, vista `v_audit_resumen`.

## 3.10 Cron de Mantenimiento

```bash
bash /opt/erp-odoo/scripts/deploy/install_cron.sh
```

| Tarea | Horario | Script |
|:------|:--------|:-------|
| Backup PostgreSQL remoto | Cada 4h | `mantenimiento/backup_postgres.sh` |
| Monitor de salud | Cada 15 min | `mantenimiento/monitor.sh` |
| Actualizar imágenes Docker | Domingo 03:00 | `mantenimiento/update.sh` |

## 3.11 Solución de Problemas

| Error | Causa | Solución |
|:------|:------|:---------|
| `could not connect to server` (Odoo) | `DB_HOST` mal o VM PG apagada | Verificar `.env` → `DB_HOST=192.168.40.10`; levantar `db-server` |
| `password authentication failed` | Contraseñas incorrectas | `docker compose down` → corregir `.env` → `docker compose up -d` |
| Nginx en bucle de reinicios | Certificados incorrectos | Verificar `grep ssl_certificate config_nginx/*.conf` y regenerar SSL |
| `dubious ownership` en git | `/opt/erp-odoo` creado por root | `git config --global --add safe.directory /opt/erp-odoo` |
| Puerto 80/443 en uso | Contenedor corrupto | `docker compose down --remove-orphans && docker compose up -d` |

---

# PARTE 4 — CI/CD con GitHub Actions

## 4.1 Cómo Funciona

```
git push → GitHub CI (ShellCheck + YAML + Docker) → ✅ pasa → CD (deploy.sh en Debian)
```

| Workflow | Archivo | Qué hace |
|:---------|:--------|:---------|
| CI | `.github/workflows/ci.yml` | ShellCheck en `scripts/` y `vagrant/`; yamllint; `docker compose config -q`; genera y valida `config.xml` |
| CD | `.github/workflows/deploy.yml` | Pull, rebuild y verifica `odoo-web` + `nginx-proxy` en el servidor |

## 4.2 Instalar Runners

### Obtener Token

En GitHub: **Settings → Actions → Runners → New self-hosted runner** → Linux / x64 → copiar **token** (válido 1 hora)

### Instalar en odoo-server

```bash
mkdir /opt/actions-runner && cd /opt/actions-runner
curl -O -L https://github.com/actions/runner/releases/download/v2.317.0/actions-runner-linux-x64-2.317.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.317.0.tar.gz
./config.sh --url https://github.com/sandrafrv/Implantacion_Segura_y_Automatizada_de_Odoo \
  --token <TOKEN> --name odoo-runner --labels 'self-hosted,linux,odoo'
sudo ./svc.sh install runner
sudo ./svc.sh start
```

### Permisos del .env

```bash
sudo chown root:servidor /opt/erp-odoo/.env
sudo chmod 640 /opt/erp-odoo/.env
```

### Sudoers para el runner

```bash
# /etc/sudoers.d/runner-deploy
runner ALL=(root) NOPASSWD: /usr/bin/chown -R runner /opt/erp-odoo
runner ALL=(root) NOPASSWD: /usr/bin/chown -R 101:101 /opt/erp-odoo/odoo-data /opt/erp-odoo/odoo_sessions /opt/erp-odoo/addons
```

## 4.3 Lo que Hace el CD en el Servidor

```bash
# 1. git pull (sincronizar)
git fetch origin && git reset --hard origin/main

# 2. docker pull (imágenes nuevas)
docker pull odoo:17 && docker pull nginx:alpine

# 3. deploy.sh:
bash scripts/deploy/deploy.sh
#   ├── Verifica PostgreSQL externo (nc -zv 192.168.40.10 5432)
#   ├── docker compose down --remove-orphans
#   ├── docker compose up -d --force-recreate
#   └── Healthcheck: curl -sk https://localhost/web/health

# 4. Verificación final: contenedores running
```

## 4.4 Verificar

```bash
sudo systemctl is-active actions.runner.*   # → active ✅
# En GitHub → Settings → Actions → Runners → estado: Idle ✅

# Probar pipeline:
git commit --allow-empty -m "test: verificar CI/CD"
git push origin main
# GitHub → Actions → CI ✅ → CD ✅
```

## 4.5 Problemas Comunes CI/CD

| Error | Solución |
|:------|:---------|
| Runner no aparece | `sudo systemctl restart actions.runner.*` |
| `dubious ownership` | `git config --global --add safe.directory /opt/erp-odoo` |
| `.env` no legible | `sudo chown root:servidor .env && sudo chmod 640 .env` |
| BD no accesible | Verificar regla pfSense VLAN 30 → VLAN 40 :5432 |

---

# PARTE 5 — Hardening

> [!CAUTION]
> **Realizar SIEMPRE AL FINAL.** Es mucho más fácil diagnosticar con acceso completo.
> Una vez en modo headless, el único acceso es SSH (clave) o Cockpit.

## 5.1 Firewall Local (UFW)

```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirige a 443)
sudo ufw allow 443/tcp   # HTTPS Nginx
sudo ufw allow 9090/tcp  # Cockpit
sudo ufw enable
sudo ufw status verbose
```

## 5.2 Endurecer SSH

**Primero: copiar clave pública desde VLAN 40:**

```bash
ssh-keygen -t ed25519 -C "admin-tfg" -f ~/.ssh/tfg_admin
ssh-copy-id -i ~/.ssh/tfg_admin.pub servidor@192.168.30.10
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # Verificar ✅
```

**Solo después de verificar que la clave funciona:**

```bash
sudo nano /etc/ssh/sshd_config
```

```ini
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
ChallengeResponseAuthentication no
LoginGraceTime 30
AllowUsers servidor
X11Forwarding no
MaxAuthTries 3
```

```bash
sudo systemctl restart sshd
# ⚠️ Verificar desde OTRA ventana antes de cerrar la actual:
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10   # ✅
```

> [!CAUTION]
> **NO cerrar la sesión SSH actual** hasta confirmar que funciona con clave desde otra ventana.

## 5.3 Modo Headless (Sin GUI)

```bash
sudo systemctl set-default multi-user.target
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y && sudo apt clean
```

## 5.4 Verificar tras Reboot

```bash
sudo reboot
ssh -i ~/.ssh/tfg_admin servidor@192.168.30.10

systemctl get-default               # → multi-user.target ✅
sudo ufw status                     # → Status: active ✅
systemctl is-active docker          # → active ✅
systemctl is-active cockpit.socket  # → active ✅
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps
# odoo-web    → Up (healthy) ✅
# nginx-proxy → Up (healthy) ✅
nc -zv 192.168.40.10 5432           # → succeeded ✅
curl -k -I https://localhost/web/health  # → HTTP/2 200 ✅
```

---

## Checklist Final Completo

```
PARTE 1 — Red (pfSense)
  ✅ 4 interfaces activas: WAN + VLAN 10 + VLAN 30 + VLAN 40
  ✅ DHCP: VLAN 10 (.100–.200) + VLAN 40 (.10–.50)
  ✅ DNS: erp.odoo.com → 192.168.30.10
  ✅ NAT: WAN 80/443 → nginx, DNS forzado en LAN y OPT2
  ✅ 32 reglas firewall (anti-pivoting + permisos mínimos)
  ✅ Panel pfSense: solo VLAN 40, Anti-Lockout desactivado

PARTE 2 — PostgreSQL
  ✅ db-server: 192.168.40.10, PostgreSQL 16 nativo
  ✅ Base de datos odoo_erp, usuario odoo
  ✅ pg_hba.conf: solo desde 192.168.30.0/24
  ✅ Cockpit en :9090

PARTE 3 — Servidor Odoo
  ✅ odoo-server: 192.168.30.10, Docker + Cockpit
  ✅ 2 contenedores healthy: odoo-web + nginx-proxy
  ✅ Empresa: TechSolutions S.L. + 10 usuarios con roles
  ✅ Auditoría SQL + Cron (backup cada 4h)

PARTE 4 — CI/CD
  ✅ Runners activos: odoo-runner + db-runner
  ✅ CI: ShellCheck + YAML + Docker validate
  ✅ CD: Despliegue automático post-CI

PARTE 5 — Hardening
  ✅ UFW: deny-all + 22/80/443/9090
  ✅ SSH: solo clave pública, sin root
  ✅ Debian headless: multi-user.target
```

---

## Orden de Arranque (tras reinicio)

```
1. Arrancar pfSense VM       → esperar ~1 min
2. Arrancar db-server      → PostgreSQL arranca automáticamente
3. Arrancar odoo-server          → Docker arranca automáticamente
4. Esperar ~3 min            → Odoo inicializa
5. Verificar desde VLAN 10   → https://erp.odoo.com
6. Verificar desde VLAN 40   → https://192.168.30.10:9090 (Cockpit)
```

---

# APÉNDICE A — Crear Vagrant Box de pfSense

> **Objetivo:** Instalar pfSense desde la ISO, configurarlo completamente, y empaquetarlo
> como `.box` para que `vagrant up pfsense` funcione sin pasos manuales.

## A.1 Crear VM e instalar pfSense

Seguir las instrucciones de la [Parte 1](#parte-1--red-y-firewall-pfsense) para crear la VM e instalar pfSense.

## A.2 Configurar pfSense completamente

Aplicar TODA la configuración del [Parte 1](#parte-1--red-y-firewall-pfsense): interfaces, DHCP, DNS, aliases, NAT, ACLs.

## A.3 Preparar para Vagrant (SSH + usuario vagrant)

### Habilitar SSH — *System → Advanced → Admin Access*

| Campo | Valor |
|:------|:------|
| Enable Secure Shell | ✅ |
| SSHd Key Only | **Password or Public Key** |
| SSH port | `22` |

### Crear usuario vagrant — *System → User Manager → Users → + Add*

| Campo | Valor |
|:------|:------|
| Username | `vagrant` |
| Password | `vagrant` |
| Full Name | `Vagrant User` |
| Group Membership | `admins` |

### Añadir clave SSH pública de Vagrant

En *Users → vagrant → Edit → Authorized SSH Keys*, pegar:

```
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
```

### Configurar sudoers

Desde la consola pfSense (opción 8 → Shell):

```sh
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers.d/vagrant
chmod 440 /usr/local/etc/sudoers.d/vagrant
```

### Verificar SSH

```bash
ssh -o StrictHostKeyChecking=no vagrant@192.168.40.1
# Password: vagrant → debe mostrar menú pfSense
```

## A.4 Empaquetar con vagrant package

1. Apagar pfSense limpiamente: menú → **Opción 5) Halt system**
2. Empaquetar:

```powershell
cd "C:\Users\sandra\Desktop\Ante proyecto\TFG-ASIRB"
vagrant package --base "TFG-pfSense-base" --output "config/pfsense-tfg.box" \
  --vagrantfile "vagrant/Vagrantfile.pfsense-box"
```

3. Verificar:

```powershell
vagrant box add --name "tfg/pfsense" config/pfsense-tfg.box --force
vagrant box list   # → tfg/pfsense (vmware_desktop, 0)
```

## A.5 Subir a GitHub Releases

1. **Releases → Draft a new release** → Tag: `v1.0-pfsense-box`
2. Arrastrar `config/pfsense-tfg.box` como binario adjunto
3. **Publish release**

URL resultante:
```
https://github.com/sandrafrv/Implantacion_Segura_y_Automatizada_de_Odoo/releases/download/v1.0-pfsense-box/pfsense-tfg.box
```

## A.6 Actualizar Vagrantfile

```ruby
# Tu box privada con SSH:
pf.vm.box = "tfg/pfsense"
pf.vm.box_url = "https://github.com/.../releases/download/v1.0-pfsense-box/pfsense-tfg.box"
pf.vm.communicator = "ssh"
pf.ssh.username = "vagrant"
pf.ssh.password = "vagrant"
```

---

# APÉNDICE B — Correcciones de Red (Vagrant)

> Bugs encontrados y corregidos durante la integración de Vagrant con VMware y pfSense.

## B.1 Gateway al final del provisioning (CRÍTICO)

**Síntoma:** APT, Docker, git clone fallaban sin Internet.
**Causa:** El gateway se configuraba al final del script, después de todas las descargas.
**Solución:** Mover la configuración de red al INICIO del script.

## B.2 `set -e` incompleto en provision_postgres.sh

```diff
- set -e
+ set -euo pipefail
```

## B.3 MACVLAN con parent incorrecto

```diff
- -o "parent=${VLAN_IFACE}.30"    # busca eth1.30 (no existe)
+ -o "parent=${VLAN_IFACE}"       # usa eth1 directamente
```

> **Nota:** MACVLAN fue finalmente descartado. VMware no soporta promiscuous mode.

## B.4 Cockpit no instalado en db-server

```diff
- apt install -y curl ca-certificates gnupg
+ apt install -y curl ca-certificates gnupg cockpit
```

## B.5 Vagrant ignora `gateway:` y `netmask:`

```diff
- deb.vm.network "private_network", ip: "192.168.30.10",
-   gateway: "192.168.30.1"          # ← IGNORADO
+ deb.vm.network "private_network", ip: "192.168.30.10",
+   auto_config: false               # provision script gestiona la red
```

## B.6 Custom en lugar de LAN Segment

**Solución:** Usar PVN IDs (Private Virtual Network IDs) en el Vagrantfile:

```ruby
PVNID_VLAN10 = "52 54 AB 10 00 00 00 00-00 00 00 00 00 00 00 10"
PVNID_VLAN30 = "52 54 AB 30 00 00 00 00-00 00 00 00 00 00 00 30"
PVNID_VLAN40 = "52 54 AB 40 00 00 00 00-00 00 00 00 00 00 00 40"

# Aplicar en provider block:
v.vmx["ethernet1.connectionType"] = "pvn"
v.vmx["ethernet1.pvnID"]          = PVNID_VLAN30
```

## B.7 Estrategia actual de red

El provisioning funciona **con o sin pfSense encendido**:

```
eth0 (NAT VMware) → Internet directo para descargas
eth1 (VLAN)       → IP estática SIN gateway

Si pfSense responde → se añade ruta a la otra VLAN
Si pfSense NO responde → el provisioning continúa normal

Script persistente en /etc/network/if-up.d/ añade rutas al arrancar pfSense.
```

---

# APÉNDICE C — LDAP (Material de Referencia)

> [!WARNING]
> **LDAP no está en el despliegue principal.** Fue implementado y retirado.

## C.1 Por qué se descartó

- Si LDAP cae, los usuarios no pueden entrar a Odoo aunque el ERP esté operativo
- Sincronización continua entre cuentas LDAP y Odoo
- Superficie de ataque adicional con un servicio más expuesto en la red

## C.2 Material disponible

| Recurso | Ubicación |
|:--------|:----------|
| Estructura de directorio | `extras/ldap/estructura.ldif` |
| Script de ACLs | `extras/ldap/ldap_politica_acceso.sh` |
| Script de usuarios | `extras/ldap/ldap_crear_usuarios.sh` |
| Script de cliente | `extras/ldap/configurar_cliente_ldap.sh` |
| Guía de reactivación | `extras/ldap/README.md` |

## C.3 Cómo reactivar en el futuro

1. Añadir servicio `ldap` en `docker/docker-compose.yml` con imagen `osixia/openldap:1.5.0`
2. Montar `extras/ldap/estructura.ldif` como volumen de bootstrap
3. Configurar Odoo: *Ajustes → Técnico → Autenticación → Servidor LDAP*
4. (Opcional) Configurar PAM + SSSD con `extras/ldap/configurar_cliente_ldap.sh`

Ver `extras/ldap/README.md` para instrucciones completas.

---

## Documentación Relacionada

| Documento | Para qué sirve |
|:----------|:---------------|
| [`GUIA_TRABAJO_PASO_A_PASO.md`](GUIA_TRABAJO_PASO_A_PASO.md) | Cuaderno de trabajo — narrativa paso a paso |
| [`../INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md) | Punto de entrada y resumen |
| [`../CONTROL_ACCESO.md`](../CONTROL_ACCESO.md) | Modelo de seguridad en 3 capas |
| [`../reglas_pfsense.md`](../reglas_pfsense.md) | Referencia completa de reglas firewall |
| [`../diagrama_red.md`](../diagrama_red.md) | Diagramas Mermaid de la arquitectura |
| [`../../vagrant/README.md`](../../vagrant/README.md) | Aprovisionamiento Vagrant |
| [`../../sql/README.md`](../../sql/README.md) | Scripts de auditoría SQL |

---

*TFG ASIR 2025/2026 — IES Cañaveral*
*Sandra Fradejas Avedillo*
