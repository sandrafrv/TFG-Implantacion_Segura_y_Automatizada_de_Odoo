# Guía de Despliegue — Implantación Segura y Automatizada de Odoo
**TFG ASIR 2025/2026 — Sandra Fradejas Avedillo**

> [!IMPORTANT]
> Este archivo ha sido reemplazado por la **Guía Maestra de Instalación** que incluye sub-guías detalladas por módulo.
>
> **→ Ir a la guía actualizada: [`INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)**

La guía maestra incluye:
- Índice centralizado con navegación a cada fase
- Sub-guías detalladas en `docs/guias/` para pfSense, Debian, Docker, Odoo, LDAP, CI/CD y Hardening
- Checklist de verificación completo
- Solución de problemas comunes por módulo

---

*El contenido histórico de este archivo se mantiene a continuación como referencia.*

---

Esta guía explica cómo reproducir la infraestructura completa **desde cero**, en el orden correcto. Sigue los pasos en secuencia.

---

## Requisitos previos

| Componente | Versión | Notas |
|------------|---------|-------|
| VirtualBox | ≥ 6.x | Hipervisor para las VMs |
| pfSense | 2.7.x | ISO descargada de netgate.com |
| Debian | 12 (Bookworm) | Con entorno gráfico GNOME |
| Docker | 24.x (`docker.io`) | Instalado por `install.sh` |
| Docker Compose | V2 | Instalado con `docker-compose` |

---

## PASO 1 — Crear las Máquinas Virtuales

### VM 1: pfSense (Firewall)
- RAM: 1 GB | CPU: 1 core | Disco: 10 GB
- Adaptador 1 → **NAT** (WAN — salida a Internet)
- Adaptador 2 → **Red Interna `"LAN"`** (VLAN 10 Clientes)
- Adaptador 3 → **Red Interna `"DMZ"`** (VLAN 30 Servidor)

### VM 2: Debian 12 (Servidor ERP)
- RAM: 4 GB | CPU: 2 cores | Disco: 40 GB
- Adaptador 1 → **Red Interna `"DMZ"`** (misma red que Adaptador 3 de pfSense)

### VM 3: Cliente (Validación)
- RAM: 2 GB
- Adaptador 1 → **Red Interna `"LAN"`**

---

## PASO 2 — Configurar pfSense

### 2.1 Asignar interfaces en el asistente de texto
Al arrancar pfSense por primera vez, asignar:
- `vtnet0` → **WAN**
- `vtnet1` → **LAN** (Gateway: `192.168.10.1`)
- `vtnet2` → **DMZ/OPT1** (Gateway: `192.168.30.1`)

### 2.2 Configuración desde la interfaz web (`https://192.168.10.1`)

**DHCP en LAN (VLAN 10):** rango `192.168.10.100 – 192.168.10.200`

**Reglas de Firewall → WAN:**
- Bloquear todo salvo puertos 80 y 443 (redirigidos por NAT)

**Reglas de Firewall → LAN:**

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | PASS | TCP | LAN net | 192.168.30.10 | 80, 443, 9090 | Odoo + Cockpit |
| 2 | PASS | TCP | LAN net | 192.168.30.10 | 22 | SSH admin |
| 3 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 5432 | Bloquear PostgreSQL |
| 4 | BLOCK | TCP/UDP | LAN net | 192.168.30.0/24 | 8069 | Bloquear Odoo directo |
| 5 | PASS | * | LAN net | * | * | Internet |

**Reglas de Firewall → DMZ (OPT1):**

| Prioridad | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|-----------|--------|-----------|--------|---------|--------|-------------|
| 1 | BLOCK | * | DMZ net | 192.168.10.0/24 | * | Anti-pivoting a LAN |
| 2 | PASS | TCP/UDP | DMZ net | * | 53 | DNS saliente |
| 3 | PASS | TCP | DMZ net | * | 80, 443 | HTTP/HTTPS saliente |
| 4 | BLOCK | * | DMZ net | * | * | Deny all |

**NAT Port Forward (Firewall → NAT → Port Forward):**
- Interface: WAN | Proto: TCP | Puerto dest: 80/443 | IP redirigida: `192.168.30.10`

### 2.3 DNS Interno (para el dominio `erp.odoo.tfg.com`)

**Services → DNS Resolver → Host Overrides → + Add:**

| Campo | Valor |
|-------|-------|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |

**Services → DHCP Server → LAN → DNS Server 1:** `192.168.10.1`

**Firewall → NAT → Port Forward (interceptar DNS de clientes):**

| Campo | Valor |
|-------|-------|
| Interface | LAN |
| Protocol | TCP/UDP |
| Source | LAN subnets (`192.168.10.0/24`) |
| Destination | `*` (cualquier IP) |
| Destination port | `53` |
| Redirect target IP | `192.168.10.1` |
| Redirect target port | `53` |

---

## PASO 3 — Preparar Debian 12 (Servidor)

### 3.1 Configurar IP estática
```bash
# Editar /etc/network/interfaces
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
```bash
sudo systemctl restart networking
ip addr show   # Debe mostrar 192.168.30.10
```

### 3.2 Clonar el repositorio en el servidor
```bash
# Instalar git
sudo apt update && sudo apt install git -y

# Clonar el repositorio
sudo git clone https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git /opt/erp-odoo
cd /opt/erp-odoo
```

---

## PASO 4 — Instalación Automática

```bash
# Dar permisos y ejecutar el instalador todo-en-uno
chmod +x install.sh
sudo ./install.sh
```

El instalador realiza automáticamente:
1. Instala dependencias: `git`, `curl`, `openssl`, `cockpit`, `docker.io`, `docker-compose`
2. Habilita servicios `docker` y `cockpit.socket`
3. Crea la estructura de directorios (`data/`, `backups/`, `certs/`, `docker/`)
4. Genera certificados SSL autofirmados (RSA 2048, 365 días)
5. Lanza `scripts/configure.sh` → pide contraseñas interactivamente
6. Ejecuta `scripts/deploy.sh` → levanta el stack Docker y espera healthcheck de Odoo
7. Ejecuta `scripts/install_cron.sh` → programa backup diario, monitor y actualización semanal

> ⏱️ El primer arranque de Odoo puede tardar 2-5 minutos mientras inicializa la base de datos.

---

## PASO 5 — Post-instalación: Configurar Odoo y LDAP

Una vez que el stack está arriba:

### 5.1 Asistente de configuración Odoo
```bash
bash /opt/erp-odoo/scripts/odoo_setup_wizard.sh
```

El asistente guía paso a paso:
1. **Nombre de la compañía** — cambia el nombre por defecto de "My Company"
2. **Módulos** — instala los módulos seleccionados (LDAP es obligatorio)
3. **Configuración LDAP** — detecta la IP del contenedor y configura la autenticación
4. **Restricción de acceso** — elimina contraseñas locales (sólo admin conserva la suya)

### 5.2 Crear usuarios en LDAP
```bash
bash /opt/erp-odoo/scripts/ldap_crear_usuarios.sh
```

El script es interactivo. Para cada usuario solicita:
- `uid` (login, ej: `jdoe`)
- Nombre completo, apellido, email
- Contraseña

Los usuarios se crean en la OU `ou=usuarios,dc=tfg,dc=com`.

### 5.3 Crear usuarios técnicos en Odoo (API, Ventas, etc.)
```bash
bash /opt/erp-odoo/scripts/odoo_crear_usuarios.sh
```

Crea automáticamente: Usuario API, Técnico, Ventas, Dirección, Becario.  
Las contraseñas se generan aleatoriamente y se muestran **una sola vez** al terminar.

---

## PASO 6 — Aplicar Auditoría SQL (Opcional)

```bash
docker exec -i odoo_erp psql -U odoo -d odoo_erp < /opt/erp-odoo/sql/audit_triggers.sql
```

Crea:
- Tabla `asir_audit_log` — registra creaciones de usuario con snapshot JSONB
- Trigger `trg_audit_new_odoo_user` en `res_users`
- Vista `v_audit_resumen` para consultas rápidas

Verificar que funciona:
```bash
docker exec -it odoo_erp psql -U odoo -d odoo_erp -c "SELECT * FROM v_audit_resumen;"
```

---

## PASO 6 — Control de Acceso por Roles (3 Capas + LDAP)

> 📄 Documentación completa en [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)

Este paso configura el modelo de seguridad en 3 capas definido en el diagrama IaC:

### 6.1 Actualizar variables de entorno LDAP

```bash
nano /opt/erp-odoo/docker/.env
# Añadir (si no están ya):
#   LDAP_ADMIN_PASSWORD=contraseña_segura_admin
#   LDAP_READONLY_PASSWORD=contraseña_segura_readonly
```

### 6.2 Levantar OpenLDAP (IP MACVLAN: 192.168.30.22)

```bash
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d ldap

# Verificar que está activo y accesible
docker ps | grep openldap
ldapsearch -H ldap://192.168.30.22 -x -b "dc=tfg,dc=com" "(objectClass=*)" dn
```

El archivo `ldap/estructura.ldif` se carga automáticamente al primer arranque y crea:
- `ou=usuarios` — cuentas de empleados
- `ou=grupos` — grupos departamentales (VLAN 10 y VLAN 40)

### 6.3 Configurar ACLs de LDAP

```bash
bash /opt/erp-odoo/scripts/ldap_politica_acceso.sh
```

Configura el modelo de acceso:
- `cn=admin` → escritura total (solo VLAN 40)
- `cn=tecnico` (grupo) → solo puede cambiar `userPassword` de empleados
- `cn=readonly` → lectura total (usado por Odoo para autenticar)
- Resto → sin acceso

### 6.4 Crear usuarios en LDAP con sus grupos

```bash
bash /opt/erp-odoo/scripts/ldap_crear_usuarios.sh
```

El script es interactivo. Para cada usuario solicita: `uid`, nombre, email, contraseña y **grupo departamental**. Los grupos disponibles son:
- **VLAN 10**: `becarios | ventas | rrhh | almacen | tecnico | jefe_ventas | jefe_rrhh | jefe_almacen`
- **VLAN 40**: `admin | dba`

### 6.5 Aplicar restricciones de Nginx (Capa C)

```bash
# Verificar sintaxis de la nueva configuración
docker exec nginx-proxy nginx -t

# Recargar sin cortar el servicio
docker exec nginx-proxy nginx -s reload
```

Nuevas restricciones activas en `config_nginx/odoo_proxy.conf`:
- `/web/database` → solo VLAN 40
- `/odoo/action-base_setup` → solo VLAN 40
- `/web/tests` → bloqueado completamente
- `/web?debug=` → solo VLAN 40

### 6.6 Crear usuarios en Odoo con roles (Capas A + B)

```bash
bash /opt/erp-odoo/scripts/odoo_crear_usuarios.sh
```

Crea los usuarios del ERP con sus grupos asignados automáticamente:

| Usuario | Rol | Módulos visibles |
|---------|-----|-----------------|
| `becario@erp.odoo.tfg.com` | Becario | Solo CRM (lectura) |
| `ventas@erp.odoo.tfg.com` | Ventas | CRM + Ventas + Facturas |
| `rrhh@erp.odoo.tfg.com` | RRHH | RRHH + Empleados |
| `almacen@erp.odoo.tfg.com` | Almacén | Inventario + Compras |
| `tecnico@erp.odoo.tfg.com` | Técnico | Inventario + Soporte |
| `jefe.ventas@erp.odoo.tfg.com` | Jefe Ventas | Ventas completo + aprobaciones |
| `jefe.rrhh@erp.odoo.tfg.com` | Jefe RRHH | RRHH completo + aprobaciones |
| `jefe.almacen@erp.odoo.tfg.com` | Jefe Almacén | Almacén completo + aprobaciones |
| `api.user@erp.odoo.tfg.com` | API | Solo XML-RPC |

> ⚠️ Las contraseñas se generan aleatoriamente y se muestran **una sola vez** al terminar. Guárdalas inmediatamente.

### 6.7 Configurar inicio de sesión LDAP en los PCs de VLAN 10

> 📄 Documentación completa en [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md) — sección "Inicio de Sesión en el Sistema Operativo"

Este paso configura los **clientes Linux de VLAN 10** para que usen el mismo usuario y contraseña LDAP tanto para entrar al PC como para entrar a Odoo.

**Ejecutar en cada PC cliente Linux de VLAN 10:**

```bash
# Copiar el script al cliente (si el repositorio no está montado localmente)
scp /opt/erp-odoo/scripts/configurar_cliente_ldap.sh usuario@192.168.10.x:~/

# Ejecutar como root en el cliente
sudo bash configurar_cliente_ldap.sh
```

El script instala y configura automáticamente:
- **SSSD** — intermediario entre el sistema y el LDAP (con caché offline)
- **PAM** — intercepta el login del SO y lo valida contra LDAP
- **NSS** — el sistema puede resolver usuarios LDAP como si fueran locales
- **pam_mkhomedir** — crea `/home/<uid>` automáticamente en el primer login

Tras la instalación, los usuarios del directorio LDAP pueden iniciar sesión con sus credenciales normales. Si se especifica un grupo durante la instalación, solo ese grupo podrá entrar en ese PC concreto.

**Verificación rápida tras ejecutar el script:**

```bash
# Debe mostrar los datos del usuario desde LDAP
getent passwd <uid_del_usuario>

# Resultado esperado (ejemplo):
# jdoe:x:2001:2000:John Doe:/home/jdoe:/bin/bash
```

---

## PASO 7 — Aplicar Auditoría SQL (Opcional)


```bash
sudo apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 9090/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

---

## PASO 8 — Configurar Red MACVLAN (IPs físicas para contenedores)

```bash
# Detectar la interfaz de red activa del servidor Debian
ip link show   # Buscar ens18 o la interfaz conectada a la DMZ

# Crear la red MACVLAN
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30

# Reiniciar el stack para que los contenedores tomen IPs de la MACVLAN
docker compose -f /opt/erp-odoo/docker/docker-compose.yml down
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d --force-recreate
```

Resultado esperado:
- `nginx-proxy` → `192.168.30.20`
- `odoo-web` → `192.168.30.21`
- `odoo_erp` (PostgreSQL) → sin IP pública (sólo red interna)

> ⚠️ El host Debian no puede hacer ping a las IPs MACVLAN de sus propios contenedores (limitación del kernel). Verificar desde otro equipo de la red o desde un contenedor temporal.

---

## PASO 9 — CI/CD con GitHub Actions (Opcional)

```bash
# En el servidor Debian, como usuario administrador (no root)
chmod +x /opt/erp-odoo/scripts/setup_runner.sh
/opt/erp-odoo/scripts/setup_runner.sh
```

El script pide:
1. URL del repositorio GitHub
2. Token de registro (obtenido en Settings → Actions → Runners → New runner)

Instala el agente como servicio systemd. Desde ese momento, cada `git push` a `main` desencadena el pipeline automático de despliegue.

---

## PASO 10 — Hardening: Debian Headless (Último paso)

> ⚠️ Hacer este paso al final. Con GUI es más fácil diagnosticar errores anteriores.

```bash
# Cambiar a modo texto
sudo systemctl set-default multi-user.target

# Eliminar entorno gráfico GNOME
sudo apt remove --purge gnome* -y
sudo apt remove --purge x11* xorg* -y
sudo apt autoremove --purge -y

# Reiniciar y verificar
sudo reboot
```

Tras el reinicio, verificar por SSH:
```bash
systemctl get-default    # multi-user.target
systemctl is-active docker   # active
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps   # todos Up
curl -k -I https://erp.odoo.tfg.com   # 200 OK
```

---

## Verificación Final — Checklist

| Comprobación | Comando / URL | Resultado esperado |
|--------------|---------------|-------------------|
| Odoo accesible | `https://erp.odoo.tfg.com` | Pantalla de login Odoo 17 |
| Cockpit accesible | `https://192.168.30.10:9090` | Panel de administración |
| DNS resuelve correctamente | `nslookup erp.odoo.tfg.com` | `192.168.30.10` |
| Contenedores activos | `docker compose -f docker/docker-compose.yml ps` | 4 contenedores `Up (healthy)` |
| PostgreSQL bloqueado | `nc -zv 192.168.30.10 5432` (desde cliente) | Timeout / Connection refused |
| Auditoría SQL activa | `SELECT * FROM v_audit_resumen;` | Sin errores |
| Cron instalado | `cat /etc/cron.d/erp-odoo` | 3 tareas programadas |
| UFW activo | `sudo ufw status` | Status: active |

---

## Orden de Arranque (tras reinicio del servidor)

1. **Encender VM pfSense** → esperar interfaces activas
2. **Encender VM Debian** → Docker arranca automáticamente con `restart: always`
3. **Verificar** → `https://erp.odoo.tfg.com` desde el cliente
4. **Monitorizar** → Cockpit en `https://192.168.30.10:9090`

---

## Scripts de Gestión Diaria

```bash
# Menú interactivo completo
sudo /opt/erp-odoo/scripts/erp.sh

# Comandos directos
bash scripts/backup.sh          # Backup manual
bash scripts/monitor.sh         # Chequeo de salud
bash scripts/ldap_crear_usuarios.sh  # Añadir usuario LDAP
docker compose -f docker/docker-compose.yml logs -f  # Logs en tiempo real
```
