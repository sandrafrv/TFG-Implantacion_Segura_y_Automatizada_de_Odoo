# Guía del Servidor — Debian + Docker + Odoo

**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)
**← Fase anterior:** [`guias/INSTALACION_RED.md`](INSTALACION_RED.md)

---

## PARTE 1 — Debian 13: Preparación del Servidor

### 1.1 Crear la VM Debian en VirtualBox

| Campo | Valor |
|:------|:------|
| Nombre | `Debian-Servidor-TFG` |
| Tipo | Linux → Debian (64-bit) |
| RAM | **4096 MB** mínimo |
| CPU | **2 cores** mínimo |
| Disco | **40 GB** (VDI, dinámico) |
| Adaptador de red | **Red Interna** → `DMZ_30` |

### 1.2 Instalar Debian 13

1. Arrancar con ISO de Debian 13 → **Graphical Install**
2. Idioma: Español | País: España | Teclado: Español
3. Hostname: `debian-erp` | Domain: `tfg.com`
4. Crear usuario `root` y usuario normal (ej. `servidor`)
5. Particionado: **Utilizar disco completo** (guiado)
6. Software: ✅ `GNOME` + ✅ `SSH server` + ✅ `standard system utilities`

> GNOME se instalará ahora para facilitar el diagnóstico. Se eliminará en la fase de Hardening.
> Debian 13 (Trixie) usa systemd-networkd por defecto — la configuración de IP estática
> puede hacerse también con `nmcli` o `nmtui` si la ISO incluye Network Manager.

### 1.3 Configurar IP Estática

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

> El nombre de la interfaz puede variar. Compruébalo con `ip link show` (`ens18`, `eth0`, `enp0s3`...).

```bash
sudo systemctl restart networking
ip addr show   # Debe mostrar: inet 192.168.30.10/24
ping -c 3 192.168.30.1   # Gateway pfSense responde
```

### 1.4 Actualizar e Instalar Dependencias Base

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget openssl ca-certificates gnupg lsb-release net-tools postgresql-client
```

### 1.5 Instalar Docker

> [!NOTE]
> En Debian 13 (Trixie) el paquete `docker.io` puede no estar en los repos oficiales todavía.
> Se recomienda instalar desde el repositorio oficial de Docker:

```bash
# Instalar dependencias necesarias
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings

# Agregar clave GPG oficial de Docker
sudo curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Añadir el repositorio oficial de Docker (Trixie)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian \
  trixie stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine + Compose
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

sudo systemctl enable docker && sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker   # Aplicar sin cerrar sesión
docker --version && docker compose version
docker run --rm hello-world   # Prueba rápida
```

### 1.6 Instalar Cockpit

```bash
sudo apt install -y cockpit
sudo systemctl enable cockpit.socket && sudo systemctl start cockpit.socket
```

Acceder desde VLAN 40: `https://192.168.30.10:9090`

### 1.7 Clonar el Repositorio

```bash
sudo git clone \
    https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git \
    /opt/erp-odoo
sudo chown -R $USER:$USER /opt/erp-odoo
cd /opt/erp-odoo
```

### 1.8 Crear el Archivo `.env` con Credenciales

```bash
cp .env.example .env
nano .env   # Editar con contraseñas reales
chmod 600 .env
```

El `.env` debe quedar así (con contraseñas **reales**, no los ejemplos):

```bash
# Conexión a PostgreSQL externo (VM vm-postgres, VLAN 40)
ODOO_ADMIN_PASSWD=<contraseña_maestra_odoo>
DB_HOST=192.168.40.10
DB_PORT=5432
DB_USER=odoo
DB_PASSWORD=<contraseña_segura_postgres>
DOMAIN=erp.odoo.tfg.com

# LDAP eliminado del despliegue principal — ver extras/ldap/ si se necesita en el futuro
```

> [!CAUTION]
> **Nunca hagas `git add .env`**. Está en `.gitignore`, pero verifica siempre con `git status` antes de hacer commit.

### 1.9 Alternativa: Instalador Todo-en-Uno

Los pasos 1.4 a 1.8 se pueden automatizar con:

```bash
cd /opt/erp-odoo
chmod +x install.sh
sudo ./install.sh
```

El instalador hace: dependencias → Cockpit → Docker → estructura de dirs → SSL → `.env` interactivo → deploy → cron.

---

## PARTE 2 — Stack Docker: Odoo + Nginx

> [!IMPORTANT]
> El stack activo contiene **únicamente 2 contenedores**: `odoo-web` y `nginx-proxy`.
> PostgreSQL reside en la **VM externa `vm-postgres`** (`192.168.40.10`, VLAN 40).
> LDAP ha sido descartado del despliegue principal — ver `extras/ldap/` para más info.

### 2.1 Arquitectura de Contenedores

```
VM Debian (192.168.30.10) — VLAN 30 (DMZ)
  odoo-web  (Odoo 17)    MACVLAN: 192.168.30.21  →  192.168.40.10:5432 (PostgreSQL externo)
  nginx-proxy (Nginx)    MACVLAN: 192.168.30.20  →  proxy inverso SSL → odoo-web:8069

VM PostgreSQL (192.168.40.10) — VLAN 40 (BD)
  PostgreSQL 16 nativo   puerto 5432
  Solo accesible desde VLAN 30 (regla pfSense explícita)
```

### 2.2 Crear la Red MACVLAN

```bash
# Detectar la interfaz de red activa
ip link show   # Buscar ens18 o la interfaz conectada a la DMZ

# Crear la red MACVLAN (una sola vez, persiste en Docker)
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30

docker network ls | grep macvlan   # Verificar
```

> [!WARNING]
> **Limitación del kernel Linux con macvlan:** el host Debian **no puede hacer ping** a las IPs MACVLAN de sus propios contenedores. Para verificar, usa un contenedor temporal:
> ```bash
> docker run --rm --network macvlan_vlan30 alpine \
>   wget -qO- --no-check-certificate https://192.168.30.20 | head -5
> ```

### 2.3 Generar Certificados SSL

Si no usaste `install.sh`:

```bash
sudo mkdir -p /opt/erp-odoo/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /opt/erp-odoo/certs/erp.key \
    -out    /opt/erp-odoo/certs/erp.crt \
    -subj "/C=ES/ST=Madrid/L=Madrid/O=TechSolutions/CN=erp.odoo.tfg.com"
ls /opt/erp-odoo/certs/   # → erp.crt  erp.key
```

### 2.4 Verificar Conectividad con PostgreSQL Externo

Antes de levantar Odoo, confirmar que la VM PostgreSQL es alcanzable:

```bash
# Desde vm-odoo (192.168.30.10)
nc -zv 192.168.40.10 5432   # → Connection succeeded ✅
psql -h 192.168.40.10 -U odoo -d odooerp -c '\l'
```

> Si falla, verificar las reglas de firewall en pfSense: OPT1 (DMZ) → OPT2 (BD) puerto 5432.

### 2.5 Levantar el Stack Docker

```bash
cd /opt/erp-odoo
docker compose -f docker/docker-compose.yml up -d

# Seguir el arranque en tiempo real (Ctrl+C para salir)
docker compose -f docker/docker-compose.yml logs -f
```

> ⏱️ El **primer arranque de Odoo puede tardar 2–5 minutos** mientras inicializa la base de datos en PostgreSQL externo. Es normal.

### 2.6 Verificar Estado de Contenedores

```bash
docker compose -f docker/docker-compose.yml ps
```

Resultado esperado (ambos `Up (healthy)`):
```
NAME          IMAGE          STATUS
odoo-web      odoo:17        Up (healthy)
nginx-proxy   nginx:alpine   Up (healthy)
```

> Solo deben aparecer **2 contenedores**. Si ves `odoo_erp` o `openldap`, el compose file tiene una versión antigua.

### 2.7 Solución de Problemas Comunes

| Error | Causa | Solución |
|:------|:------|:---------|
| `could not connect to server` (Odoo) | `DB_HOST` mal configurado o VM PostgreSQL apagada | Verificar `.env` → `DB_HOST=192.168.40.10`; levantar `vm-postgres` |
| `password authentication failed` | Contraseñas incorrectas en `.env` | `docker compose down` → corregir `.env` → `docker compose up -d` |
| Nginx en bucle de reinicios | Certificados con nombre incorrecto | Verificar `grep ssl_certificate config_nginx/*.conf` y regenerar SSL |
| `dubious ownership` en git | `/opt/erp-odoo` creado por root, runner usa otro usuario | `git config --global --add safe.directory /opt/erp-odoo` |
| Puerto 80/443 en uso | Contenedor nginx en estado corrupto | `docker compose down --remove-orphans && docker compose up -d --force-recreate` |

### 2.8 Instalar Cron de Mantenimiento

```bash
bash /opt/erp-odoo/scripts/deploy/install_cron.sh
cat /etc/cron.d/erp-odoo   # Verificar tareas instaladas
```

| Tarea | Horario | Script |
|:------|:--------|:-------|
| Backup PostgreSQL remoto | Diario 02:00 | `mantenimiento/backup_postgres.sh` |
| Monitor de salud | Cada 15 min | `mantenimiento/monitor.sh` |
| Actualizar imágenes Docker | Domingo 03:00 | `mantenimiento/update.sh` |

---

## PARTE 3 — Post-instalación de Odoo

### 3.1 Asistente de Configuración

```bash
bash /opt/erp-odoo/scripts/odoo/odoo_setup_wizard.sh
```

El asistente realiza 2 pasos principales:

1. **Renombrar empresa** → "My Company" → "TechSolutions S.L." (UPDATE en BD)
2. **Instalar módulos** → CRM, Ventas, RRHH, Inventario

> [!NOTE]
> `auth_ldap` **no se instala** en el despliegue principal.
> Si necesitas LDAP en el futuro, consulta [`extras/ldap/README.md`](../../extras/ldap/README.md).

### 3.2 Crear Usuarios Odoo con Roles

```bash
bash /opt/erp-odoo/scripts/odoo/odoo_crear_usuarios.sh
```

| Usuario | Rol | Módulos visibles | Tipo Odoo |
|:--------|:----|:----------------|:----------|
| `becario@erp.odoo.tfg.com` | Becario | Solo CRM (lectura) | Interno |
| `ventas@erp.odoo.tfg.com` | Ventas | CRM + Ventas + Facturas | Interno |
| `rrhh@erp.odoo.tfg.com` | RRHH | RRHH + Empleados | Interno |
| `almacen@erp.odoo.tfg.com` | Almacén | Inventario + Compras | Interno |
| `tecnico@erp.odoo.tfg.com` | Técnico | Inventario + Soporte | Interno |
| `jefe.ventas@erp.odoo.tfg.com` | Jefe Ventas | Ventas completo + aprobaciones | Interno |
| `jefe.rrhh@erp.odoo.tfg.com` | Jefe RRHH | RRHH completo + aprobaciones | Interno |
| `jefe.almacen@erp.odoo.tfg.com` | Jefe Almacén | Almacén completo + aprobaciones | Interno |
| `api.user@erp.odoo.tfg.com` | API | Solo XML-RPC | Interno |
| `dba@erp.odoo.tfg.com` | DBA | Sin UI (solo BD) | Interno |

> [!WARNING]
> Las contraseñas se generan aleatoriamente y se muestran **una sola vez**. Guárdalas inmediatamente.

### 3.3 Auditoría SQL en PostgreSQL Externo

```bash
# Aplicar triggers de auditoría directamente en la VM PostgreSQL externa
psql -h 192.168.40.10 -U odoo -d odooerp \
    < /opt/erp-odoo/sql/audit_triggers.sql

# Verificar que el trigger funciona
psql -h 192.168.40.10 -U odoo -d odooerp \
    -c "SELECT * FROM v_audit_resumen;"
```

El script crea:
- **Tabla** `asir_audit_log` — snapshot JSONB de cada usuario creado en Odoo
- **Trigger** `trg_audit_new_odoo_user` en `res_users`
- **Vista** `v_audit_resumen` para consultas rápidas

Ver documentación completa: [`sql/README.md`](../../sql/README.md)

### 3.4 Verificación Completa del Servidor

```bash
# Contenedores activos (deben ser exactamente 2)
docker compose -f docker/docker-compose.yml ps

# Odoo responde
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200

# Conectividad Odoo → PostgreSQL externo
nc -zv 192.168.40.10 5432   # → Connection succeeded ✅

# PostgreSQL bloqueado desde VLAN 10 (verificar desde cliente)
nc -zv 192.168.40.10 5432   # → Timeout ✅ (desde VLAN 10)

# Empresa renombrada en BD externa
psql -h 192.168.40.10 -U odoo -d odooerp \
    -c "SELECT name FROM res_company WHERE id=1;"
# → TechSolutions S.L. ✅

# Trigger de auditoría activo
psql -h 192.168.40.10 -U odoo -d odooerp \
    -c "SELECT trigger_name FROM information_schema.triggers WHERE trigger_name='trg_audit_new_odoo_user';"
# → trg_audit_new_odoo_user ✅
```

---

**→ Siguiente:** [`guias/INSTALACION_LDAP_CICD_HARDENING.md`](INSTALACION_LDAP_CICD_HARDENING.md) — LDAP (opcional) + CI/CD + Hardening
