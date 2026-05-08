# Guía Paso a Paso — VLAN 40 + MACVLAN

**TFG: Implantación Segura y Automatizada de Odoo**

> Esta guía te lleva de la mano, comando a comando, desde el estado actual del proyecto (todo funcionando) hasta tener la VLAN 40 y MACVLAN operativos.

---

## Paso 1 — pfSense: Crear VLAN 40

### 1.1 Crear la VLAN

```
Interfaces → VLANs → Add
  Parent interface : <tu interfaz LAN/trunk>
  VLAN tag         : 40
  Description      : VLAN40-Admin
→ Save → Apply Changes
```

### 1.2 Asignar interfaz

```
Interfaces → Assignments
  → Add la VLAN40 que acabas de crear
  → Clic en el nombre (OPT2 o similar)
  Enable: ✅
  Description: VLAN40_ADMIN
  IPv4 Type: Static
  IPv4 Address: 192.168.40.1 / 24
→ Save → Apply Changes
```

**✅ Verificación 1**: En pfSense, Interfaces → Overview debe mostrar VLAN40_ADMIN con IP 192.168.40.1

---

## Paso 2 — pfSense: Reglas VLAN 40

```
Firewall → Rules → VLAN40_ADMIN → Add
```

Regla 1 — SSH Admin:
```
Action   : Pass
Interface: VLAN40_ADMIN
Protocol : TCP
Source   : 192.168.40.11/32
Dest     : 192.168.30.10
Dest Port: 22
Descr    : SSH Admin → Debian
```

Regla 2 — SSH DBA (túnel):
```
Action   : Pass
Interface: VLAN40_ADMIN
Protocol : TCP
Source   : 192.168.40.12/32
Dest     : 192.168.30.10
Dest Port: 22
Descr    : SSH DBA túnel → Debian
```

Regla 3 — Bloquear resto:
```
Action   : Block
Interface: VLAN40_ADMIN
Protocol : any
Source   : VLAN40_ADMIN net
Dest     : any
Descr    : Denegar resto VLAN40
```

→ Save → Apply Changes

**✅ Verificación 2**: Desde máquina Admin (192.168.40.11), ejecutar:
```bash
ping 192.168.40.1   # debe responder (pfSense)
```

---

## Paso 3 — pfSense: Regla anti-PostgreSQL en VLAN 30

```
Firewall → Rules → VLAN30_DMZ → Add (al principio de la lista)
  Action   : Block
  Protocol : TCP
  Source   : any
  Dest     : 192.168.30.22
  Dest Port: 5432
  Descr    : BLOQUEAR acceso directo PostgreSQL
→ Save → Apply Changes
```

**✅ Verificación 3**: Desde cualquier máquina que no sea el propio Debian:
```bash
nc -zv 192.168.30.22 5432
# Esperado: timeout o connection refused
```

---

## Paso 4 — Debian: Comprobar interfaz de red

Antes de ejecutar el script MACVLAN, confirmar el nombre real de la interfaz:

```bash
ip -br link show
# Ejemplo de salida:
# lo     UNKNOWN  00:00:00:00:00:00
# eth0   UP       xx:xx:xx:xx:xx:xx   ← esta es la que necesitamos
```

Apunta el nombre exacto de la interfaz (puede ser `eth0`, `ens18`, `enp0s3`, etc.).

**✅ Verificación 4**: El nombre de interfaz está anotado y corresponde a la IP 192.168.30.10

---

## Paso 5 — Debian: Ejecutar macvlan_setup.sh

```bash
cd /opt/erp-odoo

sudo PARENT_IFACE=eth0 \\
     SUBNET=192.168.30.0/24 \\
     GATEWAY=192.168.30.1 \\
     ODOO_IP=192.168.30.21 \\
     POSTGRES_IP=192.168.30.22 \\
     HOST_MACVLAN_IP=192.168.30.23 \\
     bash scripts/macvlan_setup.sh
```

> ⚠️ Sustituye `eth0` por el nombre real de tu interfaz del paso 4.

**✅ Verificación 5**:
```bash
docker network ls | grep macvlan
# Esperado: macvlan_vlan30   macvlan   local

ip addr show macvlan_host
# Esperado: inet 192.168.30.23/32

ip route | grep 192.168.30.2
# Esperado:
#   192.168.30.21 dev macvlan_host
#   192.168.30.22 dev macvlan_host
```

---

## Paso 6 — Debian: Actualizar docker-compose.yml

Editar `docker/docker-compose.yml` para añadir las IPs MACVLAN.

Buscar la sección `networks:` al final del fichero y modificarla/añadirla:

```yaml
networks:
  internal:
    driver: bridge
    internal: true
  macvlan_vlan30:
    external: true
    name: macvlan_vlan30
```

Y en el servicio `odoo` añadir la red con IP fija:
```yaml
services:
  odoo:
    networks:
      internal:
      macvlan_vlan30:
        ipv4_address: 192.168.30.21
```

Después, reiniciar el stack:
```bash
cd /opt/erp-odoo
docker compose -f docker/docker-compose.yml down
docker compose -f docker/docker-compose.yml up -d
```

**✅ Verificación 6**:
```bash
docker inspect odoo-web | grep '"IPAddress"'
# Esperado: 192.168.30.21

ping -c 2 192.168.30.21
# Esperado: responde

curl -sk https://192.168.30.21 | grep -i odoo
# Esperado: HTML con referencias a Odoo
```

---

## Paso 7 — Verificación final completa

```bash
# Desde el servidor Debian:
echo '=== Red Docker ==='
docker network ls

echo '=== IP contenedor Odoo ==='
docker inspect odoo-web | grep '"IPAddress"'

echo '=== Ping host → Odoo ==='
ping -c 2 192.168.30.21

echo '=== Ping host → PostgreSQL ==='
ping -c 2 192.168.30.22

echo '=== Estado contenedores ==='
docker compose -f docker/docker-compose.yml ps
```

```bash
# Desde máquina Admin (192.168.40.11):
echo '=== SSH a Debian ==='
ssh admin@192.168.30.10 'hostname && uptime'

echo '=== Acceso HTTPS Odoo ==='
curl -sk https://192.168.30.21 | head -5
```

---

## Resumen de verificaciones

| # | Qué verificar | Comando | Esperado |
|---|---|---|---|
| 1 | VLAN40 en pfSense | GUI pfSense | IP 192.168.40.1 activa |
| 2 | Ping Admin → pfSense | `ping 192.168.40.1` | OK |
| 3 | PostgreSQL bloqueado | `nc -zv 192.168.30.22 5432` | Timeout |
| 4 | Interfaz Debian | `ip -br link show` | Nombre anotado |
| 5 | Red MACVLAN creada | `docker network ls` | macvlan_vlan30 presente |
| 6 | Subinterfaz host | `ip addr show macvlan_host` | IP 192.168.30.23 |
| 7 | IP Odoo | `docker inspect odoo-web` | 192.168.30.21 |
| 8 | Ping a Odoo | `ping -c2 192.168.30.21` | OK |
| 9 | SSH Admin | `ssh admin@192.168.30.10` | Conecta |
| 10 | HTTPS Odoo | navegador o curl | Carga Odoo |

---

*TFG — IES Cañaveral ASIR 2025/2026*
