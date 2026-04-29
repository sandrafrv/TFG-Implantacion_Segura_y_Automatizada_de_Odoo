# Changelog

Todos los cambios notables del proyecto se documentan en este archivo.

El formato sigue el estándar [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

---

## [Sin publicar]

### Añadido

- `scripts/install_cron.sh` — Script que instala automáticamente todas las tareas
  programadas (cron) del proyecto: monitorización cada 5 min, backup diario a las 02:00
  y actualización semanal los domingos a las 03:00.

### Modificado

- `scripts/deploy.sh` — Añadida verificación de salud activa tras el despliegue. El script
  ahora espera hasta 5 minutos consultando el endpoint `/web/health` de Odoo antes de
  declarar el despliegue exitoso. Si Odoo no responde, muestra los últimos 30 líneas de log
  y termina con error.

- `scripts/monitor.sh` — Mejorado con auto-reinicio automático de contenedores caídos
  mediante `docker start`. Añadida función `log_evento()` que escribe en
  `/var/log/erp_monitor.log` con marca de tiempo. Corregido el orden de chequeo de
  contenedores (primero DB, luego Odoo, luego Nginx) para garantizar dependencias correctas.

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

- `.github/workflows/ci.yml` — Pipeline CI con GitHub Actions que valida: YAML con
  `yamllint`, estructura Docker Compose con `docker compose config`, scripts Bash con
  `ShellCheck` y Markdown con `markdownlint`.

- `docs/implementation_plan.md` — Plan de implementación por fases.

- `docs/task.md` — Lista de tareas por fase del proyecto.

- `docs/reglas_pfsense.md` — Documentación de reglas de firewall pfSense.

- `docs/github_issues.md` — Registro de issues de GitHub del proyecto.

- `docs/propuestas_mejoras_extra.md` — Ideas y mejoras futuras identificadas.

- `CLAUDE.md` — Skill de documentación automática para el asistente de IA.
