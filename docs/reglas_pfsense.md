# Configuración de Reglas en pfSense (Firewall y NAT)

Este documento detalla todas las reglas configuradas en pfSense para la arquitectura de red del proyecto TFG.
La infraestructura cuenta con **cuatro interfaces**: **WAN** (red pública), **LAN/VLAN 10** (clientes 192.168.10.0/24), **OPT1/DMZ/VLAN 30** (zona desmilitarizada 192.168.30.0/24) y **OPT2/VLAN 40** (administración y base de datos 192.168.40.0/24).

> **Nota:** En pfSense, el orden de las reglas importa. Se evalúan de arriba a abajo y se aplica la primera que coincide.

> [!NOTE]
> **LDAP no forma parte del despliegue principal.** No hay ningún servicio en `192.168.30.22`.
> Las reglas de LDAP han sido eliminadas. Si se despliega LDAP como componente opcional
> (ver `extras/ldap/`), añadir manualmente las reglas necesarias para `192.168.30.22:389/636`.

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
      │         │  Puede alcanzar VLAN 40 solo en puerto 5432 (Odoo → PostgreSQL)
      │         │  NO puede alcanzar VLAN 10 ← anti-pivoting
      │         │  NO puede acceder al panel de pfSense
      │
      └─── VLAN 40 / Admin+BD (192.168.40.0/24) ──► Administración + PostgreSQL
                │  Acceso total: SSH, Cockpit, pfSense, Odoo admin, psql
                │  NO puede acceder a VLAN 10 ← segmentación estricta
```

---

## Interfaz WAN

*Firewall → Rules → WAN*

> Toda la administración se realiza desde la VLAN 40 (interna). Desde WAN solo se permite el acceso público a Odoo.

| Pos | Estado | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---|:---|:---|:---:|:---|
| 1 |  Block | * | Redes RFC 1918 | * | * | Block private networks *(automática)* |
| 2 |  Block | * | Redes Bogon | * | * | Block bogon networks *(automática)* |
| 3 |  Pass | IPv4 TCP | * | WAN address | 80 | HTTP público → redirige a HTTPS |
| 4 |  Pass | IPv4 TCP | * | WAN address | 443 | HTTPS público → Odoo |
| 5 |  Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |

###  Puntos clave — WAN

- Las reglas **Block private networks** y **Block bogon networks** se activan en *Interfaces → WAN* y las genera pfSense automáticamente. Protegen contra spoofing.
- **SSH, Cockpit y panel pfSense no se abren desde WAN**. Toda la administración es interna desde VLAN 40.
- La regla **Bloquear todo lo demás** debe estar siempre en última posición.

---

## Interfaz LAN / VLAN 10 — Clientes

*Firewall → Rules → LAN*

Controla el tráfico desde la red de clientes (192.168.10.0/24). Los clientes solo pueden usar Odoo y navegar por Internet. No pueden administrar nada.

> ** El orden es crítico.** Los bloqueos hacia zonas de administración van **antes** que los permisos.

| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 |  Block | * | LAN | `192.168.40.0/24` | * | **Bloquear acceso a VLAN Admin+BD** ← ¡PRIMERO! |
| 2 |  Block | * | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 |  Block | * | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 |  Block | * | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL (VLAN 40 ya bloqueada por regla 1) |
| 5 | ~~Pass~~ | IPv4 * | LAN subnets | * | * | ~~Default allow LAN to any~~ *(desactivada)* |
| 6 |  Pass | IPv4 TCP | LAN subnets | `192.168.30.20` | 80 | Odoo HTTP vía Nginx (MACVLAN) |
| 7 |  Pass | IPv4 TCP | LAN subnets | `192.168.30.20` | 443 | Odoo HTTPS vía Nginx (MACVLAN) |
| 8 |  Pass | IPv4 * | LAN subnets | * | * | Navegación general Internet |
| 9 |  Block | IPv4 * | * | * | * | **Deny all** ← ¡ÚLTIMO! |

###  Puntos clave — LAN

- La **"Default allow LAN to any"** (regla 5) debe estar **desactivada** (en gris). Se sustituye por reglas específicas.
- La regla Anti-Lockout automática de pfSense debe desactivarse desde *System → Advanced → Admin Access → Disable anti-lockout rule* **solo después** de confirmar acceso desde VLAN 40.
- Los puertos 8069 y 8072 (Odoo nativo y WebSocket) **no se abren directamente** — los clientes acceden solo a través de Nginx en los puertos 80/443 de la IP MACVLAN `192.168.30.20`.
- **LDAP eliminado:** no hay reglas de acceso a `192.168.30.22`. Si se despliega LDAP opcional, añadir regla antes del Deny all.

---

## Interfaz OPT1 / DMZ / VLAN 30

*Firewall → Rules → OPT1*

Controla el tráfico desde el servidor Debian y los contenedores (192.168.30.0/24). La DMZ tiene acceso mínimo a Internet para actualizaciones y DNS, y acceso directo a PostgreSQL en VLAN 40.

> **El orden es crítico.** Los bloqueos de anti-pivoting deben ir **ANTES** que cualquier regla de permiso.

| Pos | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 |  Block | IPv4 * | DMZ | `192.168.10.0/24` | * | **DMZ NO puede atacar VLAN 10** ← ¡PRIMERO! |
| 2 |  Block | IPv4 * | DMZ | `192.168.10.1` | * | **DMZ NO puede acceder a pfSense LAN** |
| 3 |  Pass | IPv4 TCP | `192.168.30.21` | `192.168.40.10` | 5432 | **Odoo → PostgreSQL externo** ← explícita |
| 4 |  Block | IPv4 * | DMZ | `192.168.40.0/24` | * | **DMZ NO puede acceder a VLAN Admin** (excepto regla 3) |
| 5 |  Pass | IPv4 TCP | DMZ | * | 80 | Actualizaciones HTTP |
| 6 |  Pass | IPv4 TCP | DMZ | * | 443 | Actualizaciones HTTPS |
| 7 |  Pass | IPv4 UDP | DMZ | * | 53 | DNS resolución de nombres |
| 8 |  Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |

###  Puntos clave — DMZ

- La regla 3 (`odoo-web → PostgreSQL`) debe ir **antes** del bloqueo general a VLAN 40 (regla 4).
- PostgreSQL en VLAN 40 (`192.168.40.10:5432`) solo es accesible desde `192.168.30.21` (odoo-web MACVLAN).
- Las reglas 1 y 2 de bloqueo deben estar siempre arriba del todo para evitar pivoting.
- **LDAP eliminado:** no hay ninguna regla de acceso a `192.168.30.22`.

### Lógica de evaluación

```
Tráfico desde servidor DMZ (192.168.30.x)
         │
[Pos. 1] ¿Va hacia VLAN 10 (192.168.10.0/24)?          ──►  BLOQUEADO (anti-pivoting)
[Pos. 2] ¿Va hacia pfSense LAN (10.1)?                  ──►  BLOQUEADO (protege pfSense)
[Pos. 3] ¿Es TCP :5432 desde odoo-web a 192.168.40.10?  ──►  PERMITIDO (Odoo → PostgreSQL)
[Pos. 4] ¿Va hacia VLAN 40 (192.168.40.0/24)?           ──►  BLOQUEADO (anti-pivoting admin)
         │ No
[Pos. 5] ¿Es TCP puerto 80?                             ──►  PERMITIDO (actualizaciones)
[Pos. 6] ¿Es TCP puerto 443?                            ──►  PERMITIDO (actualizaciones)
[Pos. 7] ¿Es UDP puerto 53?                             ──►  PERMITIDO (DNS)
         │ No coincide
[Pos. 8] Cualquier otro tráfico                         ──►  BLOQUEADO (deny-all)
```

### Nota técnica — Egress Filtering

Durante el TFG se evaluó restringir la salida de la DMZ a rangos CIDR específicos (GitHub/Azure) mediante pfBlockerNG con ASN. Se descartó por requerir un token externo de IPinfo.io, introduciendo dependencia de terceros. Se mantiene una regla de salida permisiva por **TCP 443** hacia `Any`, bloqueando el resto de protocolos y puertos. Esta decisión está documentada para su defensa en la memoria del TFG.

---

## Interfaz OPT2 / VLAN 40 — Administración + Base de Datos

*Firewall → Interfaces → Assignments → OPT2*

La VLAN 40 (`192.168.40.0/24`) es la **red exclusiva de administración y base de datos**. Desde aquí se gestiona todo: pfSense, SSH, Cockpit, psql directo a PostgreSQL y Odoo admin.

> [!IMPORTANT]
> Esta VLAN aloja también la VM de PostgreSQL (`192.168.40.10`). La separación física entre
> la DMZ (VLAN 30) y la base de datos (VLAN 40) garantiza que, aunque el stack Docker
> sea comprometido, la base de datos permanece inaccesible desde la DMZ (salvo la regla explícita Odoo→PG).

### Configuración de la interfaz OPT2

*Interfaces → OPT2*

| Campo | Valor |
|---|---|
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | `192.168.40.1` / `24` |
| Description | `VLAN_ADMIN_BD` |

### DHCP OPT2

*Services → DHCP Server → OPT2*

| Campo | Valor |
|---|---|
| Enable | Si |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

### Reglas Firewall → OPT2

| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 |  Pass | TCP | VLAN 40 | `This Firewall` | 443 | **Panel pfSense** ← acceso exclusivo |
| 2 |  Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 |  Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit — gestión visual |
| 4 |  Pass | TCP | VLAN 40 | `192.168.30.20` | 443 | Nginx/Odoo admin completo (MACVLAN) |
| 5 |  Pass | TCP | VLAN 40 | `192.168.40.10` | 5432 | **Acceso DBA directo a PostgreSQL** |
| 6 |  Pass | TCP | VLAN 40 | * | 80, 443 | Actualizaciones Internet |
| 7 |  Pass | UDP | VLAN 40 | * | 53 | DNS resolución |
| 8 |  Block | * | VLAN 40 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 9 |  Block | * | VLAN 40 | * | * | **Deny all** ← ¡ÚLTIMO! |

> **LDAP eliminado:** Las reglas de acceso a `192.168.30.22:389/636` han sido retiradas.
> Si se despliega LDAP como componente opcional (ver `extras/ldap/`), añadir antes del Deny all:
> `Pass TCP VLAN40 → 192.168.30.22:389` y `Pass TCP VLAN40 → 192.168.30.22:636`.

---

## NAT — Port Forwarding

*Firewall → NAT → Port Forward*

### Entradas WAN → DMZ (acceso público a Odoo)

El tráfico público entra por la WAN y se redirige a la IP MACVLAN de `nginx-proxy` (`192.168.30.20`):

| Interfaz | Proto | Source | Destino | Puerto entrada | Redirige a | Puerto destino | Descripción |
|:---:|:---:|:---:|:---|:---:|:---|:---:|:---|
| WAN | TCP | * | WAN address | 80 | `192.168.30.20` | 80 | HTTP → nginx-proxy MACVLAN |
| WAN | TCP | * | WAN address | 443 | `192.168.30.20` | 443 | HTTPS → nginx-proxy MACVLAN |

### Redirección DNS (forzar DNS interno por VLAN)

| Interfaz | Proto | Source | Destino | Puerto | Redirige a | Descripción |
|:---:|:---:|:---|:---:|:---:|:---|:---|
| LAN | TCP/UDP | `192.168.10.0/24` | * | 53 | `192.168.10.1` | Forzar DNS VLAN 10 → pfSense |
| OPT2 | TCP/UDP | `192.168.40.0/24` | * | 53 | `192.168.40.1` | Forzar DNS VLAN 40 → pfSense |

> **Por qué es necesario:** Los clientes Linux modernos con `systemd-resolved` pueden ignorar el DNS del DHCP y enviar consultas a 8.8.8.8. Esta regla intercepta cualquier consulta DNS desde cada VLAN y la redirige a pfSense, garantizando que `erp.odoo.tfg.com` resuelva siempre a `192.168.30.20`.

### NAT Outbound

*Firewall → NAT → Outbound → Modo: Automatic*

Con el modo automático pfSense aplica NAT a todas las subnets internas. Si usas modo Manual, añade una entrada por cada subnet:

| Source | Traducción | Descripción |
|:---|:---|:---|
| `192.168.10.0/24` | WAN address | Clientes salen a Internet |
| `192.168.30.0/24` | WAN address | DMZ/Odoo sale a Internet |
| `192.168.40.0/24` | WAN address | Admin/BD sale a Internet |

---

## DHCP — Configuración por interfaz

### DHCP LAN / VLAN 10

*Services → DHCP Server → LAN*

| Campo | Valor |
|---|---|
| Enable | Si |
| Range | `192.168.10.100 – 192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |

### DHCP OPT2 / VLAN 40

*Services → DHCP Server → OPT2*

| Campo | Valor |
|---|---|
| Enable | si |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

> La DMZ (VLAN 30) **no usa DHCP**. Las IPs son estáticas configuradas directamente en el servidor Debian y en los ficheros Docker MACVLAN.

---

## DNS Resolver

*Services → DNS Resolver → General Settings*

| Campo | Valor |
|---|---|
| Enable | Si |
| Network Interfaces | LAN, OPT1, OPT2, Localhost |

### Host Override — Odoo

*Services → DNS Resolver → Host Overrides → + Add*

| Campo | Valor |
|---|---|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.20` |
| Description | `nginx-proxy Odoo ERP — DMZ MACVLAN` |

### Flujo completo de resolución DNS

```
Cliente VLAN 10 (systemd-resolved envía consulta a 8.8.8.8:53)
        │
        ▼  pfSense intercepta (NAT Port Forward LAN TCP/UDP :53)
        │
        ▼  Redirige a 192.168.10.1:53
        │
[ pfSense DNS Resolver ]
        │  Host Override → erp.odoo.tfg.com = 192.168.30.20
        ▼
Cliente recibe 192.168.30.20 → abre HTTPS → nginx-proxy → Odoo
```

---

## Tabla IPs MACVLAN — DMZ

| Contenedor | Red interna (`odoo_net`) | IP MACVLAN (`macvlan_vlan30`) | Acceso |
|:---|:---|:---|:---|
| `nginx-proxy` (Nginx Alpine) | 172.19.0.4 | `192.168.30.20` | Todos (80/443) — entrada principal |
| `odoo-web` (Odoo 17) | 172.19.0.3 | `192.168.30.21` | Solo vía Nginx (8069/8072 internos) |

> **PostgreSQL:** no es un contenedor Docker — está en `vm-postgres` (`192.168.40.10`, VLAN 40).
> **LDAP eliminado:** no hay `openldap` ni IP `192.168.30.22` en el despliegue principal.

---

## Securización del Panel pfSense

El panel de pfSense solo debe ser accesible desde la VLAN 40. Se aplica en dos capas.

### Capa 1 — Red (Firewall)

1. Crear en *Firewall → Rules → OPT2* la regla que permite acceso al panel desde VLAN 40 (ya incluida en la tabla de OPT2, regla 1).
2. Ir a *System → Advanced → Admin Access* y marcar **Disable webConfigurator anti-lockout rule**.

>  **Solo deshabilitar la Anti-Lockout después de confirmar acceso desde una IP de la VLAN 40** (`https://192.168.40.1`). De lo contrario quedarás fuera del firewall.

### Capa 2 — Autenticación (local pfSense)

El panel pfSense se protege con las cuentas locales de pfSense. No se usa LDAP en el despliegue principal.

```
Sistema → User Manager → Users → admin
  Contraseña: cambiar la contraseña por defecto (pfsense) en el primer acceso
  Acceso: solo desde VLAN 40 (garantizado por las reglas de firewall)
```

> [!TIP]
> **Integración LDAP en pfSense (opcional):** Si en el futuro se despliega OpenLDAP
> (ver `extras/ldap/`), se puede configurar en *System → User Manager → Authentication Servers*.
> El servidor LDAP estaría en `192.168.30.22:389`. Ver la guía `extras/ldap/README.md`.

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
nslookup erp.odoo.tfg.com            # Debe devolver 192.168.30.20
curl -k -I https://erp.odoo.tfg.com  # Debe devolver HTTP/2 200

# Desde admin VLAN 40
ssh usuario@192.168.30.10            # Debe conectar
psql -h 192.168.40.10 -U odoo -d odooerp -c '\l'  # PostgreSQL accesible
# Navegador → https://192.168.40.1      → Panel pfSense accesible
# Navegador → https://192.168.30.10:9090 → Cockpit accesible

# Desde VLAN 10 (debe fallar)
nc -zv 192.168.40.10 5432            # → Timeout ✅ (BD no accesible)
```

---

## Checklist de configuración completa

```
✅ Interfaces asignadas
   ├─ WAN  → IP externa (DHCP o estática)
   ├─ LAN  → 192.168.10.1/24  (VLAN 10 clientes)
   ├─ OPT1 → 192.168.30.1/24  (VLAN 30 DMZ)
   └─ OPT2 → 192.168.40.1/24  (VLAN 40 admin+BD)

✅ DHCP
   ├─ LAN  → 192.168.10.100–200, DNS 192.168.10.1
   └─ OPT2 → 192.168.40.10–50,  DNS 192.168.40.1
   (OPT1/DMZ → IPs estáticas en Debian, sin DHCP)

✅ Firewall Rules
   ├─ WAN  → solo 80/443 público + deny all
   ├─ LAN  → bloqueos VLAN40+admin primero + Odoo(MACVLAN.20)/Internet + deny all
   ├─ OPT1 → bloqueos anti-pivoting + regla Odoo→PG(:5432) + salida mínima + deny all
   └─ OPT2 → panel pfSense + SSH/Cockpit/psql + deny all (sin reglas LDAP)

✅ NAT Port Forward
   ├─ WAN :80  → 192.168.30.20:80   (nginx-proxy MACVLAN)
   ├─ WAN :443 → 192.168.30.20:443  (nginx-proxy MACVLAN)
   ├─ LAN  DNS :53 → 192.168.10.1   (forzar DNS VLAN 10)
   └─ OPT2 DNS :53 → 192.168.40.1   (forzar DNS VLAN 40)

✅ NAT Outbound → Automatic

✅ DNS Resolver
   ├─ Habilitado en LAN, OPT1, OPT2, Localhost
   └─ Host Override: erp.odoo.tfg.com → 192.168.30.20 (nginx-proxy MACVLAN)

✅ System → Advanced → Admin Access
   └─ Disable anti-lockout rule (tras confirmar acceso desde VLAN 40)

ℹ️  LDAP: no configurado en este despliegue — ver extras/ldap/ si se necesita
```

---

*Referencia de arquitectura: [`docs/diagrama_red.md`](diagrama_red.md)*
*Guía de instalación red: [`docs/guias/INSTALACION_RED.md`](guias/INSTALACION_RED.md)*
*Control de acceso: [`docs/CONTROL_ACCESO.md`](CONTROL_ACCESO.md)*
