# Changelog

Todos los cambios notables del proyecto se documentan en este archivo.

El formato sigue el estándar [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

---

## [Sin publicar]

---

## [v1.4 — 2026-05-06]

### Corregido

- **Fallo del pipeline CD Deploy — base de datos Odoo no inicializada:**
  El job `Desplegar Stack en Servidor Debian` completaba con resultado `Failed` de forma
  repetida (5+ ejecuciones consecutivas entre las 16:21 y las 17:57 UTC).

  **Causa raíz:** El archivo `.env` no existía en el servidor (`/opt/erp-odoo/.env`).
  Al arrancar el stack Docker sin variables de entorno, Odoo no podía conectarse a
  PostgreSQL y la base de datos `odoo_erp` quedaba sin inicializar. La tabla
  `ir_module_module` no existía, lo que provocaba el error en cascada:
  ```
  ERROR: relation "ir_module_module" does not exist
  KeyError: 'ir.http'
  GET /web/health HTTP/1.1" 500
  ```
  El healthcheck del contenedor fallaba y el script `deploy.sh` agotaba los 30 intentos
  (300 segundos) sin que Odoo respondiera.

  **Solución aplicada:**
  1. Parada completa del stack: `docker compose -f docker/docker-compose.yml down`.
  2. Borrado de los volúmenes de datos corruptos:
     `sudo rm -rf postgres-data/pgdata` y `sudo rm -rf odoo-data/filestore`.
  3. Creación del archivo `.env` a partir de la plantilla:
     `cp .env.example .env` y configuración de credenciales.
  4. Reinicio del stack: `docker compose -f docker/docker-compose.yml up -d`.
  5. Odoo inicializó la base de datos desde cero correctamente.
     Primer healthcheck exitoso: `GET /web/health HTTP/1.1" 200` a las 18:08:12 UTC.

  **Causa secundaria detectada:** El directorio `/opt/erp-odoo` contenía una carpeta
  `postgres-data/pgdata/` con permisos de `root` inaccesibles para el usuario `server`,
  lo que impedía a git listar el directorio (advertencia `Permiso denegado`).

  **Prevención:** El archivo `.env` debe crearse manualmente en el servidor durante el
  proceso de instalación inicial (`install.sh`). Ver `.env.example` para referencia de
  las variables requeridas (`POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`,
  `ODOO_MASTER_PASSWORD`).

---

## [v1.3 — 2026-04-30]

### Añadido

- **Fase 8 completada:** Pipeline CI/CD con GitHub Actions 100% operativo en el servidor Debian de la DMZ.
  - Runner `debian` instalado como servicio systemd en `/opt/actions-runner`.
    - Versión del agente: `2.334.0`. SHA256 verificado.
    - Servicio: `actions.runner.sandrafrv-TFG-Implantacion_Segura_y_Automatizada_de_Odoo.debian.service`.
    - Arranca automáticamente con el sistema (`enabled` en systemd).
  - Pipeline `CD Deploy` ejecutado y validado end-to-end:
    - Stack Docker desplegado automáticamente tras push a `main`.
    - Los 3 contenedores (`odoo_erp`, `odoo-web`, `nginx-proxy`) quedan en estado `healthy`.
    - Odoo operativo en `https://erp.techsolutions.local` tras el despliegue.
  - Step `git fetch + git reset --hard origin/main` añadido al workflow para garantizar
    que el servidor siempre ejecuta la versión más reciente de los scripts del repositorio.

### Corregido

- **`scripts/deploy.sh` — comprobación de puertos 80/443:**
  El check original usaba `ss -tlnp | grep` para detectar conflictos de puerto, pero sin
  permisos de root el comando no muestra el nombre del proceso. El script fallaba aunque los
  puertos los ocupara el propio contenedor `nginx-proxy` del stack.
  **Solución:** se comprueba si `nginx-proxy` está corriendo con `docker ps`. Si está activo,
  los puertos son del stack propio y el re-deploy es válido. Solo falla si el contenedor
  no existe y el puerto está ocupado (conflicto real externo).

- **`scripts/deploy.sh` — permisos de lectura en `.env`:**
  El archivo `.env` tenía permisos `600` (solo root). El runner corre como usuario `server`
  y no podía leerlo, lo que causaba un error en cascada interpretado como "error de sintaxis"
  en `docker-compose.yml`.
  **Solución:** `sudo chown root:server /opt/erp-odoo/docker/.env && sudo chmod 640 /opt/erp-odoo/docker/.env`.

- **`.github/workflows/deploy.yml` — error `dubious ownership` en git:**
  El directorio `/opt/erp-odoo` fue creado por `root` (via `install.sh`), pero el runner
  corre como `server`. Git bloquea el acceso por la política de seguridad `safe.directory`.
  **Solución:** step `git config --global --add safe.directory /opt/erp-odoo` añadido
  como primer paso del workflow. Además: `sudo chown -R server:server /opt/erp-odoo`
  aplicado en el servidor para alinear propietario con usuario del runner.

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
