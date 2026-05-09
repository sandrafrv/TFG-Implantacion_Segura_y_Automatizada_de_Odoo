# Scripts de Administración y Despliegue

Este directorio contiene todos los scripts Bash necesarios para gestionar el ciclo de vida del entorno ERP. Para facilitar su mantenimiento y uso, han sido categorizados en subdirectorios temáticos.

## Advertencia de Ejecución

> **Importante:** Estos scripts están diseñados para ejecutarse **únicamente en el servidor Debian** (DMZ). No deben ejecutarse desde máquinas cliente (Windows/macOS) ni desde el firewall pfSense.

Antes de ejecutar cualquier script, asegúrate de tener permisos:
```bash
chmod +x /opt/erp-odoo/scripts/**/*.sh
```

---

## 🚀 1. Despliegue y Configuración (`deploy/`)

| Script | Descripción | Cuándo usarlo |
|--------|-------------|---------------|
| `deploy.sh` | Levanta todo el stack Docker (`docker-compose up -d`) y realiza pruebas de salud (`healthchecks`) para asegurar que todo arrancó bien. | Primer despliegue o para levantar el servicio manualmente. |
| `configure.sh` | Script interactivo para configurar de forma segura el archivo `.env` sin tener que editarlo a mano, evitando errores de sintaxis. | Durante la instalación inicial o cambio de credenciales. |

| `install_cron.sh` | Programa todas las tareas automatizadas del sistema (backups, monitorización, actualizaciones) y la rotación de logs. | Una sola vez, durante la instalación del sistema. |
| `erp.sh` | **Orquestador Central.** Muestra un menú interactivo en terminal para gestionar todo el proyecto sin memorizar comandos. | Uso general del administrador del sistema. |

---

## 🏢 2. Gestión de Odoo (`odoo/`)

| Script | Descripción | Cuándo usarlo |
|--------|-------------|---------------|
| `odoo_setup_wizard.sh` | Asistente post-instalación por línea de comandos. Instala módulos, renombra la compañía por defecto y configura parámetros base. | Justo después de la inicialización de la base de datos por Odoo. |
| `odoo_crear_usuarios.sh` | Interactúa con la API XML-RPC de Odoo para crear usuarios de forma programática y masiva. | Mantenimiento de usuarios cuando no se tiene acceso a la interfaz web. |

---

## 🔐 3. Integración LDAP (`ldap/`)

| Script | Descripción | Cuándo usarlo |
|--------|-------------|---------------|
| `configurar_cliente_ldap.sh` | Instala y configura las herramientas de cliente LDAP en el host (como `ldap-utils`) para poder testear la conexión al directorio. | Troubleshooting o configuración inicial de conectividad. |
| `ldap_crear_usuarios.sh` | Se conecta al contenedor `odoo-ldap` y crea nuevos usuarios en el directorio activo usando comandos `ldapadd`. | Para dar de alta nuevos empleados en la empresa de forma centralizada. |
| `ldap_politica_acceso.sh` | Modifica reglas de contraseñas, grupos o unidades organizativas (OUs) en OpenLDAP. | Cuando se requieren cambios en las políticas de seguridad de la organización. |

---

## 🛠️ 4. Mantenimiento y Operaciones (`mantenimiento/`)

| Script | Descripción | Cuándo usarlo |
|--------|-------------|---------------|
| `backup.sh` | Genera un volcado completo de la base de datos PostgreSQL en formato comprimido y elimina backups antiguos. | Tarea diaria (vía cron) o antes de cambios críticos. |
| `restore.sh` | Elimina la base de datos actual, la recrea limpia y restaura un volcado desde un archivo `.dump`. | Recuperación ante desastres (Disaster Recovery). |
| `update.sh` | Descarga las últimas imágenes de Docker, reinicia los contenedores actualizados y limpia las imágenes huérfanas. | Mantenimiento periódico (vía cron semanal). |
| `monitor.sh` | Chequea que los contenedores Nginx, Odoo y PostgreSQL estén `Up`. Si uno falla, intenta reiniciarlo y lo registra en un log. | Tarea periódica muy frecuente (vía cron cada 5 mins). |
