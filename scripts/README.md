# Scripts de Administración y Despliegue

**TFG ASIR 2025/2026 — TechSolutions S.L.**

> [!IMPORTANT]
> Todos los scripts están diseñados para ejecutarse **únicamente en el servidor Debian** (`192.168.30.10`).
> **No ejecutar en PCs cliente, en pfSense ni en Windows/macOS localmente.**

---

## Dar Permisos de Ejecución (Primera Vez)

```bash
# Dar permisos a todos los scripts del proyecto de una sola vez
find /opt/erp-odoo/scripts -name "*.sh" -exec chmod +x {} \;

# O individualmente:
chmod +x /opt/erp-odoo/scripts/deploy/*.sh
chmod +x /opt/erp-odoo/scripts/odoo/*.sh
chmod +x /opt/erp-odoo/scripts/ldap/*.sh
chmod +x /opt/erp-odoo/scripts/mantenimiento/*.sh
```

---

## 🚀 Despliegue y Configuración (`deploy/`)

Scripts para el ciclo de vida del stack: instalación, configuración y arranque.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `erp.sh` | **Orquestador central.** Menú interactivo para gestionar todo el proyecto sin memorizar comandos | Administración diaria |
| `deploy.sh` | Levanta el stack Docker (`docker compose up -d`) y espera confirmación de healthcheck de Odoo | Primer despliegue o arranque manual |
| `configure.sh` | Configurador interactivo del archivo `docker/.env` (pide contraseñas con eco desactivado) | Instalación inicial o cambio de credenciales |
| `install_cron.sh` | Instala las 3 tareas cron del sistema (backup, monitor, update) y aplica logrotate | Una sola vez, en la instalación inicial |
| `generate_pfsense_config.sh` | Genera `config/pfsense_config.xml` con todas las interfaces, DHCP, DNS, NAT y reglas de firewall del proyecto. El CI lo valida y lo sube como artefacto descargable | Instalación inicial de pfSense o reimplantación |

```bash
# Menú interactivo (opción recomendada para el día a día)
sudo /opt/erp-odoo/scripts/deploy/erp.sh

# Levantar el stack manualmente
bash /opt/erp-odoo/scripts/deploy/deploy.sh

# Configurar .env de forma segura
bash /opt/erp-odoo/scripts/deploy/configure.sh

# Instalar cron automático
sudo bash /opt/erp-odoo/scripts/deploy/install_cron.sh

# Generar config.xml de pfSense (también disponible como artefacto CI)
bash /opt/erp-odoo/scripts/deploy/generate_pfsense_config.sh
```

---

## 🏢 Gestión de Odoo (`odoo/`)

Scripts para la configuración interna del ERP vía API XML-RPC.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `odoo_setup_wizard.sh` | Asistente post-instalación: renombra la empresa, instala módulos y configura la conexión LDAP | Justo después del primer arranque de Odoo |
| `odoo_crear_usuarios.sh` | Crea usuarios Odoo con sus grupos de rol (becario, ventas, RRHH, etc.) vía XML-RPC | Tras la configuración de LDAP |

```bash
# Configuración inicial de Odoo (empresa + módulos + LDAP)
bash /opt/erp-odoo/scripts/odoo/odoo_setup_wizard.sh

# Crear todos los usuarios con sus roles
bash /opt/erp-odoo/scripts/odoo/odoo_crear_usuarios.sh
```

> [!WARNING]
> `odoo_crear_usuarios.sh` muestra las contraseñas generadas **una sola vez** al terminar.
> Cópialas inmediatamente en un gestor de contraseñas.

---

## 🔐 Integración LDAP (`ldap/`)

Scripts para gestionar el directorio centralizado de usuarios.

| Script | Descripción | Cuándo usarlo |
|:-------|:------------|:--------------|
| `configurar_cliente_ldap.sh` | Instala y configura SSSD + PAM + NSS en un PC cliente VLAN 10 para login con credencial LDAP | En cada PC de VLAN 10 que necesite login LDAP |
| `ldap_crear_usuarios.sh` | Crea usuarios en el directorio OpenLDAP de forma interactiva (uid, nombre, email, contraseña, grupo) | Dar de alta nuevos empleados |
| `ldap_politica_acceso.sh` | Aplica las ACLs de seguridad LDAP: admin=escritura, tecnico=solo contraseñas, readonly=lectura | Una vez tras el primer arranque de OpenLDAP |

```bash
# Aplicar ACLs (una sola vez tras instalar OpenLDAP)
bash /opt/erp-odoo/scripts/ldap/ldap_politica_acceso.sh

# Añadir un nuevo empleado al directorio
bash /opt/erp-odoo/scripts/ldap/ldap_crear_usuarios.sh

# Configurar un PC cliente VLAN 10 para login con LDAP
# (ejecutar EN EL PC CLIENTE, no en el servidor)
sudo bash /opt/erp-odoo/scripts/ldap/configurar_cliente_ldap.sh
```

---

## 🛠️ Mantenimiento y Operaciones (`mantenimiento/`)

Scripts para el mantenimiento automatizado del sistema ERP.

| Script | Descripción | Cuándo usarlo | Cron |
|:-------|:------------|:--------------|:-----|
| `backup.sh` | Volcado completo de PostgreSQL en formato comprimido (`pg_dump -F c`). Retención de 7 días. | Manual o por cron | Diario 02:00 |
| `restore.sh` | Borra la BD actual, la recrea limpia y restaura desde un archivo `.dump` | Recuperación ante desastres | Manual |
| `monitor.sh` | Comprueba que los 4 contenedores están `Up`. Si alguno falla, lo reinicia y lo registra en log | Por cron | Cada 15 min |
| `update.sh` | Descarga las últimas imágenes Docker, reinicia los contenedores y elimina imágenes huérfanas | Por cron | Domingos 03:00 |

```bash
# Backup manual
bash /opt/erp-odoo/scripts/mantenimiento/backup.sh

# Restaurar desde un backup específico
bash /opt/erp-odoo/scripts/mantenimiento/restore.sh /opt/erp-odoo/backups/erp_20260513_020001.dump

# Chequeo de salud manual
bash /opt/erp-odoo/scripts/mantenimiento/monitor.sh

# Actualización manual de imágenes Docker
bash /opt/erp-odoo/scripts/mantenimiento/update.sh

# Ver los backups disponibles
ls -lh /opt/erp-odoo/backups/
```

---

## Referencia Rápida — Comandos Docker

```bash
# Estado de los contenedores
docker compose -f /opt/erp-odoo/docker/docker-compose.yml ps

# Logs en tiempo real (todos)
docker compose -f /opt/erp-odoo/docker/docker-compose.yml logs -f

# Logs de un servicio específico
docker compose -f /opt/erp-odoo/docker/docker-compose.yml logs -f odoo-web

# Reiniciar un servicio
docker compose -f /opt/erp-odoo/docker/docker-compose.yml restart nginx-proxy

# Parar todo el stack
docker compose -f /opt/erp-odoo/docker/docker-compose.yml down

# Arrancar todo el stack
docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d

# Entrar a la consola de PostgreSQL
docker exec -it odoo_erp psql -U odoo -d odoo_erp

# Limpiar imágenes sin usar
docker system prune -f
```

---

*Guía de instalación completa: [`docs/INSTALACION_COMPLETA.md`](../docs/INSTALACION_COMPLETA.md)*
