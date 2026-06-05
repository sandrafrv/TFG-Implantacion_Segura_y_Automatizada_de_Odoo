# CLAUDE.md — Guía Técnica del Repositorio

Este archivo define cómo cualquier agente IA (Claude, Copilot, etc.) o colaborador debe comportarse en este repositorio. Se carga automáticamente en cada sesión de Claude Code.

---

## Contexto del Proyecto

**Proyecto:** TFG — Implantación Segura y Automatizada de Odoo
**Autora principal:** Sandra Fradejas Avedillo
**Grado:** ASIR — IES Cañaveral, curso 2025/2026
**Descripción:** Entorno productivo completo para el ERP Odoo 17 con 3 VMs orquestadas por Vagrant, pfSense como firewall perimetral, Nginx + Odoo en Docker (MACVLAN) y PostgreSQL en VM externa aislada en VLAN 40.

---

## Arquitectura Actual (Junio 2026)

| VM Vagrant | Rol | IP | VLAN |
|---|---|---|---|
| `pfsense` | Firewall / Router / NAT | 192.168.10.1 / 30.1 / 40.1 | WAN + VMnet1 + VMnet2 + VMnet3 |
| `odoo-server` | Debian 12 + Docker | 192.168.30.10 | VMnet2 (VLAN 30 — DMZ) |
| `db-server` | PostgreSQL 16 nativo | 192.168.40.10 | VMnet3 (VLAN 40 — Admin/BD) |

**Contenedores Docker activos** (solo en `odoo-server`, red bridge `odoo_net`):
- `odoo-web` — Odoo 17, puerto interno 8069, no expuesto al exterior
- `nginx-proxy` — Nginx Alpine, expone puertos 80/443 del host (192.168.30.10)

> ⚠️ **MACVLAN descartado**: VMware host-only (VMnet2/3) no permite modo promiscuo.
> Los contenedores MACVLAN no son alcanzables desde el host ni desde otras IPs de la red.
> La arquitectura actual usa bridge Docker + port mapping al host 192.168.30.10.

> ⚠️ Los servicios `db` (PostgreSQL) y `ldap` (OpenLDAP) han sido **eliminados** del `docker-compose.yml`. PostgreSQL está en `db-server` (`192.168.40.10`). LDAP está descartado — ver `extras/ldap/`.

---

## Estructura del Repositorio

```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
├── Vagrantfile                        # Define las 2 VMs Debian y sus redes (VMware)
├── scripts/setup_vmnet.ps1            # Configura VMnet1/2/3 antes de vagrant up
├── vagrant/                           # Scripts de aprovisionamiento
│   ├── provision_debian.sh             # Aprovisiona odoo-server (Docker, Nginx, SSL, runner)
│   ├── provision_postgres.sh           # Aprovisiona db-server (PG16, runner)
│   └── Vagrantfile.pfsense-box         # Vagrantfile experimental para pfSense (referencia)
├── docker/
│   ├── docker-compose.yml              # Solo odoo-web + nginx-proxy (bridge odoo_net)
│   └── odoo.conf                       # db_host = 192.168.40.10
├── scripts/
│   ├── deploy/
│   │   ├── deploy.sh                   # Verifica BD externa antes de levantar
│   │   ├── configure.sh                # Lee .env desde raíz del proyecto
│   │   ├── erp.sh                      # Menú interactivo de gestión
│   │   ├── install_cron.sh             # Cron cada 4h + /etc/backup_odoo.env
│   │   └── generate_pfsense_config.sh  # Genera config.xml para pfSense
│   ├── mantenimiento/
│   │   ├── backup_postgres.sh          # pg_dump remoto a 192.168.40.10
│   │   ├── backup.sh                   # Backup legacy (referencia)
│   │   ├── restore.sh                  # Restaura en BD externa
│   │   ├── monitor.sh                  # Solo odoo-web + nginx-proxy
│   │   └── update.sh                   # Actualiza imágenes Docker (con --env-file)
│   ├── odoo/
│   │   ├── odoo_crear_usuarios.sh
│   │   └── odoo_setup_wizard.sh
│   ├── ldap/                           # ⚠️ DESACTIVADO — solo referencia
│   └── repomix_lite.py                 # Volcado del repo para contexto LLM
├── sql/
│   └── audit_triggers.sql              # Triggers PL/pgSQL para auditoría
├── config_nginx/
│   └── odoo_proxy.conf                 # Config Nginx: SSL, WebSocket, headers
├── config/logrotate.d/
│   └── erp-odoo                        # Rota /var/log/backup_odoo.log y otros
├── extras/ldap/                       # LDAP descartado — mejora futura
├── docs/                              # Documentación técnica completa
├── .env.example                       # Plantilla sin variables LDAP
└── CLAUDE.md                          # Este archivo
```

---

## Comandos Frecuentes

### Vagrant

```bash
vagrant up                    # Levantar las 3 VMs
vagrant up vm-odoo            # Levantar solo la VM de Odoo
vagrant provision vm-odoo     # Re-ejecutar el aprovisionamiento
vagrant ssh vm-odoo           # Conectarse a la VM de Odoo
vagrant ssh vm-postgres       # Conectarse a la VM de PostgreSQL
vagrant halt                  # Apagar todas las VMs
vagrant destroy -f            # Destruir todas las VMs
```

### Docker (dentro de vm-odoo)

```bash
cd /opt/odoo
docker compose up -d          # Levantar odoo-web + nginx-proxy
docker compose down           # Parar contenedores
docker compose logs -f        # Ver logs en tiempo real
docker compose ps             # Estado de los contenedores
```

> ⚠️ El servicio `db` y `ldap` ya NO existen en el `docker-compose.yml`.

### Ver logs de PostgreSQL (vm-postgres)

```bash
vagrant ssh vm-postgres
sudo journalctl -u postgresql -f
sudo tail -f /var/log/postgresql/*.log
```

### Scripts de despliegue

```bash
bash scripts/deploy/deploy.sh         # Verificar BD externa y desplegar
bash scripts/deploy/configure.sh      # Configurar (lee .env desde raíz)
bash scripts/deploy/erp.sh            # Menú interactivo de gestión
bash scripts/deploy/install_cron.sh   # Instalar cron de backup (cada 4h)
```

### Mantenimiento

```bash
bash scripts/mantenimiento/backup_postgres.sh   # Backup remoto via pg_dump
bash scripts/mantenimiento/restore.sh <backup>  # Restaurar en BD externa
bash scripts/mantenimiento/monitor.sh           # Estado de contenedores
bash scripts/mantenimiento/update.sh            # Actualizar imágenes Docker
```

### Verificar conectividad BD (troubleshooting)

```bash
vagrant ssh vm-odoo
nc -zv 192.168.40.10 5432
psql -h 192.168.40.10 -U odoo -d odooerp -c '\l'
```

---

## Variables de Entorno

El archivo `.env` debe estar en la **raíz del proyecto**, no dentro de `docker/`.

```bash
cp .env.example .env
nano .env
```

Variables mínimas requeridas:

```env
ODOO_ADMIN_PASSWD=cambia_esto
DB_HOST=192.168.40.10
DB_PORT=5432
DB_USER=odoo
DB_PASSWORD=cambia_esto
DOMAIN=tu_dominio_o_ip
```

> Las variables de LDAP han sido eliminadas de `.env.example`.

---

## Credenciales de Backup

`install_cron.sh` crea `/etc/backup_odoo.env` con permisos 600 (solo root). Los scripts `backup_postgres.sh` y `restore.sh` leen las credenciales de este archivo.

```bash
# /etc/backup_odoo.env (generado automáticamente, no tocar a mano)
DB_HOST=192.168.40.10
DB_USER=odoo
DB_PASSWORD=...
```

---

## CI/CD — GitHub Actions

| Archivo | Qué hace |
|---|---|
| `.github/workflows/ci.yml` | `shellcheck` en `scripts/` y `vagrant/`; `yamllint`; `docker compose config -q` |
| `.github/workflows/deploy.yml` | Despliega y verifica `odoo-web` + `nginx-proxy` (sin PostgreSQL ni LDAP) |

---

## Convenciones del Proyecto

1. **Bash:** Todos los scripts deben pasar `shellcheck` sin errores.
2. **Variables de entorno:** Usar `.env` en raíz. Nunca hardcodear credenciales.
3. **PostgreSQL:** Siempre apuntar a `192.168.40.10`. Nunca usar `localhost` ni contenedor `db`. Base de datos: `odoo_erp`.
4. **LDAP:** No añadir dependencias LDAP al despliegue principal. Todo va en `extras/ldap/`.
5. **Logs de backup:** El cron escribe en `/var/log/backup_odoo.log`, rotado por logrotate.
6. **VMware / Vagrant:** El hipervisor es **VMware Workstation** con plugin `vagrant-vmware-desktop`. Las subredes VMnet1/2/3 las gestiona `scripts/setup_vmnet.ps1`.
7. **Runners CI/CD:** `odoo-runner` en `odoo-server` (labels: `self-hosted,linux,odoo`) y `db-runner` en `db-server` (labels: `self-hosted,linux,db`).
8. **Idioma:** Toda la documentación en español.
9. **Tono:** Técnico pero claro — orientado al tutor del TFG.

---

## Documentación Automática

Cada vez que se realice un cambio técnico en el repositorio, documentar en este orden:

```
1. Implementar el cambio técnico
2. Actualizar docs/CHANGELOG.md
3. Actualizar docs/HISTORIAL_IMPLEMENTACION.md si afecta a una fase
4. Actualizar docs/reglas_pfsense.md si hay cambios de firewall
5. Informar: "✅ Cambio realizado y documentado en docs/"
```

---

## Detección Automática de Problemas de Seguridad

Siempre que se revisen archivos, alertar si se detecta:

- 🔴 **CRÍTICO:** Contraseñas o tokens hardcodeados en código fuente
- 🟠 **ADVERTENCIA:** Puertos expuestos innecesariamente en docker-compose
- 🟡 **AVISO:** Variables sensibles sin usar `.env`
- 🔵 **INFO:** Configuración mejorable pero no crítica

---

## Solución de Problemas Frecuentes

**Odoo no conecta con la BD:**
```bash
vagrant ssh vm-odoo
nc -zv 192.168.40.10 5432
# Si falla, revisar reglas de firewall en pfSense (VLAN 30 → VLAN 40)
```

**El script deploy.sh falla en el check de BD:**
```bash
cat .env | grep DB_HOST   # Debe ser 192.168.40.10
```

**El cron de backup no funciona:**
```bash
ls -la /etc/backup_odoo.env    # Debe ser -rw------- root root
tail -f /var/log/backup_odoo.log
```

**Los contenedores no arrancan:**
```bash
docker compose logs odoo-web
docker compose logs nginx-proxy
# Verificar que .env está en la raíz y no en docker/
```
