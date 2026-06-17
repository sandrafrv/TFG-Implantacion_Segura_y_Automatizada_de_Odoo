# Vagrant — Infraestructura como Código

Esta carpeta contiene los scripts de aprovisionamiento de las **3 VMs** que forman el entorno del proyecto, orquestadas por el `Vagrantfile` de la raíz.

---

## Arquitectura de VMs

| VM Vagrant | Rol | IP | VLAN | Script de aprovisionamiento |
|:-----------|:----|:---|:-----|:----------------------------|
| `vm-pfsense` | Firewall / Router / NAT / DHCP | 192.168.10.1 / 30.1 / 40.1 | WAN + VLAN 10 + VLAN 30 + VLAN 40 | `provision_pfsense.sh` |
| `vm-odoo` | Debian 13 + Docker (Nginx + Odoo) | 192.168.30.10 | VLAN 30 (DMZ) | `provision_debian.sh` |
| `vm-postgres` | PostgreSQL 16 nativo (sin Docker) | 192.168.40.10 | VLAN 40 (BD) | `provision_postgres.sh` |

---

## Comandos principales

```bash
# Desde la raíz del repositorio
vagrant up          # Levantar las 3 VMs
vagrant up vm-odoo      # Levantar solo vm-odoo
vagrant provision vm-odoo   # Re-ejecutar el aprovisionamiento de vm-odoo
vagrant ssh vm-odoo      # Conectarse a la VM de Odoo
vagrant ssh vm-postgres    # Conectarse a la VM de PostgreSQL
vagrant ssh vm-pfsense    # Conectarse a la VM de pfSense
vagrant halt         # Apagar todas las VMs
vagrant destroy -f      # Destruir todas las VMs
vagrant status        # Estado de todas las VMs
```

---

## Contenido de esta carpeta

### `provision_debian.sh`

Aprovisiona `vm-odoo` (Debian 13 Trixie). Realiza:

1. Corrección de mirrors obsoletos de Debian y configuración de teclado en español.
2. Instalación de repositorios oficiales de Docker y cliente de PostgreSQL 16.
3. Creación del usuario `runner` y clonación del repositorio de GitHub usando un Personal Access Token (PAT).
4. Generación del archivo `.env` y creación de red MACVLAN (`macvlan_vlan30`).
5. Generación de certificados SSL autofirmados para el proxy inverso.
6. Levantamiento del stack de Docker (`odoo-web` + `nginx-proxy`).
7. Descarga, registro y arranque del servicio del **Self-Hosted Runner de GitHub Actions** (`odoo-runner`).
8. Modificación del enrutamiento permanente para usar pfSense (`192.168.30.1`) como gateway, eliminando la ruta NAT de Vagrant.

### `provision_pfsense.sh`

Aprovisiona `vm-pfsense` (FreeBSD/pfSense). Realiza:

1. Configuración de las 4 interfaces de red (WAN, VLAN 10, VLAN 30, VLAN 40)
2. Configuración de reglas básicas de firewall
3. Habilitación de NAT Port Forward (WAN:443 → 192.168.30.20:443)
4. Configuración de DHCP en VLAN 10 y VLAN 30

> **Nota:** La configuración completa de pfSense se puede generar con `scripts/deploy/generate_pfsense_config.sh` y aplicar desde el panel web de pfSense en `Diagnostics → Backup/Restore`.

### `provision_postgres.sh`

Aprovisiona `vm-postgres` (Debian 13 Trixie). Realiza:

1. Instalación de PostgreSQL 16 desde el repositorio oficial
2. Creación del usuario `odoo` y la base de datos `odooerp`
3. Configuración de `pg_hba.conf` para aceptar conexiones desde `192.168.30.0/24` (VLAN 30)
4. Configuración de `postgresql.conf` para escuchar en `0.0.0.0`
5. Aplicación de los triggers de auditoría PL/pgSQL (`sql/audit_triggers.sql`)

Ver también: [`Explicacion_provision_postgres.md`](Explicacion_provision_postgres.md)

### `Explicacion_provision_postgres.md`

Documento de referencia que explica en detalle el proceso de aprovisionamiento de PostgreSQL: por qué se decidió separar la BD en una VM externa, las implicaciones de seguridad y las diferencias con el diseño inicial (PostgreSQL en Docker).

---

## Redes configuradas por Vagrant

El `Vagrantfile` configura las siguientes redes virtuales en VirtualBox:

| Red | Tipo | Subred | Propósito |
|:----|:-----|:-------|:----------|
| `vboxnet0` | Host-only | `192.168.10.0/24` | VLAN 10 — Clientes |
| `vboxnet1` | Host-only | `192.168.30.0/24` | VLAN 30 — DMZ (Odoo + Nginx) |
| `vboxnet2` | Host-only | `192.168.40.0/24` | VLAN 40 — BD (PostgreSQL) |

---

## Requisitos

- **VirtualBox** 7.0+
- **Vagrant** 2.3+
- Al menos **8 GB de RAM** libre para las 3 VMs simultáneas
- **20 GB de espacio en disco** libre

---

## Troubleshooting

**`vm-odoo` no conecta con PostgreSQL:**
```bash
vagrant ssh vm-odoo
nc -zv 192.168.40.10 5432
# Si falla: revisar que vm-postgres está UP y la regla de pfSense VLAN30→VLAN40:5432
```

**Re-aprovisionar una VM desde cero:**
```bash
vagrant destroy vm-odoo -f
vagrant up vm-odoo
```

**Ver logs de aprovisionamiento:**
```bash
vagrant up vm-odoo --debug 2>&1 | tee vagrant_debug.log
```

---

*ASIR 2025/2026 — IES Cañaveral*
