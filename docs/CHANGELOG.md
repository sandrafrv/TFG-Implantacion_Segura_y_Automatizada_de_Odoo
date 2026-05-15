# Changelog

Todos los cambios notables del proyecto se documentan en este archivo.
Formato: [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

---

## [Sin publicar]

### En progreso

- Hardening final: Debian headless + SSH por clave pública
- Capturas de pantalla para la memoria del TFG
- Redacción final de la memoria del TFG
- Pruebas de integración end-to-end con las 3 VMs levantadas

---

## [v1.7 — 2026-05-15]

### Añadido

- **Infraestructura como Código con Vagrant** (`Vagrantfile`):
  Define y orquesta las 3 VMs del proyecto (pfSense, Odoo+Nginx, PostgreSQL).
  Configura redes (VLAN 10, 30 y 40) con IPs estáticas y asignación de recursos (RAM/CPU).

- **Script de aprovisionamiento VM2** (`vagrant/provision_debian.sh`):
  Aprovisiona la VM de Odoo/Nginx (VLAN 30). Clona el repositorio, instala Docker CE, Nginx,
  certificados SSL autofirmados, crea la red macvlan y despliega el `docker-compose.yml`.

- **Script de aprovisionamiento VM1** (`vagrant/provision_pfsense.sh`):
  Aprovisiona pfSense aplicando el `config.xml` autogenerado si existe, o informa los pasos
  manuales necesarios.

- **Script de aprovisionamiento VM3** (`vagrant/provision_postgres.sh`):
  Aprovisiona el servidor de base de datos PostgreSQL 16 nativo en VLAN 40.

- **Documentación del aprovisionamiento PostgreSQL** (`vagrant/Explicacion_provision_postgres.md`):
  Explica el proceso y la lógica del script de aprovisionamiento de la VM3.

- **README de la carpeta vagrant/** (`vagrant/README.md`):
  Índice y descripción de los 3 scripts de aprovisionamiento. Explica el orden de ejecución,
  configuración necesaria y troubleshooting.

- **Nuevo script de backup PostgreSQL remoto** (`scripts/mantenimiento/backup_postgres.sh`):
  Utiliza `pg_dump` conectando remotamente a la VM de base de datos (`192.168.40.10`).
  Genera volcado comprimido con marca de tiempo y aplica retención de 7 días.

- **Extras LDAP** (`extras/ldap/README.md`, `extras/ldap/estructura.ldif`):
  Documentación sobre por qué se descartó LDAP en esta versión y cómo retomarlo.
  Backup de la estructura de usuarios y grupos LDAP.

- **README de la carpeta sql/** (`sql/README.md`):
  Explica el propósito de `audit_triggers.sql`, cómo ejecutarlo, y que apunta a la BD
  en `192.168.40.10`.

- **README de deprecación en scripts/ldap/** (`scripts/ldap/README.md`):
  Aviso claro de que estos scripts ya no forman parte del despliegue activo.
  Referéncia a `extras/ldap/` para quien quiera retomar la integración.

- **README de la carpeta ldap/** (`ldap/README.md`):
  Aviso de que es material legacy y que el contenido activo está en `extras/ldap/`.

### Modificado

- **`docker/docker-compose.yml`**: Eliminado el servicio `db` (PostgreSQL local) y el servicio
  `ldap` (OpenLDAP). Ahora solo corren `odoo-web` y `nginx-proxy`.

- **`docker/odoo.conf`**: Cambiado `db_host` de `localhost` a `192.168.40.10` (VM3 PostgreSQL).

- **`scripts/deploy/deploy.sh`**: Actualizado para verificar primero la conectividad con la
  base de datos externa antes de levantar contenedores.

- **`scripts/deploy/configure.sh`**: Ajustado para referenciar `.env` en la raíz del
  repositorio en lugar de dentro de `docker/`.

- **`scripts/deploy/erp.sh`**: Eliminada la opción del menú para ver logs del contenedor
  PostgreSQL local. Sustituida por instrucciones de cómo ver los logs en la VM `db-server`.

- **`scripts/deploy/install_cron.sh`**: Crea `/etc/backup_odoo.env` (chmod 600) con
  credenciales de BD. Cron de backup ahora ejecuta cada 4 horas apuntando a BD externa.

- **`scripts/mantenimiento/restore.sh`**: Restaura en BD externa (`192.168.40.10`) usando
  credenciales cargadas desde `/etc/backup_odoo.env`.

- **`scripts/mantenimiento/monitor.sh`**: Retirados `odoo_erp` y `openldap` de la lista
  de contenedores monitorizados. Solo monitoriza `odoo-web` y `nginx-proxy`.

- **`scripts/README.md`**: Añadido `backup_postgres.sh` al índice. Marcada la carpeta
  `scripts/ldap/` como deprecada.

- **`.env.example`**: Eliminadas todas las variables relacionadas con LDAP.

- **`.github/workflows/ci.yml`**: Añadida validación ShellCheck para scripts de `vagrant/`.

- **`.github/workflows/deploy.yml`**: Actualizada lista de contenedores a verificar
  (eliminando PostgreSQL y LDAP).

- **`config/logrotate.d/erp-odoo`**: Añadida rotación del nuevo log `/var/log/backup_odoo.log`.

- **`README.md`**: Reescrito con la nueva arquitectura 3 VMs, diagrama Mermaid actualizado,
  tabla IPs/VLANs, sección Docker con solo 2 contenedores, sección backups, inicio rápido Vagrant.

- **`CLAUDE.md`**: Actualizado con arquitectura actual, comandos por VM, advertencias
  de BD externa y LDAP retirado.

- **`docs/diagrama_red.md`**: Reescrito con la nueva topología de 3 VMs y 3 VLANs.

- **`docs/CONTROL_ACCESO.md`**: LDAP movido a sección "mejora futura". Autenticación
  actualizada a modelo nativo de Odoo.

- **`docs/HISTORIAL_IMPLEMENTACION.md`**: Añadida Fase 6 completa con Vagrant + PostgreSQL
  externo + retirada de LDAP.

- **`docs/INSTALACION_COMPLETA.md`**: Flujo de instalación actualizado con `vagrant up`
  como punto de entrada principal.

- **`docs/reglas_pfsense.md`**: Añadidas reglas inter-VLAN 30→40 para PostgreSQL.
  Eliminadas reglas de LDAP.

- **`docs/guias/INSTALACION_SERVIDOR.md`**: Alternativa `vagrant up` documentada.

- **`docs/guias/INSTALACION_RED.md`**: Reescrita con nueva topología 3 VMs y VLAN 40.

- **`docs/guias/INSTALACION_LDAP_CICD_HARDENING.md`**: Sección LDAP convertida a
  "no activo en esta versión, ver `extras/ldap/`".

- **`docs/mas_info/informe_erp.md`**: Sección de arquitectura técnica actualizada.

### Eliminado

- Servicio `db` (PostgreSQL) del `docker-compose.yml` — movido a VM3 nativa.
- Servicio `ldap` (OpenLDAP) del `docker-compose.yml` — movido a `extras/ldap/`.
- Variables LDAP del `.env.example`.
- Monitoreo de contenedores `odoo_erp` y `openldap` del script `monitor.sh`.

### Seguridad

- PostgreSQL ahora está en VLAN 40 aislada, inaccesible desde Internet y VLAN 10.
- Credenciales de backup almacenadas en `/etc/backup_odoo.env` con permisos 600.
- Superficie de ataque reducida al eliminar contenedor LDAP y PostgreSQL de Docker.

---

## [Sin publicar — pre-v1.7]

### En progreso

- Hardening final: Debian headless + SSH por clave pública
- Capturas de pantalla para la memoria del TFG
- Redacción de la memoria del TFG

### Añadido

- **Automatización de la configuración de pfSense** (`scripts/deploy/generate_pfsense_config.sh`):
  Script Bash que genera un `config.xml` completo con todas las interfaces (WAN, LAN, OPT1/DMZ,
  OPT2/VLAN_ADMIN), DHCP, DNS Resolver con Host Override, NAT Port Forward, aliases y las 30+
  reglas de firewall del proyecto. Importable vía **Diagnostics → Backup/Restore**.
- **Integración CI para pfSense** (`.github/workflows/ci.yml`):
  El pipeline ahora genera el `config.xml`, lo valida con `xmllint` y lo sube como **artefacto
  descargable** desde GitHub Actions (retención 30 días).

### Modificado

- **Sistema operativo del servidor:** Cambiado de **Debian 12 (Bookworm)** a **Debian 13 (Trixie)**.

---

## [v1.6 — 2026-05-13]

### Añadido

- **Guía maestra de instalación desde cero** (`docs/INSTALACION_COMPLETA.md`)
- **Sub-guías por módulo** en `docs/guias/`
- **`docs/diagrama_red.md`** completamente reescrito con diagrama Mermaid actualizado
- **`docs/GESTION_REPOSITORIO.md`** actualizado con estructura real del repositorio
- **`docs/github_issues.md`** ampliado con nuevas plantillas

### Modificado

- `docs/GUIA_DESPLIEGUE.md` — Añadido redirect a `INSTALACION_COMPLETA.md`

---

## [v1.5 — 2026-05-09]

### Añadido

- Archivado de documentación histórica en `docs/archive/`
- Historial consolidado en `HISTORIAL_IMPLEMENTACION.md`
- Organización de scripts en subcarpetas `deploy/`, `odoo/`, `ldap/`, `mantenimiento/`
- VLAN 40 (red de administración): `192.168.40.1/24`
- LDAP como autenticador del panel pfSense
- SSSD + PAM en clientes VLAN 10
- Control de acceso en 3 capas documentado en `CONTROL_ACCESO.md`

---

## [v1.4 — 2026-05-06]

### Corregido

- **Pipeline CD — base de datos Odoo no inicializada:**
  Sin `.env`, Odoo no podía conectarse a PostgreSQL. Causa: `.env` no existía en el servidor.
  Solución: recrear `.env` y purgar volumen de datos PostgreSQL.

---

## [v1.3 — 2026-04-30]

### Añadido

- Pipeline CI/CD completamente operativo en servidor Debian
- Runner `debian` instalado como servicio systemd
- 4 contenedores en estado `healthy` tras primer despliegue exitoso

### Corregido

- `deploy.sh` — comprobación de puertos 80/443 con `docker ps` en lugar de `ss -tlnp`
- `deploy.sh` — permisos de `.env`: `chown root:server` + `chmod 640`
- `deploy.yml` — `dubious ownership` en git resuelto

---

## [v1.2 — 2026-04-30]

### Añadido

- Auditoría PL/pgSQL ejecutada y validada en producción:
  tabla `asir_audit_log`, vista `v_audit_resumen`, trigger `trg_audit_new_odoo_user`

### Corregido

- Nombre del contenedor PostgreSQL: `odoo-db` → `odoo_erp` en todos los scripts

---

## [v1.1 — 2026-04-30]

### Añadido

- `install.sh` — Instalador todo-en-uno
- `.env.example` + `scripts/deploy/configure.sh`
- `scripts/deploy/erp.sh` — Orquestador central interactivo
- `config/logrotate.d/erp-odoo` — Rotación semanal de logs
- `scripts/deploy/install_cron.sh` — Instalador de tareas cron

### Modificado

- `docker/docker-compose.yml` — Healthchecks nativos + `depends_on` con `service_healthy`
- `docker/odoo.conf` — `longpolling_port` → `gevent_port`
- `config_nginx/odoo_proxy.conf` — Rutas SSL sincronizadas

---

## [v1.0 — 2026-04-29]

### Añadido

- `docker/docker-compose.yml` — Stack inicial: PostgreSQL 16, Odoo 17 CE, Nginx Alpine
- `docker/odoo.conf` — `proxy_mode`, `workers`, `gevent_port`
- `config_nginx/odoo_proxy.conf` — Proxy inverso HTTPS con TLSv1.2/1.3
- `scripts/deploy/deploy.sh` — Despliegue con healthcheck
- `scripts/mantenimiento/backup.sh` — `pg_dump -F c`
- `scripts/mantenimiento/restore.sh` — Restauración limpia
- `scripts/mantenimiento/update.sh` — `docker compose pull` + prune
- `scripts/mantenimiento/monitor.sh` — Chequeo de contenedores
- `sql/audit_triggers.sql` — Tabla, función y trigger de auditoría
- `.github/workflows/ci.yml` — CI: ShellCheck + YAML lint + Markdownlint
- `docs/reglas_pfsense.md` — Documentación de reglas pfSense
- `CLAUDE.md` — Skill de documentación para el asistente IA
