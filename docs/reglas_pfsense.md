# Configuración de Reglas en pfSense (Firewall y NAT)

Este documento detalla todas las reglas configuradas en pfSense para la arquitectura de red del proyecto TFG.
La infraestructura cuenta con **cuatro interfaces**: **WAN** (red pública), **LAN/VLAN 10** (clientes 192.168.10.0/24), **OPT1/DMZ/VLAN 30** (zona desmilitarizada 192.168.30.0/24) y **OPT2/VLAN 40** (administración 192.168.40.0/24).

> **Nota:** En pfSense, el orden de las reglas importa. Se evalúan de arriba a abajo y se aplica la primera que coincide.

---

## Arquitectura de seguridad

```
Internet (WAN)
      │
      │  Solo puertos 80/443 abiertos al público
      │  SSH, Cockpit y panel pfSense → solo desde VLAN 40
      ▼
  [ pfSense ]
      │
      ├─── VLAN 10 / LAN (192.168.10.0/24) ──► Clientes / Trabajadores
      │         │  Accede a Odoo vía Nginx (80/443)
      │         │  Puede navegar por Internet
      │         │  NO puede acceder a VLAN 40, SSH, Cockpit ni panel pfSense
      │
      ├─── VLAN 30 / DMZ (192.168.30.0/24) ──► Servidor Debian + contenedores
      │         │  Puede salir a Internet (HTTP/HTTPS/DNS)
      │         │  NO puede alcanzar VLAN 10 ni VLAN 40 ← anti-pivoting
      │         │  NO puede acceder al panel de pfSense
      │
      └─── VLAN 40 / Admin (192.168.40.0/24) ──► Equipo de administración
                │  Acceso total: SSH, Cockpit, pfSense, LDAP, Odoo admin
                │  NO puede acceder a VLAN 10 ← segmentación estricta
```

---

## Interfaz WAN

*Firewall → Rules → WAN*

> Toda la administración se realiza desde la VLAN 40 (interna). Desde WAN solo se permite el acceso público a Odoo.

| Pos | Estado | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---|:---|:---|:---:|:---|
| 1 | ❌ Block | * | Redes RFC 1918 | * | * | Block private networks *(automática)* |
| 2 | ❌ Block | * | Redes Bogon | * | * | Block bogon networks *(automática)* |
| 3 | ✅ Pass | IPv4 TCP | * | WAN address | 80 | HTTP público → redirige a HTTPS |
| 4 | ✅ Pass | IPv4 TCP | * | WAN address | 443 | HTTPS público → Odoo |
| 5 | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |

### ⚠️ Puntos clave — WAN

- Las reglas **Block private networks** y **Block bogon networks** se activan en *Interfaces → WAN* y las genera pfSense automáticamente. Protegen contra spoofing.
- **SSH, Cockpit y panel pfSense no se abren desde WAN**. Toda la administración es interna desde VLAN 40.
- La regla **Bloquear todo lo demás** debe estar siempre en última posición.

---

## Interfaz LAN / VLAN 10 — Clientes

*Firewall → Rules → LAN*

Controla el tráfico desde la red de clientes (192.168.10.0/24). Los clientes solo pueden usar Odoo y navegar por Internet. No pueden administrar nada.

> **⚠️ El orden es crítico.** Los bloqueos hacia zonas de administración van **antes** que los permisos.

| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | ❌ Block | * | LAN | `192.168.40.0/24` | * | **Bloquear acceso a VLAN Admin** ← ¡PRIMERO! |
| 2 | ❌ Block | * | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 | ❌ Block | * | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 | ❌ Block | * | LAN | `192.168.30.22` | 636 | Bloquear LDAPS admin |
| 5 | ❌ Block | * | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 6 | ~~Pass~~ | IPv4 * | LAN subnets | * | * | ~~Default allow LAN to any~~ *(desactivada)* |
| 7 | ✅ Pass | IPv4 TCP | LAN subnets | `192.168.30.10` | 80 | Odoo HTTP vía Nginx |
| 8 | ✅ Pass | IPv4 TCP | LAN subnets | `192.168.30.10` | 443 | Odoo HTTPS vía Nginx |
| 9 | ✅ Pass | IPv4 TCP | LAN subnets | `192.168.30.22` | 389 | LDAP autenticación *(cn=readonly)* |
| 10 | ✅ Pass | IPv4 * | LAN subnets | * | * | Navegación general Internet |
| 11 | ❌ Block | IPv4 * | * | * | * | **Deny all** ← ¡ÚLTIMO! |

### ⚠️ Puntos clave — LAN

- La **"Default allow LAN to any"** (regla 6) debe estar **desactivada** (en gris). Se sustituye por reglas específicas.
- La regla Anti-Lockout automática de pfSense debe desactivarse desde *System → Advanced → Admin Access → Disable anti-lockout rule* **solo después** de confirmar acceso desde VLAN 40.
- Los puertos 8069 y 8072 (Odoo nativo y WebSocket) **no se abren directamente** — los clientes acceden solo a través de Nginx en los puertos 80/443.

---

## Interfaz OPT1 / DMZ / VLAN 30

*Firewall → Rules → OPT1*

Controla el tráfico desde el servidor Debian y los contenedores (192.168.30.0/24). La DMZ tiene acceso mínimo a Internet para actualizaciones y DNS.

> **⚠️ El orden es crítico.** Los bloqueos de anti-pivoting deben ir **ANTES** que cualquier regla de permiso.

| Pos | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | ❌ Block | IPv4 * | DMZ | `192.168.10.0/24` | * | **DMZ NO puede atacar VLAN 10** ← ¡PRIMERO! |
| 2 | ❌ Block | IPv4 * | DMZ | `192.168.10.1` | * | **DMZ NO puede acceder a pfSense LAN** |
| 3 | ❌ Block | IPv4 * | DMZ | `192.168.40.0/24` | * | **DMZ NO puede acceder a VLAN Admin** |
| 4 | ✅ Pass | IPv4 TCP | DMZ | * | 80 | Actualizaciones HTTP |
| 5 | ✅ Pass | IPv4 TCP | DMZ | * | 443 | Actualizaciones HTTPS |
| 6 | ✅ Pass | IPv4 UDP | DMZ | * | 53 | DNS resolución de nombres |
| 7 | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |

### ⚠️ Puntos clave — DMZ

- Los puertos SMTP (25, 465, 587) **no están abiertos** ya que el proyecto no utiliza envío de emails. Si en el futuro se necesitan, añadir antes del Deny all.
- PostgreSQL (5432) tampoco se abre: la base de datos es interna al servidor Debian.
- Las reglas 1, 2 y 3 de bloqueo deben estar siempre arriba del todo para evitar pivoting.

### Lógica de evaluación

```
Tráfico desde servidor DMZ (192.168.30.x)
         │
[Pos. 1] ¿Va hacia VLAN 10 (192.168.10.0/24)?  ──► ❌ BLOQUEADO (anti-pivoting)
[Pos. 2] ¿Va hacia pfSense LAN (10.1)?          ──► ❌ BLOQUEADO (protege pfSense)
[Pos. 3] ¿Va hacia VLAN 40 (192.168.40.0/24)?  ──► ❌ BLOQUEADO (anti-pivoting admin)
         │ No
[Pos. 4] ¿Es TCP puerto 80?                     ──► ✅ PERMITIDO (actualizaciones)
[Pos. 5] ¿Es TCP puerto 443?                    ──► ✅ PERMITIDO (actualizaciones)
[Pos. 6] ¿Es UDP puerto 53?                     ──► ✅ PERMITIDO (DNS)
         │ No coincide
[Pos. 7] Cualquier otro tráfico                 ──► ❌ BLOQUEADO (deny-all)
```

### Nota técnica — Egress Filtering

Durante el TFG se evaluó restringir la salida de la DMZ a rangos CIDR específicos (GitHub/Azure) mediante pfBlockerNG con ASN. Se descartó por requerir un token externo de IPinfo.io, introduciendo dependencia de terceros. Se mantiene una regla de salida permisiva por **TCP 443** hacia `Any`, bloqueando el resto de protocolos y puertos. Esta decisión está documentada para su defensa en la memoria del TFG.

---

## Interfaz OPT2 / VLAN 40 — Administración

*Firewall → Interfaces → Assignments → OPT2*

La VLAN 40 (`192.168.40.0/24`) es la **red exclusiva de administración**. Desde aquí se gestiona todo: pfSense, SSH, Cockpit, LDAP y Odoo admin.

> [!IMPORTANT]
> Esta VLAN no existe en el diagrama original del TFG pero sí en el diseño IaC actualizado (mayo 2026). Requiere un adaptador de red adicional en la VM pfSense y en las máquinas de administración.

### Configuración de la interfaz OPT2

*Interfaces → OPT2*

| Campo | Valor |
|---|---|
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | `192.168.40.1` / `24` |
| Description | `VLAN_ADMIN` |

### DHCP OPT2

*Services → DHCP Server → OPT2*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

### Reglas Firewall → OPT2

| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | ✅ Pass | TCP | VLAN 40 | `This Firewall` | 443 | **Panel pfSense** ← acceso exclusivo |
| 2 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit — gestión visual |
| 4 | ✅ Pass | TCP | VLAN 40 | `192.168.30.20` | 443 | Nginx/Odoo admin completo |
| 5 | ✅ Pass | TCP | VLAN 40 | `192.168.30.22` | 389 | LDAP admin (lectura + escritura) |
| 6 | ✅ Pass | TCP | VLAN 40 | `192.168.30.22` | 636 | LDAPS admin (cifrado) |
| 7 | ✅ Pass | TCP | VLAN 40 | * | 80, 443 | Actualizaciones Internet |
| 8 | ✅ Pass | UDP | VLAN 40 | * | 53 | DNS resolución |
| 9 | ❌ Block | * | VLAN 40 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 10 | ❌ Block | * | VLAN 40 | * | * | **Deny all** ← ¡ÚLTIMO! |

---

## NAT — Port Forwarding

*Firewall → NAT → Port Forward*

### Entradas WAN → DMZ (acceso público a Odoo)

| Interfaz | Proto | Source | Destino | Puerto entrada | Redirige a | Puerto destino | Descripción |
|:---:|:---:|:---:|:---|:---:|:---|:---:|:---|
| WAN | TCP | * | WAN address | 80 | `192.168.30.10` | 80 | HTTP → Nginx Odoo |
| WAN | TCP | * | WAN address | 443 | `192.168.30.10` | 443 | HTTPS → Nginx Odoo |

### Redirección DNS (forzar DNS interno por VLAN)

| Interfaz | Proto | Source | Destino | Puerto | Redirige a | Descripción |
|:---:|:---:|:---|:---:|:---:|:---|:---|
| LAN | TCP/UDP | `192.168.10.0/24` | * | 53 | `192.168.10.1` | Forzar DNS VLAN 10 → pfSense |
| OPT2 | TCP/UDP | `192.168.40.0/24` | * | 53 | `192.168.40.1` | Forzar DNS VLAN 40 → pfSense |

> **Por qué es necesario:** Los clientes Linux modernos con `systemd-resolved` pueden ignorar el DNS del DHCP y enviar consultas a 8.8.8.8. Esta regla intercepta cualquier consulta DNS desde cada VLAN y la redirige a pfSense, garantizando que `erp.odoo.tfg.com` resuelva siempre a `192.168.30.10`.

### NAT Outbound

*Firewall → NAT → Outbound → Modo: Automatic*

Con el modo automático pfSense aplica NAT a todas las subnets internas. Si usas modo Manual, añade una entrada por cada subnet:

| Source | Traducción | Descripción |
|:---|:---|:---|
| `192.168.10.0/24` | WAN address | Clientes salen a Internet |
| `192.168.30.0/24` | WAN address | DMZ/Odoo sale a Internet |
| `192.168.40.0/24` | WAN address | Admin sale a Internet |

---

## DHCP — Configuración por interfaz

### DHCP LAN / VLAN 10

*Services → DHCP Server → LAN*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Range | `192.168.10.100 – 192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |

### DHCP OPT2 / VLAN 40

*Services → DHCP Server → OPT2*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

> La DMZ (VLAN 30) **no usa DHCP**. Las IPs son estáticas configuradas directamente en el servidor Debian y en los ficheros Docker MACVLAN.

---

## DNS Resolver

*Services → DNS Resolver → General Settings*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Network Interfaces | LAN, OPT1, OPT2, Localhost |

### Host Override — Odoo

*Services → DNS Resolver → Host Overrides → + Add*

| Campo | Valor |
|---|---|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |
| Description | `Servidor Odoo ERP - DMZ` |

### Flujo completo de resolución DNS

```
Cliente VLAN 10 (systemd-resolved envía consulta a 8.8.8.8:53)
        │
        ▼  pfSense intercepta (NAT Port Forward LAN TCP/UDP :53)
        │
        ▼  Redirige a 192.168.10.1:53
        │
[ pfSense DNS Resolver ]
        │  Host Override → erp.odoo.tfg.com = 192.168.30.10
        ▼
Cliente recibe 192.168.30.10 → abre HTTPS → Nginx → Odoo ✅
```

---

## Tabla IPs MACVLAN — DMZ

| Contenedor | Red interna (`odoo_net`) | IP MACVLAN (`macvlan_vlan30`) | Acceso |
|:---|:---|:---|:---|
| `odoo_erp` (PostgreSQL) | 172.19.0.x | ❌ Sin IP externa | Solo contenedores internos |
| `odoo-web` (Odoo 17) | 172.19.0.3 | `192.168.30.21` | VLAN 10 + VLAN 40 vía Nginx |
| `openldap` (LDAP) | 172.19.0.5 | `192.168.30.22` | VLAN 10 (:389 readonly), VLAN 40 (:389/:636 admin) |
| `nginx-proxy` (Nginx) | 172.19.0.4 | `192.168.30.20` | Todos (80/443) |

---

## Securización del Panel pfSense

El panel de pfSense solo debe ser accesible desde la VLAN 40. Se aplica en dos capas.

### Capa 1 — Red (Firewall)

1. Crear en *Firewall → Rules → OPT2* la regla que permite acceso al panel desde VLAN 40 (ya incluida en la tabla de OPT2, regla 1).
2. Ir a *System → Advanced → Admin Access* y marcar **Disable webConfigurator anti-lockout rule**.

> ⚠️ **Solo deshabilitar la Anti-Lockout después de confirmar acceso desde una IP de la VLAN 40** (`https://192.168.40.1`). De lo contrario quedarás fuera del firewall.

### Capa 2 — Autenticación LDAP

*System → User Manager → Authentication Servers → + Add*

| Campo | Valor |
|---|---|
| Descriptive name | `OpenLDAP DMZ` |
| Type | LDAP |
| Hostname | `192.168.30.22` |
| Port | `389` |
| Transport | TCP - Standard |
| Base DN | `dc=tfg,dc=com` |
| Authentication containers | `ou=usuarios,dc=tfg,dc=com` |
| Bind credentials | `cn=admin,dc=tfg,dc=com` |
| User naming attribute | `uid` |
| Group naming attribute | `cn` |
| Group member attribute | `member` |

Crear en *System → User Manager → Groups* un grupo llamado **`admin`** con privilegio **WebCfg - All pages**. No crear el grupo `dba` con privilegios en pfSense.

Activar en *System → User Manager → Settings → Authentication Server*: `OpenLDAP DMZ`.

**Resultado:** El usuario `dba` puede ver el login pero pfSense le deniega el acceso al no pertenecer al grupo con privilegios. Solo el usuario `admin` puede entrar.

---

## Nginx — Verificación server_name

El `server_name` de Nginx debe coincidir con el Host Override DNS.

```bash
# Verificar valor actual
grep server_name /opt/erp-odoo/config_nginx/*.conf

# Corregir si es necesario
sudo sed -i 's/erp.techsolutions.local/erp.odoo.tfg.com/g' /opt/erp-odoo/config_nginx/*.conf

# Recargar sin cortar servicio
docker exec nginx-proxy nginx -s reload
docker exec nginx-proxy nginx -t
```

---

## Verificación final del sistema

```bash
# Desde cliente VLAN 10
nslookup erp.odoo.tfg.com            # Debe devolver 192.168.30.10
curl -k -I https://erp.odoo.tfg.com  # Debe devolver HTTP/2 200

# Desde admin VLAN 40
ssh usuario@192.168.30.10            # Debe conectar
# Navegador → https://192.168.40.1      → Panel pfSense accesible
# Navegador → https://192.168.30.10:9090 → Cockpit accesible
```

---

## Checklist de configuración completa

```
✅ Interfaces asignadas
   ├─ WAN  → IP externa (DHCP o estática)
   ├─ LAN  → 192.168.10.1/24  (VLAN 10 clientes)
   ├─ OPT1 → 192.168.30.1/24  (VLAN 30 DMZ)
   └─ OPT2 → 192.168.40.1/24  (VLAN 40 admin)

✅ DHCP
   ├─ LAN  → 192.168.10.100–200, DNS 192.168.10.1
   └─ OPT2 → 192.168.40.10–50,  DNS 192.168.40.1
   (OPT1/DMZ → IPs estáticas en Debian, sin DHCP)

✅ Firewall Rules
   ├─ WAN  → solo 80/443 público + deny all
   ├─ LAN  → bloqueos admin primero + Odoo/Internet + deny all
   ├─ OPT1 → bloqueos anti-pivoting primero + salida mínima + deny all
   └─ OPT2 → panel pfSense + SSH/Cockpit/LDAP/Odoo + deny all

✅ NAT Port Forward
   ├─ WAN :80  → 192.168.30.10:80   (Nginx)
   ├─ WAN :443 → 192.168.30.10:443  (Nginx)
   ├─ LAN  DNS :53 → 192.168.10.1   (forzar DNS VLAN 10)
   └─ OPT2 DNS :53 → 192.168.40.1   (forzar DNS VLAN 40)

✅ NAT Outbound → Automatic

✅ DNS Resolver
   ├─ Habilitado en LAN, OPT1, OPT2, Localhost
   └─ Host Override: erp.odoo.tfg.com → 192.168.30.10

✅ System → Advanced → Admin Access
   └─ Disable anti-lockout rule (tras confirmar acceso desde VLAN 40)
```
