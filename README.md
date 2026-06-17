# TFC — Implantación Segura y Automatizada de Odoo 17

![Estado: Finalizado](https://img.shields.io/badge/Estado-Finalizado-success?style=for-the-badge)
![Versión: v1.0--TFC](https://img.shields.io/badge/Versi%C3%B3n-v1.0--TFC-blue?style=for-the-badge)

> **Proyecto de Fin de Ciclo — ASIR**
> Implantación de un sistema ERP Odoo 17 Community Edition en una infraestructura virtualizada, segmentada por VLANs, con despliegue automatizado mediante Vagrant, Docker y GitHub Actions.
> 
> **Estado del Proyecto:** ✅ Proyecto finalizado y entregado. La versión actual representa la implementación estable final.

---

## Índice

1. [Descripción del proyecto](#descripción-del-proyecto)
2. [Arquitectura de red](#arquitectura-de-red)
3. [Estructura del repositorio](#estructura-del-repositorio)
4. [Requisitos previos](#requisitos-previos)
5. [Variables de entorno](#variables-de-entorno)
6. [Puesta en marcha](#puesta-en-marcha)
7. [Stack Docker (odoo-server)](#stack-docker-odoo-server)
8. [PostgreSQL (db-server)](#postgresql-db-server)
9. [Nginx — Proxy inverso HTTPS](#nginx--proxy-inverso-https)
10. [GitHub Actions — CI/CD](#github-actions--cicd)
11. [Runners self-hosted](#runners-self-hosted)
12. [Scripts auxiliares](#scripts-auxiliares)
13. [Gestión de runners al destruir VMs](#gestión-de-runners-al-destruir-vms)
14. [Secrets de GitHub requeridos](#secrets-de-github-requeridos)
15. [Autoría y Licencia](#autoría-y-licencia)

---

## Descripción del proyecto

El proyecto despliega Odoo 17 CE como ERP empresarial sobre una infraestructura completamente virtualizada en VMware Workstation Pro. La arquitectura separa los servicios en VLANs distintas, con pfSense como cortafuegos y enrutador central, Docker para la contenerización de Odoo y Nginx en la DMZ, y PostgreSQL en una VM dedicada en la red de administración.

El ciclo completo de vida (aprovisionamiento → despliegue → actualización) está automatizado:
- **Vagrant** provisiona y configura las VMs Debian desde cero.
- **Docker Compose** levanta y gestiona los contenedores de Odoo y Nginx.
- **GitHub Actions** ejecuta el pipeline CI/CD sobre runners self-hosted instalados en las propias VMs.

---

## Arquitectura de red

```
┌─────────────────────────────────────────────────────────────────┐
│                     VMware Workstation Pro                      │
│                                                                 │
│  ┌──────────────┐    ┌──────────────────────────────────────┐   │
│  │   Host       │    │          pfSense (Firewall)          │   │
│  │  Windows     │    │   WAN: 192.168.133.x (vmnet8/NAT)    │   │
│  │              │◄──►│   LAN: 192.168.10.1  (vmnet1)        │   │
│  └──────────────┘    │   DMZ: 192.168.30.1  (vmnet2)        │   │
│                      │  ADMIN: 192.168.40.1  (vmnet3)       │   │
│                      └──────────────────────────────────────┘   │
│                             │           │           │           │
│                         vmnet1       vmnet2       vmnet3        │
│                          LAN          DMZ         ADMIN         │
│                       10.0/24       30.0/24      40.0/24        │
│                                        │            │           │
│                               ┌────────┴──┐  ┌─────┴───────┐    │
│                               │odoo-server│  │  db-server  │    │
│                               │192.168.   │  │192.168.     │    │
│                               │  30.10    │  │  40.10      │    │
│                               │           │  │             │    │
│                               │ ┌───────┐ │  │ PostgreSQL  │    │
│                               │ │Nginx  │ │  │    :5432    │    │
│                               │ │:80/443│ │  │             │    │
│                               │ └───┬───┘ │  └─────────────┘    │
│                               │ ┌───┴───┐ │                     │
│                               │ │ Odoo  │ │                     │
│                               │ │ :8069 │ │                     │
│                               │ └───────┘ │                     │
│                               └───────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

| VLAN | Red | VMnet | Propósito |
|------|-----|-------|-----------|
| LAN | 192.168.10.0/24 | vmnet1 | Usuarios internos |
| DMZ | 192.168.30.0/24 | vmnet2 | odoo-server (Odoo + Nginx) |
| ADMIN | 192.168.40.0/24 | vmnet3 | db-server (PostgreSQL) |
| WAN | 192.168.133.x | vmnet8 | Salida a Internet (NAT) |

> **Nota:** MACVLAN fue descartado. VMware host-only (VMnet2/3) no permite modo promiscuo, por lo que los contenedores MACVLAN no son alcanzables desde el host ni desde otros equipos de la misma red. El enrutamiento inter-VLAN lo realiza pfSense entre VMnet1/2/3.

---

## Estructura del repositorio

```
TFC-Implantacion_Segura_y_Automatizada_de_Odoo/
│
├── Vagrantfile                    # Orquestación de VMs (db-server + odoo-server)
├── .env.example                   # Plantilla de variables de entorno
├── .gitignore
├── .gitattributes
├── LICENSE
├── README.md
├── SECURITY.md                    # Política de seguridad
│
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Pipeline CI (validación)
│       ├── deploy.yml             # Pipeline CD (despliegue automático)
│       └── README.md
│
├── docker/
│   ├── docker-compose.yml         # Stack: odoo-web + nginx-proxy
│   └── odoo.conf                  # Configuración de Odoo 17
│
├── vagrant/
│   ├── provision_debian.sh        # Provisioning de odoo-server
│   ├── provision_postgres.sh      # Provisioning de db-server
│   ├── disable_nat_gateway.sh     # Configura pfSense como único gateway
│   └── README.md
│
├── config_nginx/
│   └── odoo_proxy.conf            # Configuración Nginx (proxy inverso HTTPS)
│
├── scripts/
│   ├── README.md                  # Índice y guía de uso de scripts
│   ├── deploy/                    # Scripts de despliegue y ciclo de vida
│   │   ├── deploy.sh              # Despliega y verifica el stack Docker
│   │   ├── erp.sh                 # Menú interactivo de administración
│   │   ├── configure.sh           # Configurador interactivo del .env
│   │   ├── install_cron.sh        # Instala tareas cron de mantenimiento
│   │   └── generate_pfsense_config.sh  # Genera config.xml para pfSense
│   ├── mantenimiento/             # Backups, monitor y actualizaciones
│   │   ├── backup_postgres.sh     # pg_dump remoto con retención 7 días
│   │   ├── restore.sh             # Restauración desde backup .sql.gz
│   │   ├── monitor.sh             # Chequeo de salud con auto-reinicio
│   │   └── update.sh              # Actualización de imágenes Docker
│   └── odoo/                      # Gestión de la instancia Odoo
│       └── odoo_crear_usuarios.sh # Crea usuarios y roles vía XML-RPC
│
├── config/                        # Configuraciones adicionales (logrotate)
├── sql/                           # Scripts SQL de auditoría PostgreSQL
└── docs/                          # Documentación del proyecto
```

---

## Requisitos previos

### Software en el host Windows

| Herramienta | Versión recomendada | Instalación |
|---|---|---|
| VMware Workstation Pro | 17+ | Manual |
| Vagrant | 2.4+ | `winget install HashiCorp.Vagrant` |
| Plugin vagrant-vmware-desktop | Última | `vagrant plugin install vagrant-vmware-desktop` |
| Git | 2.39+ | `winget install Git.Git` |

### VMnets requeridas en VMware

Antes de levantar las VMs, configurar manualmente las VMnets en VMware Network Editor:

- **vmnet1** → 192.168.10.0/24 (LAN)
- **vmnet2** → 192.168.30.0/24 (DMZ)
- **vmnet3** → 192.168.40.0/24 (ADMIN)

### pfSense

pfSense se configura manualmente en VMware Workstation como VM independiente. No se gestiona a través de Vagrant. Debe estar encendido antes de levantar las VMs Debian.

---

## Variables de entorno

Copiar `.env.example` a `.env` en la raíz del proyecto y rellenar los valores reales:

```bash
cp .env.example .env
```

| Variable | Descripción | Obligatoria |
|---|---|---|
| `POSTGRES_PASSWORD` | Contraseña del usuario `odoo` en PostgreSQL | Sí |
| `ODOO_MASTER_PASSWORD` | Contraseña maestra de Odoo | Sí |
| `GH_PAT` | Personal Access Token de GitHub (scope: `repo`) | Sí |
| `GH_RUNNER_TOKEN_ODOO` | Token de registro del runner de odoo-server | Sí (caduca en 1h) |
| `GH_RUNNER_TOKEN_DB` | Token de registro del runner de db-server | Sí (caduca en 1h) |

> **Importante:** Los tokens `GH_RUNNER_TOKEN_*` caducan a la hora de generarse. Generarlos justo antes de ejecutar `vagrant up`. Se obtienen en: **GitHub → Repositorio → Settings → Actions → Runners → New self-hosted runner**.

---

## Puesta en marcha

### Orden de arranque obligatorio

```
1. Encender pfSense manualmente en VMware
2. vagrant up db-server        ← SIEMPRE primero
3. vagrant up odoo-server
```

### Comandos Vagrant

```powershell
# Levantar ambas VMs (respeta el orden interno del Vagrantfile)
vagrant up

# Levantar una VM concreta
vagrant up db-server
vagrant up odoo-server

# Ver estado
vagrant status

# Acceder por SSH
vagrant ssh db-server
vagrant ssh odoo-server

# Apagar VMs
vagrant halt

# Destruir VMs (desregistra runners automáticamente)
vagrant destroy -f
```

---

## Stack Docker (odoo-server)

El servidor de Odoo (`192.168.30.10`) ejecuta dos contenedores Docker orquestados con Docker Compose.

### Contenedores

| Contenedor | Imagen | Puerto expuesto | Función |
|---|---|---|---|
| `odoo-web` | `odoo:17` | Interno (8069) | Aplicación ERP Odoo 17 CE |
| `nginx-proxy` | `nginx:alpine` | 80, 443 (host) | Proxy inverso HTTPS |

### Ejecutar el stack

```bash
# Desde /opt/erp-odoo en odoo-server
docker compose -p erp-odoo --env-file .env -f docker/docker-compose.yml up -d

# Ver estado
docker compose -f docker/docker-compose.yml ps

# Ver logs
docker logs odoo-web
docker logs nginx-proxy
```

### Volúmenes persistentes

| Volumen local | Montaje en contenedor | Propósito |
|---|---|---|
| `../addons` | `/mnt/extra-addons` | Módulos personalizados de Odoo |
| `../odoo-data` | `/var/lib/odoo` | Datos persistentes de Odoo |
| `./odoo.conf` | `/etc/odoo/odoo.conf` | Configuración de Odoo |
| `../odoo_sessions` | `/tmp/odoo` | Sesiones de usuario |
| `../config_nginx` | `/etc/nginx/conf.d` | Configuración de Nginx |
| `../certs` | `/etc/ssl/certs_local` | Certificados SSL |

### Red interna Docker

Ambos contenedores se comunican a través de la red bridge `odoo_net`. Nginx hace proxy hacia `http://odoo-web:8069` internamente, sin exponer Odoo al exterior.

---

## PostgreSQL (db-server)

PostgreSQL 16 se ejecuta **de forma nativa** (no contenerizado) en la VM `db-server` (`192.168.40.10`), en la VLAN de administración.

El contenedor `odoo-web` se conecta directamente a esta IP:

```yaml
environment:
  - HOST=192.168.40.10
  - USER=odoo
  - PASSWORD=${POSTGRES_PASSWORD}
```

El script `vagrant/provision_postgres.sh` se encarga de:
- Instalar PostgreSQL 16
- Crear el usuario `odoo` con los permisos necesarios
- Configurar `pg_hba.conf` para aceptar conexiones desde la VLAN DMZ (192.168.30.0/24)
- Registrar el runner `db-runner` en GitHub Actions

---

## Nginx — Proxy inverso HTTPS

Nginx actúa como única puerta de entrada al sistema. Recibe todas las peticiones HTTPS en el puerto 443 del host (`192.168.30.10`) y las reenvía al contenedor `odoo-web:8069`.

La configuración se encuentra en `config_nginx/odoo_proxy.conf` y cubre:
- Redirección HTTP → HTTPS (puerto 80 → 443)
- Terminación SSL con certificados autofirmados en `/etc/ssl/certs_local/`
- Headers de seguridad (`X-Frame-Options`, `X-Content-Type-Options`, etc.)
- Soporte de WebSocket para el cliente web de Odoo (`/websocket`)
- Configuración de `proxy_pass` hacia el contenedor interno

### Acceso a Odoo

```
https://192.168.30.10        → Odoo desde la red (IP directa)
https://erp.odoo.tfc.com     → Odoo desde LAN/Admin (requiere DNS en pfSense)
```

Para que el dominio `erp.odoo.tfc.com` resuelva correctamente, el DNS Resolver (Unbound) de pfSense debe tener configurada la entrada:

```
erp.odoo.tfc.com → 192.168.30.10
```

---

## GitHub Actions — CI/CD

El pipeline CI/CD se compone de dos workflows:

### CI — `ci.yml`

Se ejecuta en cada push o pull request a `main`. Realiza validaciones de sintaxis y estructura del proyecto.

### CD — `deploy.yml`

Se activa automáticamente cuando el workflow CI finaliza con éxito en la rama `main`. Ejecuta los siguientes pasos sobre el runner `odoo-server`:

1. **Verificar entorno** — muestra hostname, fecha y versión de Docker
2. **Marcar directorio como seguro** — evita el error de Git con `safe.directory`
3. **Sincronizar repositorio** — `git pull` con autenticación mediante `GH_PAT`
4. **Actualizar imágenes Docker** — `docker pull odoo:17` y `docker pull nginx:alpine`
5. **Ejecutar `deploy.sh`** — script de despliegue en `scripts/deploy/`
6. **Verificar contenedores** — comprueba que `odoo-web` y `nginx-proxy` están `running`; si alguno está caído, ejecuta `docker compose up -d` automáticamente
7. **Estado final** — muestra `docker compose ps` y hace health check de Odoo

---

## Runners self-hosted

> **⚠️ Nota para evaluación:** Los runners self-hosted se ejecutan en las máquinas virtuales locales de esta infraestructura. Si las VMs no están encendidas, los workflows de GitHub Actions se quedarán en estado "Pending" o los runners aparecerán como "Offline".

Cada VM tiene instalado un GitHub Actions runner que permite ejecutar los pipelines directamente sobre la infraestructura del TFC.

| Runner | VM | IP | Label |
|---|---|---|---|
| `odoo-runner` | odoo-server | 192.168.30.10 | `self-hosted`, `linux`, `odoo` |
| `db-runner` | db-server | 192.168.40.10 | `self-hosted`, `linux`, `db` |

### Registrar runners manualmente

Si las VMs se han levantado sin Vagrant o los tokens han caducado:

```bash
# 1. Generar token nuevo en GitHub:
#    Settings → Actions → Runners → New self-hosted runner

# 2. En odoo-server (192.168.30.10):
cd /opt/actions-runner
./config.sh \
  --url https://github.com/sandrafrv/TFC-Implantacion_Segura_y_Automatizada_de_Odoo \
  --token <TOKEN_NUEVO> \
  --name odoo-runner \
  --labels self-hosted,linux,odoo \
  --unattended
sudo ./svc.sh install
sudo ./svc.sh start

# 3. En db-server (192.168.40.10):
cd /opt/actions-runner
./config.sh \
  --url https://github.com/sandrafrv/TFC-Implantacion_Segura_y_Automatizada_de_Odoo \
  --token <TOKEN_NUEVO> \
  --name db-runner \
  --labels self-hosted,linux,db \
  --unattended
sudo ./svc.sh install
sudo ./svc.sh start
```

### Verificar estado de los runners

```bash
# En cualquier VM
sudo ./svc.sh status

# O en GitHub: Settings → Actions → Runners
```

---

## Scripts auxiliares

| Script | Ubicación | Descripción |
|---|---|---|
| `deploy.sh` | `scripts/deploy/` | Despliegue del stack Docker, llamado por el CD y `odoo-init.service` |
| `erp.sh` | `scripts/deploy/` | Menú interactivo de administración del ERP |
| `configure.sh` | `scripts/deploy/` | Configurador interactivo del `.env` |
| `install_cron.sh` | `scripts/deploy/` | Instala cron de backup/monitor/actualización (automático en `vagrant up`) |
| `generate_pfsense_config.sh` | `scripts/deploy/` | Genera `config.xml` completo para pfSense |
| `odoo_crear_usuarios.sh` | `scripts/odoo/` | Crea usuarios y roles en Odoo vía XML-RPC (automático al final de `deploy.sh`) |
| `backup_postgres.sh` | `scripts/mantenimiento/` | Backup `pg_dump` remoto con retención 7 días |
| `restore.sh` | `scripts/mantenimiento/` | Restauración desde backup `.sql.gz` |
| `monitor.sh` | `scripts/mantenimiento/` | Chequeo de salud de contenedores con auto-reinicio |
| `update.sh` | `scripts/mantenimiento/` | Actualización de imágenes Docker |

> Ver [`scripts/README.md`](scripts/README.md) para instrucciones de uso detalladas.

---

## Gestión de runners al destruir VMs

El `Vagrantfile` incluye triggers `before :destroy` que desregistran automáticamente los runners de GitHub usando la API REST antes de destruir cada VM:

```powershell
# Se ejecuta automáticamente con:
vagrant destroy db-server
vagrant destroy odoo-server
# o
vagrant destroy -f
```

El trigger utiliza `GH_PAT` para autenticarse en la API de GitHub, localizar el runner por nombre y eliminarlo del repositorio. Si el runner no existe en GitHub (ya fue eliminado manualmente), el trigger continúa sin error.

---

## Secrets de GitHub requeridos

Configurar en **GitHub → Repositorio → Settings → Secrets and variables → Actions**:

| Secret | Descripción |
|---|---|
| `GH_PAT` | Personal Access Token con scope `repo` |
| `POSTGRES_PASSWORD` | Contraseña de la base de datos PostgreSQL |

---

## Autoría y Licencia

**Autora:** Sandra ([@sandrafrv](https://github.com/sandrafrv))  
**Proyecto:** Trabajo de Fin de Ciclo (ASIR)

Este proyecto está bajo la licencia **GPL-3.0** (GNU General Public License v3.0). Consulta el archivo [`LICENSE`](LICENSE) para más detalles.
