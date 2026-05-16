El script `vagrant/provision_postgres.sh` es el fichero que Vagrant ejecuta automáticamente dentro de la VM de base de datos (la **VM 3 — db-server**) justo después de crearla, para dejarla lista sin intervención manual.

Esta VM se despliega en la **VLAN 40 (Administración y Base de Datos)** con la IP `192.168.40.10`.

---

## Qué hace paso a paso

### 1. Espera de Red y Configuración Base
```bash
set -e
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
```
Carga la contraseña desde el entorno (pasada por el `Vagrantfile`) o usa `changeme_db` como fallback.
A continuación, realiza comprobaciones de conectividad y corrige los mirrors obsoletos de la imagen base de Debian Bookworm, forzando la distribución del teclado a español.

### 2. Instalación de PostgreSQL 16
```bash
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg trusted=yes] \
https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list
apt-get install -y postgresql-16 postgresql-client-16
```
Añade el repositorio oficial de PostgreSQL (pgdg) para instalar la versión 16, en lugar de la versión por defecto de Debian, y lo arranca como servicio del sistema.

### 3. Creación de Usuario y Base de Datos
```bash
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
EOF
```
Crea el rol `odoo` y la base de datos `odoo_erp`, asignando los permisos correspondientes.

### 4. Aislamiento de Red (Seguridad Crítica)
```bash
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "host  odoo_erp  odoo  192.168.30.0/24  md5" >> "$PG_HBA"
systemctl restart postgresql
```
Estas líneas garantizan que:
1. `listen_addresses = '*'` → PostgreSQL escucha en todas las interfaces de la VM.
2. `pg_hba.conf` → Solo permite conexiones desde la subred **`192.168.30.0/24` (DMZ donde está Odoo)**. Ninguna otra red (como la LAN de empleados) podrá alcanzar la base de datos, aunque descubran la IP.

### 5. Instalación del Runner de GitHub Actions
El script descarga e instala automáticamente un **Self-Hosted Runner** de GitHub Actions:
- Verifica la existencia del token (`GH_RUNNER_TOKEN`).
- Crea un usuario `runner` sin privilegios.
- Descarga el binario de actions-runner.
- Registra el runner en el repositorio apuntando a la VM3 con las etiquetas `self-hosted, linux, db`.
- Arranca el runner como servicio `systemd`.

### 6. Enrutamiento Persistente (VLAN 40)
```bash
cat > /etc/network/interfaces.d/vlan40-routes <<NETEOF
...
post-up ip route add default via 192.168.40.1 dev eth1
...
```
Debido a que Vagrant usa una interfaz NAT (`eth0`) por defecto para administrar la máquina, el script elimina la ruta por defecto de Vagrant y configura a **pfSense (`192.168.40.1`)** como gateway principal persistente, forzando que todo el tráfico de la VM pase por el firewall del proyecto.

---

## Flujo completo cuando haces `vagrant up db-server`

```text
       vagrant up db-server
               │
               ▼
VirtualBox crea la VM (Debian, 2 GB RAM, eth1: 192.168.40.10)
               │
               ▼
Vagrant ejecuta provision_postgres.sh dentro de la VM
               │
               ▼
1. Repositorios y red NAT inicial verificados
2. PostgreSQL 16 instalado + usuario 'odoo' + BD 'odoo_erp'
3. Conexiones filtradas solo desde 192.168.30.0/24 (DMZ)
4. GitHub Actions Runner registrado como 'db-runner'
5. Enrutamiento modificado: Gateway = pfSense (192.168.40.1)
               │
               ▼
       ¡VM 3 LISTA PARA USAR!
```
Cuando posteriormente se levanta la **VM 2 (odoo-server)** en la DMZ, el contenedor de Odoo apunta directamente a `192.168.40.10:5432` y el acceso se realiza con éxito gracias a las reglas configuradas aquí y en pfSense.
