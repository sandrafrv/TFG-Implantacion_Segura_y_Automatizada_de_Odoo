# Lista de Tareas: Implantación Odoo con pfSense y Docker

Este documento servirá para llevar un seguimiento de nuestro progreso a medida que empezamos la ejecución del proyecto.
Marca con `[x]` las tareas a medida que se vayan completando en el entorno real o virtual.

## Fase 1: Arquitectura y Red Base (pfSense)
- [ ] Descargar ISO de pfSense y crear Máquina Virtual.
- [ ] Configurar 3 adaptadores de red en la VM pfSense (WAN, LAN Clientes, DMZ).
- [ ] Ejecutar la instalación básica de pfSense.
- [ ] Asignar interfaces (VLANs 10 y 30 si se usa Trunk, o interfaces físicas/virtuales directas).
- [ ] Configurar servidor DHCP en pfSense para la VLAN 10 (LAN Clientes).
- [ ] Instalar Máquina Virtual de Cliente (Windows 10 o Desktop Linux) en VLAN 10.
- [ ] Validar que el Cliente obtiene IP por DHCP y tiene salida a Internet.

## Fase 2: Configuración del Servidor Base (Debian 12 en DMZ)
- [ ] Descargar ISO de Debian 12 Server ("netinst") y crear Máquina Virtual en la red de la DMZ.
- [ ] Instalar Debian (seleccionar solo sistema base, sin entorno de escritorio).
- [ ] Configurar IP estática (`192.168.30.10`) editando `/etc/network/interfaces` u otra vía.
- [ ] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [ ] Validar conexión a Internet desde el Servidor Debian.
- [ ] Instalar e inicializar Cockpit (`apt install cockpit -y` y `systemctl enable --now cockpit.socket`).
- [ ] Acceder al panel de Cockpit desde el Cliente web en `https://192.168.30.10:9090` y validar conectividad.
- [ ] Instalar Docker Engine y Docker Compose CLI.
- [ ] Añadir usuario administrador al grupo `docker`.
- [ ] Habilitar Docker en el arranque del sistema (`systemctl enable --now docker`).

## Fase 3: Despliegue de Docker (Odoo, PostgreSQL y Nginx)
- [ ] Crear estructura de directorios en `/opt/erp-odoo` (data, scripts, certs, config_nginx).
- [ ] Generar certificados SSL autofirmados con OpenSSL y guardarlos en `/opt/erp-odoo/certs/`.
- [ ] Crear el archivo `/opt/erp-odoo/config_nginx/odoo_proxy.conf` para rutear HTTP a HTTPS localmente.
- [ ] Redactar el fichero [docker-compose.yml](file:///c:/Users/sandra/Downloads/Ante%20proyecto/TFG-ASIRB/docker/docker-compose.yml) final, que levanta a `db`, `odoo` y `nginx`. Odoo no exporta puertos externos; Nginx exporta 80 y 443 al host.
- [ ] Ejecutar `docker-compose up -d`.
- [ ] Revisar logs global (`docker-compose logs -f`) para comprobar salud de los tres contenedores.
- [ ] Validar desde el host que web load funciona `curl -I -k https://127.0.0.1`.

## Fase 4: Automatización y Scripts DevOps (Bash)
- [ ] Construir script `deploy.sh` (Despliegue con docker-compose up).
- [ ] Construir script `update.sh` (Actualización de imágenes y recreación).
- [ ] Construir script `backup.sh` (Volcado comprimido usando `pg_dump -F c`).
- [ ] Construir script `restore.sh` (Restauración limpiando DB previa).
- [ ] Construir script `monitor.sh` (Chequeo de salud y alertas si falla un contenedor).
- [ ] Dar permisos de ejecución a todos los scripts (`chmod +x *.sh`).
- [ ] Configurar un `CRON` para copias de seguridad de madrugada y monitorización horaria.
- [ ] Testear un ciclo completo: desplegar, hacer backup, borrar base de datos y restaurar.

## Fase 5: Auditoría Avanzada de DB (PostgreSQL)
- [ ] Conectarse a la BD PostgreSQL (`docker exec -it odoo-db psql...`).
- [ ] Crear la tabla de registros personalizados `asir_audit_log`.
- [ ] Crear en PL/pgSQL la función `audit_users_action()`.
- [ ] Vincular el _Trigger_ a la tabla `res_users` de Odoo (disparo en evento `INSERT`).
- [ ] Validar auditoría: crear un usuario en Odoo y verificar que la tabla de logs lo registra.

## Fase 6: Seguridad de Capa 2 Local (UFW)
- [ ] Instalar `ufw` (`apt install ufw`).
- [ ] Configurar UFW para permitir SSH (22), Cockpit (9090), HTTP (80) y HTTPS (443).
- [ ] Habilitar y comprobar el estado de UFW.

## Fase 7: Integración Exterior y Pruebas Globales
- [ ] Configurar reglas de Firewall en pfSense: Permitir tráfico desde WAN/LAN hacia DMZ a los puertos 80/443 de la `192.168.30.10`.
- [ ] Configurar _Port Forwarding_ en pfSense para atrapar tráfico WAN y derivarlo a Nginx.
- [ ] Desde el PC Cliente (VLAN 10), añadir entrada DNS o en archivo `hosts` para asociar `erp.techsolutions.local` a pfSense o a la DMZ, según enrutamiento.
- [ ] Entrar al ERP vía `https://erp.techsolutions.local` desde el Cliente.
- [ ] Revisar si los *Triggers* funcionan también desde la capa final web.
- [ ] (Opcional) Exportar logs de acceso de Nginx para adjuntar en la memoria.
