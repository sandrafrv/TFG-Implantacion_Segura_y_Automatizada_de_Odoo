# Lista de Tareas: Implantación Odoo con pfSense y Docker

Este documento sirve para llevar un seguimiento de nuestro progreso a medida que ejecutamos el proyecto.
Marca con `[x]` las tareas a medida que se vayan completando en el entorno real o virtual.

## Fase 0: Investigación Técnica y Justificación de Diseño
- [x] **[2026-04-29]** Investigación tecnológica completada: evaluación de Odoo vs Dolibarr vs ERPNext.
- [x] **[2026-04-29]** Decisión de OS documentada: Debian 12 elegido sobre Ubuntu/Mint.
- [x] **[2026-04-29]** Nota técnica sobre macvlan documentada en `implementation_plan.md` y `README.md`.
- [x] **[2026-04-29]** Referencias técnicas (CIS, Odoo deploy, PostgreSQL audit) añadidas al `README.md`.
- [x] **[2026-04-29]** Comparativa ERP añadida al `docs/implementation_plan.md` (Fase 0).

## Fase 1: Arquitectura y Red Base (pfSense)
- [x] Descargar ISO de pfSense y crear Máquina Virtual.
- [x] Configurar 3 adaptadores de red en la VM pfSense (WAN, LAN Clientes, DMZ).
- [x] Ejecutar la instalación básica de pfSense.
- [x] Asignar interfaces (VLANs 10 y 30 si se usa Trunk, o interfaces físicas/virtuales directas).
- [x] Configurar servidor DHCP en pfSense para la VLAN 10 (LAN Clientes).
- [x] Instalar Máquina Virtual de Cliente (Windows 10 o Desktop Linux) en VLAN 10.
- [x] Validar que el Cliente obtiene IP por DHCP y tiene salida a Internet.

## Fase 2: Configuración del Servidor Base (Debian 12 en DMZ)
- [x] Descargar ISO de Debian 12 (versión completa con entorno gráfico) y crear Máquina Virtual en la red de la DMZ.
- [x] Instalar Debian seleccionando **entorno de escritorio GNOME** (mejora el mantenimiento visual)
- [x] Configurar IP estática (`192.168.30.10`) editando `/etc/network/interfaces` u otra vía.
- [x] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [x] Validar conexión a Internet desde el Servidor Debian.
- [x] Instalar e inicializar Cockpit (`apt install cockpit -y` y `systemctl enable --now cockpit.socket`).
- [ ] Acceder al panel de Cockpit desde el Cliente web en `https://192.168.30.10:9090` y validar conectividad.
- [ ] Instalar `cockpit-pcp` para habilitar el historial de métricas y gráficas de rendimiento persistentes.
- [ ] Configurar el dashboard de Cockpit para monitorizar el uso de recursos de los contenedores Docker/Odoo.
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
- [x] **[2026-04-29]** Construir script `deploy.sh` — Despliega el stack con verificación de salud activa (curl al endpoint /web/health).
- [x] **[2026-04-29]** Construir script `update.sh` — Actualización de imágenes y limpieza de huérfanas.
- [x] **[2026-04-29]** Construir script `backup.sh` — Volcado comprimido con `pg_dump -F c` y marca de tiempo.
- [x] **[2026-04-29]** Construir script `restore.sh` — Restauración limpia (dropdb + createdb + pg_restore).
- [x] **[2026-04-29]** Construir script `monitor.sh` — Chequeo de salud con auto-reinicio y log en `/var/log/erp_monitor.log`.
- [x] **[2026-04-29]** Construir script `install_cron.sh` — Instala todas las tareas cron automáticamente (monitor/5min, backup/2AM, update/domingo3AM).
- [ ] Dar permisos de ejecución a todos los scripts (`chmod +x scripts/*.sh`) en el servidor Debian.
- [ ] Ejecutar `sudo ./scripts/install_cron.sh` en el servidor para activar las tareas automáticas.
- [ ] Testear un ciclo completo: desplegar, hacer backup, borrar base de datos y restaurar.

## Fase 5: Auditoría Avanzada de DB (PostgreSQL)
- [x] **[2026-04-29]** Script SQL `audit_triggers.sql` creado con tabla `asir_audit_log`, función `func_audit_users()` y trigger `trg_audit_new_odoo_user`.
- [x] **[2026-04-29]** Auditoría mejorada con campo **JSONB** (`row_data`): ahora almacena el estado completo del registro con `row_to_json(NEW)::JSONB`. Fuente: Wiki PostgreSQL audit trigger.
- [x] **[2026-04-29]** Vista `v_audit_resumen` creada para consultas rápidas en la defensa (extrae `login` y `name` del JSONB).
- [x] **[2026-04-29]** `docker/odoo.conf` actualizado: fórmula de workers `(CPU×2)+1` documentada, `longpolling_port = 8072` y `max_cron_threads = 1` añadidos.
- [ ] Conectarse a la BD PostgreSQL (`docker exec -it odoo-db psql -U odoo -d odoo_erp`) y ejecutar el script.
- [ ] Validar auditoría: crear un usuario en Odoo y verificar que la tabla de logs lo registra con JSONB (`SELECT * FROM v_audit_resumen;`).

## Fase 6: Seguridad de Capa 2 Local (UFW)
- [ ] Instalar `ufw` (`apt install ufw`).
- [ ] Configurar UFW para permitir SSH (22), Cockpit (9090), HTTP (80) y HTTPS (443).
- [ ] Habilitar y comprobar el estado de UFW.

## Fase 6b: Hardening del Proxy Inverso (Nginx)
- [x] **[2026-04-29]** Cabeceras de seguridad HTTP añadidas a `config_nginx/odoo_proxy.conf`: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy. Fuente: investigacion.md + oec.sh.
- [x] **[2026-04-29]** Bloque `location /longpolling/` añadido para WebSocket de LiveChat en puerto 8072.
- [x] **[2026-04-29]** `scripts/backup.sh` mejorado con política de retención de 7 días (`find -mtime +7 -delete`).

## Fase 7: Integración Exterior y Pruebas Globales
- [ ] Configurar reglas de Firewall en pfSense: Permitir tráfico desde WAN/LAN hacia DMZ a los puertos 80/443 de la `192.168.30.10`.
- [ ] Configurar _Port Forwarding_ en pfSense para atrapar tráfico WAN y derivarlo a Nginx.
- [ ] Desde el PC Cliente (VLAN 10), añadir entrada DNS o en archivo `hosts` para asociar `erp.techsolutions.local` a pfSense o a la DMZ, según enrutamiento.
- [ ] Entrar al ERP vía `https://erp.techsolutions.local` desde el Cliente.
- [ ] Revisar si los *Triggers* funcionan también desde la capa final web.
- [ ] (Opcional) Exportar logs de acceso de Nginx para adjuntar en la memoria.

## Fase 8: Pipeline CI/CD Completo (GitHub Actions)
- [x] **[2026-04-29]** Crear workflow `deploy.yml` — Pipeline CD con self-hosted runner que descarga imágenes Docker y ejecuta `deploy.sh` automáticamente tras cada CI exitoso.
- [x] **[2026-04-29]** Crear script `setup_runner.sh` — Registra e instala el servidor Debian como runner de GitHub con systemd.
- [ ] En el servidor Debian: editar `scripts/setup_runner.sh` con la URL del repo y el token de GitHub.
- [ ] Obtener token de registro en: GitHub → Repositorio → Settings → Actions → Runners → "New self-hosted runner".
- [ ] Ejecutar `chmod +x scripts/setup_runner.sh && ./scripts/setup_runner.sh` en el servidor Debian.
- [ ] Verificar que el runner aparece como "Idle" en GitHub → Settings → Actions → Runners.
- [ ] Hacer un `git push` a main y comprobar que el workflow `CD Deploy` se activa automáticamente en la pestaña Actions.
- [ ] Validar que los contenedores se levantan correctamente en el servidor tras el despliegue automático.
