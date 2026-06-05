# Guía Maestra de Instalación desde Cero

**TFG ASIR 2025/2026 — Implantación Segura y Automatizada de Odoo ERP**
*Sandra Fradejas Avedillo — IES Cañaveral*

> [!IMPORTANT]
> Este es el **punto de entrada único**. Sigue las fases en orden.
> Cada sección resume lo esencial y enlaza a la guía técnica detallada.
>
> **→ Guía técnica completa:** [`guias/GUIA_COMPLETA.md`](guias/GUIA_COMPLETA.md)
> **→ Cuaderno de trabajo paso a paso:** [`guias/GUIA_TRABAJO_PASO_A_PASO.md`](guias/GUIA_TRABAJO_PASO_A_PASO.md)
> **→ Índice de documentación:** [`docs/README.md`](README.md)

---

## Prerequisitos

- **VMware Workstation** instalado en el equipo anfitrión (Windows)
- **Vagrant ≥ 2.3** + plugin `vagrant-vmware-desktop`:
  ```powershell
  winget install HashiCorp.Vagrant
  vagrant plugin install vagrant-vmware-desktop
  ```
- Variables de entorno configuradas en PowerShell antes de `vagrant up`:
  ```powershell
  $env:GH_PAT="ghp_tutoken"                 # Personal Access Token (scope: repo)
  $env:GH_RUNNER_TOKEN_ODOO="AXXXXX"         # Runner token para odoo-server
  $env:GH_RUNNER_TOKEN_DB="AYYYYY"           # Runner token para db-server
  $env:POSTGRES_PASSWORD="tu_password_seguro"
  ```
- Conexión a Internet en el equipo anfitrión
- Repositorio clonado localmente

---

## Arquitectura General

```
Internet (WAN)
     │ NAT 80/443
     ▼
[ pfSense — 4 interfaces ]
     │           │           │
  VLAN 10     VLAN 30     VLAN 40
  192.168.10  192.168.30  192.168.40
  Clientes    DMZ Server  Admin + BD
     │           │           │
  PCs           Debian 12   PCs Admin
                192.168.30.10  SSH/Cockpit/pfSense
                │
    ┌──────────────────────────────────┐
    │ nginx-proxy  :80/:443 (port map)  │  Docker bridge odoo_net
    │ odoo-web     :8069 (solo interno) │
    └──────────────────────────────────┘
                         │ TCP :5432
                 [ db-server — 192.168.40.10 ]
                   PostgreSQL 16 — VM nativa
```

> ⚠️ **LDAP no forma parte del despliegue principal.** Ver `extras/ldap/` si necesitas retomarlo.

---

## Tabla de Direccionamiento

| Componente | VLAN | IP | Acceso permitido |
|:-----------|:-----|:---|:----------------|
| pfSense gateway LAN | 10 | 192.168.10.1 | Solo VLAN 40 (panel) |
| pfSense gateway DMZ | 30 | 192.168.30.1 | — |
| pfSense gateway Admin/BD | 40 | 192.168.40.1 | Solo VLAN 40 |
| **odoo-server** — Debian 12 host | DMZ (VLAN 30) | 192.168.30.10 | SSH/Cockpit solo VLAN 40 — HTTPS todos |
| └─ **nginx-proxy** (Docker, port mapping) | DMZ (VLAN 30) | — (usa IP del host) | :80/:443 vía 192.168.30.10 |
| └─ **odoo-web** (Docker, red interna) | DMZ (VLAN 30) | — (red `odoo_net`) | Solo vía nginx-proxy |
| **db-server** — PostgreSQL 16 | BD (VLAN 40) | 192.168.40.10 | Solo :5432 desde VLAN 30 (Odoo) y VLAN 40 (admins) |

---

## Opción A — Despliegue Automático con Vagrant (Recomendado)

```bash
git clone https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git
cd TFG-Implantacion_Segura_y_Automatizada_de_Odoo
cp .env.example .env
nano .env              # Rellenar variables obligatorias
vagrant up             # Levanta las 3 VMs automáticamente
```

| VM Vagrant | Rol | IP | Provision script |
|---|---|---|---|
| `pfsense` | Firewall / Router / NAT | 192.168.10.1 / 30.1 / 40.1 | VM manual — importar config.xml desde panel |
| `odoo-server` | Debian 12 + Docker (Nginx + Odoo) | 192.168.30.10 | `vagrant/provision_debian.sh` |
| `db-server` | PostgreSQL 16 nativo | 192.168.40.10 | `vagrant/provision_postgres.sh` |

> **Nota:** pfSense (`pfsense`) usa `communicator: none` — Vagrant solo levanta la VM.
> La config se importa manualmente via `Diagnostics → Backup/Restore` (ver FASE 1).

---

## Opción B — Instalación Manual por Fases

### 🔷 FASE 1 — Red y Firewall (pfSense)

**Tiempo estimado: 45–60 min**

**→ Guía completa:** [`guias/GUIA_COMPLETA.md — Parte 1`](guias/GUIA_COMPLETA.md#parte-1--red-y-firewall-pfsense)

| Paso | Descripción |
|:-----|:------------|
| 1–2 | VM pfSense: 4 adaptadores (WAN / LAN VLAN 10 / DMZ VLAN 30 / Admin VLAN 40) |
| 3 | Asignación de interfaces en consola de texto |
| 4 | Acceso a la interfaz web desde LAN |
| 5 | Configuración OPT1 (VLAN 30 — DMZ) y OPT2 (VLAN 40 — Admin/BD) |
| 6 | DHCP: LAN (.100–.200) y VLAN 40 (.10–.50) |
| 7 | DNS Resolver: Host Override `erp.odoo.tfg.com → 192.168.30.10` (host odoo-server) |
| 8 | NAT: WAN:80/443 → `192.168.30.10` (Nginx expone puertos del host) |
| 9 | Reglas firewall: bloqueos anti-pivoting + permisos mínimos |
| 10 | Desactivar Anti-Lockout tras confirmar acceso VLAN 40 |

**Atajo:** `bash scripts/deploy/generate_pfsense_config.sh` genera el `config.xml` completo.
Importar en **Diagnostics → Backup/Restore**.

**Verificación rápida:**
```bash
nslookup erp.odoo.tfg.com   # → 192.168.30.10 desde VLAN 10
nc -zv 192.168.40.10 5432   # → Timeout (bloqueado) desde VLAN 10
```

---

### 🗄️ FASE 2 — VM PostgreSQL

**Tiempo estimado: 15–20 min**

**→ Documentación:** [`../vagrant/README.md`](../vagrant/README.md)

| Paso | Descripción |
|:-----|:------------|
| 1 | Crear VM Debian 13 mínima con IP estática `192.168.40.10` (VLAN 40) |
| 2 | Instalar PostgreSQL 16: `apt install postgresql-16` |
| 3 | Crear usuario y base de datos Odoo |
| 4 | Configurar `pg_hba.conf`: aceptar conexiones desde `192.168.30.0/24` |
| 5 | Configurar `postgresql.conf`: `listen_addresses = '192.168.40.10'` |
| 6 | Verificar conectividad desde vm-odoo: `nc -zv 192.168.40.10 5432` |

```bash
# En vm-postgres:
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD 'cambia_esto';
CREATE DATABASE odooerp OWNER odoo;
EOF
```

**Verificación rápida:**
```bash
# Desde vm-odoo:
psql -h 192.168.40.10 -U odoo -d odooerp -c '\l'
```

---

### 🖧 FASE 3 — Servidor Debian + Docker + Odoo

**Tiempo estimado: 30–60 min (+ 5 min primer arranque Odoo)**

**→ Guía completa:** [`guias/GUIA_COMPLETA.md — Parte 3`](guias/GUIA_COMPLETA.md#parte-3--servidor-debian--docker--odoo)

| Parte | Descripción |
|:------|:------------|
| Parte 1 | VM Debian 12: IP estática `192.168.30.10`, Docker, Cockpit, clonar repo, `.env` |
| Parte 2 | SSL autofirmado, `docker compose up -d`, 2 contenedores `healthy` (bridge + port mapping), cron |
| Parte 3 | Post-instalación Odoo: empresa, módulos, usuarios con roles, auditoría SQL |

**Atajo:** `sudo bash vagrant/provision_debian.sh` ejecuta las partes 1 y 2 automáticamente.

**Verificación rápida:**
```bash
docker compose -f docker/docker-compose.yml ps
# Resultado esperado: odoo-web (healthy), nginx-proxy (healthy)
curl -k -I https://erp.odoo.tfg.com   # → HTTP/2 200
```

---

### 🔐 FASE 4 — CI/CD + Hardening

**Tiempo estimado: 30–45 min**

**→ Guía completa:** [`guias/GUIA_COMPLETA.md — Partes 4 y 5`](guias/GUIA_COMPLETA.md#parte-4--cicd-con-github-actions)

| Parte | Descripción |
|:------|:------------|
| CI/CD | Self-hosted runner, pipeline CI (ShellCheck/YAML/Docker) + CD (deploy automático) |
| Hardening | UFW, SSH por clave pública, eliminar GNOME, headless |

> [!CAUTION]
> El hardening (SSH + headless) debe hacerse **siempre al final**, cuando todo lo demás funciona.

> [!NOTE]
> **LDAP (OpenLDAP)** fue implementado durante el desarrollo pero retirado del despliegue activo.
> Si necesitas integrarlo, ver `extras/ldap/README.md`.

**Verificación rápida:**
```bash
systemctl get-default          # → multi-user.target
sudo ufw status                # → active
```

---

## Orden de Arranque (tras Reinicio)

```
1. Arrancar pfSense VM       → esperar ~1 min (interfaces activas)
2. Arrancar vm-postgres VM   → PostgreSQL arranca automáticamente
3. Arrancar vm-odoo VM       → Docker arranca automáticamente
4. Esperar ~3 min            → Odoo inicializa (primer arranque)
5. Verificar desde VLAN 10   → https://erp.odoo.tfg.com
6. Verificar desde VLAN 40   → https://192.168.30.10:9090 (Cockpit)
```

---

## Checklist Final

```
FASE 1 — Red
  ✅ pfSense: 4 interfaces activas (WAN + VLAN 10 + 30 + 40)
  ✅ DHCP VLAN 10 y VLAN 40
  ✅ DNS: erp.odoo.tfg.com → 192.168.30.10
  ✅ NAT: WAN 80/443 → nginx-proxy en host (192.168.30.10)
  ✅ Reglas: anti-pivoting + permisos mínimos
  ✅ Panel pfSense: solo VLAN 40
  ✅ Anti-Lockout desactivado

FASE 2 — PostgreSQL
  ✅ vm-postgres: IP estática 192.168.40.10
  ✅ PostgreSQL 16 activo y escuchando en :5432
  ✅ Usuario y BD odoo creados
  ✅ pg_hba.conf: acepta conexiones desde 192.168.30.0/24
  ✅ Conectividad verificada desde vm-odoo

FASE 3 — Servidor Odoo
  ✅ odoo-server: IP estática 192.168.30.10
  ✅ Docker + Cockpit activos
  ✅ Bridge odoo_net: nginx-proxy (:80/:443 port mapping) + odoo-web (interno)
  ✅ 2 contenedores healthy (odoo-web + nginx-proxy)
  ✅ Odoo: empresa + módulos + usuarios con roles
  ✅ Auditoría SQL aplicada (audit_triggers.sql)
  ✅ Cron: backup_postgres.sh + monitor.sh

FASE 4 — Seguridad
  ✅ CI/CD: runner activo + pipeline funcional
  ✅ UFW: deny-all + 22/80/443/9090
  ✅ SSH: solo clave pública, sin root
  ✅ Debian headless: multi-user.target
```

---

## Documentación Relacionada

| Documento | Para qué sirve |
|:----------|:--------------|
| [`GUIA_COMPLETA.md`](guias/GUIA_COMPLETA.md) | **📘 Guía técnica unificada — pfSense + PostgreSQL + Odoo + CI/CD + Hardening** |
| [`GUIA_TRABAJO_PASO_A_PASO.md`](guias/GUIA_TRABAJO_PASO_A_PASO.md) | **📋 Cuaderno de trabajo — Narrativa paso a paso desde cero** |
| [`README.md`](README.md) | Índice completo de toda la documentación |
| [`CONTROL_ACCESO.md`](CONTROL_ACCESO.md) | Modelo de seguridad en 3 capas |
| [`reglas_pfsense.md`](reglas_pfsense.md) | Referencia completa de reglas pfSense |
| [`diagrama_red.md`](diagrama_red.md) | Diagramas de arquitectura |
| [`HISTORIAL_IMPLEMENTACION.md`](HISTORIAL_IMPLEMENTACION.md) | Historia del desarrollo |
| [`CHANGELOG.md`](CHANGELOG.md) | Registro de cambios |
| [`../vagrant/README.md`](../vagrant/README.md) | Aprovisionamiento Vagrant |
| [`../sql/README.md`](../sql/README.md) | Scripts de auditoría SQL |

---

*TFG ASIR 2025/2026 — IES Cañaveral*
