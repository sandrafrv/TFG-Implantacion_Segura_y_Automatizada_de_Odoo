# Changelog

Todos los cambios notables del proyecto se documentan en este archivo.

El formato sigue el estándar [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

---

## [Sin publicar]

---

## [v1.4 — 2026-04-30]

### Añadido

- **Fase 8 completada:** Runner self-hosted de GitHub Actions registrado y activo en el servidor Debian.
  - Agente descargado manualmente: `actions-runner-linux-x64-2.334.0.tar.gz` (214 MB) en `/opt/actions-runner`.
  - Hash SHA-256 verificado correctamente: `048024cd2c848eb6f14d5646d56c13a4def2ae7ee3ad12122bee960c56f3d271 OK`.
  - Runner configurado con `./config.sh` conectado al repositorio `sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo`.
  - Labels asignadas: `self-hosted`, `Linux`, `X64`. Grupo: `Default`. Work folder: `_work`.
  - Confirmación de GitHub: `√ Connected to GitHub` / `√ Runner successfully added` / `√ Settings Saved`.
  - Runner activo y escuchando jobs: `Listening for Jobs` (versión `2.334.0`).
  - Pendiente: instalar como servicio `systemd` con `sudo ./svc.sh install && sudo ./svc.sh start`.

---

## [v1.3 — 2026-04-30]

### Añadido

- **Fase 6 completada:** Firewall de capa host UFW configurado y activo en el servidor Debian.
  - Política por defecto: `deny incoming`, `allow outgoing`.
  - Reglas activas: SSH (22/tcp), Cockpit (9090/tcp), HTTP (80/tcp), HTTPS (443/tcp) — IPv4 e IPv6.
  - UFW habilitado y persistente en arranque del sistema (`ufw enable`).

- **Fase 7 completada:** Validación global del sistema desde el cliente Ubuntu (VLAN 10).
  - DNS interno configurado en `/etc/hosts` del cliente: `erp.techsolutions.local → 192.168.30.10`.
  - Acceso HTTPS a `https://erp.techsolutions.local` validado desde el cliente.
  - Logs de Nginx verificados: peticiones reales desde `192.168.10.101` con redirección HTTP→HTTPS (301).
  - Prueba de auto-recuperación exitosa: contenedor `odoo-web` parado manualmente y recuperado automáticamente (Up 41s).
  - Auditoría end-to-end validada: `user@tfg.prueba` registrado en `asir_audit_log` desde la UI web de Odoo.

### Corregido

- **Nombre incorrecto del contenedor PostgreSQL** en `scripts/backup.sh`, `scripts/restore.sh` y `scripts/monitor.sh`:
  los scripts usaban `odoo-db` como nombre del contenedor, pero el nombre real definido en `docker-compose.yml` es `odoo_erp`.
  Corregido en commit `b0022e4`. Backup manual ejecutado tras la corrección: `backup_20260430_151554.dump` (1.38 MB) generado correctamente.

---

## [v1.2 — 2026-04-30]

### Añadido

- **Fase 5 completada:** Trigger de auditoría `trg_audit_new_odoo_user` ejecutado y validado en producción.
  - Script `sql/audit_triggers.sql` aplicado sobre el contenedor `odoo_erp` (PostgreSQL 16).
  - Tabla `asir_audit_log` creada con campo JSONB `row_data` para snapshot completo del registro.
  - Vista `v_audit_resumen` operativa: extrae `login` y `name` del JSONB para consultas rápidas.
  - Validación end-to-end confirmada: creación de usuario `user@tfg.prueba` desde la UI web de Odoo
    generó automáticamente el registro `audit_id=1, CREACION_USUARIO, res_users, id=8` a las 12:13:57 UTC.

### Corregido

- **Nombre incorrecto del contenedor PostgreSQL** en `docs/implementation_plan.md` y `sql/audit_triggers.sql`:
  el nombre real definido en `docker-compose.yml` es `odoo_erp`, no `odoo-db`.
  Corregido en la documentación de ejecución.

---

## [v1.1 — 2026-04-30]

### Añadido

- `install.sh` — Instalador todo-en-uno que clona el repositorio e instala dependencias.
- `.env.example` y `scripts/configure.sh` — Plantilla pública y configurador interactivo de entorno.
- `erp.sh` — Script orquestador centralizado con subcomandos.
- `config/logrotate.d/erp-odoo` — Política de rotación semanal de logs de cron.
- `scripts/install_cron.sh` — Script que instala automáticamente todas las tareas
  programadas (cron) y aplica la política de logrotate.

### Modificado

- `docker/docker-compose.yml` — Añadidos healthchecks nativos para PostgreSQL, Odoo y Nginx.
  Modificado `depends_on` para usar la condición de servicio saludable.
  Corregidas las rutas de volúmenes a `../` para apuntar correctamente a la raíz desde la carpeta `docker/`.

- `docker/odoo.conf` — Añadidos parámetros de conexión a BD y paths de addons.
  Actualizado `longpolling_port` a `gevent_port` por deprecación en Odoo 17.

- `config_nginx/odoo_proxy.conf` — Corregidas las rutas de certificados SSL para coincidir con `install.sh`.

### Corregido

- **Error de permisos en `/var/lib/odoo/.local`**: Resuelto al corregir las rutas relativas de los volúmenes.
- **Bucle de reinicio en Nginx**: Resuelto al sincronizar los nombres de los archivos de certificado.
- **Error de inicialización de Odoo**: Resuelto mediante `docker compose run --rm` para el primer arranque.

---

## [v1.0 — 2026-04-29]

### Añadido

- `docker/docker-compose.yml` — Definición completa del stack Docker con tres servicios:
  `odoo-db` (PostgreSQL 16), `odoo-web` (Odoo 17 CE) y `nginx-proxy` (Nginx Alpine).
  Red privada `odoo_net` tipo bridge. Solo Nginx expone puertos al host.

- `docker/.env` — Archivo de variables de entorno secretas (credenciales PostgreSQL y
  Odoo Master Password). Excluido de Git mediante `.gitignore`.

- `docker/odoo.conf` — Configuración personalizada de Odoo con `proxy_mode = True`
  y ajustes de rendimiento.

- `config_nginx/odoo_proxy.conf` — Configuración del proxy inverso Nginx. Bloque HTTP
  (redireccion 301 a HTTPS) y bloque HTTPS con terminación TLS, cabeceras de seguridad
  y timeouts de 720s para operaciones pesadas.

- `scripts/deploy.sh` — Script de despliegue del stack Docker Compose.

- `scripts/backup.sh` — Script de volcado comprimido de PostgreSQL con `pg_dump -F c`.
  Genera archivos con marca de tiempo en `/opt/erp-odoo/backups/`.

- `scripts/restore.sh` — Script de recuperación ante desastres. Borra y recrea la BD
  antes de restaurar. Reinicia el contenedor de Odoo al finalizar.

- `scripts/update.sh` — Script de actualización de imágenes Docker y limpieza de
  imágenes huérfanas con `docker image prune`.

- `scripts/monitor.sh` — Script de monitorización del estado de los contenedores.

- `sql/audit_triggers.sql` — Tabla `asir_audit_log`, función PL/pgSQL `func_audit_users()`
  y trigger `trg_audit_new_odoo_user` sobre `res_users` de Odoo.

- `.github/workflows/ci.yml` — Pipeline CI con GitHub Actions.

- `docs/implementation_plan.md` — Plan de implementación por fases.

- `docs/task.md` — Lista de tareas por fase del proyecto.

- `docs/reglas_pfsense.md` — Documentación de reglas de firewall pfSense.

- `docs/github_issues.md` — Registro de issues de GitHub del proyecto.

- `docs/propuestas_mejoras_extra.md` — Ideas y mejoras futuras identificadas.

- `CLAUDE.md` — Skill de documentación automática para el asistente de IA.
