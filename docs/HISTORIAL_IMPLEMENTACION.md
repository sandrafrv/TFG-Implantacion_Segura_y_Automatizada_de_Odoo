# Historial de Implementación — Cómo se construyó este repositorio
**TFG ASIR 2025/2026 — Sandra Fradejas Avedillo**

> [!NOTE]
> Este documento narra el proceso real de desarrollo: decisiones tomadas, problemas encontrados y cómo se resolvieron.
> Es la historia técnica del repositorio. **No es una guía de instalación.**
>
> **→ Guía de instalación desde cero:** [`docs/INSTALACION_COMPLETA.md`](INSTALACION_COMPLETA.md)

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

Elegido **Debian 13 (Trixie)** sobre Ubuntu/Mint porque:
- Ciclos de soporte más largos
- Es el sistema de referencia en la documentación oficial de Odoo
- Sin snaps ni paquetes propietarios
- `docker.io` disponible en repositorios oficiales

### Arquitectura de red inicial

Se decidió usar pfSense como firewall con tres zonas separadas:
- **WAN** — salida a Internet
- **LAN (VLAN 10, 192.168.10.0/24)** — equipos cliente
- **DMZ (VLAN 30, 192.168.30.0/24)** — servidor ERP

Dentro del servidor Debian, todos los servicios en contenedores Docker con red bridge interna. Solo Nginx expone puertos al host.

---

## v1.0 — Creación de la Infraestructura Base (2026-04-29)

**`docker/docker-compose.yml`** — Stack inicial con 3 servicios: `odoo_erp` (PostgreSQL 16), `odoo-web` (Odoo 17 CE), `nginx-proxy` (Nginx Alpine).

**`docker/odoo.conf`** — `proxy_mode = True`, `workers = 2`, `gevent_port = 8072`, `limit_time_real = 1200s`.

**`sql/audit_triggers.sql`** — Tabla `asir_audit_log` JSONB, función `func_audit_users()`, trigger `trg_audit_new_odoo_user`.

**`.github/workflows/ci.yml`** — CI: ShellCheck + YAML lint + Markdownlint.

---

## v1.1 — Automatización y Robustez (2026-04-30)

Problema resuelto: despliegue manual demasiado complejo.

- **`install.sh`** — instalador todo-en-uno
- **`.env.example` + `scripts/configure.sh`** — gestión segura de credenciales
- **`scripts/erp.sh`** — orquestador central con menú interactivo
- **`config/logrotate.d/erp-odoo`** — rotación semanal de logs
- Healthchecks nativos añadidos en `docker-compose.yml` (`pg_isready`, `curl /web/health`, `nginx -t`)
- `depends_on` con `service_healthy` para garantizar orden de arranque

Errores resueltos: `Permission denied` en `/var/lib/odoo/.local`, bucle de reinicio en Nginx, `longpolling_port` deprecado (renombrado a `gevent_port`).

---

## v1.2 — Auditoría SQL en Producción (2026-04-30)

Ejecución del trigger de auditoría y validación end-to-end:
```
audit_id=1, CREACION_USUARIO, res_users, id=8, 2026-04-30 12:13:57 UTC
```

---

## v1.3 — Pipeline CI/CD Completo (2026-04-30)

Runner self-hosted instalado en `/opt/actions-runner` como servicio systemd.

Errores resueltos: `permission denied` en `.env`, `dubious ownership` en git, comprobación de puertos con `docker ps` en lugar de `ss -tlnp`.

---

## v1.4 — Resolución de Fallo en Pipeline por .env Ausente (2026-05-06)

**Causa raíz:** El archivo `docker/.env` no existía en el servidor tras una limpieza. Sin las variables de entorno, Odoo no podía conectarse a PostgreSQL y la BD quedaba sin inicializar.

**Solución:** `docker compose down` → borrar datos corruptos → recrear `.env` → `docker compose up -d` limpio.

---

## Fase A — Verificación de Aislamiento VLAN (2026-05-08)

Desde el cliente VLAN 10:
- `nc -zv 192.168.30.10 5432` → **Timeout** ✅ (PostgreSQL bloqueado)
- `nc -zv 192.168.30.10 8069` → **Timeout** ✅ (Odoo directo bloqueado)
- `curl -k https://192.168.30.10` → **200/302** ✅ (Odoo accesible por Nginx)
- Desde DMZ, `ping 192.168.10.x` → **Sin respuesta** ✅ (aislado)

---

## Fase B — MACVLAN: IPs Físicas para Contenedores (2026-05-08)

Para que pfSense vea los contenedores como hosts físicos independientes:

```bash
docker network create --driver macvlan --subnet=192.168.30.0/24 \
  --gateway=192.168.30.1 --opt parent=ens18 macvlan_vlan30
```

- `nginx-proxy` → IP fija `192.168.30.20`
- `odoo-web` → IP fija `192.168.30.21`

**Limitación:** El host Debian no puede hacer ping a las IPs MACVLAN de sus propios contenedores. Verificar desde otro equipo o desde un contenedor temporal.

---

## Fase C — Integración LDAP (2026-05-06 → 2026-05-08) ⚠️ RETIRADA

> [!WARNING]
> **LDAP fue implementado y posteriormente retirado del despliegue activo.**
> Esta fase documenta el proceso histórico.
> El material está disponible en `extras/ldap/` y los scripts en `scripts/ldap/` (deprecados).

### Lo que se implementó

- Contenedor `odoo-ldap` (OpenLDAP 1.5.0) en `docker-compose.yml`
- Scripts `ldap_crear_usuarios.sh` y `ldap_politica_acceso.sh`
- ACLs de mínimo privilegio, SSSD + PAM en clientes VLAN 10

### Por qué se retiró

La integración LDAP añadía complejidad operativa significativa: contenedor adicional con estado persistente, variables extra en `.env`, mayor superficie de ataque. Para el entorno de demostración del TFG, la autenticación nativa de Odoo cubre todos los casos de uso necesarios. LDAP queda documentado como **mejora futura** en `extras/ldap/README.md`.

---

## v1.7 — Infraestructura como Código con Vagrant (2026-05-15)

### Motivación

1. PostgreSQL en Docker compartía recursos con Odoo y Nginx
2. No había aislamiento real de red para la BD (todo en bridge Docker)
3. La instalación manual era frágil y no reproducible

### Las 3 VMs definidas en el Vagrantfile

| VM | Nombre Vagrant | IP | Rol |
|:---|:---|:---|:---|
| VM1 | `pfsense` | dinámica WAN | Firewall + NAT + VPN |
| VM2 | `odoo-server` | `192.168.30.10` | Debian + Docker (Odoo + Nginx) |
| VM3 | `db-server` | `192.168.40.10` | PostgreSQL 16 nativo |

### Cambios principales en esta fase

- **`docker/docker-compose.yml`**: eliminados servicios `db` y `ldap`. Solo quedan `odoo-web` y `nginx-proxy`.
- **`docker/odoo.conf`**: `db_host` cambiado de `localhost` a `192.168.40.10`
- **`scripts/mantenimiento/backup_postgres.sh`**: nuevo script `pg_dump` remoto, cron cada 4h, credenciales en `/etc/backup_odoo.env` (chmod 600)
- **CI/CD**: ShellCheck extendido a `vagrant/`, verificación post-deploy solo comprueba `odoo-web` y `nginx-proxy`

---

## Estado Actual del Repositorio (Mayo 2026)

> [!NOTE]
> La tabla siguiente refleja el estado **real y actual** de la infraestructura.

| Componente | Estado | Notas |
|------------|--------|-------|
| pfSense (VM1) | ✅ Activo | 4 interfaces (WAN/VLAN10/DMZ/VLAN40), reglas verificadas |
| Debian 12 (VM2) | ✅ Activo | Docker + Cockpit, IP `192.168.30.10` |
| Docker stack | ✅ **2 contenedores** healthy | `odoo-web` y `nginx-proxy` únicamente |
| MACVLAN | ❌ **Descartada** | VMware host-only no permite promiscuous mode — bridge + port mapping |
| **LDAP** | ❌ **No activo** | Retirado del despliegue → ver `extras/ldap/` |
| PostgreSQL (VM3) | ✅ Activo | **Nativo** en `192.168.40.10`, fuera de Docker |
| DNS interno | ✅ Configurado | `erp.odoo.tfg.com` → `192.168.30.10` (host odoo-server) |
| CI/CD | ✅ Operativo | Runner activo, verifica 2 contenedores |
| Auditoría SQL | ✅ Ejecutada | Trigger en `res_users` de BD en VM3 |
| Backups | ✅ Programados | Cada 4h vía `pg_dump` remoto, retención 7 días |
| UFW (VM2) | ✅ Activo | Solo 22, 80, 443, 9090 |
| Control de acceso | ✅ Activo | Nginx rutas por IP + roles nativos de Odoo |
| VLAN 40 (Admin) | ✅ Configurada | Panel pfSense + SSH + Cockpit solo desde VLAN 40 |
| Vagrant (IaC) | ✅ Operativo | `vagrant up` despliega las 2 VMs Debian automáticamente |

### Pendiente para la defensa

| Tarea | Prioridad |
|-------|-----------|
| Debian headless (eliminar GUI) | Alta |
| SSH por clave pública | Alta |
| Capturas de pantalla para la memoria | Alta |
| Redactar memoria del TFG | Alta |
| Preparar demostración para la defensa | Alta |

---

## Estructura Final del Repositorio

```
Implantacion_Segura_y_Automatizada_de_Odoo/
├── Vagrantfile                  # Define las 2 VMs Debian (IaC) — pfSense es VM manual
├── .env                         # Variables de entorno (en la RAÍZ, no en docker/)
├── .env.example                 # Plantilla sin secretos ni variables LDAP
├── vagrant/                     # Scripts de aprovisionamiento de cada VM
│   ├── README.md                # Índice y guía de las VMs
│   ├── provision_debian.sh      # VM2: Docker + Nginx + Odoo + SSL + runner
│   ├── provision_postgres.sh    # VM3: PostgreSQL 16 nativo + runner
│   └── Vagrantfile.pfsense-box  # Vagrantfile experimental pfSense (referencia)
├── docker/                      # Solo 2 servicios: odoo-web + nginx-proxy
│   ├── docker-compose.yml       # SIN db, SIN ldap, bridge odoo_net
│   └── odoo.conf                # db_host = 192.168.40.10
├── config_nginx/
├── scripts/
│   ├── README.md
│   ├── deploy/
│   ├── mantenimiento/           # backup_postgres.sh, restore.sh, monitor.sh
│   ├── odoo/
│   └── ldap/                    # ⚠️ DEPRECADO
├── sql/
├── extras/ldap/                 # LDAP como mejora futura
└── docs/                        # Documentación técnica completa
```
