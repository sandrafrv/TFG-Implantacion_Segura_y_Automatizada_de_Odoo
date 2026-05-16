El script `vagrant/provision_postgres.sh` es el fichero que Vagrant ejecuta automáticamente dentro de la VM de base de datos (la **VM 3 — db-server**) justo después de crearla, para dejarla lista sin intervención manual.

Esta VM se despliega en la **VLAN 40 (Administración y Base de Datos)** con la IP `192.168.40.10`.

> **Última actualización (16 Mayo):** Documentación sincronizada con los últimos cambios del script, incluyendo configuración regional, limpieza de repositorios y despliegue del Self-Hosted Runner.

---

## Qué hace paso a paso

### 1. Espera de Red y Configuración Base (Actualizado)
Carga la contraseña desde el entorno (pasada por el `Vagrantfile`) o usa `changeme_db` como fallback.
A continuación, realiza comprobaciones de conectividad. Para evitar errores en el provisioning debidos a imágenes base de Debian con repositorios caídos o firmas caducadas, corrige los mirrors en `/etc/apt/sources.list`. Además, fuerza la distribución del teclado a español mediante `dpkg-reconfigure`.

### 2. Instalación de PostgreSQL 16
Añade el repositorio oficial de PostgreSQL (pgdg) para instalar la versión 16, en lugar de la versión por defecto de Debian, y lo arranca como servicio del sistema.

### 3. Creación de Usuario y Base de Datos
Crea el rol `odoo` y la base de datos `odoo_erp`, asignando los permisos correspondientes.

### 4. Aislamiento de Red (Seguridad Crítica)
Estas líneas en `postgresql.conf` y `pg_hba.conf` garantizan que:
1. `listen_addresses = '*'` → PostgreSQL escucha en todas las interfaces de la VM.
2. `pg_hba.conf` → Solo permite conexiones desde la subred **`192.168.30.0/24` (DMZ donde está Odoo)**. Ninguna otra red podrá alcanzar la base de datos, aunque descubran la IP.

### 5. Instalación del Runner de GitHub Actions (`db-runner`)
El script descarga e instala automáticamente un **Self-Hosted Runner** de GitHub Actions para despliegue automatizado:
- Verifica la existencia del token (`GH_RUNNER_TOKEN`).
- Crea un usuario `runner` sin privilegios.
- Descarga el binario de `actions-runner` (v2.317.0).
- Registra el runner en el repositorio apuntando a la VM3 con las etiquetas `self-hosted, linux, db`.
- Arranca el runner como servicio `systemd`.

### 6. Enrutamiento Persistente hacia pfSense (VLAN 40)
Debido a que Vagrant usa una interfaz NAT (`eth0`) por defecto, el script configura el enrutamiento para que la puerta de enlace sea **pfSense (`192.168.40.1`)** de forma permanente. Elimina la ruta por defecto de Vagrant, forzando que todo el tráfico de salida pase por el firewall del proyecto para ser filtrado (Egress Filtering).

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
1. Repositorios parcheados, teclado en español, red NAT verificada
2. PostgreSQL 16 instalado + usuario 'odoo' + BD 'odoo_erp'
3. Conexiones filtradas solo desde 192.168.30.0/24 (DMZ)
4. GitHub Actions Runner registrado y arrancado como 'db-runner'
5. Enrutamiento modificado: Gateway = pfSense (192.168.40.1)
               │
               ▼
       ¡VM 3 LISTA PARA USAR!
```

Cuando posteriormente se levanta la **VM 2 (odoo-server)** en la DMZ, el contenedor de Odoo apunta directamente a `192.168.40.10:5432` y el acceso se realiza con éxito gracias a las reglas configuradas aquí y en pfSense.
