# Guía de Configuración Manual de pfSense — ACLs completas

> **Versión:** Mayo 2026 — Arquitectura TFG (3 VMs, MACVLAN, PostgreSQL externo, sin LDAP)
> **Audiencia:** Configuración manual UNA VEZ antes de usar el flujo automatizado Vagrant.

---

## Resumen del flujo

```
1. [Este documento]  → Configurar pfSense manualmente la primera vez
2. generate_pfsense_config.sh → Exportar la config a config/pfsense_config.xml
3. vagrant up        → Levantar odoo-server + db-server
```

---

## 0. Acceso inicial a pfSense

| Dato | Valor |
|---|---|
| URL | `https://192.168.40.1` (desde VLAN 40) o `https://192.168.10.1` (inicial) |
| Usuario | `admin` |
| Contraseña | `pfsense` (cambiar en el primer login) |

> ⚠️ Si es la primera vez, pfSense mostrará el **Setup Wizard**. Puedes completarlo o saltarlo.

---

## 1. Interfaces — Asignación y configuración

*Interfaces → Assignments*

Asignar las NICs en este orden:

| Interfaz pfSense | NIC VMware | Descripción | IP |
|---|---|---|---|
| WAN | em0 | Red pública (DHCP) | DHCP |
| LAN | em1 | VLAN 10 — Clientes | `192.168.10.1/24` |
| OPT1 | em2 | VLAN 30 — DMZ | `192.168.30.1/24` |
| OPT2 | em3 | VLAN 40 — Admin+BD | `192.168.40.1/24` |

### Configurar cada interfaz

**WAN** *(Interfaces → WAN)*:
- IPv4 Configuration Type: `DHCP`
- ✅ Block private networks
- ✅ Block bogon networks

**LAN** *(Interfaces → LAN)*:
- Enable: ✅
- IPv4 Configuration: `Static IPv4`
- IPv4 Address: `192.168.10.1 / 24`
- Description: `LAN_CLIENTES`

**OPT1** *(Interfaces → OPT1)*:
- Enable: ✅
- IPv4 Configuration: `Static IPv4`
- IPv4 Address: `192.168.30.1 / 24`
- Description: `DMZ`

**OPT2** *(Interfaces → OPT2)*:
- Enable: ✅
- IPv4 Configuration: `Static IPv4`
- IPv4 Address: `192.168.40.1 / 24`
- Description: `VLAN_ADMIN_BD`

---

## 2. DHCP Server

### LAN / VLAN 10 — Clientes

*Services → DHCP Server → LAN*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Range From | `192.168.10.100` |
| Range To | `192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |

### OPT2 / VLAN 40 — Admin+BD

*Services → DHCP Server → OPT2*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Range From | `192.168.40.10` |
| Range To | `192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

> La DMZ (OPT1/VLAN 30) **NO tiene DHCP** — IPs estáticas en el servidor Debian y Docker.

---

## 3. DNS Resolver

*Services → DNS Resolver → General Settings*

| Campo | Valor |
|---|---|
| Enable | ✅ |
| Network Interfaces | LAN, OPT1, OPT2, Localhost |
| Outgoing Interfaces | WAN |
| DNSSEC | ✅ |

### Host Override — Odoo ERP

*Services → DNS Resolver → Host Overrides → + Add*

| Campo | Valor |
|---|---|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.20` |
| Description | `nginx-proxy Odoo ERP — DMZ MACVLAN` |

> ⚠️ La IP debe ser `192.168.30.20` (nginx-proxy MACVLAN), **no** `192.168.30.10`.

---

## 4. Firewall → Aliases

*Firewall → Aliases → + Add* (crear uno por uno)

| Nombre | Tipo | Dirección | Descripción |
|---|---|---|---|
| `Servidor_Debian` | Host | `192.168.30.10` | Servidor Debian DMZ |
| `Nginx_Proxy` | Host | `192.168.30.20` | Nginx Reverse Proxy MACVLAN |
| `Odoo_Web` | Host | `192.168.30.21` | Odoo ERP MACVLAN |
| `PostgreSQL_VM` | Host | `192.168.40.10` | PostgreSQL 16 VLAN 40 |
| `VLAN_Clientes` | Network | `192.168.10.0/24` | Red VLAN 10 Clientes |
| `VLAN_Admin` | Network | `192.168.40.0/24` | Red VLAN 40 Admin+BD |

---

## 5. NAT — Port Forward

*Firewall → NAT → Port Forward → + Add*

### Reglas NAT (crear en este orden)

**Regla 1 — HTTP público → Nginx**

| Campo | Valor |
|---|---|
| Interface | WAN |
| Protocol | TCP |
| Source | any |
| Destination | WAN address |
| Destination Port | 80 |
| Redirect Target IP | `192.168.30.20` |
| Redirect Target Port | 80 |
| Description | `HTTP publico - Nginx Odoo` |
| Filter Rule Association | Pass |

**Regla 2 — HTTPS público → Nginx**

| Campo | Valor |
|---|---|
| Interface | WAN |
| Protocol | TCP |
| Source | any |
| Destination | WAN address |
| Destination Port | 443 |
| Redirect Target IP | `192.168.30.20` |
| Redirect Target Port | 443 |
| Description | `HTTPS publico - Nginx Odoo` |
| Filter Rule Association | Pass |

**Regla 3 — Forzar DNS VLAN 10**

| Campo | Valor |
|---|---|
| Interface | LAN |
| Protocol | TCP/UDP |
| Source | LAN subnets |
| Destination | any |
| Destination Port | 53 |
| Redirect Target IP | `192.168.10.1` |
| Redirect Target Port | 53 |
| Description | `Forzar DNS VLAN 10 a pfSense` |

**Regla 4 — Forzar DNS VLAN 40**

| Campo | Valor |
|---|---|
| Interface | OPT2 |
| Protocol | TCP/UDP |
| Source | OPT2 subnets |
| Destination | any |
| Destination Port | 53 |
| Redirect Target IP | `192.168.40.1` |
| Redirect Target Port | 53 |
| Description | `Forzar DNS VLAN 40 a pfSense` |

### NAT Outbound

*Firewall → NAT → Outbound*

- Mode: **Automatic Outbound NAT** ← dejar así

---

## 6. Reglas Firewall — WAN

*Firewall → Rules → WAN*

> Las reglas Block private/bogon se activan automáticamente desde la configuración de la interfaz WAN.
> Añadir manualmente las reglas de paso y el deny-all.

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | Block | * | RFC 1918 | * | * | Block private networks *(auto)* |
| 2 | Block | * | Bogon | * | * | Block bogon networks *(auto)* |
| **3** | **Pass** | IPv4 TCP | any | WAN address | **80** | HTTP público → redirige a HTTPS |
| **4** | **Pass** | IPv4 TCP | any | WAN address | **443** | HTTPS público → Odoo |
| **5** | **Block** | IPv4 * | any | any | * | **Bloquear todo lo demás ← ÚLTIMO** |

### Cómo añadir la regla Pass (repite para cada regla):

1. *Firewall → Rules → WAN → + Add (arriba)*
2. Action: **Pass**
3. Interface: **WAN**
4. Address Family: **IPv4**
5. Protocol: **TCP**
6. Source: **any**
7. Destination: **WAN address** → puerto **80** (o 443)
8. Description: rellena el campo
9. **Save** → **Apply Changes**

---

## 7. Reglas Firewall — LAN (VLAN 10)

*Firewall → Rules → LAN*

> ⚠️ **ORDEN CRÍTICO**: Los bloqueos van primero.
> Desactivar la "Default allow LAN to any" (ponla en estado deshabilitado, no la borres todavía).

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | **Block** | IPv4 * | LAN | `192.168.40.0/24` | * | **Bloquear acceso a VLAN Admin+BD ← PRIMERO** |
| 2 | **Block** | IPv4 TCP | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 | **Block** | IPv4 TCP | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 | **Block** | IPv4 TCP | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 5 | ~~Pass~~ | IPv4 * | LAN | any | * | ~~Default allow LAN to any~~ **← DESHABILITAR** |
| 6 | **Pass** | IPv4 TCP | LAN | `192.168.30.20` | 80 | Odoo HTTP vía Nginx |
| 7 | **Pass** | IPv4 TCP | LAN | `192.168.30.20` | 443 | Odoo HTTPS vía Nginx |
| 8 | **Pass** | IPv4 * | LAN | any | * | Navegación general Internet |
| 9 | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

### Cómo deshabilitar la regla "Default allow LAN to any":

1. *Firewall → Rules → LAN*
2. Localizar la regla con descripción "Default allow LAN to any rule"
3. Hacer click en el icono de lápiz (editar)
4. Marcar **Disabled** en la parte superior
5. **Save** → **Apply Changes**

---

## 8. Reglas Firewall — OPT1 / DMZ (VLAN 30)

*Firewall → Rules → OPT1*

> ⚠️ **ORDEN CRÍTICO**: Los bloqueos anti-pivoting deben ir ANTES que cualquier regla de permiso.

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | **Block** | IPv4 * | OPT1 | `192.168.10.0/24` | * | **DMZ NO puede atacar VLAN 10 ← PRIMERO** |
| 2 | **Block** | IPv4 * | OPT1 | `192.168.10.1` | * | DMZ NO puede acceder a pfSense LAN |
| 3 | **Pass** | IPv4 TCP | `192.168.30.21` | `192.168.40.10` | 5432 | **Odoo-web → PostgreSQL ← ANTES del bloqueo VLAN40** |
| 4 | **Block** | IPv4 * | OPT1 | `192.168.40.0/24` | * | DMZ NO puede acceder a VLAN Admin |
| 5 | **Pass** | IPv4 TCP | OPT1 | any | 80 | Actualizaciones HTTP |
| 6 | **Pass** | IPv4 TCP | OPT1 | any | 443 | Actualizaciones HTTPS |
| 7 | **Pass** | IPv4 UDP | OPT1 | any | 53 | DNS resolución |
| 8 | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

### Detalle de la regla 3 (crítica):

1. *Firewall → Rules → OPT1 → + Add*
2. Action: **Pass**
3. Interface: **OPT1**
4. Protocol: **TCP**
5. Source → Single host: `192.168.30.21`
6. Destination → Single host: `192.168.40.10`, Port: `5432`
7. Description: `Odoo-web (192.168.30.21) -> PostgreSQL VLAN 40`
8. **Save** → colocar en posición 3 (después de los dos bloqueos anti-pivoting) → **Apply Changes**

---

## 9. Reglas Firewall — OPT2 / VLAN 40 (Admin)

*Firewall → Rules → OPT2*

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| 1 | **Pass** | IPv4 TCP | OPT2 | This Firewall (self) | 443 | **Panel pfSense — acceso exclusivo** |
| 2 | **Pass** | IPv4 TCP | OPT2 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 | **Pass** | IPv4 TCP | OPT2 | `192.168.30.10` | 9090 | Cockpit — gestión visual |
| 4 | **Pass** | IPv4 TCP | OPT2 | `192.168.30.20` | 443 | Nginx/Odoo admin (MACVLAN) |
| 5 | **Pass** | IPv4 TCP | OPT2 | `192.168.40.10` | 5432 | Acceso DBA directo a PostgreSQL |
| 6 | **Pass** | IPv4 TCP | OPT2 | any | 80 | Actualizaciones HTTP |
| 7 | **Pass** | IPv4 TCP | OPT2 | any | 443 | Actualizaciones HTTPS |
| 8 | **Pass** | IPv4 UDP | OPT2 | any | 53 | DNS resolución |
| 9 | **Block** | IPv4 * | OPT2 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 10 | **Block** | IPv4 * | any | any | * | **Deny all ← ÚLTIMO** |

### Detalle regla 1 — Panel pfSense:

1. Action: **Pass**, Interface: **OPT2**, Protocol: **TCP**
2. Source: OPT2 subnets
3. Destination: **This Firewall** (seleccionar en el desplegable)
4. Destination Port: `443`
5. Description: `Panel pfSense - acceso exclusivo VLAN 40`

---

## 10. Securización del panel de administración

*System → Advanced → Admin Access*

| Opción | Valor |
|---|---|
| Disable webConfigurator anti-lockout rule | ✅ **Marcar** |

> ⚠️ **SOLO marcar esto DESPUÉS de haber confirmado** que puedes acceder a `https://192.168.40.1` desde una IP de la VLAN 40. Si lo marcas antes, quedarás bloqueado fuera del firewall.

### Cambiar contraseña admin:

*System → User Manager → Users → admin → Edit*

- Password: cambiar `pfsense` por una contraseña segura

---

## 11. Exportar configuración (para importación automática con Vagrant)

Una vez que todo funciona correctamente, exportar la configuración para automatizar con Vagrant:

### Opción A — Usar el generador del proyecto (recomendado):

```bash
# En Git Bash o WSL desde la raíz del proyecto
bash scripts/deploy/generate_pfsense_config.sh
```

Esto genera `config/pfsense_config.xml`.

### Opción B — Exportar desde la propia pfSense:

1. *Diagnostics → Backup/Restore*
2. Pestaña **Backup Configuration**
3. Include extra data: ✅ (incluye contraseñas)
4. Click **Download configuration as XML**
5. Guardar el archivo como `config/pfsense_config.xml` en la raíz del proyecto

> Con cualquiera de las dos opciones, el XML queda en `config/pfsense_config.xml`
> y el flujo Vagrant lo importará automáticamente en el siguiente `vagrant up pfsense`.

---

## 12. Verificación final

```bash
# Desde cliente VLAN 10
nslookup erp.odoo.tfg.com          # Debe devolver 192.168.30.20
curl -k -I https://erp.odoo.tfg.com  # Debe devolver HTTP/2 200

# Desde admin VLAN 40
ssh usuario@192.168.30.10           # SSH al servidor Debian
psql -h 192.168.40.10 -U odoo -d odooerp -c '\l'  # PostgreSQL OK
# Navegador → https://192.168.40.1  → Panel pfSense accesible

# Estas deben FALLAR (confirma segmentación):
nc -zv 192.168.40.10 5432           # Desde VLAN 10 → Timeout ✅
nc -zv 192.168.10.5 80              # Desde DMZ → Timeout ✅
```

---

## Checklist de configuración

```
[ ] 1. Interfaces asignadas y configuradas
       ├─ WAN  → DHCP, block private/bogon ✓
       ├─ LAN  → 192.168.10.1/24 ✓
       ├─ OPT1 → 192.168.30.1/24 ✓
       └─ OPT2 → 192.168.40.1/24 ✓

[ ] 2. DHCP habilitado
       ├─ LAN  → 192.168.10.100–200 ✓
       └─ OPT2 → 192.168.40.10–50  ✓

[ ] 3. DNS Resolver habilitado en LAN, OPT1, OPT2
       └─ Host Override: erp.odoo.tfg.com → 192.168.30.20 ✓

[ ] 4. Aliases creados (6 aliases) ✓

[ ] 5. NAT Port Forward
       ├─ WAN :80  → 192.168.30.20:80  ✓
       ├─ WAN :443 → 192.168.30.20:443 ✓
       ├─ LAN  DNS → 192.168.10.1:53   ✓
       └─ OPT2 DNS → 192.168.40.1:53   ✓

[ ] 6. Reglas WAN (5 reglas, deny-all al final) ✓

[ ] 7. Reglas LAN (9 reglas, Default allow deshabilitada, deny-all al final) ✓

[ ] 8. Reglas OPT1/DMZ (8 reglas, orden anti-pivoting > Odoo→PG > bloqueo VLAN40) ✓

[ ] 9. Reglas OPT2/Admin (10 reglas, panel pfSense solo VLAN40, deny-all al final) ✓

[ ] 10. Anti-lockout deshabilitado (TRAS confirmar acceso desde VLAN 40) ✓

[ ] 11. Contraseña admin cambiada ✓

[ ] 12. config.xml exportado a config/pfsense_config.xml ✓
```

---

*Arquitectura: [`docs/diagrama_red.md`](../diagrama_red.md)*
*Reglas completas en XML: [`scripts/deploy/generate_pfsense_config.sh`](../../scripts/deploy/generate_pfsense_config.sh)*
*Control de acceso: [`docs/CONTROL_ACCESO.md`](../CONTROL_ACCESO.md)*
