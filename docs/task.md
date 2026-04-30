# Lista de Tareas: Implantación Odoo con pfSense y Docker

Este documento sirve para llevar un seguimiento de nuestro progreso a medida que ejecutamos el proyecto.
Marca con `[x]` las tareas a medida que se vayan completando en el entorno real o virtual.

> **Última actualización:** 2026-04-29

---

## Fase 0: Investigación Técnica y Justificación de Diseño

- [x] **[2026-04-29]** Investigación tecnológica completada: evaluación de Odoo vs Dolibarr vs ERPNext.
- [x] **[2026-04-29]** Decisión de OS documentada: Debian 12 elegido sobre Ubuntu/Mint (con entorno gráfico GNOME).
- [x] **[2026-04-29]** Nota técnica sobre macvlan documentada en `implementation_plan.md` y `README.md`.
- [x] **[2026-04-29]** Referencias técnicas (CIS, Odoo deploy, PostgreSQL audit) añadidas al `README.md`.
- [x] **[2026-04-29]** Comparativa ERP añadida al `docs/implementation_plan.md` (Fase 0).
- [x] **[2026-04-29]** Arquitectura de red definida: WAN / LAN (192.168.10.0/24) / DMZ (192.168.30.0/24).

---

## Fase 1: Arquitectura y Red Base (pfSense)

- [x] Descargar ISO de pfSense y crear Máquina Virtual.
- [x] Configurar 3 adaptadores de red en la VM pfSense (WAN, LAN Clientes, DMZ/OPT1).
- [x] Ejecutar la instalación básica de pfSense.
- [x] Asignar interfaces (WAN, LAN y OPT1 para la DMZ).
- [x] Configurar servidor DHCP en pfSense para la VLAN 10 (LAN Clientes).
- [x] Instalar Máquina Virtual de Cliente (Windows 10 o Desktop Linux) en LAN.
- [x] Validar que el Cliente obtiene IP por DHCP y tiene salida a Internet.
- [x] **[2026-04-29]** Reglas WAN configuradas: bloqueo redes privadas/bogon, apertura 80/443 público, SSH y Cockpit restringidos a IP admin (`192.168.163.140`).
- [x] **[2026-04-29]** Reglas LAN configuradas: anti-lockout activa, "allow all" desactivada, reglas específicas hacia DMZ (80/443/8069/8072) y bloqueo de acceso inverso desde DMZ.
- [x] **[2026-04-29]** Reglas DMZ (OPT1) configuradas en orden correcto: bloqueos primero (anti-pivoting hacia LAN y pfSense), luego permisos de salida (HTTP/HTTPS/DNS/SMTP/PostgreSQL), deny-all al final.
- [x] **[2026-04-29]** NAT Port Forwarding configurado: HTTP (80) y HTTPS (443) hacia `192.168.30.10`, SSH y Cockpit restringidos a IP admin.
- [x] **[2026-04-29]** Reglas documentadas en `docs/reglas_pfsense.md` con tablas, diagramas de flujo y puntos clave.
- [x] **[2026-04-29]** Limpiar reglas EasyRule duplicadas en OPT1 (HTTP, HTTPS, DNS repetidos — consolidar en una sola por protocolo).
- [x] **[2026-04-29]** Eliminar o restringir la regla `Passed via EasyRule` con `IPv4 *` (allow all) en OPT1 — es demasiado permisiva.
- [x] **[2026-04-29]** Confirmar que la regla "Bloquear todo lo demás" de WAN está correctamente posicionada como última.
- [x] **[2026-04-29]** Documentar la IP real del administrador (`192.168.163.140`) en el inventario/README del proyecto.

---

## Fase 2: Configuración del Servidor Base (Debian 12 en DMZ)

- [x] Descargar ISO de Debian 12 con entorno gráfico y crear VM en la red de la DMZ.
- [x] Instalar Debian seleccionando **entorno de escritorio GNOME**.
- [x] Configurar IP estática (`192.168.30.10`) en `/etc/network/interfaces`.
- [x] Actualizar repositorios y sistema (`apt update && apt upgrade`).
- [x] Validar conexión a Internet desde el Servidor Debian (tras corrección de reglas DMZ en pfSense).
- [x] **[2026-04-29]** Instalar e inicializar Cockpit (`apt install cockpit -y` + `systemctl enable --now cockpit.socket`).
- [x] **[2026-04-29]** Acceder al panel Cockpit desde el Cliente en `https://192.168.30.10:9090` y validar conectividad.
- [x] **[2026-04-29]** Instalar `cockpit-pcp` para habilitar historial de métricas y gráficas de rendimiento persistentes.
- [x] **[2026-04-29]** Configurar el dashboard de Cockpit para monitorizar recursos de los contenedores Docker/Odoo.
- [x] **[2026-04-29]** Instalar Docker Engine y Docker Compose CLI (`apt install docker.io docker-compose-plugin -y`).
- [x] Añadir usuario administrador al grupo `docker` (`usermod -aG docker $USER`).
- [x] Habilitar Docker en el arranque del sistema (`systemctl enable --now docker`).

---

## Fase 3: Despliegue de Docker (Odoo, PostgreSQL y Nginx)

> Los ficheros de configuración ya están creados. Esta fase consiste en desplegarlos en el servidor.

- [x] **[2026-04-29]** `docker/docker-compose.yml` redactado: servicios `db` (PostgreSQL 16), `odoo` (17.0) y `nginx`. Odoo no exporta puertos externos; Nginx expone 80 y 443.
- [x] **[2026-04-29]** `docker/odoo.conf` configurado: workers con fórmula `(CPU×2)+1`, `longpolling_port = 8072`, `max_cron_threads = 1`.
- [x] **[2026-04-29]** `docker/.env` creado con variables de entorno para credenciales y nombres de BD.
- [x] **[2026-04-29]** `config_nginx/odoo_proxy.conf` creado: proxy inverso HTTP→HTTPS, cabeceras de seguridad (HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy), bloque WebSocket `/longpolling/` en puerto 8072.
- [ ] Crear estructura de directorios en `/opt/erp-odoo` en el servidor (data, scripts, certs, config_nginx).
- [ ] Subir los ficheros del repositorio al servidor (`git clone` o `scp`).
- [ ] Generar certificados SSL autofirmados con OpenSSL y guardarlos en `/opt/erp-odoo/certs/`.
- [ ] Ejecutar `docker compose up -d` desde `/opt/erp-odoo/docker/`.
- [ ] Revisar logs globales (`docker compose logs -f`) para comprobar salud de los tres contenedores.
- [ ] Validar desde el host: `curl -I -k https://127.0.0.1` devuelve `200 OK`.

---

## Fase 4: Automatización y Scripts DevOps (Bash)

> Todos los scripts están creados y documentados. Esta fase consiste en activarlos en el servidor.

- [x] **[2026-04-29]** `scripts/deploy.sh` — Despliega el stack con verificación de salud activa (curl al endpoint `/web/health`).
- [x] **[2026-04-29]** `scripts/update.sh` — Actualización de imágenes y limpieza de contenedores huérfanos.
- [x] **[2026-04-29]** `scripts/backup.sh` — Volcado comprimido con `pg_dump -F c`, marca de tiempo y política de retención de 7 días.
- [x] **[2026-04-29]** `scripts/restore.sh` — Restauración limpia (`dropdb` + `createdb` + `pg_restore`).
- [x] **[2026-04-29]** `scripts/monitor.sh` — Chequeo de salud con auto-reinicio y log en `/var/log/erp_monitor.log`.
- [x] **[2026-04-29]** `scripts/install_cron.sh` — Instala todas las tareas cron automáticamente (monitor cada 5 min, backup a las 2AM, update domingo 3AM).
- [x] **[2026-04-29]** `scripts/setup_runner.sh` — Registra e instala el servidor Debian como runner de GitHub con systemd.
- [ ] Subir la carpeta `scripts/` al servidor Debian (dentro de `/opt/erp-odoo/`).
- [ ] Dar permisos de ejecución a todos los scripts: `chmod +x /opt/erp-odoo/scripts/*.sh`.
- [ ] Ejecutar `sudo ./scripts/install_cron.sh` en el servidor para activar las tareas cron automáticas.
- [ ] Testear un ciclo completo: desplegar → hacer backup → borrar BD → restaurar → validar integridad.

---

## Fase 5: Auditoría Avanzada de BD (PostgreSQL)

- [x] **[2026-04-29]** `sql/audit_triggers.sql` creado con tabla `asir_audit_log`, función `func_audit_users()` y trigger `trg_audit_new_odoo_user`.
- [x] **[2026-04-29]** Campo **JSONB** (`row_data`) añadido: almacena el estado completo del registro con `row_to_json(NEW)::JSONB`.
- [x] **[2026-04-29]** Vista `v_audit_resumen` creada para consultas rápidas en la defensa (extrae `login` y `name` del JSONB).
- [ ] Conectarse a la BD PostgreSQL: `docker exec -it odoo-db psql -U odoo -d odoo_erp`.
- [ ] Ejecutar el script: `\i /opt/erp-odoo/sql/audit_triggers.sql`.
- [ ] Validar auditoría: crear un usuario en Odoo → verificar registro en tabla (`SELECT * FROM v_audit_resumen;`).

---

## Fase 6: Seguridad de Capa de Red en Servidor (UFW)

- [ ] Instalar `ufw`: `apt install ufw -y`.
- [ ] Configurar reglas: permitir SSH (22), Cockpit (9090), HTTP (80) y HTTPS (443).
  ```bash
  ufw allow 22/tcp
  ufw allow 9090/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw default deny incoming
  ufw default allow outgoing
  ```
- [ ] Habilitar UFW: `ufw enable`.
- [ ] Verificar estado: `ufw status verbose`.

---

## Fase 7: Integración Exterior y Pruebas Globales

- [ ] Validar Port Forwarding pfSense: desde fuera de la LAN, acceder a `https://[IP-WAN]` y que responda Nginx/Odoo.
- [ ] Desde el PC Cliente (LAN), añadir entrada en `/etc/hosts` o DNS interno para `erp.techsolutions.local` → `192.168.30.10`.
- [ ] Acceder al ERP vía `https://erp.techsolutions.local` desde el Cliente y validar carga completa.
- [ ] Verificar que los triggers de auditoría funcionan desde la capa web (crear usuario desde UI → comprobar log).
- [ ] Revisar logs de acceso de Nginx: `docker exec nginx cat /var/log/nginx/access.log`.
- [ ] (Opcional) Exportar logs de Nginx y adjuntarlos en la memoria del proyecto.
- [ ] Prueba de recuperación ante fallos: parar el contenedor `odoo` → verificar que `monitor.sh` lo reinicia automáticamente.

---

## Fase 8: Pipeline CI/CD Completo (GitHub Actions)

- [x] **[2026-04-29]** `.github/workflows/ci.yml` — Pipeline CI: lint de shell scripts con `shellcheck` y validación del `docker-compose.yml`.
- [x] **[2026-04-29]** `.github/workflows/deploy.yml` — Pipeline CD con self-hosted runner: descarga imágenes Docker y ejecuta `deploy.sh` automáticamente tras cada CI exitoso.
- [x] **[2026-04-29]** `scripts/setup_runner.sh` — Registra e instala el servidor Debian como runner de GitHub con systemd.
- [ ] En el servidor Debian: editar `scripts/setup_runner.sh` con la URL del repo y el token de GitHub.
- [ ] Obtener token en: GitHub → Repositorio → Settings → Actions → Runners → "New self-hosted runner".
- [ ] Ejecutar en el servidor: `chmod +x scripts/setup_runner.sh && sudo ./scripts/setup_runner.sh`.
- [ ] Verificar que el runner aparece como **"Idle"** en GitHub → Settings → Actions → Runners.
- [ ] Hacer un `git push` a `main` y comprobar que el workflow **"CD Deploy"** se activa en la pestaña Actions.
- [ ] Validar que los contenedores se levantan correctamente en el servidor tras el despliegue automático.

## Fase 9: Mejoras de Automatización Avanzada (Scripting y Docker)

- [x] **[2026-04-30]** Crear script `install.sh` (instalador todo-en-uno).
  - _Qué se hizo:_ Se desarrolló un script en Bash para la instalación inicial en servidor limpio clonando el repositorio.
  - _Archivos afectados:_ `install.sh`
  - _Resultado:_ Permite un despliegue desde cero ejecutando un solo archivo.
- [x] **[2026-04-30]** Crear plantilla `.env.example` y configurador.
  - _Qué se hizo:_ Se extrajeron las variables de entorno a una plantilla pública y se creó un script de configuración interactiva.
  - _Archivos afectados:_ `.env.example`, `scripts/configure.sh`, `.gitignore`
  - _Resultado:_ Mejora la seguridad al no requerir edición manual de archivos ocultos.
- [x] **[2026-04-30]** Añadir `healthcheck` nativos en Docker.
  - _Qué se hizo:_ Se configuró validación nativa para la BD, aplicación y proxy web en el archivo Compose.
  - _Archivos afectados:_ `docker/docker-compose.yml`
  - _Resultado:_ Docker puede conocer la salud interna de los servicios antes de arrancar los dependientes.
- [x] **[2026-04-30]** Mejorar `monitor.sh` y añadir Logrotate.
  - _Qué se hizo:_ El monitor ahora lee `State.Health.Status` además de `State.Running`. Se añadió política de rotación semanal.
  - _Archivos afectados:_ `scripts/monitor.sh`, `config/logrotate.d/erp-odoo`, `scripts/install_cron.sh`
  - _Resultado:_ Monitorización más robusta y prevención de llenado del disco por exceso de logs.
- [x] **[2026-04-30]** Crear orquestador `erp.sh` y pre-checks.
  - _Qué se hizo:_ Se unificaron los comandos en `erp.sh` y se añadieron comprobaciones preventivas a los despliegues.
  - _Archivos afectados:_ `erp.sh`, `scripts/deploy.sh`, `scripts/update.sh`, `scripts/backup.sh`
  - _Resultado:_ Administración centralizada y scripts más resistentes a fallos de entorno.
- [x] **[2026-04-30]** Actualizar CI de GitHub Actions.
  - _Qué se hizo:_ Se incorporaron los nuevos scripts Bash a la validación de ShellCheck.
  - _Archivos afectados:_ `.github/workflows/ci.yml`
  - _Resultado:_ El código Bash de la raíz también cuenta con análisis estático de código.

---

## Fase 10: Documentación Final y Defensa

- [ ] Revisar y completar `docs/implementation_plan.md` con todas las decisiones técnicas tomadas.
- [ ] Actualizar `CHANGELOG.md` con los cambios de cada sesión de trabajo.
- [ ] Redactar la **Memoria del TFG** con estructura formal: introducción, objetivos, arquitectura, implementación, pruebas y conclusiones.
- [ ] Preparar capturas de pantalla para la memoria: Cockpit, pfSense, Odoo funcionando, GitHub Actions.
- [ ] Preparar demostración en vivo para la defensa: ciclo completo deploy → backup → restore → auditoría.
- [ ] Revisar el `README.md` para que sirva como guía de despliegue rápida del proyecto.
- [ ] (Opcional) Exportar el proyecto como imagen OVA/OVF para entrega o repositorio.

---

## Resumen de Estado

| Fase | Descripción | Estado |
|:---:|:---|:---:|
| 0 | Investigación y diseño | ✅ Completada |
| 1 | Arquitectura pfSense y red | ✅ Completada (limpieza EasyRules pendiente) |
| 2 | Servidor Debian base | 🔄 En progreso (Docker pendiente) |
| 3 | Despliegue Docker | 🔄 Ficheros listos, despliegue pendiente |
| 4 | Scripts DevOps | 🔄 Scripts listos, activación en servidor pendiente |
| 5 | Auditoría PostgreSQL | 🔄 Script listo, ejecución en BD pendiente |
| 6 | UFW Firewall local | ⏳ Pendiente |
| 7 | Pruebas globales | ⏳ Pendiente |
| 8 | CI/CD GitHub Actions | 🔄 Workflows listos, runner pendiente |
| 9 | Mejoras Automatización | ✅ Completada |
| 10 | Documentación y defensa | ⏳ Pendiente |
