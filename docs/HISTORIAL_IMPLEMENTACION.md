# Historial de Implementación — Cómo se construyó este repositorio
**TFG ASIR 2025/2026 — Sandra Fradejas Avedillo**

Este documento narra el proceso real de desarrollo del proyecto: decisiones tomadas, problemas encontrados, cómo se resolvieron y en qué orden se construyó todo. Es la historia técnica del repositorio.

---

## Fase 0 — Investigación y Decisiones de Diseño (2026-04-29)

### ¿Qué ERP elegir?

Se evaluaron tres ERPs de código abierto antes de comenzar:

| Criterio | **Odoo 17** | Dolibarr | ERPNext |
|----------|-------------|----------|---------|
| Facilidad de uso | ✅ Alta | Media | Media |
| API REST/XML-RPC | ✅ Madura | Limitada | Alta |
| Consumo de recursos | Moderado | ✅ Ligero | Pesado |
| Cobertura funcional | ✅ Completa | Básica | Muy completa |
| **Veredicto** | ✅ **Elegido** | Descartado | Descartado |

**Decisión:** Odoo 17 CE por su API XML-RPC madura y documentación oficial.

### ¿Qué sistema operativo?

Elegido **Debian 12 (Bookworm)** sobre Ubuntu/Mint porque:
- Ciclos de soporte más largos
- Es el sistema de referencia en la documentación oficial de Odoo
- Sin snaps ni paquetes propietarios
- `docker.io` disponible en repositorios oficiales

### Arquitectura de red

Se decidió usar pfSense como firewall con tres zonas separadas:
- **WAN** — salida a Internet
- **LAN (VLAN 10, 192.168.10.0/24)** — equipos cliente
- **DMZ (VLAN 30, 192.168.30.0/24)** — servidor ERP

Dentro del servidor Debian, todos los servicios en contenedores Docker con red bridge interna. Solo Nginx expone puertos al host.

### Decisión inicial sobre redes Docker

Se evaluó **macvlan** (IPs físicas por contenedor) pero se descartó inicialmente por complejidad. Se comenzó con **bridge** y se añadió macvlan más adelante (Fase B).

---

## v1.0 — Creación de la Infraestructura Base (2026-04-29)

### Archivos creados

**`docker/docker-compose.yml`** — Stack inicial con 3 servicios:
- `odoo_erp` (PostgreSQL 16) — BD sin puertos expuestos
- `odoo-web` (Odoo 17 CE) — sin puertos al host
- `nginx-proxy` (Nginx Alpine) — único punto de entrada, puertos 80/443

Red Docker `odoo_net` tipo bridge. Solo Nginx expone puertos.

**`docker/odoo.conf`** — Configuración de Odoo:
- `proxy_mode = True` — imprescindible al estar detrás de Nginx
- `workers = 2` — para VM de 2 cores
- `gevent_port = 8072` — para LiveChat/WebSocket
- `limit_time_real = 1200s` — para informes PDF pesados

**`config_nginx/odoo_proxy.conf`** — Proxy inverso:
- Bloque HTTP: redirección 301 a HTTPS
- Bloque HTTPS: TLSv1.2/1.3, cabeceras de seguridad (HSTS, X-Frame-Options, nosniff), timeouts 720s
- Bloque `/longpolling/` → puerto 8072 para WebSocket

**Scripts Bash iniciales:**
- `scripts/deploy.sh` — levanta el stack y espera healthcheck
- `scripts/backup.sh` — `pg_dump -F c` con retención 7 días
- `scripts/restore.sh` — borra y recrea la BD antes de restaurar
- `scripts/update.sh` — `docker compose pull` + `image prune`
- `scripts/monitor.sh` — chequea los 3 contenedores, auto-reinicia si caen

**`sql/audit_triggers.sql`** — Auditoría PostgreSQL:
- Tabla `asir_audit_log` con campo JSONB `row_data`
- Función PL/pgSQL `func_audit_users()`
- Trigger `trg_audit_new_odoo_user` en `res_users`

**`.github/workflows/ci.yml`** — CI con GitHub Actions:
- Validación YAML del docker-compose
- ShellCheck en todos los scripts `.sh`
- Markdownlint en documentación

**Documentación inicial:** `implementation_plan.md`, `task.md`, `reglas_pfsense.md`

---

## v1.1 — Automatización y Robustez (2026-04-30)

### Problema: Despliegue manual demasiado complejo

El proceso manual de instalación tenía demasiados pasos manuales. Se crean herramientas de automatización:

**`install.sh`** — Instalador todo-en-uno:
- Instala dependencias (`git`, `curl`, `openssl`, `cockpit`, `docker.io`)
- Clona el repositorio en `/opt/erp-odoo`
- Genera certificados SSL autofirmados
- Llama a `configure.sh` y luego a `deploy.sh`

**`.env.example` + `scripts/configure.sh`** — Gestión segura de credenciales:
- La plantilla pública sirve de guía
- `configure.sh` pide contraseñas interactivamente (sin eco en terminal)
- Aplica `chmod 600` al `.env` generado

**`scripts/erp.sh`** — Orquestador central con menú interactivo (opciones 1-10 para gestionar el ciclo de vida completo)

**`config/logrotate.d/erp-odoo`** — Rotación semanal automática de logs

**`scripts/install_cron.sh`** — Instala las 3 tareas cron en `/etc/cron.d/erp-odoo`

### Problema: Docker healthchecks faltantes

Se añadieron healthchecks nativos en `docker-compose.yml`:
- PostgreSQL: `pg_isready`
- Odoo: `curl /web/health`
- Nginx: `nginx -t`

Y `depends_on` con condición `service_healthy` para garantizar orden de arranque.

### Problema: Rutas de volúmenes incorrectas

El `docker-compose.yml` estaba en `docker/` pero los volúmenes apuntaban con rutas absolutas. Se corrigió a rutas relativas con `../` para que funcionen desde cualquier ubicación.

### Problema: `longpolling_port` deprecado en Odoo 17

El parámetro antiguo se renombró a `gevent_port`. Corregido en `docker/odoo.conf`.

### Errores resueltos:

- **`Permission denied` en `/var/lib/odoo/.local`** → corregido al arreglar las rutas de volúmenes
- **Bucle de reinicio en Nginx** → resuelto sincronizando nombres de certificados SSL en `install.sh`
- **Error de inicialización de Odoo** → primer arranque con `docker compose run --rm`

---

## v1.2 — Auditoría SQL en Producción (2026-04-30)

### Ejecución del trigger de auditoría

```bash
docker exec -i odoo_erp psql -U odoo -d odoo_erp < sql/audit_triggers.sql
```

### Problema: Nombre incorrecto del contenedor

El nombre real en `docker-compose.yml` era `odoo_erp` pero en algunos scripts y documentación se usaba `odoo-db`. Corregido en `backup.sh`, `restore.sh`, `monitor.sh` y documentación.

**Commit:** `b0022e4`

### Validación end-to-end confirmada

Crear usuario desde la UI de Odoo → verificar en la tabla de auditoría:
```
audit_id=1, CREACION_USUARIO, res_users, id=8, 2026-04-30 12:13:57 UTC
```
El trigger captura el snapshot JSONB completo del usuario creado. ✅

---

## v1.3 — Pipeline CI/CD Completo (2026-04-30)

### Configuración del Self-Hosted Runner

```bash
# En el servidor Debian
/opt/erp-odoo/scripts/setup_runner.sh
```

Runner instalado en `/opt/actions-runner`, versión `2.334.0` (SHA256 verificado).  
Nombre del runner: `debian`. Labels: `self-hosted, Linux, X64`.  
Instalado como servicio systemd: `actions.runner.sandrafrv-...debian.service`

**`deploy.yml`** creado — pipeline CD que se dispara tras CI exitoso:
1. `git reset --hard origin/main` (garantiza última versión)
2. `docker pull` de las 3 imágenes
3. `bash scripts/deploy.sh`

### Errores resueltos durante la puesta en marcha del CI/CD

**Error: `permission denied` en `.env`**
- **Causa:** `.env` tenía permisos `600` (solo root). El runner corre como usuario `server`.
- **Solución:** `sudo chown root:server /opt/erp-odoo/docker/.env && sudo chmod 640 /opt/erp-odoo/docker/.env`

**Error: Docker Compose dice "errores de sintaxis" (sin haberlos)**
- **Causa:** Cascada del error de permisos. Docker no podía leer el `.env` y lo interpretaba como error de configuración.
- **Solución:** Corregir los permisos del `.env` (ver arriba).

**Error: `dubious ownership` en git**
- **Causa:** `/opt/erp-odoo` fue creado por `root` pero el runner corre como `server`. Git bloquea acceso.
- **Solución:** Step `git config --global --add safe.directory /opt/erp-odoo` añadido al inicio del workflow.

**Error: Comprobación de puertos 80/443 falla en re-deploy**
- **Causa:** `ss -tlnp` sin root no muestra el nombre del proceso. El script fallaba aunque los puertos fueran del propio `nginx-proxy`.
- **Solución:** Verificar si `nginx-proxy` está corriendo con `docker ps`. Si lo está, es re-deploy válido.

**Validación final:** 3 contenedores `healthy`, pipeline CD ejecutado y completado en commit `0cdee22`. ✅

---

## v1.4 — Resolución de Fallo en Pipeline por .env Ausente (2026-05-06)

### Problema: Pipeline CD fallaba 5+ veces consecutivas

**Síntomas:**
```
ERROR: relation "ir_module_module" does not exist
KeyError: 'ir.http'
GET /web/health HTTP/1.1" 500
```

**Causa raíz:** El archivo `docker/.env` no existía en el servidor tras una limpieza. Sin las variables de entorno, Odoo no podía conectarse a PostgreSQL y la BD quedaba sin inicializar.

**Solución aplicada:**
1. `docker compose down` — parada completa del stack
2. `sudo rm -rf postgres-data/pgdata` y `sudo rm -rf odoo-data/filestore` — borrar datos corruptos
3. Recrear el `.env` con las credenciales correctas
4. `docker compose up -d` — arranque limpio
5. Odoo inicializa la BD desde cero → primer healthcheck 200 OK ✅

---

## Fase A — Verificación de Aislamiento VLAN (2026-05-08)

### Validación de reglas pfSense

Desde el cliente VLAN 10:
- `nc -zv 192.168.30.10 5432` → **Timeout** ✅ (PostgreSQL bloqueado)
- `nc -zv 192.168.30.10 8069` → **Timeout** ✅ (Odoo directo bloqueado)
- `curl -k https://192.168.30.10` → **200/302** ✅ (Odoo accesible por Nginx)
- Desde DMZ, `ping 192.168.10.x` → **Sin respuesta** ✅ (aislado)

---

## Fase B — MACVLAN: IPs Físicas para Contenedores (2026-05-08)

### Por qué se implementó

Para que pfSense vea los contenedores como hosts físicos independientes con IPs en la VLAN30, no como un único servidor. Esto permite reglas de firewall por contenedor.

### Problema: Formato YAML incompatible

El `docker-compose.yml` usaba formato lista en `networks` (`- odoo_net`), lo que impedía añadir la red MACVLAN con IP fija. Se reescribió con Python para garantizar indentación YAML correcta.

### Implementación

```bash
docker network create \
  --driver macvlan \
  --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 \
  --opt parent=ens18 \
  macvlan_vlan30
```

`docker-compose.yml` actualizado:
- `nginx-proxy` → IP fija `192.168.30.20`
- `odoo-web` → IP fija `192.168.30.21`
- `odoo_erp` (PostgreSQL) → sin IP MACVLAN (sólo red interna, por seguridad)

### Limitación documentada

El host Debian **no puede hacer ping a las IPs MACVLAN de sus propios contenedores**. Es una limitación conocida del driver macvlan en Linux (el tráfico host→contenedor MACVLAN no pasa por la interfaz física). Verificar desde otro equipo o desde un contenedor temporal.

```bash
# Verificación desde contenedor temporal
docker run --rm --network macvlan_vlan30 alpine \
  wget -qO- --no-check-certificate https://192.168.30.20 | grep "<title>"
# → <title>Odoo</title> ✅
```

**Commit:** `7ee1cd2`

---

## Fase C — Integración LDAP (2026-05-06 → 2026-05-08)

### Objetivo

Centralizar la autenticación de Odoo contra un directorio LDAP (OpenLDAP), eliminando contraseñas locales por usuario.

### Implementación

**Servicio añadido a `docker-compose.yml`:**
```yaml
ldap:
  image: osixia/openldap:1.5.0
  container_name: odoo-ldap
  environment:
    LDAP_ORGANISATION: "TFG ASIR"
    LDAP_DOMAIN: "tfg.com"
    LDAP_ADMIN_PASSWORD: ${LDAP_ADMIN_PASSWORD}
  volumes:
    - ../ldap_data:/var/lib/ldap
    - ../ldap_config:/etc/ldap/slapd.d
  networks:
    odoo_net:
```

**Variable añadida a `docker/.env`:**
```
LDAP_ADMIN_PASSWORD=<contraseña_segura>
```

### Scripts creados para gestionar LDAP

**`scripts/ldap_crear_usuarios.sh`** — Script interactivo que:
- Verifica el contenedor `odoo-ldap`
- Crea la OU `ou=usuarios,dc=tfg,dc=com` si no existe
- Permite crear usuarios en bucle con verificación post-creación

**`scripts/odoo_setup_wizard.sh`** — Asistente post-instalación:
- Renombra la compañía en BD (`UPDATE res_company`)
- Instala módulos (incluyendo `auth_ldap` obligatorio)
- Configura la conexión LDAP en la tabla `res_company_ldap`
- Opcionalmente deshabilita contraseñas locales para usuarios no-admin

### Problemas resueltos durante la integración

**Problema: Odoo no podía conectar con LDAP por nombre de host**
- El contenedor LDAP se llama `odoo-ldap` en la red Docker interna
- En la configuración de Odoo se usa la IP detectada con `docker inspect`

**Cambio en `ldap_crear_usuarios.sh` (2026-05-08):**
- Eliminadas variables no usadas `LDAP_HOST`, `LDAP_PORT`, `LDAP_DOMAIN` (advertencias ShellCheck SC2034)
- Año actualizado en cabecera: 2025 → 2026

---

## Estado Actual del Repositorio (2026-05-08)

### Infraestructura desplegada

| Componente | Estado | Notas |
|------------|--------|-------|
| pfSense | ✅ Activo | Reglas VLAN configuradas y verificadas |
| Debian 12 | ✅ Activo | Con Docker y Cockpit |
| Docker stack | ✅ 4 contenedores healthy | PostgreSQL, Odoo, LDAP, Nginx |
| MACVLAN | ✅ Activa | Nginx en .20, Odoo en .21 |
| LDAP | ✅ Integrado | `odoo-ldap` en `odoo_net` |
| DNS interno | ✅ Configurado | `erp.odoo.tfg.com` → `192.168.30.10` |
| CI/CD | ✅ Operativo | Runner `debian-dmz` activo |
| Auditoría SQL | ✅ Ejecutada | Trigger en `res_users` |
| Backups | ✅ Programados | Diario a las 02:00 |
| UFW | ✅ Activo | Solo 22, 80, 443, 9090 |

### Pendiente

| Tarea | Prioridad |
|-------|-----------|
| Debian headless (eliminar GUI) | Media |
| Endurecer SSH (clave pública, no contraseña) | Media |
| Restringir SSH solo desde VLAN 10 | Media |
| Capturas de pantalla para la memoria | Alta |
| Redactar memoria del TFG | Alta |
| Preparar demostración para la defensa | Alta |

---

## Anexo: Planes de Fases y Pipeline (Histórico)

> *Nota: Este anexo resume los hitos documentados originalmente en `plan_fases_pendientes.md` y `plan_iac_github.md` durante el desarrollo del proyecto.*

### Resumen de Fases
- **Fase A (VLAN):** Verificación y endurecimiento de la segmentación entre VLAN 10 (LAN) y VLAN 30 (DMZ). Acceso solo a HTTPS (443) y bloqueos explícitos a PostgreSQL y Odoo directo.
- **Fase B (MACVLAN):** Asignación de IPs físicas de la VLAN30 a los contenedores (Nginx en `.20`, Odoo en `.21`).
- **Fase C (LDAP):** Despliegue de `odoo-ldap`, creación de usuarios de prueba y configuración del login centralizado en Odoo vía XML-RPC.
- **Fase D (Headless & Hardening):** Conversión de Debian a `multi-user.target` (sin GUI) y endurecimiento de SSH (claves públicas, restricción de acceso solo a VLAN de administración).

### Infraestructura como Código (IaC) y GitHub Actions
Se diseñó un pipeline CI/CD completo en GitHub donde el repositorio actúa como **fuente de verdad**:
- **CI Validator (`ci.yml`):** Ejecuta `shellcheck` en los scripts, valida la sintaxis de `docker-compose.yml` y lint de Markdown.
- **CD Deploy (`deploy.yml`):** Utiliza un **self-hosted runner** instalado en el servidor Debian para aplicar automáticamente los cambios en producción (MACVLAN, SSH, Docker, Roles).

---

## Estructura Final del Repositorio

```
TFG-ASIRB/
├── .github/workflows/
│   ├── ci.yml          # CI: ShellCheck + YAML + Markdown
│   └── deploy.yml      # CD: despliegue automático al servidor
├── config/logrotate.d/
│   └── erp-odoo        # Rotación semanal de logs
├── config_nginx/
│   └── odoo_proxy.conf # Proxy inverso Nginx + SSL + cabeceras seguridad
├── docker/
│   ├── .env            # Credenciales (excluido de Git)
│   ├── docker-compose.yml  # 4 servicios: DB, Odoo, LDAP, Nginx
│   └── odoo.conf       # Configuración interna de Odoo
├── docs/
│   ├── GUIA_DESPLIEGUE.md         # ← Cómo desplegar desde cero
│   ├── HISTORIAL_IMPLEMENTACION.md # ← Este archivo
│   ├── CHANGELOG.md               # Registro de cambios por versión
│   ├── implementation_plan.md     # Plan técnico detallado (con comandos)
│   ├── reglas_pfsense.md          # Reglas de firewall documentadas
│   ├── task.md                    # Lista de tareas por fase
│   └── mas_info/
│       ├── informe_erp.md         # Investigación técnica completa
│       └── investigacion.md
├── scripts/
│   ├── backup.sh           # Backup comprimido de PostgreSQL
│   ├── configure.sh        # Configuración interactiva del .env
│   ├── deploy.sh           # Despliegue del stack con healthcheck
│   ├── erp.sh              # Orquestador central (menú interactivo)
│   ├── install_cron.sh     # Instala tareas cron y logrotate
│   ├── ldap_crear_usuarios.sh   # Gestión de usuarios LDAP
│   ├── monitor.sh          # Monitor de salud + auto-reinicio
│   ├── odoo_crear_usuarios.sh   # Crea usuarios Odoo por XML-RPC
│   ├── odoo_setup_wizard.sh     # Post-instalación Odoo + LDAP
│   ├── restore.sh          # Restauración de backup
│   ├── setup_runner.sh     # Registra GitHub Actions runner
│   └── update.sh           # Actualización de imágenes Docker
├── sql/
│   └── audit_triggers.sql  # Auditoría PL/pgSQL en PostgreSQL
├── .env.example            # Plantilla pública de variables
├── .gitignore              # Excluye .env, certs, data/, ISOs/
├── CLAUDE.md               # Instrucciones para el asistente AI
├── install.sh              # Instalador todo-en-uno
└── README.md               # Documentación principal del proyecto
```
