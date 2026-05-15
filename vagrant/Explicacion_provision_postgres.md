El script vagrant/provision_postgres.sh es el fichero que Vagrant ejecuta automáticamente dentro de la VM de base de datos (la VM 3 — db-server) justo después de crearla, para dejarla lista sin que toques nada manualmente.

Qué hace línea por línea
bash
set -e
Si cualquier comando falla, el script para inmediatamente. Evita que continúe con errores silenciosos.

bash
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-changeme_db}"
Coge la contraseña del entorno (la que le pasa el Vagrantfile) o usa changeme_db como valor por defecto si no se la pasan.

bash
apt-get update -qq
apt-get install -y postgresql-16 postgresql-client-16
systemctl enable --now postgresql
Instala PostgreSQL 16 y lo arranca como servicio del sistema.

bash
sudo -u postgres psql <<EOF
CREATE USER odoo WITH PASSWORD '${POSTGRES_PASSWORD}';
CREATE DATABASE odoo_erp OWNER odoo;
GRANT ALL PRIVILEGES ON DATABASE odoo_erp TO odoo;
EOF
Crea el usuario odoo y la base de datos odoo_erp dentro de PostgreSQL.

bash
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "host odoo_erp odoo 192.168.30.0/24 md5" >> "$PG_HBA"
systemctl restart postgresql
Estas tres líneas son las más importantes de seguridad. Hacen dos cosas:

listen_addresses = '*' → PostgreSQL escucha en todas las interfaces (por defecto solo escucha en localhost y Odoo no podría conectarse desde otra VM)

Regla pg_hba.conf → Solo permite conexiones desde la red 192.168.30.0/24 (la VLAN de Odoo), con usuario odoo, con contraseña MD5. Nadie más puede conectarse.

¿Está bien?
✅ Sí, el script está correcto. Pero hay una cosa a tener en cuenta: la línea del sed busca exactamente este texto:

text
#listen_addresses = 'localhost'
En Debian/Ubuntu con PostgreSQL 16, ese comentario existe por defecto, así que funcionará. Si por algún motivo ya estuviera descomentado, el sed no haría nada y tendrías que editarlo a mano.

Flujo completo cuando haces vagrant up
text
vagrant up db-server
       │
       ▼
VMware crea la VM (Debian, 2 GB RAM, IP 192.168.40.10)
       │
       ▼
Vagrant ejecuta provision_postgres.sh dentro de la VM
       │
       ▼
PostgreSQL 16 instalado + usuario odoo + BD odoo_erp
       │
       ▼
Acepta conexiones solo desde 192.168.30.0/24 (Odoo)
Cuando luego levantes la VM de Odoo, apuntará a 192.168.40.10:5432 y se conectará directamente a esta base de datos.
