# Scripts de Administración y Despliegue

**TFG ASIR 2025/2026 — TechSolutions S.L.**

> [!IMPORTANT]
> Todos los scripts están diseñados para ejecutarse **únicamente en el servidor Debian** (`odoo-server`, `192.168.30.10`).
> **No ejecutar en PCs cliente, en pfSense ni en Windows/macOS localmente.**

> [!NOTE]
> PostgreSQL reside en la **VM externa `db-server`** (`192.168.40.10`, VLAN 40). Los scripts de backup y restore se conectan a esa IP. No usar `localhost` ni ningún contenedor `db`.

---

## Dar Permisos de Ejecución (Primera Vez)

```bash
find /opt/erp-odoo/scripts -name "*.sh" -exec chmod +x {} \;
```

---

## 🚀 Despliegue y Configuración (`deploy/`)

Scripts para el ciclo de vida del stack: instalación, configuración y arranque.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------:|
| `erp.sh` | **Orquestador central.** Menú interactivo para gestionar el proyecto | Administración diaria |
| `deploy.sh` | Verifica conectividad con la BD externa (`192.168.40.10:5432`), levanta el stack Docker e inicializa la BD si es necesario | Primer despliegue o arranque manual |
| `configure.sh` | Configurador interactivo del archivo `.env` en la raíz del proyecto | Cambio manual de credenciales |
| `install_cron.sh` | Crea `/etc/backup_odoo.env` (permisos 600) e instala cron de backup/monitor/actualización | Automático en `vagrant up` · re-ejecutar si se cambia la contraseña |
| `generate_pfsense_config.sh` | Genera `config.xml` con interfaces, DHCP, NAT y reglas de firewall para pfSense | Instalación inicial de pfSense |

```bash
# Menú interactivo (administración diaria)
sudo bash scripts/deploy/erp.sh

# Desplegar manualmente (verifica BD antes de levantar contenedores)
sudo bash scripts/deploy/deploy.sh

# Cambiar contraseñas del .env manualmente
bash scripts/deploy/configure.sh

# Re-instalar cron (tras cambio de contraseña POSTGRES)
sudo bash scripts/deploy/install_cron.sh

# Regenerar config.xml de pfSense
bash scripts/deploy/generate_pfsense_config.sh
```

> [!NOTE]
> `deploy.sh` e `install_cron.sh` se ejecutan automáticamente durante el `vagrant up` a través de `provision_debian.sh`. Solo es necesario lanzarlos manualmente en re-despliegues o cambios de configuración.

---

## 🏢 Gestión de Odoo (`odoo/`)

Scripts para la configuración interna del ERP vía API XML-RPC.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------:|
| `odoo_crear_usuarios.sh` | Crea usuarios Odoo con sus grupos de rol vía XML-RPC. Es idempotente: omite usuarios ya existentes | Automático al final de `deploy.sh` |

```bash
# Ejecutar manualmente si es necesario re-crear usuarios
bash scripts/odoo/odoo_crear_usuarios.sh
```

> [!WARNING]
> `odoo_crear_usuarios.sh` muestra las contraseñas generadas **una sola vez**. Guárdalas inmediatamente o consúltalas en el journal: `sudo journalctl -u odoo-init`.

---

## 🛠️ Mantenimiento y Operaciones (`mantenimiento/`)

Scripts para el mantenimiento automatizado del sistema. Se instalan como tareas cron mediante `install_cron.sh`.

| Script | Descripción | Frecuencia |
|:-------|:------------|:----------:|
| `backup_postgres.sh` | `pg_dump` remoto a `192.168.40.10`. Retención 7 días. Log en `/var/log/backup_odoo.log` | Cada 4h (cron) |
| `restore.sh` | Restaura en la BD externa (`192.168.40.10`) usando credenciales de `/etc/backup_odoo.env` | Manual |
| `monitor.sh` | Comprueba `odoo-web` y `nginx-proxy`. Si alguno falla, lo reinicia automáticamente | Cada 15 min (cron) |
| `update.sh` | Descarga nuevas imágenes Docker y recrea contenedores. Conserva los volúmenes | Domingos 03:00 (cron) |

```bash
# Backup manual (BD externa)
bash scripts/mantenimiento/backup_postgres.sh

# Restaurar desde un backup específico
bash scripts/mantenimiento/restore.sh /backups/postgres/odoo_20260601_0400.sql.gz

# Ver backups disponibles
ls -lh /backups/postgres/

# Chequeo de salud manual
bash scripts/mantenimiento/monitor.sh

# Actualización manual de imágenes Docker
bash scripts/mantenimiento/update.sh

# Ver log de backups
tail -f /var/log/backup_odoo.log
```

---

## Referencia Rápida — Docker

```bash
# Estado de los contenedores
docker compose -f docker/docker-compose.yml ps

# Logs en tiempo real
docker compose -f docker/docker-compose.yml logs -f

# Logs de un servicio concreto
docker compose -f docker/docker-compose.yml logs -f odoo-web

# Reiniciar un servicio
docker compose -f docker/docker-compose.yml restart nginx-proxy

# Parar todo el stack
docker compose -f docker/docker-compose.yml down

# Arrancar todo el stack
docker compose -f docker/docker-compose.yml up -d

# Acceder a PostgreSQL externo
psql -h 192.168.40.10 -U odoo -d odoo_erp

# Limpiar imágenes sin usar
docker system prune -f
```

---

*Guía de instalación completa: [`docs/INSTALACION_COMPLETA.md`](../docs/INSTALACION_COMPLETA.md)*
