# Changelog

Todos los cambios notables del proyecto se documentan en este archivo.
Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

---

## [Sin publicar]

### En progreso

- Hardening final: Debian headless + SSH por clave pública
- Capturas de pantalla para la memoria del TFG
- Redacción de la memoria del TFG

---

## [v1.8 — 2026-05-22]

### Corregido

- **BUG-08 `scripts/deploy/generate_pfsense_config.sh` — DNS Host Override apuntaba al host Debian en vez de nginx-proxy** (🔴 CRÍTICA):
  La variable `DNS_TARGET` usaba `$SERVER_IP` (`192.168.30.10`, servidor Debian), pero el DNS debe resolver
  a `$NGINX_IP` (`192.168.30.20`, `nginx-proxy` MACVLAN), que es el único punto de entrada HTTPS.
  Corrección: `DNS_TARGET="$NGINX_IP"`.

- **BUG-09 `generate_pfsense_config.sh` — Orden incorrecto de reglas en OPT1/DMZ** (🔴 CRÍTICA):
  La regla `PASS Odoo→PostgreSQL` se generaba **antes** de los bloqueos anti-pivoting.
  En pfSense el orden de evaluación es de arriba hacia abajo: colocar el PASS primero significaba que
  **cualquier** host de la DMZ podría haber alcanzado `192.168.40.10:5432`, no solo `odoo-web`.
  Orden correcto ahora: Bloqueo VLAN10 (Pos.1) → Bloqueo pfSense-LAN (Pos.2) → **PASS Odoo→PG (Pos.3)** → Bloqueo VLAN40 (Pos.4).

- **BUG-10 `generate_pfsense_config.sh` — Regla DBA PostgreSQL ausente en OPT2/VLAN 40** (🟠 MEDIA):
  El XML generado no incluía la regla que permite a los administradores de la VLAN 40 conectarse
  directamente a PostgreSQL (`192.168.40.10:5432`). Esta regla sí estaba documentada en `docs/reglas_pfsense.md`
  (Pos.5 de OPT2) pero no se generaba en el `config.xml`. Añadida.

- **BUG-11 `generate_pfsense_config.sh` — Aliases incompletos** (🟡 BAJA):
  Faltaban los aliases `Odoo_Web` (para `192.168.30.21`) y `PostgreSQL_VM` (para `192.168.40.10`).
  Añadidos para facilitar la lectura de reglas en la interfaz web de pfSense.

### Modificado

- **`docs/reglas_pfsense.md`**: añadida advertencia explícita en la sección DNS Resolver y en el checklist
  final indicando que el Host Override debe apuntar a `192.168.30.20` (nginx-proxy), no a `192.168.30.10`.
  Añadida cabecera con versión y fecha de última actualización.

---

## [v1.7 — 2026-05-15]

> Revisión IaC completa del repositorio. Se auditaron estáticamente todos los scripts y archivos de configuración. Se identificaron y corrigieron 7 bugs.

### Corregido

- **BUG-01 `docker/odoo.conf` — `db_host` apuntaba al nombre de contenedor `db`** (🔴 CRÍTICA):
  Cambiado `db_host = db` → `db_host = 192.168.40.10`.
  La BD reside en la VM PostgreSQL externa (VLAN 40), no en un contenedor local.
  El valor incorrecto no causaba fallo inmediato (la variable de entorno `HOST` en `docker-compose.yml` tiene prioridad),
  pero era confuso y peligroso si se cambiaba el método de inyección de variables.

- **BUG-02 `scripts/mantenimiento/restore.sh` — Restauraba contra contenedor `odoo_erp` inexistente** (🔴 CRÍTICA):
  El script ha sido reescrito para ejecutar el restore directamente contra la VM PostgreSQL externa
  via `pg_restore -h 192.168.40.10`. Ahora: para `odoo-web`, elimina y recrea la BD remotamente,
  restaura el dump con `zcat | psql` y reinicia el contenedor Odoo.

- **BUG-03 `scripts/mantenimiento/monitor.sh` — Monitorizaba `odoo_erp` y `openldap` inexistentes** (🟠 MEDIA):
  Lista de contenedores corregida:
  `("odoo_erp" "openldap" "odoo-web" "nginx-proxy")` → `("odoo-web" "nginx-proxy")`.
  Eliminadas las alertas falsas generadas cada 15 minutos por los contenedores que no existen en el stack actual.

- **BUG-05 `scripts/deploy/configure.sh` — Ruta del `.env` inconsistente** (🟠 MEDIA):
  El script generaba el `.env` en `$PROJECT_DIR/docker/.env` pero `provision_debian.sh` lo creaba en
  la raíz (`$PROJECT_DIR/.env`) y `docker compose` busca el `.env` en el directorio de trabajo
  (`/opt/erp-odoo/`). Unificado: el `.env` siempre se escribe en `$PROJECT_DIR/.env` (raíz).

- **BUG-06 `config/logrotate.d/erp-odoo` — Patrón de logs incompleto** (🟡 BAJA):
  El patrón `erp_*.log` no cubría `/var/log/erp-odoo/erp.log` (creado por `erp.sh`) ni
  `/var/log/backup_odoo.log` (creado por `backup_postgres.sh`). Corregido a:
  `/var/log/erp_*.log /var/log/erp-odoo/*.log /var/log/backup_odoo.log`.

- **BUG-07 `scripts/deploy/erp.sh` — Menú de logs incluía opción para `odoo_erp` inexistente** (🟡 BAJA):
  La opción de logs del menú interactivo ha sido limpiada. Ahora muestra solo:
  `1) nginx-proxy`, `2) odoo-web`, `3) Todos`. Se añadió nota informativa de cómo
  consultar los logs de PostgreSQL via SSH a la VM `db-server`.

### Notas de la revisión

- **`vagrant/provision_debian.sh` BUG-04** (🟡 BAJA): Se recomienda sustituir `chmod +x scripts/deploy/*.sh`
  por `find scripts/ -name "*.sh" -exec chmod +x {} +` para mayor robustez ante directorios faltantes.
  Pendiente de aplicar si se reactiva el entorno Vagrant.

- **Alertas de seguridad menores documentadas en la revisión:**
  - `Vagrantfile`: passwords de fallback `changeme_db/changeme_master` solo activos si no se pasan variables de entorno.
  - `docker-compose.yml`: Puerto 80 expuesto al host es **intencional** (redirige a 443 vía Nginx).

### Añadido

- **Automatización de la configuración de pfSense** (`scripts/deploy/generate_pfsense_config.sh`):
  Script Bash que genera un `config.xml` completo con todas las interfaces (WAN, LAN, OPT1/DMZ,
  OPT2/VLAN_ADMIN), DHCP, DNS Resolver con Host Override, NAT Port Forward, aliases y las 30+
  reglas de firewall del proyecto. Importable vía **Diagnostics → Backup/Restore**.
- **Integración CI para pfSense** (`.github/workflows/ci.yml`):
  El pipeline ahora genera el `config.xml`, lo valida con `xmllint` y lo sube como **artefacto
  descargable** desde GitHub Actions (retención 30 días). Permite obtener una configuración
  validada sin ejecutar nada localmente.

### Modificado

- **Sistema operativo del servidor:** Cambiado de **Debian 12 (Bookworm)** a **Debian 13 (Trixie)**.
  - La instalación de Docker cambia de `docker.io` (paquete Debian) al repositorio oficial de Docker CE (`docker-ce`, `containerd.io`, `docker-compose-plugin`).
  - La codename del repositorio de Docker pasa de `bookworm` a `trixie`.
  - Configuración de red compatible: `systemd-networkd` (por defecto en Trixie) o `NetworkManager` (`nmcli`/`nmtui`).
  - El resto de la infraestructura (pfSense, Docker stack, LDAP, Nginx) **no cambia**.

---

## [v1.6 — 2026-05-13]

### Añadido

- **Guía maestra de instalación desde cero** (`docs/INSTALACION_COMPLETA.md`):
  Punto de entrada único que documenta las 8 fases de instalación con secciones de resumen,
  comandos clave, checklist de verificación final y orden de arranque.

- **Sub-guías por módulo** en `docs/guias/`:
  - `01_PFSENSE_INSTALACION.md` — VM, interfaces, DHCP, DNS, NAT, todas las reglas de firewall, LDAP auth en panel
  - `02_DEBIAN_PREPARACION.md` — IP estática, Docker, Cockpit, clonación del repo, `.env`
  - `03_DOCKER_STACK.md` — Red MACVLAN, SSL, `docker compose up`, troubleshooting
  - `04_ODOO_CONFIGURACION.md` — Post-instalación, módulos, conexión LDAP, usuarios por rol, auditoría SQL
  - `05_LDAP_INSTALACION.md` — Estructura LDAP, ACLs, usuarios, SSSD+PAM en clientes Linux
  - `07_CICD_GITHUB.md` — Self-hosted runner, pipeline CI/CD, permisos `.env`
  - `08_HARDENING_FINAL.md` — UFW, SSH con claves, headless, checklist final

- **`docs/diagrama_red.md`** completamente reescrito con:
  - Diagrama Mermaid actualizado con VLAN 40, MACVLAN e IPs reales
  - Tabla de direccionamiento IP completa
  - Diagrama de zonas de seguridad y anti-pivoting
  - Flujo de autenticación de un empleado
  - Esquema de la red Docker interna

- **`docs/GESTION_REPOSITORIO.md`** actualizado con:
  - Árbol de estructura real del repositorio
  - Flujo GitOps con reglas claras
  - Tabla de cuándo actualizar cada documento
  - Nomenclatura para capturas de pantalla

- **`docs/github_issues.md`** ampliado con:
  - Issue para control de acceso por roles (3 capas)
  - Issue para securización del panel pfSense con LDAP
  - Referencias a los nuevos documentos en cada plantilla
  - Separación clara de labels sugeridos

### Modificado

- `docs/GUIA_DESPLIEGUE.md` — Añadido redirect prominente a `INSTALACION_COMPLETA.md`

---

## [v1.5 — 2026-05-09]

### Añadido

- **Archivado de documentación histórica:** Documentos de planificación original
  movidos a `docs/archive/` para mantener la raíz limpia.
- **Historial consolidado:** Planes pendientes e IaC fusionados en `HISTORIAL_IMPLEMENTACION.md`.
- **Organización de scripts:** Subcarpetas `deploy/`, `odoo/`, `ldap/`, `mantenimiento/`
  creadas en `scripts/` e indexadas en `scripts/README.md`.
- **Plantillas GitHub Issues** actualizadas para los hitos finales de infraestructura.
- **VLAN 40 (red de administración):** Configurada en pfSense (OPT2, `192.168.40.1/24`).
  Reglas: panel pfSense + SSH + Cockpit + LDAP admin + Odoo admin, sin acceso a VLAN 10.
- **LDAP como autenticador del panel pfSense:** Solo el grupo `admin` tiene privilegio
  `WebCfg - All pages`. El usuario `dba` es rechazado.
- **SSSD + PAM en clientes VLAN 10:** Script `configurar_cliente_ldap.sh` —
  login en PC Linux con credencial LDAP centralizada.
- **ACLs LDAP:** Script `ldap_politica_acceso.sh` — modelo de mínimo privilegio.
  Técnico solo puede cambiar contraseñas; readonly solo puede leer.
- **Control de acceso en 3 capas:** Nginx (rutas por VLAN) + Odoo tipo usuario + Odoo grupos por rol.
  Documentado en `CONTROL_ACCESO.md`.

---

## [v1.4 — 2026-05-06]

### Corregido

- **Pipeline CD — base de datos Odoo no inicializada:**
  El job `Desplegar Stack en Servidor Debian` fallaba de forma repetida (5+ ejecuciones).

  **Causa raíz:** El archivo `.env` no existía en el servidor. Sin variables de entorno,
  Odoo no podía conectarse a PostgreSQL y la base de datos quedaba sin inicializar.
  Error en cascada:
  ```
  ERROR: relation "ir_module_module" does not exist
  KeyError: 'ir.http'
  GET /web/health HTTP/1.1" 500
  ```

  **Solución:**
  1. `docker compose down`
  2. `sudo rm -rf postgres-data/pgdata` y `sudo rm -rf odoo-data/filestore`
  3. Recrear `.env` con credenciales correctas
  4. `docker compose up -d` → primer healthcheck 200 OK a las 18:08:12 UTC ✅

  **Prevención:** El `.env` debe crearse manualmente durante la instalación inicial
  (ver `.env.example` y `docs/guias/02_DEBIAN_PREPARACION.md`).

---

## [v1.3 — 2026-04-30]

### Añadido

- **Pipeline CI/CD completamente operativo** en el servidor Debian de la DMZ:
  - Runner `debian` instalado como servicio systemd en `/opt/actions-runner`
  - Versión del agente: `2.334.0` (SHA256 verificado)
  - Servicio: `actions.runner.sandrafrv-...debian.service` (enabled en systemd)
  - Stack Docker desplegado automáticamente tras push a `main`
  - 4 contenedores (`odoo_erp`, `odoo-web`, `openldap`, `nginx-proxy`) en estado `healthy`

### Corregido

- **`deploy.sh` — comprobación de puertos 80/443:**
  `ss -tlnp` sin root no muestra el proceso propietario. El script fallaba
  aunque los puertos fueran del propio `nginx-proxy`.
  **Solución:** Comprobar con `docker ps` si `nginx-proxy` está corriendo antes de
  considerar que hay un conflicto real de puertos.

- **`deploy.sh` — permisos de `.env`:**
  `.env` con permisos `600` (solo root) — el runner como usuario `server` no podía leerlo.
  **Solución:** `sudo chown root:server docker/.env && sudo chmod 640 docker/.env`

- **`deploy.yml` — `dubious ownership` en git:**
  `/opt/erp-odoo` creado por `root` pero el runner corre como `server`.
  **Solución:** `git config --global --add safe.directory /opt/erp-odoo`
  + `sudo chown -R server:server /opt/erp-odoo`

---

## [v1.2 — 2026-04-30]

### Añadido

- **Auditoría PL/pgSQL ejecutada y validada en producción:**
  - Tabla `asir_audit_log` con campo JSONB `row_data`
  - Vista `v_audit_resumen` con `login` y `name` extraídos del JSONB
  - Validación: creación de usuario en Odoo → `audit_id=1, CREACION_USUARIO, res_users, id=8` ✅

### Corregido

- Nombre del contenedor PostgreSQL: `odoo-db` → `odoo_erp` (real en `docker-compose.yml`).
  Corregido en `backup.sh`, `restore.sh`, `monitor.sh` y documentación.

---

## [v1.1 — 2026-04-30]

### Añadido

- `install.sh` — Instalador todo-en-uno (dependencias + Docker + Cockpit + SSL + cron)
- `.env.example` + `scripts/deploy/configure.sh` — Plantilla pública y configurador interactivo
- `scripts/deploy/erp.sh` — Orquestador central con menú interactivo
- `config/logrotate.d/erp-odoo` — Rotación semanal de logs
- `scripts/deploy/install_cron.sh` — Instalador de tareas cron automatizadas

### Modificado

- `docker/docker-compose.yml` — Healthchecks nativos para PostgreSQL, Odoo y Nginx.
  `depends_on` con condición `service_healthy`. Rutas de volúmenes corregidas a `../`.
- `docker/odoo.conf` — `longpolling_port` → `gevent_port` (deprecado en Odoo 17)
- `config_nginx/odoo_proxy.conf` — Rutas de certificados SSL sincronizadas con `install.sh`

### Corregido

- `Permission denied` en `/var/lib/odoo/.local` → rutas de volúmenes relativas corregidas
- Bucle de reinicio en Nginx → nombres de certificados SSL sincronizados
- Error de inicialización de Odoo → primer arranque con `docker compose run --rm`

---

## [v1.0 — 2026-04-29]

### Añadido

- `docker/docker-compose.yml` — Stack inicial: `odoo_erp` (PostgreSQL 16), `odoo-web` (Odoo 17 CE),
  `nginx-proxy` (Nginx Alpine). Red bridge `odoo_net`. Solo Nginx expone puertos.
- `docker/odoo.conf` — `proxy_mode = True`, `workers = 2`, `gevent_port = 8072`, `limit_time_real = 1200`
- `config_nginx/odoo_proxy.conf` — Proxy inverso HTTPS con TLSv1.2/1.3, HSTS, X-Frame-Options,
  timeouts 720s y bloque `/longpolling/` para WebSocket
- `scripts/deploy/deploy.sh` — Despliegue con espera de healthcheck
- `scripts/mantenimiento/backup.sh` — `pg_dump -F c` con retención 7 días
- `scripts/mantenimiento/restore.sh` — Restauración limpia con borrado previo de BD
- `scripts/mantenimiento/update.sh` — `docker compose pull` + `image prune`
- `scripts/mantenimiento/monitor.sh` — Chequeo de contenedores con auto-reinicio
- `sql/audit_triggers.sql` — Tabla `asir_audit_log`, función `func_audit_users()`,
  trigger `trg_audit_new_odoo_user` en `res_users`
- `.github/workflows/ci.yml` — CI: ShellCheck + YAML lint + Markdownlint
- `docs/reglas_pfsense.md` — Documentación de reglas pfSense
- `docs/github_issues.md` — Plantillas de GitHub Issues
- `CLAUDE.md` — Skill de documentación para el asistente IA
