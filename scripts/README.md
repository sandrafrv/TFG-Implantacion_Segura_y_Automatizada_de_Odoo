# Scripts de Administración y Despliegue

**TFG ASIR 2025/2026 — TechSolutions S.L.**

> [!IMPORTANT]
> Todos los scripts están diseñados para ejecutarse **únicamente en el servidor Debian** (`vm-odoo`, `192.168.30.10`).
> **No ejecutar en PCs cliente, en pfSense ni en Windows/macOS localmente.**

> [!NOTE]
> PostgreSQL reside en la **VM externa `vm-postgres`** (`192.168.40.10`, VLAN 40). Los scripts de backup y restore se conectan a esa IP. No usar `localhost` ni ningún contenedor `db`.

---

## Dar Permisos de Ejecución (Primera Vez)

```bash
find /opt/odoo/scripts -name "*.sh" -exec chmod +x {} \;
```

---

## 🚀 Despliegue y Configuración (`deploy/`)

Scripts para el ciclo de vida del stack: instalación, configuración y arranque.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `erp.sh` | **Orquestador central.** Menú interactivo para gestionar el proyecto | Administración diaria |
| `deploy.sh` | Verifica conectividad con la BD externa (`192.168.40.10:5432`) y luego levanta el stack Docker | Primer despliegue o arranque manual |
| `configure.sh` | Configurador del archivo `.env` en la raíz del proyecto | Instalación inicial o cambio de credenciales |
| `install_cron.sh` | Crea `/etc/backup_odoo.env` (permisos 600), instala cron de backup cada 4h y aplica logrotate | Una sola vez, en la instalación inicial |
| `generate_pfsense_config.sh` | Genera `config.xml` con interfaces, DHCP, NAT y reglas de firewall para pfSense | Instalación inicial de pfSense |

```bash
# Menú interactivo
bash scripts/deploy/erp.sh

# Desplegar (verifica BD antes de levantar contenedores)
bash scripts/deploy/deploy.sh

# Configurar .env
bash scripts/deploy/configure.sh

# Instalar cron de backup
sudo bash scripts/deploy/install_cron.sh

# Generar config.xml de pfSense
bash scripts/deploy/generate_pfsense_config.sh
```

> ⚠️ El `.env` debe estar en la **raíz del proyecto**, no dentro de `docker/`.

---

## 🏢 Gestión de Odoo (`odoo/`)

Scripts para la configuración interna del ERP vía API XML-RPC.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `odoo_setup_wizard.sh` | Asistente post-instalación: renombra la empresa e instala módulos | Tras el primer arranque de Odoo |
| `odoo_crear_usuarios.sh` | Crea usuarios Odoo con sus grupos de rol vía XML-RPC | Tras la configuración inicial |

```bash
bash scripts/odoo/odoo_setup_wizard.sh
bash scripts/odoo/odoo_crear_usuarios.sh
```

> [!WARNING]
> `odoo_crear_usuarios.sh` muestra las contraseñas generadas **una sola vez**. Guárdalas inmediatamente.

---

## 🔐 Scripts LDAP (`ldap/`) — DESACTIVADOS

> ⚠️ **Estos scripts están desactivados.** LDAP fue descartado del despliegue principal. El servicio `openldap` ya no existe en `docker-compose.yml`.
>
> Ver: [`scripts/ldap/README.md`](ldap/README.md) y [`extras/ldap/README.md`](../extras/ldap/README.md)

| Script | Descripción | Estado |
|:-------|:------------|:-------|
| `configurar_cliente_ldap.sh` | Configura cliente LDAP en Debian (SSSD + PAM + NSS) | ⚠️ Desactivado |
| `ldap_crear_usuarios.sh` | Crea usuarios en OpenLDAP | ⚠️ Desactivado |
| `ldap_politica_acceso.sh` | Aplica ACLs de seguridad en LDAP | ⚠️ Desactivado |

---

## 🛠️ Mantenimiento y Operaciones (`mantenimiento/`)

Scripts para el mantenimiento automatizado del sistema.

| Script | Descripción | Cron |
|:-------|:------------|:-----|
| `backup_postgres.sh` | **NUEVO** — `pg_dump` remoto a `192.168.40.10`. Retención 7 días. Log en `/var/log/backup_odoo.log` | Cada 4h (vía `install_cron.sh`) |
| `backup.sh` | Backup legacy — referencia histórica | Manual |
| `restore.sh` | Restaura en la BD externa (`192.168.40.10`) usando credenciales de `/etc/backup_odoo.env` | Manual |
| `monitor.sh` | Comprueba `odoo-web` y `nginx-proxy`. Si alguno falla, lo reinicia | Cada 15 min |
| `update.sh` | Descarga nuevas imágenes Docker y reinicia contenedores | Domingos 03:00 |

```bash
# Backup manual (BD externa)
bash scripts/mantenimiento/backup_postgres.sh

# Restaurar desde un backup específico
bash scripts/mantenimiento/restore.sh /opt/odoo/backups/odoo_20260515_0200.sql.gz

# Chequeo de salud manual
bash scripts/mantenimiento/monitor.sh

# Actualización manual de imágenes Docker
bash scripts/mantenimiento/update.sh

# Ver backups disponibles
ls -lh /opt/odoo/backups/postgres/

# Ver log de backups
tail -f /var/log/backup_odoo.log
```

---

## 🔧 Utilidades (`repomix_lite.py`)

Script Python que genera un volcado completo del repositorio en un único archivo de texto (`repomix-output.md`), útil para pasar el código como contexto a modelos de lenguaje.

```bash
python3 scripts/repomix_lite.py
```

---

## Referencia Rápida — Docker

```bash
# Estado de los contenedores (solo odoo-web y nginx-proxy)
docker compose -f docker/docker-compose.yml ps

# Logs en tiempo real
docker compose -f docker/docker-compose.yml logs -f

# Logs de un servicio
docker compose -f docker/docker-compose.yml logs -f odoo-web

# Reiniciar un servicio
docker compose -f docker/docker-compose.yml restart nginx-proxy

# Parar todo
docker compose -f docker/docker-compose.yml down

# Arrancar todo
docker compose -f docker/docker-compose.yml up -d

# Acceder a PostgreSQL externo
psql -h 192.168.40.10 -U odoo -d odooerp

# Limpiar imágenes sin usar
docker system prune -f
```

---

*Guía de instalación completa: [`docs/INSTALACION_COMPLETA.md`](../docs/INSTALACION_COMPLETA.md)*
