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

## Fase 2: Configuración del Servidor Base (Linux Mint en DMZ)
- [ ] Descargar ISO de GNU/Linux Mint 22 y crear Máquina Virtual en la red de la DMZ.
- [ ] Instalar Linux Mint.
- [ ] Configurar IP estática (`192.168.30.10`).
- [ ] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [ ] Validar conexión a Internet desde el Servidor Mint.
- [ ] Instalar Docker Engine y Docker Compose.
- [ ] Añadir usuario al grupo `docker`.
- [ ] Habilitar Docker en el arranque del sistema.

## Fase 3: Despliegue de Odoo y PostgreSQL (Docker)
- [ ] Crear estructura de directorios en `/opt/erp-odoo` (data, scripts).
- [ ] Redactar el fichero `docker-compose.yml` final, asegurando que Odoo escucha _solo_ en localhost (127.0.0.1:8069).
- [ ] Ejecutar `docker-compose up -d`.
- [ ] Revisar logs de los contenedores para comprobar conexión a BD y arranque correcto de Odoo.
- [ ] Validar localmente (dentro del Mint) que `curl http://127.0.0.1:8069` responde.

## Fase 4: Automatización y Scripts (Bash)
- [ ] Crear script `backup.sh` para volcado de PostgreSQL (`pg_dump`).
- [ ] Crear script `restore.sh` para restauración de base de datos (`pg_restore`).
- [ ] Configurar una tarea `CRON` para ejecutar el backup de madrugada.
- [ ] Testear el script de backup manualmente.
- [ ] Detener Odoo, simular un borrado, testear el script de restauración completo.

## Fase 5: Auditoría Avanzada de DB (PostgreSQL)
- [ ] Conectarse a la BD PostgreSQL (`docker exec -it odoo-db psql...`).
- [ ] Crear la tabla de registros personalizados `asir_audit_log`.
- [ ] Crear en PL/pgSQL la función `audit_users_action()`.
- [ ] Vincular el _Trigger_ a la tabla `res_users` de Odoo (disparo en evento `INSERT`).
- [ ] Validar auditoría: crear un usuario en Odoo y verificar que la tabla de logs lo registra.

## Fase 6: Seguridad de Host y Proxy Inverso (Nginx + UFW)
- [ ] Instalar `ufw`.
- [ ] Configurar UFW para permitir puertos 22 (restringido IPs), 80 y 443. Denegar el resto por defecto.
- [ ] Instalar Nginx y OpenSSL.
- [ ] Generar certificados SSL autofirmados para dominio corporativo de simulación (ej. `erp.techsolutions.local`).
- [ ] Configurar bloque *Server* de Nginx para redirigir tráfico HTTP -> HTTPS y hacer `proxy_pass` hacia `127.0.0.1:8069`.
- [ ] Reiniciar/Verificar Nginx.

## Fase 7: Integración Exterior y Pruebas Globales
- [ ] Configurar reglas de Firewall en pfSense: Permitir tráfico desde WAN/LAN hacia DMZ a los puertos 80/443 de la `192.168.30.10`.
- [ ] Configurar _Port Forwarding_ en pfSense para atrapar tráfico WAN y derivarlo a Nginx.
- [ ] Desde el PC Cliente (VLAN 10), añadir entrada DNS o en archivo `hosts` para asociar `erp.techsolutions.local` a pfSense o a la DMZ, según enrutamiento.
- [ ] Entrar al ERP vía `https://erp.techsolutions.local` desde el Cliente.
- [ ] Revisar si los *Triggers* funcionan también desde la capa final web.
- [ ] (Opcional) Exportar logs de acceso de Nginx para adjuntar en la memoria.
