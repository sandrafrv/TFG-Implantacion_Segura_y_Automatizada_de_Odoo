# Plan de Implementación — VLAN 40 + Red MACVLAN

**TFG: Implantación Segura y Automatizada de Odoo**  
Autores: Sandra Fradejas Avedillo · Mario García García · Javier Córdoba Del Valle  
Centro: IES Cañaveral — ASIR 2025/2026

---

## Índice

1. [Contexto y objetivo](#1-contexto-y-objetivo)
2. [Arquitectura de red resultante](#2-arquitectura-de-red-resultante)
3. [Fase 1 — Crear VLAN 40 en pfSense](#3-fase-1--crear-vlan-40-en-pfsense)
4. [Fase 2 — Configurar MACVLAN en Debian](#4-fase-2--configurar-macvlan-en-debian)
5. [Fase 3 — Actualizar docker-compose.yml](#5-fase-3--actualizar-docker-composeyml)
6. [Fase 4 — Reglas de firewall pfSense](#6-fase-4--reglas-de-firewall-pfsense)
7. [Verificaciones y pruebas](#7-verificaciones-y-pruebas)
8. [Checklist de puesta en marcha](#8-checklist-de-puesta-en-marcha)
9. [Diagrama de flujos](#9-diagrama-de-flujos)

---

## 1. Contexto y objetivo

### Estado actual (antes de este cambio)

| Elemento | Red | IP |
|---|---|---|
| pfSense (gateway) | VLAN 10 + VLAN 30 | 192.168.10.1 / 192.168.30.1 |
| Clientes Odoo | VLAN 10 | 192.168.10.x |
| Servidor Debian + Docker | VLAN 30 (DMZ) | 192.168.30.10 |
| Contenedores (bridge Docker) | Red interna Docker | 172.17.x.x |

### Problema que resuelve

Los contenedores Odoo y PostgreSQL actualmente están en la red bridge interna de Docker (172.17.x.x) y **no son visibles directamente en la red física**. Esto dificulta:

- Aplicar reglas de firewall individuales por contenedor en pfSense.
- Acceder directamente a Odoo desde la VLAN 10 sin pasar por el host.
- Aislar PostgreSQL completamente a nivel de red.

### Objetivo de este cambio

1. **Crear VLAN 40** en pfSense dedicada a administración del servidor (acceso SSH restringido).
2. **Crear red MACVLAN** en Docker para que cada contenedor tenga su propia IP en la VLAN 30.
3. **Aplicar reglas de firewall** específicas por IP de contenedor en pfSense.

---

## 2. Arquitectura de red resultante

```text
pfSense
├── WAN        → Internet
├── VLAN 10    → 192.168.10.0/24  (Clientes Odoo — acceso web HTTPS)
├── VLAN 30    → 192.168.30.0/24  (DMZ — Debian + contenedores)
│   ├── 192.168.30.10   Servidor Debian (host Docker)
│   ├── 192.168.30.21   Contenedor Odoo        (MACVLAN)
│   ├── 192.168.30.22   Contenedor PostgreSQL  (MACVLAN)
│   └── 192.168.30.23   Subinterfaz host MACVLAN
└── VLAN 40    → 192.168.40.0/24  (Admin — SSH restringido)
    ├── 192.168.40.1    pfSense gateway VLAN 40
    ├── 192.168.40.11   Máquina Admin
    └── 192.168.40.12   Máquina DBA
```

### Tabla completa de IPs

| Elemento | VLAN | IP | Rol |
|---|---|---|---|
| pfSense VLAN 10 | 10 | 192.168.10.1 | Gateway clientes |
| pfSense VLAN 30 | 30 | 192.168.30.1 | Gateway DMZ |
| pfSense VLAN 40 | 40 | 192.168.40.1 | Gateway Admin |
| Servidor Debian | 30 | 192.168.30.10 | Docker host + runner |
| Contenedor Odoo | 30 | 192.168.30.21 | ERP (MACVLAN) |
| Contenedor PostgreSQL | 30 | 192.168.30.22 | BD (MACVLAN) |
| Subinterfaz host MACVLAN | 30 | 192.168.30.23 | Host ↔ contenedores |
| Máquina Admin | 40 | 192.168.40.11 | SSH admin + sudo |
| Máquina DBA | 40 | 192.168.40.12 | SSH túnel PostgreSQL |
| Clientes Odoo | 10 | 192.168.10.x | Acceso web HTTPS |

---

## 3. Fase 1 — Crear VLAN 40 en pfSense

### 3.1 Crear la VLAN

1. Ir a **Interfaces → VLANs → Add**
2. Rellenar:
   - **Parent interface**: la interfaz física conectada al switch (p.ej. `em1`)
   - **VLAN tag**: `40`
   - **Description**: `VLAN40-Admin`
3. Guardar y aplicar cambios.

### 3.2 Asignar la interfaz

1. Ir a **Interfaces → Assignments**
2. En la lista desplegable de interfaces disponibles, seleccionar la VLAN 40 recién creada.
3. Clic en **Add** y luego en el nombre de la nueva interfaz (aparecerá como `OPT2` o similar).
4. Configurar:
   - **Enable**: ✅
   - **Description**: `VLAN40_ADMIN`
   - **IPv4 Configuration Type**: Static IPv4
   - **IPv4 Address**: `192.168.40.1 / 24`
5. Guardar y aplicar.

### 3.3 Configurar DHCP para VLAN 40 (opcional, si usáis DHCP)

1. Ir a **Services → DHCP Server → VLAN40_ADMIN**
2. Activar el servidor DHCP.
3. Rango: `192.168.40.100` — `192.168.40.200`
4. Añadir reservas estáticas para:
   - Máquina Admin: MAC → `192.168.40.11`
   - Máquina DBA: MAC → `192.168.40.12`
5. Guardar.

> **Nota**: Si las máquinas admin/DBA ya tienen IP fija configurada en su NIC, el DHCP no es necesario.

### 3.4 Verificar conectividad básica

Desde pfSense, ir a **Diagnostics → Ping**:
- Origen: interfaz VLAN40_ADMIN
- Destino: `192.168.40.11` (máquina admin) → debe responder

---

## 4. Fase 2 — Configurar MACVLAN en Debian

Esta fase se ejecuta mediante el script `scripts/macvlan_setup.sh`. El pipeline CI/CD lo ejecutará automáticamente al hacer push a main, pero también se puede lanzar manualmente.

### 4.1 Variables necesarias

| Variable | Valor | Descripción |
|---|---|---|
| `PARENT_IFACE` | `eth0` (o la interfaz real) | Interfaz física del Debian en VLAN 30 |
| `SUBNET` | `192.168.30.0/24` | Subred MACVLAN |
| `GATEWAY` | `192.168.30.1` | pfSense VLAN 30 |
| `ODOO_IP` | `192.168.30.21` | IP fija contenedor Odoo |
| `POSTGRES_IP` | `192.168.30.22` | IP fija contenedor PostgreSQL |
| `HOST_MACVLAN_IP` | `192.168.30.23` | IP subinterfaz host |
| `IP_RANGE` | `192.168.30.21/29` | Rango asignable a contenedores |

### 4.2 Ejecutar manualmente (primera vez)

```bash
# En el servidor Debian como root:
sudo PARENT_IFACE=eth0 \
     SUBNET=192.168.30.0/24 \
     GATEWAY=192.168.30.1 \
     ODOO_IP=192.168.30.21 \
     POSTGRES_IP=192.168.30.22 \
     HOST_MACVLAN_IP=192.168.30.23 \
     bash /opt/erp-odoo/scripts/macvlan_setup.sh
```

### 4.3 Verificar red MACVLAN en Docker

```bash
# Debe aparecer la red macvlan_vlan30
docker network ls | grep macvlan

# Debe mostrar el driver macvlan
docker network inspect macvlan_vlan30 | grep -A5 '"Driver"'

# Subinterfaz del host debe estar UP con IP 192.168.30.23
ip addr show macvlan_host

# Rutas hacia los contenedores deben existir
ip route | grep 192.168.30.2
```

---

## 5. Fase 3 — Actualizar docker-compose.yml

El `docker-compose.yml` debe asignar las IPs fijas MACVLAN a cada contenedor.

### Sección `networks` a añadir/modificar:

```yaml
networks:
  internal:
    driver: bridge
    internal: true

  macvlan_vlan30:
    external: true
    name: macvlan_vlan30
```

### Sección `services` — Odoo:

```yaml
odoo:
  networks:
    internal:
    macvlan_vlan30:
      ipv4_address: 192.168.30.21
```

### Sección `services` — PostgreSQL:

```yaml
db:
  networks:
    internal:    # Solo accesible desde Odoo
    # NO asignar macvlan_vlan30 a PostgreSQL directamente
    # El acceso externo es solo mediante túnel SSH
```

> **Importante**: PostgreSQL **no** recibe IP pública MACVLAN. Solo Odoo la tiene. El DBA accede vía túnel SSH, nunca directamente.

---

## 6. Fase 4 — Reglas de firewall pfSense

### Reglas en VLAN 40 (Admin)

Ir a **Firewall → Rules → VLAN40_ADMIN**:

| # | Origen | Destino | Puerto | Acción | Descripción |
|---|---|---|---|---|---|
| 1 | 192.168.40.11/32 | 192.168.30.10 | 22/TCP | ALLOW | SSH Admin → Debian |
| 2 | 192.168.40.12/32 | 192.168.30.10 | 22/TCP | ALLOW | SSH DBA → Debian (túnel) |
| 3 | 192.168.40.11/32 | 192.168.30.21 | 8069/TCP | ALLOW | Admin → Odoo debug |
| 4 | 192.168.40.0/24 | any | any | DENY | Bloquear resto VLAN40 |

### Reglas en VLAN 30 (DMZ)

Ir a **Firewall → Rules → VLAN30_DMZ**:

| # | Origen | Destino | Puerto | Acción | Descripción |
|---|---|---|---|---|---|
| 1 | any | 192.168.30.22 | 5432/TCP | BLOCK | Bloquear acceso directo PostgreSQL |
| 2 | 192.168.10.0/24 | 192.168.30.21 | 443/TCP | ALLOW | Clientes → Odoo HTTPS |
| 3 | any | any | any | DENY | Denegar resto |

### Reglas en VLAN 10 (Clientes)

| # | Origen | Destino | Puerto | Acción | Descripción |
|---|---|---|---|---|---|
| 1 | 192.168.10.0/24 | 192.168.30.21 | 443/TCP | ALLOW | HTTPS a Odoo |
| 2 | 192.168.10.0/24 | 192.168.30.0/24 | any | DENY | Sin acceso al resto de DMZ |
| 3 | 192.168.10.0/24 | 192.168.40.0/24 | any | DENY | Sin acceso a Admin |

---

## 7. Verificaciones y pruebas

### 7.1 Verificar VLAN 40

```bash
# Desde máquina Admin (192.168.40.11)
ping 192.168.40.1          # debe responder (pfSense)
ping 192.168.30.10         # debe responder (Debian) si hay regla
ssh admin@192.168.30.10    # debe conectar
```

### 7.2 Verificar MACVLAN

```bash
# En el servidor Debian
docker network ls | grep macvlan
# Esperado: macvlan_vlan30   macvlan   local

docker inspect odoo-web | grep '"IPAddress"'
# Esperado: 192.168.30.21

ping -c 2 192.168.30.21    # Host → Odoo: debe responder
ping -c 2 192.168.30.22    # Host → PostgreSQL: debe responder
```

### 7.3 Verificar aislamiento PostgreSQL

```bash
# Desde VLAN 10 (cliente) — NO debe responder
nc -zv 192.168.30.22 5432
# Esperado: Connection refused o timeout

# Desde pfSense → Diagnostics → Ping a 192.168.30.22:5432
# Esperado: bloqueado por regla VLAN30
```

### 7.4 Verificar túnel DBA

```bash
# Desde máquina DBA (192.168.40.12)
ssh -N -L 5433:192.168.30.22:5432 -i ~/.ssh/dba_key odoo-dba@192.168.30.10 &
psql -h 127.0.0.1 -p 5433 -U odoo -d odoo_erp -c "SELECT version();"
# Esperado: responde con versión de PostgreSQL
```

### 7.5 Verificar Odoo accesible desde VLAN 10

Desde un cliente en VLAN 10, abrir navegador:
```
https://192.168.30.21
```
Debe cargar la interfaz de Odoo.

---

## 8. Checklist de puesta en marcha

### En pfSense

- [ ] VLAN 40 creada con tag 40 en la interfaz correcta
- [ ] Interfaz VLAN40_ADMIN asignada y habilitada con IP 192.168.40.1/24
- [ ] DHCP o reservas estáticas configuradas para 192.168.40.11 y .12
- [ ] Reglas VLAN 40: SSH admin y DBA permitidos, resto denegado
- [ ] Reglas VLAN 30: PostgreSQL bloqueado desde exterior
- [ ] Reglas VLAN 10: solo HTTPS a Odoo, sin acceso a otras VLANs
- [ ] Switch configurado con trunk/access ports para VLAN 40 (si aplica)

### En el servidor Debian

- [ ] Script `macvlan_setup.sh` ejecutado sin errores
- [ ] Red `macvlan_vlan30` visible en `docker network ls`
- [ ] Subinterfaz `macvlan_host` activa con IP 192.168.30.23
- [ ] Rutas a 192.168.30.21 y .22 presentes en `ip route`
- [ ] `docker-compose.yml` actualizado con IPs MACVLAN
- [ ] Contenedor Odoo responde en 192.168.30.21
- [ ] Variables de entorno en `.env` actualizadas

### Pruebas de conectividad

- [ ] Admin (VLAN40) → SSH Debian: OK
- [ ] DBA (VLAN40) → Túnel SSH + psql: OK
- [ ] Cliente (VLAN10) → HTTPS Odoo: OK
- [ ] Cliente (VLAN10) → PostgreSQL directo: BLOQUEADO
- [ ] Admin (VLAN40) → PostgreSQL directo: BLOQUEADO
- [ ] Host Debian → ping Odoo (192.168.30.21): OK
- [ ] Host Debian → ping PostgreSQL (192.168.30.22): OK

---

## 9. Diagrama de flujos

```text
┌─────────────┐     VLAN 10      ┌──────────┐
│ Clientes    │ ──── HTTPS 443 ─▶│          │
│192.168.10.x │                  │          │
└─────────────┘                  │ pfSense  │
                                 │          │
┌─────────────┐     VLAN 40      │          │
│ Admin       │ ──── SSH 22 ───▶│          │
│192.168.40.11│                  │          │
└─────────────┘                  │          │
                                 │          │
┌─────────────┐     VLAN 40      │          │
│ DBA         │ ──── SSH 22 ───▶│          │
│192.168.40.12│   (solo túnel)   └────┬─────┘
└─────────────┘                       │
                                       │ VLAN 30 (DMZ)
                              ┌────────▼────────────────────┐
                              │   Servidor Debian            │
                              │   192.168.30.10             │
                              │                             │
                              │   ┌─────────────────────┐  │
                              │   │ macvlan_host        │  │
                              │   │ 192.168.30.23       │  │
                              │   └──────────┬──────────┘  │
                              │              │              │
                              │   ┌──────────▼──────────┐  │
                              │   │ Red MACVLAN vlan30  │  │
                              │   │                     │  │
                              │   │ Odoo  192.168.30.21 │  │
                              │   │ PgSQL 192.168.30.22 │  │
                              │   │   (solo vía túnel)  │  │
                              │   └─────────────────────┘  │
                              └─────────────────────────────┘
```

---

*Documento generado para el TFG — IES Cañaveral ASIR 2025/2026*
