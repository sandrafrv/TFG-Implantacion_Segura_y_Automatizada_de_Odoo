# Vagrant — Infraestructura como Código

**TFG ASIR 2025/2026 — TechSolutions S.L.**

Esta carpeta contiene los scripts de aprovisionamiento automático para las **3 máquinas virtuales** del entorno. Vagrant orquesta la creación y configuración de todas ellas a partir del `Vagrantfile` en la raíz del proyecto.

---

## Requisitos Previos

- [Vagrant](https://www.vagrantup.com/) ≥ 2.3
- [VirtualBox](https://www.virtualbox.org/) ≥ 7.0
- `.env` configurado en la raíz del proyecto (`cp .env.example .env` y rellenar)

---

## Arranque del Entorno Completo

```bash
# Clonar el repositorio
git clone https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo.git
cd TFG-Implantacion_Segura_y_Automatizada_de_Odoo

# Configurar variables de entorno
cp .env.example .env
nano .env

# Levantar las 3 VMs en orden
vagrant up
```

> `vagrant up` levanta primero `vm-pfsense`, luego `vm-odoo` y por último `vm-postgres`.
> El orden importa porque pfSense debe estar operativo antes de que las demás VMs configuren sus rutas.

---

## Las 3 VMs del Proyecto

| VM | Rol | IP Principal | VLAN | RAM recomendada |
|:---|:----|:------------|:-----|:----------------|
| `vm-pfsense` | Firewall / Router / NAT / DHCP | `192.168.10.1` / `192.168.30.1` / `192.168.40.1` | WAN + VLAN 10 + VLAN 30 + VLAN 40 | 512 MB |
| `vm-odoo` | Debian 13 + Docker (Nginx + Odoo) | `192.168.30.10` | VLAN 30 (DMZ) | 2 GB |
| `vm-postgres` | PostgreSQL 16 nativo | `192.168.40.10` | VLAN 40 (Admin/BD) | 1 GB |

---

## Scripts de Aprovisionamiento

### `provision_pfsense.sh`
Aprovisiona la VM de pfSense:
- Configura las 4 interfaces de red (WAN + VLAN 10 + VLAN 30 + VLAN 40)
- Aplica DHCP en cada VLAN
- Habilita NAT para salida a Internet desde VLAN 30
- Prepara el entorno para la importación del `config.xml` generado por `scripts/deploy/generate_pfsense_config.sh`

### `provision_debian.sh`
Aprovisiona `vm-odoo` (Debian 13 Trixie):
- Configura IP estática en VLAN 30 (`192.168.30.10`)
- Instala Docker CE + Docker Compose plugin (repositorio oficial Docker)
- Instala Cockpit para administración web en `:9090`
- Clona el repositorio en `/opt/odoo/`
- Crea el archivo `.env` en la raíz del proyecto
- Genera certificados SSL autofirmados con OpenSSL
- Levanta el stack Docker (`odoo-web` + `nginx-proxy`)
- Instala el cron de backups remotos (cada 4 horas) vía `install_cron.sh`
- Instala el self-hosted runner de GitHub Actions como servicio systemd

> ⚠️ Solo corren **2 contenedores**: `odoo-web` y `nginx-proxy`.
> PostgreSQL **no** corre en Docker — está en `vm-postgres`.
> LDAP fue descartado — ver `extras/ldap/`.

### `provision_postgres.sh`
Aprovisiona `vm-postgres` (Debian 13 Trixie):
- Configura IP estática en VLAN 40 (`192.168.40.10`)
- Instala PostgreSQL 16 desde el repositorio oficial PGDG
- Crea el usuario `odoo` y la base de datos `odooerp`
- Configura `postgresql.conf`: `listen_addresses = '192.168.40.10'`
- Configura `pg_hba.conf`: acceso solo desde `192.168.30.0/24` (VLAN 30 — Odoo)
- Aplica los triggers de auditoría (`sql/audit_triggers.sql`)
- Configura UFW: solo acepta `:5432` desde `192.168.30.0/24`

Ver [`Explicacion_provision_postgres.md`](Explicacion_provision_postgres.md) para el detalle técnico del aprovisionamiento de PostgreSQL.

---

## Comandos Vagrant Útiles

```bash
# Estado de todas las VMs
vagrant status

# Levantar una VM concreta
vagrant up vm-odoo

# Re-ejecutar el aprovisionamiento
vagrant provision vm-odoo

# Conectarse por SSH
vagrant ssh vm-odoo
vagrant ssh vm-postgres
vagrant ssh vm-pfsense

# Apagar todas las VMs
vagrant halt

# Destruir todo (⚠️ elimina datos)
vagrant destroy -f

# Reiniciar y re-aprovisionar desde cero
vagrant destroy -f && vagrant up
```

---

## Troubleshooting

**Odoo no conecta con PostgreSQL tras `vagrant up`:**
```bash
vagrant ssh vm-odoo
nc -zv 192.168.40.10 5432
# Si falla: revisar que vm-postgres está en estado running y las reglas pfSense VLAN30→VLAN40
```

**El runner de GitHub Actions no arranca:**
```bash
vagrant ssh vm-odoo
sudo systemctl status actions.runner.*.service
```

**PostgreSQL no acepta conexiones:**
```bash
vagrant ssh vm-postgres
sudo systemctl status postgresql
sudo cat /etc/postgresql/16/main/pg_hba.conf
```

---

*Diagrama de red completo: [`docs/diagrama_red.md`](../docs/diagrama_red.md)*
*Guía de instalación manual: [`docs/INSTALACION_COMPLETA.md`](../docs/INSTALACION_COMPLETA.md)*
