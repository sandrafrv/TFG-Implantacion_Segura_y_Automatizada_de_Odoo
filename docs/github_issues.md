# Plantillas para GitHub Issues (TFG ASIR)

Este documento contiene las tareas del proyecto divididas por fases (Épicas o Issues principales), formateadas exactamente con la sintaxis de GitHub. 
Puedes copiar todo el contenido que está debajo de cada título y pegarlo directamente en el cuadro de texto al crear un nuevo **Issue** en tu repositorio de GitHub. 
¡Las casillas de verificación interactivas se generarán automáticamente!

---

## Título del Issue 1: Fase 1 - Arquitectura y Red Base (pfSense)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Desplegar la infraestructura de base que soportará las distintas redes virtuales y la configuración vital del firewall perimetral.

### ✅ Tareas a realizar
- [ ] Descargar ISO de pfSense y crear Máquina Virtual.
- [ ] Configurar 3 adaptadores de red en la VM pfSense (WAN, LAN Clientes, DMZ).
- [ ] Ejecutar la instalación básica de pfSense.
- [ ] Asignar interfaces (VLANs 10 y 30 si se usa Trunk, o interfaces físicas/virtuales directas).
- [ ] Configurar servidor DHCP en pfSense para la VLAN 10 (LAN Clientes).
- [ ] Instalar Máquina Virtual de Cliente (Windows 10 o Desktop Linux) en VLAN 10.
- [ ] Validar que el Cliente obtiene IP por DHCP y tiene salida a Internet.


---

## Título del Issue 2: Fase 2 - Configuración del Servidor Base (Debian 12 en DMZ)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Preparar el Servidor Linux único sobre el cual correrá el entorno Docker, optimizándolo para bajo consumo (sin interfaz gráfica loca) pero con gestión web centralizada.

### ✅ Tareas a realizar
- [ ] Descargar ISO de Debian 12 Server ("netinst") y crear Máquina Virtual en la red de la DMZ.
- [ ] Instalar Debian (seleccionar solo sistema base, sin entorno de escritorio).
- [ ] Configurar IP estática (`192.168.30.10`) editando `/etc/network/interfaces` u otra vía.
- [ ] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [ ] Validar conexión a Internet desde el Servidor Debian.
- [ ] Instalar e inicializar Cockpit (`sudo apt install cockpit -y` y `sudo systemctl enable --now cockpit.socket`).
- [ ] Acceder al panel de Cockpit desde el Cliente web en `https://192.168.30.10:9090` y validar conectividad.
- [ ] Instalar Docker Engine y Docker Compose CLI.
- [ ] Añadir usuario administrador al grupo `docker`.
- [ ] Habilitar Docker en el arranque del sistema (`sudo systemctl enable --now docker`).
- [ ] Implementar CI/CD subiendo el flujo de trabajo (`ci.yml`) a la carpeta `.github/workflows` de este respositorio.


---

## Título del Issue 3: Fase 3 - Despliegue de Docker (Odoo, PostgreSQL y Nginx)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Levantar toda la pila del ERP utilizando herramientas de orquestación (Docker Compose), de forma aislada y exponiendo el tráfico a través del proxy inverso en los puertos seguros del Host (80, 443).

### ✅ Tareas a realizar
- [ ] Crear estructura de directorios en `/opt/erp-odoo` (data, scripts, certs, config_nginx).
- [ ] Generar certificados SSL autofirmados con OpenSSL y guardarlos en `/opt/erp-odoo/certs/`.
- [ ] Crear el archivo `/opt/erp-odoo/config_nginx/odoo_proxy.conf` para rutear HTTP a HTTPS localmente.
- [ ] Redactar el fichero `docker-compose.yml` final, que levanta a `db`, `odoo` y `nginx`. *(Nota: Odoo no exporta puertos externos; Nginx exporta 80 y 443 al host).*
- [ ] Ejecutar despliegue con `docker-compose up -d`.
- [ ] Revisar logs globales (`docker-compose logs -f`) para comprobar salud de los tres contenedores.
- [ ] Validar localmente (desde el host Debian) que funciona la carga web: `curl -I -k https://127.0.0.1`.


---

## Título del Issue 4: Fase 4 - Automatización y Scripts DevOps (Bash)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Codificar y programar los scripts de mantenimiento y administración del ERP que aseguran la disponibilidad de los datos y la automatización inteligente.

### ✅ Tareas a realizar
- [ ] Construir script `deploy.sh` (Despliegue fácil con docker-compose up).
- [ ] Construir script `update.sh` (Actualización de imágenes y recreación).
- [ ] Construir script `backup.sh` (Volcado comprimido eficiente usando `pg_dump -F c`).
- [ ] Construir script `restore.sh` (Restauración limpiando DB previa).
- [ ] Construir script `monitor.sh` (Chequeo de salud recurrente y alertas si falla un contenedor).
- [ ] Dar permisos de ejecución a todos los scripts (`chmod +x *.sh`).
- [ ] Configurar un `CRON` para copias de seguridad de madrugada y monitorización horaria.
- [ ] Testear simulando un ciclo completo: desplegar, hacer backup, borrar base de datos y restaurar con éxito.


---

## Título del Issue 5: Fase 5 - Auditoría Avanzada de DB (PostgreSQL)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Configurar el rastreo y auditoría en la propia base de datos usando SQL para registrar cualquier creación de un nuevo usuario en la app.

### ✅ Tareas a realizar
- [ ] Conectarse a la BD PostgreSQL (`docker exec -it odoo-db psql -U odoo -d odoo_erp`).
- [ ] Crear la tabla de registros personalizados `asir_audit_log`.
- [ ] Crear en PL/pgSQL la función `audit_users_action()`.
- [ ] Vincular el _Trigger_ a la tabla `res_users` de Odoo (que dispare el evento tras un `INSERT`).
- [ ] Validar auditoría: crear un usuario aleatorio en Odoo y verificar mediante consulta SQL que la tabla de logs lo documenta correctamente.


---

## Título del Issue 6: Fase 6 - Seguridad de Capa 2 Local (UFW)

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Blindar el propio Servidor Debian para que rechace cualquier petición que no pertenezca explícitamente a los servicios alojados y al puerto de administración gráfica.

### ✅ Tareas a realizar
- [ ] Instalar cortafuegos en Debian si no estuviera: `sudo apt install ufw`.
- [ ] Configurar UFW para permitir accesos críticos: SSH (22), Cockpit (9090), HTTP (80) y HTTPS (443).
- [ ] Configurar UFW para denegar el resto por defecto.
- [ ] Habilitar y comprobar el estado de UFW protegiendo la red sin bloquearse a sí mismo.


---

## Título del Issue 7: Fase 7 - Integración Exterior y Pruebas Globales

**Descripción (Copiar lo siguiente):**

### 🎯 Objetivo
Realizar las configuraciones de enrutamiento final que interconectan a los usuarios con la DMZ, simulando todos los accesos con DNS de cara al resultado final del proyecto.

### ✅ Tareas a realizar
- [ ] Configurar reglas de Firewall en pfSense: Permitir tráfico direccional desde WAN/LAN hacia DMZ a los puertos 80/443 de la IPv4 `192.168.30.10`.
- [ ] Configurar _Port Forwarding_ en pfSense para atrapar tráfico WAN y derivarlo a Nginx.
- [ ] Desde el PC Cliente (VLAN 10), añadir entrada en el servidor DNS o en el archivo `hosts` local para asociar `erp.techsolutions.local` a pfSense o a la DMZ (según el enrutamiento interno).
- [ ] Entrar al ERP vía el navegador web en `https://erp.techsolutions.local` desde el Cliente final.
- [ ] Revisar si los *Triggers* y auditorías siguen funcionando también desde la capa final web.
- [ ] Opcional: Exportar logs de acceso de Nginx comprobando los "Access Log" y "Error log" para adjuntarlos a la memoria escrita.
