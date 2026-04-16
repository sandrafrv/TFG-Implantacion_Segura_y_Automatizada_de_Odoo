# Plan de Implantación Detallado: Odoo ERP con pfSense y Docker (TFG ASIR)

Este documento contiene el desglose técnico y exhaustivo paso a paso para la implantación del escenario propuesto. Constituye nuestra hoja de ruta principal, con comandos exactos y código preparado para su uso.

---

## Fase 1: Preparación del Entorno Base y Red (pfSense)

### 1.1 Esquema de Direccionamiento IP

**1. Diagrama de Conexiones Lógicas**

```mermaid
graph TD
    WAN((Internet / WAN)) -->|DHCP Externo| PFSENSE[pfSense Firewall/Router]
    PFSENSE -->|Gateway: 192.168.30.1| DMZ[VLAN 30 - DMZ / Servidor Principal]
    PFSENSE -->|Gateway: 192.168.10.1| LAN_CLI[VLAN 10 - LAN Clientes]
    
    DMZ --> DOCKER_HOST[Servidor Único Debian 12\n192.168.30.10]
    
    subgraph DOCKER_HOST [Servidor Único Debian 12 (192.168.30.10)]
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
| **DMZ (VLAN 30)** | `192.168.30.0/24` | `192.168.30.1` | **`192.168.30.10`** | `80`, `443` (Web), `22` (SSH), `9090` (Cockpit) | **Servidor Único (Debian):** Host Docker y GUI |
| **LAN Clientes (VLAN 10)**| `192.168.10.0/24` | `192.168.10.1` | `192.168.10.x` | *Ninguno hacia adentro* | Equipos de usuarios (Tráfico saliente) |
| *(Contenedor Nginx)* | Red Privada Docker | Switch Docker | Dinámica | `80`, `443` compartidos host| Proxy Inverso Alpine |
| *(Contenedor db)* | Red Privada Docker | Switch Docker | Dinámica | `5432` (TCP) | PostgreSQL 16 cerrado |
| *(Contenedor odoo)* | Red Privada Docker | Switch Docker | Dinámica | `8069` (TCP) | Odoo 17 cerrado |

### 1.2 Hipervisor y Máquinas Virtuales (VirtualBox / VMware)
1.  **pfSense (Firewall/Enrutador):**
    *   3 Adaptadores de red. Adaptador 1: NAT/Bridged (WAN). Adaptador 2: Red Interna "LAN" (VLAN 10). Adaptador 3: Red Interna "DMZ" (VLAN 30).
2.  **Servidor Debian 12 Unificado (Nginx + Docker/Odoo):**
    *   1 Adaptador de red conectado a la Red Interna "DMZ" (VLAN 30).
    *   IP Fija a configurar: `192.168.30.10`.
    *   *Se centraliza todo el aplicativo y proxy en el mismo anfitrión.*

---

## Fase 2: Configuración del Servidor Base (Debian 12 Server)

### 2.1 Preparación Inicial e Interfaz Cockpit
Arrancar la VM del Servidor (VLAN 30) instalada en modo solo texto (Minimal) y abrir la terminal:

```bash
# Otorgar IP estática (editar /etc/network/interfaces o similar en Debian)
# Comprobar conectividad exterior a través de pfSense
ping -c 4 8.8.8.8

# Actualizar repositorios e instalar paquetes base del sistema
sudo apt update && sudo apt upgrade -y
sudo apt install curl nano git bash-completion htop -y

# Instalar y habilitar Cockpit (Gestión por Interfaz Gráfica Web)
sudo apt install cockpit -y
sudo systemctl enable --now cockpit.socket
# Ya puedes gestionar visualmente el servidor desde el cliente ingresando a https://192.168.30.10:9090
```

### 2.2 Instalación de Docker y Orquestación
```bash
# Instalar Docker y Docker Compose
sudo apt install docker.io docker-compose -y

# Habilitar el servicio para arranque automático
sudo systemctl enable --now docker

# Añadir los usuarios al grupo docker para evitar usar "sudo" en cada comando
sudo usermod -aG docker sandra

# Cerrar sesión o aplicar el cambio al shell actual
newgrp docker

# Comprobar la instalación
docker ps
```

### 2.3 Integración Continua (GitHub Actions)
Configuraremos un validador sintáctico estático para proteger la rama principal de errores en la configuración de Docker, Markdown y Bash.
```bash
# Crear estructura de GitHub Actions en el repositorio local
mkdir -p .github/workflows
touch .github/workflows/ci.yml
```
*(El contenido exacto del archivo `ci.yml` se detallará en la configuración del repositorio para ejecutar validadores sintácticos estáticos).*

---

## Fase 3: Orquestación de Odoo 17 y PostgreSQL 16 (Docker)

### 3.1 Estructura de Directorios
En el servidor Debian, prepara el esquema de carpetas para el proyecto ERP vía Cockpit terminal o SSH:

```bash
mkdir -p /opt/erp-odoo/data/{postgres,odoo_addons,odoo_etc,odoo_web}
mkdir -p /opt/erp-odoo/{scripts,config_nginx,certs}
cd /opt/erp-odoo
```

### 3.2 Creación del Fichero `docker-compose.yml`
Crear el archivo base (el contenido exacto lo proveemos en la carpeta `/docker` del repositorio, el cual incluye los servicios `db`, `odoo`, y `nginx`, utilizando archivo `.env` por seguridad).

**Ejecución Inicial:**
```bash
cd /opt/erp-odoo
docker-compose up -d
docker-compose logs -f   # Comprobar que no hay errores de sintaxis o conexión
```

---

## Fase 4: Automatización y Escaneo (Scripts DevOps)

Deberás ubicar los ficheros de Bash detallados en nuestra carpeta de GitHub `/scripts` y darles permisos de ejecución (`chmod +x *.sh`). 

### Batería de Scripts Programados:
- **`backup.sh`**: Usa `pg_dump` con formato `custom` que nativamente comprime los datos de PostgreSQL.
- **`restore.sh`**: Restaura la base de datos de Odoo desde un archivo de backup (borrando la actual antes).
- **`deploy.sh`**: Levantamiento automático de la infraestructura de docker compose.
- **`update.sh`**: Actualización segura del entorno Docker descargando versiones actualizadas y limpiando *prune*.
- **`monitor.sh`**: Vigila los contenedores, puede ser llamado por cron para verificar que nada está caído.

### Tarea Cron Diaria (Copias Automáticas)
Para programar tanto el backup (a las 02:00 AM) como el chequeo de monitorización (cada hora):
```bash
crontab -e
# Añadir:
0 2 * * * /opt/erp-odoo/scripts/backup.sh > /var/log/odoo_backup.log 2>&1
0 * * * * /opt/erp-odoo/scripts/monitor.sh > /var/log/odoo_monitor.log 2>&1
```

---

## Fase 5: Auditoría en PostgreSQL (PL/pgSQL Trigger)

Para registrar las acciones de base de datos a un nivel más profundo. *(Ejecutado por el rol de Base de Datos).*

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

Protegemos el único servidor en la DMZ (`192.168.30.10`). Se restringen las peticiones a solo lo necesario (Nginx HTTP/HTTPS) y la administración (Cockpit y SSH).

```bash
# Instalar UFW si no lo trae Debian
sudo apt install ufw -y

# Permitir SSH y Cockpit 
sudo ufw allow 22/tcp
sudo ufw allow 9090/tcp

# Permitir HTTP y HTTPS hacia el contenedor Nginx
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Activar firewall
sudo ufw enable
```

---

## Fase 7: Publicación y Seguridad Perimetral (Nginx en Docker y pfSense)

En lugar de instalar Nginx nativamente, configuraremos los archivos que leerá el contenedor.

### 7.1 Generación de Certificado SSL Autofirmado (Para Simulación)
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /opt/erp-odoo/certs/odoo-selfsigned.key -out /opt/erp-odoo/certs/odoo-selfsigned.crt
# (Common Name: erp.techsolutions.local)
```

### 7.2 Configuración del Proxy Inverso
(Configurar el Server Block en `/opt/erp-odoo/config_nginx/odoo_proxy.conf` suministrado en el repositorio Git y aplicar un `docker-compose restart nginx`).

### 7.3 Conexión con pfSense (Capa de Redes)
En el portal web de pfSense:
1. Ir a **Firewall > NAT > Port Forward**.
2. Crear una regla en la interfaz **WAN**, para el destino WAN Address hacia los puertos alias `80,443`.
3. Target IP (Redirect target): **La IP del Nginx de DMZ** (`192.168.30.10`).
4. Aplicar los cambios.

---

## Resumen de la Ejecución Final
1. Enciende las VMs en orden: pfSense y luego el servidor Debian unificado.
2. El administrador puede entrar a `https://192.168.30.10:9090` para revisar visualmente el host con Cockpit.
3. El cliente entra a `https://erp.techsolutions.local` desde WAN o la LAN local (VLAN 10).
4. El DNS de pfSense resuelve que esa URL apunta a la DMZ (`192.168.30.10`).
5. El Nginx Dockerizado captura la petición en el puerto 443, la descifra, y la manda internamente al puerto `8069` del contenedor Odoo.
