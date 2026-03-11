# Plan de Implantación Detallado: Odoo ERP con pfSense y Docker (TFG ASIR)

Este documento contiene el desglose técnico y exhaustivo paso a paso para la implantación del escenario propuesto. Constituye tu hoja de ruta principal, con comandos exactos y código preparado para su uso.

---

## Fase 1: Preparación del Entorno Base y Red (pfSense)

### 1.1 Esquema de Direccionamiento IP

**1. Diagrama de Conexiones Lógicas**

```mermaid
graph TD
    WAN((Internet / WAN)) -->|DHCP Externo| PFSENSE[pfSense Firewall/Router]
    PFSENSE -->|Gateway: 192.168.30.1| DMZ[VLAN 30 - DMZ / Servidor Principal]
    PFSENSE -->|Gateway: 192.168.10.1| LAN_CLI[VLAN 10 - LAN Clientes]
    
    DMZ --> DOCKER_HOST[Servidor Único Linux Mint\n192.168.30.10]
    
    subgraph DOCKER_HOST [Servidor Único Linux Mint (192.168.30.10)]
        NGINX_PROXY[Contenedor Nginx\n(Puertos 80/443 al Host)]
        ODOO_DOCKER[Contenedor Odoo\n(Aislado en Red Docker)]
        PG_DOCKER[Contenedor PostgreSQL\n(Aislado en Red Docker)]
        NGINX_PROXY -.->|ProxyPass nombre_odoo| ODOO_DOCKER
    end

    LAN_CLI --> PC_CLIENTE[Cliente Windows/Linux\n192.168.10.x]
    PC_CLIENTE -.->|Petición Externa 443| DOCKER_HOST
```

**2. Tabla de Direccionamiento IP y Puertos Abiertos**

| Zona Configurada | Subred (CIDR) | Puerta de Enlace (pfSense) | IP del Sistema | Puertos en Uso (Destino) | Servicio Alojado |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **WAN (Exterior)** | Red Fija/DHCP | Router físico local | IP de la WAN | `80`, `443` (TCP) | Redirección NAT hacia la DMZ |
| **DMZ (VLAN 30)** | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.10`** | `80`, `443` (Web), `22` (SSH) | **Servidor Único (Mint):** Host Docker |
| **LAN Clientes (VLAN 10)**| `192.168.10.0/24` | `192.168.10.1` | `192.168.10.x` | *Ninguno hacia adentro* | Equipos de usuarios (Tráfico saliente) |
| *(Contenedor Nginx)* | Red Privada Docker | Switch Docker | Dinámica | `80`, `443` compartidos host| Proxy Inverso Alpine |
| *(Contenedor db)* | Red Privada Docker | Switch Docker | Dinámica | `5432` (TCP) | PostgreSQL 16 cerrado |
| *(Contenedor odoo)* | Red Privada Docker | Switch Docker | Dinámica | `8069` (TCP) | Odoo 17 cerrado |

### 1.2 Hipervisor y Máquinas Virtuales (VirtualBox / VMware)
1.  **pfSense (Firewall/Enrutador):**
    *   3 Adaptadores de red. Adaptador 1: NAT/Bridged (WAN). Adaptador 2: Red Interna "LAN" (VLAN 10). Adaptador 3: Red Interna "DMZ" (VLAN 30).
2.  **Servidor Linux Mint Unificado (Nginx + Docker/Odoo):**
    *   1 Adaptador de red conectado a la Red Interna "DMZ" (VLAN 30).
    *   IP Fija a configurar: `192.168.30.10`.
    *   *Se centraliza todo el aplicativo y proxy en el mismo anfitrión.*

---

## Fase 2: Configuración del Servidor Base (Linux Mint 22)

### 2.1 Preparación Inicial
Arrancar la VM del Servidor (VLAN 30) y abrir la terminal:

```bash
# Otorgar IP estática (editar la conexión de red a través del GUI de Mint o por comandos)
# Comprobar conectividad exterior a través de pfSense
ping -c 4 8.8.8.8

# Actualizar repositorios e instalar paquetes base del sistema
sudo apt update && sudo apt upgrade -y
sudo apt install curl nano git bash-completion htop -y
```

### 2.2 Instalación de Docker y Orquestación
```bash
# Instalar Docker y Docker Compose
sudo apt install docker.io docker-compose -y

# Habilitar el servicio para arranque automático
sudo systemctl enable --now docker

# Añadir tu usuario al grupo docker para evitar usar "sudo" en cada comando
sudo usermod -aG docker sandra

# Cerrar sesión o aplicar el cambio al shell actual
newgrp docker

# Comprobar la instalación
docker ps
```

---

## Fase 3: Orquestación de Odoo 17 y PostgreSQL 16 (Docker)

### 3.1 Estructura de Directorios
En el servidor Linux Mint, prepara el esquema de carpetas para el proyecto ERP:

```bash
mkdir -p /opt/erp-odoo/data/{postgres,odoo_addons,odoo_etc,odoo_web}
mkdir -p /opt/erp-odoo/{scripts,config_nginx,certs}
cd /opt/erp-odoo
```

### 3.2 Creación del Fichero `docker-compose.yml`
Crear el archivo base `nano docker-compose.yml` y pegar la siguiente configuración:

```yaml
version: '3.8'

services:
  db:
    image: postgres:16
    container_name: odoo-db
    restart: always
    environment:
      - POSTGRES_DB=odoo_erp
      - POSTGRES_PASSWORD=SuperSecretAdminPassword123
      - POSTGRES_USER=odoo
      - PGDATA=/var/lib/postgresql/data/pgdata
    volumes:
      - ./data/postgres:/var/lib/postgresql/data/pgdata
    # No se exponen puertos, aislado en la red interna de Docker

  odoo:
    image: odoo:17
    container_name: odoo-web
    restart: always
    depends_on:
      - db
    environment:
      - HOST=db
      - USER=odoo
      - PASSWORD=SuperSecretAdminPassword123
    volumes:
      - ./data/odoo_addons:/mnt/extra-addons
      - ./data/odoo_etc:/etc/odoo
      - ./data/odoo_web:/var/lib/odoo
    # No se exponen puertos al host, Nginx accede vía red Docker interna

  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: always
    depends_on:
      - odoo
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config_nginx:/etc/nginx/conf.d
      - ./certs:/etc/ssl/certs_local
```

**Ejecución Inicial:**
```bash
cd /opt/erp-odoo
docker-compose up -d
docker-compose logs -f   # Comprobar que no hay errores de sintaxis o conexión
```

---

## Fase 4: Automatización y Mantenimiento (Scripts Bash)

Deberás ubicar estos ficheros dentro de `/opt/erp-odoo/scripts/` y darles permisos de ejecución (`chmod +x *.sh`).

### 4.1 Script de Copia de Seguridad (`backup.sh`)
```bash
#!/bin/bash
# Realiza un dump en crudo de la BBDD PostgreSQL del contenedor Odoo

BACKUP_DIR="/opt/erp-odoo/backups"
FECHA=$(date +"%Y%m%d_%H%M%S")
DB_CONT="odoo-db"
DB_USER="odoo"
DB_NAME="odoo_erp"

mkdir -p $BACKUP_DIR

echo "Iniciando volcado de la BBDD de Odoo..."
docker exec -t $DB_CONT pg_dump -U $DB_USER -d $DB_NAME -F c -f /tmp/backup_$FECHA.dump

# Extraer el archivo desde el contenedor al host
docker cp $DB_CONT:/tmp/backup_$FECHA.dump $BACKUP_DIR/backup_$FECHA.dump
docker exec -t $DB_CONT rm /tmp/backup_$FECHA.dump

echo "Backup completado y guardado en $BACKUP_DIR/backup_$FECHA.dump"
```

### 4.2 Script de Restauración (`restore.sh`)
```bash
#!/bin/bash
# Restaura el último backup. Uso: ./restore.sh archivo.dump

if [ -z "$1" ]; then
    echo "Debe especificar el archivo de backup a restaurar."
    exit 1
fi

BKP_FILE=$1
DB_CONT="odoo-db"
DB_USER="odoo"
DB_NAME="odoo_erp"

echo "Copiando $BKP_FILE al contenedor..."
docker cp $BKP_FILE $DB_CONT:/tmp/restore.dump

echo "Restaurando base de datos. Se desconectarán usuarios activos..."
docker exec -t $DB_CONT dropdb -U $DB_USER $DB_NAME --if-exists
docker exec -t $DB_CONT createdb -U $DB_USER $DB_NAME
docker exec -t $DB_CONT pg_restore -U $DB_USER -d $DB_NAME -1 /tmp/restore.dump

docker exec -t $DB_CONT rm /tmp/restore.dump
echo "Restauración completada. Reiniciando contenedor Odoo..."
docker restart odoo-web
```

### 4.3 Tarea Cron Diaria
Para automatizar que el `backup.sh` se ejecute a las 02:00 AM todos los días:
```bash
crontab -e
# Y añadir al final del fichero:
0 2 * * * /opt/erp-odoo/scripts/backup.sh >> /var/log/odoo_backup.log 2>&1
```

---

## Fase 5: Auditoría en PostgreSQL (PL/pgSQL Trigger)

Para registrar las acciones de base de datos a un nivel más profundo. *(Estos comandos se ejecutan dentro del contenedor de base de datos o en un gestor como pgAdmin).*

```sql
-- Conectarse primero al contenedor: docker exec -it odoo-db psql -U odoo -d odoo_erp

-- 1. Crear tabla de auditoría para monitorizar acciones de inserción en res_users (usuarios Odoo)
CREATE TABLE IF NOT EXISTS asir_audit_log (
    audit_id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    table_name VARCHAR(50),
    record_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Crear función PL/pgSQL
CREATE OR REPLACE FUNCTION audit_users_action()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO asir_audit_log (action_type, table_name, record_id)
        VALUES ('CREACION USUARIO', TG_TABLE_NAME, NEW.id);
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el Disparador (Trigger) asociado a la tabla
CREATE TRIGGER tgr_audit_res_users
AFTER INSERT ON res_users
FOR EACH ROW
EXECUTE FUNCTION audit_users_action();
```

---

## Fase 6: Seguridad de Capa 2 Local (UFW)

Protegemos el único servidor en la DMZ (`192.168.30.10`). Ahora el tráfico Odoo (8069) está bloqueado por defecto porque el contenedor no exporta puertos. UFW solo debe permitir el tráfico a los puertos exportados del contenedor Nginx.

```bash
# Permitir SSH (Idealmente restringir IP de admin: ej. ufw allow from 192.168.10.x to any port 22)
sudo ufw allow 22/tcp

# Permitir HTTP y HTTPS hacia el contenedor Nginx
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Activar firewall
sudo ufw enable
```

---

## Fase 7: Publicación y Seguridad Perimetral (Nginx en Docker)

En lugar de instalar Nginx nativamente, configuraremos los archivos que leerá el contenedor.

### 7.1 Generación de Certificado SSL Autofirmado (Para Simulación)
Generamos las claves y las dejamos en la carpeta que leerá el volumen de Docker:
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/erp-odoo/certs/odoo-selfsigned.key -out /opt/erp-odoo/certs/odoo-selfsigned.crt
# (Rellenar los datos indicados al vuelo, especialmente el Common Name: erp.techsolutions.local)
```

### 7.2 Configuración del Proxy Inverso
Crear el Server Block en `/opt/erp-odoo/config_nginx/odoo_proxy.conf`:

```nginx
server {
    listen 80;
    server_name erp.techsolutions.local;
    # Redirigir de HTTP a HTTPS forzoso
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name erp.techsolutions.local;

    # Rutas dentro del contenedor leyendo del volumen de /certs
    ssl_certificate /etc/ssl/certs_local/odoo-selfsigned.crt;
    ssl_certificate_key /etc/ssl/certs_local/odoo-selfsigned.key;
    
    # Afinamiento de Seguridad SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # Bloque de Proxy Pass a Odoo (A través de la red interna Docker)
    location / {
        proxy_pass http://odoo-web:8069;
        proxy_http_version 1.1;
        
        # Cabeceras para que Odoo sepa la IP original del usuario que lo visita
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Aplicar la configuración:**
Como está todo en Docker, un simple `docker-compose restart nginx` en `/opt/erp-odoo` aplicará cualquier cambio.

### 7.3 Conexión con pfSense (Capa de Mario)
En el portal web de pfSense:
1. Ir a **Firewall > NAT > Port Forward**.
2. Crear una regla en la interfaz **WAN**, para el destino WAN Address hacia los puertos alias `80,443`.
3. Target IP (Redirect target): **La IP del Nginx de DMZ** (`192.168.30.10`).
4. Aplicar los cambios.

---

## Resumen de la Ejecución Final
1. Enciende las VMs en orden: pfSense y luego el Linux Mint unificado.
2. El cliente entra a `https://erp.techsolutions.local` desde WAN o la LAN local (VLAN 10).
3. El DNS de pfSense resuelve que esa URL apunta a la DMZ (`192.168.30.10`).
4. El Nginx del Linux Mint captura la petición en el puerto 443, la descifra, y la manda internamente al puerto `8069` del contenedor Odoo.
