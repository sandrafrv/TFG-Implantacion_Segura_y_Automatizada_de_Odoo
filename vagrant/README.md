# vagrant/ — Aprovisionamiento de las 3 VMs

Esta carpeta contiene todos los scripts de aprovisionamiento que Vagrant ejecuta automáticamente al hacer `vagrant up`. Cada script configura una de las tres máquinas virtuales del proyecto.

---

## VMs del proyecto

| VM | Script | IP | VLAN | Rol |
|---|---|---|---|---|
| `vm-pfsense` | `provision_pfsense.sh` | 192.168.10.1 / 30.1 / 40.1 | WAN+10+30+40 | Firewall / Router / NAT |
| `vm-odoo` | `provision_debian.sh` | 192.168.30.10 | VLAN 30 (DMZ) | Debian 13 + Docker |
| `vm-postgres` | `provision_postgres.sh` | 192.168.40.10 | VLAN 40 (BD) | PostgreSQL 16 nativo |

---

## Archivos

### `provision_debian.sh`
Aprovisiona la VM de Odoo/Nginx (VLAN 30):
- Clona el repositorio en `/opt/odoo`
- Instala Docker Engine y Docker Compose
- Instala y configura Nginx
- Genera certificados SSL autofirmados
- Crea la red `macvlan_vlan30`
- Despliega `docker-compose.yml` (solo `odoo-web` + `nginx-proxy`)

### `provision_pfsense.sh`
Aprovisiona la VM de pfSense (firewall):
- Si existe `vagrant/config.xml`, lo aplica automáticamente
- Si no existe, muestra los pasos manuales de configuración
- Para generar `config.xml`: `bash scripts/deploy/generate_pfsense_config.sh`

### `provision_postgres.sh`
Aprovisiona la VM de PostgreSQL (VLAN 40):
- Instala PostgreSQL 16 nativo (sin Docker)
- Crea el usuario y base de datos `odoo`
- Configura `pg_hba.conf` para aceptar conexiones desde VLAN 30 (`192.168.30.0/24`)
- Configura `listen_addresses = '*'` en `postgresql.conf`

### `Explicacion_provision_postgres.md`
Documento explicativo con la lógica del aprovisionamiento de PostgreSQL: por qué está fuera de Docker, cómo se conecta Odoo a él y qué reglas de pfSense son necesarias.

---

## Uso rápido

```bash
# Levantar las 3 VMs de golpe
vagrant up

# Levantar una sola VM
vagrant up vm-odoo
vagrant up vm-postgres
vagrant up vm-pfsense

# Re-ejecutar el aprovisionamiento sin destruir la VM
vagrant provision vm-odoo

# Conectarse a una VM
vagrant ssh vm-odoo
vagrant ssh vm-postgres

# Apagar y destruir
vagrant halt
vagrant destroy -f
```

---

## Orden de aprovisionamiento recomendado

1. `vagrant up vm-postgres` — La BD debe estar lista antes que Odoo
2. `vagrant up vm-pfsense` — El firewall debe estar listo antes de configurar reglas
3. `vagrant up vm-odoo` — Odoo se conectará a la BD al arrancar

> Si se levanta todo con `vagrant up`, Vagrant gestiona el orden automáticamente según esté definido en el `Vagrantfile`.

---

## Requisitos previos

- [VirtualBox](https://www.virtualbox.org/) instalado
- [Vagrant](https://www.vagrantup.com/) instalado
- `.env` creado en la raíz del proyecto (`cp .env.example .env`)
- Al menos **8 GB de RAM** disponibles en el host (las 3 VMs juntas)
