# Configuración de Reglas en pfSense (Firewall y NAT)

Este documento detalla todas las reglas configuradas en pfSense para la arquitectura de red del proyecto TFG.
La infraestructura cuenta con **cuatro interfaces**: **WAN** (red pública), **LAN/VLAN10** (clientes, 192.168.10.0/24), **OPT1/DMZ** (servidores, 192.168.30.0/24) y **OPT2/Admin** (administración, 192.168.40.0/24).

> **Nota:** En pfSense, el orden de las reglas importa. Se evalúan de arriba a abajo y se aplica la primera que coincide.

---

## Topología de red

| Zona | Interfaz pfSense | Subred | Gateway | Descripción |
|---|---|---|---|---|
| Clientes / Trabajadores | LAN | 192.168.10.0/24 | 192.168.10.1 | PCs de empleados, acceso a Odoo |
| Servidores / DMZ | OPT1 | 192.168.30.0/24 | 192.168.30.1 | Servidor Debian, Odoo, PostgreSQL |
| **Administración** | **OPT2** | **192.168.40.0/24** | **192.168.40.1** | **Máquina Admin y DBA — aislada** |
| Internet | WAN | DHCP ISP | — | Red pública |

> **Por qué VLAN 40 separada:** Si un atacante compromete un contenedor Odoo (VLAN 30), no puede alcanzar las máquinas de administración. Las reglas `VLAN30→VLAN40 BLOCK` y `VLAN10→VLAN40 BLOCK` garantizan ese aislamiento.

---

## Interfaz WAN

*Firewall → Rules → WAN*

| Posición | Estado | Protocolo | Origen | Destino | Puerto | Descripción |
| :---: | :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | ❌ Block | * | Redes RFC 1918 | * | * | Block private networks (automática) |
| 2 | ❌ Block | * | Redes Bogon | * | * | Block bogon networks (automática) |
| 3 | ✅ Pass | IPv4 TCP | * | WAN address | 80 | HTTP (redirige a HTTPS) |
| 4 | ✅ Pass | IPv4 TCP | * | WAN address | 443 | HTTPS público hacia Odoo |
| 5 | ✅ Pass | IPv4 TCP | * | 192.168.30.10 | 80 | NAT HTTP → Nginx Odoo |
| 6 | ✅ Pass | IPv4 TCP | * | 192.168.30.10 | 443 | NAT HTTPS → Nginx Odoo |
| 7 | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** |

### ⚠️ Puntos clave — WAN
- Las reglas **Block private networks** y **Block bogon networks** son generadas automáticamente por pfSense.
- El acceso SSH **ya no se expone por WAN**. El Admin accede por la VLAN 40 interna únicamente.
- La regla `Bloquear todo lo demás` debe estar **al final**.

---

## Interfaz LAN — VLAN 10 (Clientes)
*Firewall → Rules → LAN*

Controla el tráfico que sale desde la red interna de clientes (192.168.10.0/24).

| # | Estado | Protocolo | Source | Destino | Puerto | Descripción |
|---|:---:|:---:|:---|:---|:---:|:---|
| 1 | ✅ Pass | * | * | LAN Address | 443 / 80 | **Anti-Lockout Rule** *(auto)* |
| 2 | ✅ Pass | IPv4 TCP | LAN subnets | 192.168.30.10 | 80 | LAN → Odoo HTTP |
| 3 | ✅ Pass | IPv4 TCP | LAN subnets | 192.168.30.10 | 443 | LAN → Odoo HTTPS |
| 4 | ✅ Pass | IPv4 TCP | LAN subnets | 192.168.30.10 | 8069 | Clientes → Odoo puerto nativo |
| 5 | ✅ Pass | IPv4 TCP | LAN subnets | 192.168.30.10 | 8072 | WebSocket Odoo *(live chat)* |
| 6 | ✅ Pass | IPv4 * | LAN subnets | * | * | LAN → Internet *(navegación general)* |
| 7 | ❌ Block | IPv4 * | 192.168.10.0/24 | 192.168.40.0/24 | * | **VLAN10 NO puede alcanzar VLAN Admin** |
| 8 | ❌ Block | IPv4 * | 192.168.30.0/24 | * | * | Bloquear acceso directo desde DMZ |

### ⚠️ Puntos clave — LAN
- La regla 7 es nueva: **bloquea que cualquier cliente de la VLAN 10 acceda a la VLAN 40** de administración.
- La regla 8 bloquea que IPs de la DMZ intenten comunicarse hacia la LAN (anti-pivoting).

---

## Interfaz OPT1 / DMZ — VLAN 30 (Servidores)
*Firewall → Rules → OPT1*

Controla el tráfico que sale desde el servidor Debian en la DMZ (192.168.30.0/24).

> **⚠️ El orden es crítico.** Los bloques deben ir ANTES que los permisos.

| Posición | Acción | Protocolo | Source | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| **1** | ❌ Block | IPv4 * | DMZ subnets | 192.168.10.0/24 | * | **DMZ NO puede atacar LAN** |
| **2** | ❌ Block | IPv4 * | DMZ subnets | 192.168.10.1 | * | **DMZ NO puede acceder a pfSense LAN** |
| **3** | ❌ Block | IPv4 * | DMZ subnets | 192.168.40.0/24 | * | **DMZ NO puede alcanzar VLAN Admin** ← NUEVO |
| **4** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 80 | Servidor → actualizaciones internet |
| **5** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 443 | Servidor → actualizaciones internet |
| **6** | ✅ Pass | IPv4 UDP | DMZ subnets | * | 53 | DNS resolución de nombres |
| **7** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 25 | Envío de emails desde Odoo |
| **8** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 465 | Envío de emails desde Odoo |
| **9** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 587 | Envío de emails desde Odoo |
| **10** | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** |

### Lógica de evaluación — OPT1/DMZ

```
Tráfico desde servidor DMZ (192.168.30.10)
         │
         ▼
[Pos. 1] ¿Va hacia LAN (192.168.10.0/24)?   ──► ❌ BLOQUEADO (anti-pivoting)
[Pos. 2] ¿Va hacia pfSense LAN (.10.1)?      ──► ❌ BLOQUEADO (protege pfSense)
[Pos. 3] ¿Va hacia VLAN Admin (40.0/24)?     ──► ❌ BLOQUEADO (aislamiento admin) ← NUEVO
         │ No
         ▼
[Pos. 4] ¿Es TCP puerto 80?                  ──► ✅ PERMITIDO (actualizaciones)
[Pos. 5] ¿Es TCP puerto 443?                 ──► ✅ PERMITIDO (actualizaciones)
[Pos. 6] ¿Es UDP puerto 53?                  ──► ✅ PERMITIDO (DNS)
[Pos. 7-9] ¿Es SMTP/465/587?                ──► ✅ PERMITIDO (emails Odoo)
         │ No coincide con ninguna
         ▼
[Pos. 10] Cualquier otro tráfico             ──► ❌ BLOQUEADO (deny-all)
```

---

## Interfaz OPT2 / Admin — VLAN 40 (Administración) ← NUEVA
*Firewall → Rules → OPT2*

Controla el tráfico desde las máquinas de administración y DBA (192.168.40.0/24).

> Esta interfaz tiene **acceso restringido y unidireccional**: puede llegar al servidor, pero nada puede llegar a ella desde otras VLANs.

| Posición | Acción | Protocolo | Source | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| **1** | ✅ Pass | IPv4 TCP | 192.168.40.11/32 | 192.168.30.10 | 22 | **SSH Admin → servidor** |
| **2** | ✅ Pass | IPv4 TCP | 192.168.40.12/32 | 192.168.30.10 | 22 | **SSH DBA → servidor (túnel)** |
| **3** | ✅ Pass | IPv4 TCP | 192.168.40.11/32 | 192.168.30.21 | 8069 | Admin → Odoo (debug/panel) |
| **4** | ✅ Pass | IPv4 TCP | 192.168.40.0/24 | * | 80 | Admin → Internet (actualizaciones) |
| **5** | ✅ Pass | IPv4 TCP | 192.168.40.0/24 | * | 443 | Admin → Internet (actualizaciones) |
| **6** | ✅ Pass | IPv4 UDP | 192.168.40.0/24 | * | 53 | DNS para máquinas admin |
| **7** | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** |

### ⚠️ Puntos clave — OPT2/Admin
- Solo **Admin (`.40.11`)** puede hacer SSH al servidor y acceder al panel de Odoo.
- Solo **DBA (`.40.12`)** puede hacer SSH al servidor (para crear el túnel a PostgreSQL).
- **PostgreSQL (5432) no está expuesto** en ninguna regla — el DBA solo accede vía túnel SSH.
- Ninguna otra VLAN puede iniciar conexiones hacia la VLAN 40.

### Lógica de evaluación — OPT2/Admin

```
Tráfico desde VLAN Admin (192.168.40.x)
         │
         ▼
[Pos. 1] ¿Es Admin (.40.11) → servidor :22?  ──► ✅ PERMITIDO (SSH administración)
[Pos. 2] ¿Es DBA (.40.12) → servidor :22?    ──► ✅ PERMITIDO (SSH túnel DBA)
[Pos. 3] ¿Es Admin → Odoo :8069?             ──► ✅ PERMITIDO (debug panel)
[Pos. 4-5] ¿Es HTTP/HTTPS a internet?        ──► ✅ PERMITIDO (actualizaciones)
[Pos. 6] ¿Es DNS?                            ──► ✅ PERMITIDO
         │ No coincide
         ▼
[Pos. 7] Cualquier otro tráfico              ──► ❌ BLOQUEADO
```

---

## NAT — Port Forwarding
*Firewall → NAT → Port Forward*

| Interfaz | Protocolo | Source | Destino | Puerto origen | Redirige a | Puerto destino | Descripción |
|:---:|:---:|:---:|:---|:---:|:---|:---:|:---|
| WAN | TCP | * | WAN address | 80 | 192.168.30.10 | 80 | NAT HTTP → Nginx Odoo |
| WAN | TCP | * | WAN address | 443 | 192.168.30.10 | 443 | NAT HTTPS → Nginx Odoo |
| LAN | TCP/UDP | 192.168.10.0/24 | * | 53 | 192.168.10.1 | 53 | Forzar DNS VLAN10 → pfSense |

> **Nota:** El acceso SSH ya **no se expone por WAN**. El administrador accede directamente desde la VLAN 40 interna. Se elimina la regla NAT SSH de WAN que existía anteriormente.

---

## DNS — Resolución de Nombres para Odoo
*Services → DNS Resolver + Firewall → NAT → Port Forward*

### Paso 1 — Host Override en el DNS Resolver

*Services → DNS Resolver → Host Overrides → + Add*

| Campo | Valor |
|:---|:---|
| **Host** | `erp.odoo` |
| **Domain** | `tfg.com` |
| **IP Address** | `192.168.30.10` |
| **Description** | `Servidor Odoo ERP - DMZ` |

### Paso 2 — DNS Server en el DHCP de la LAN

*Services → DHCP Server → LAN → Server Options*

| Campo | Valor |
|:---|:---|
| **DNS Server 1** | `192.168.10.1` |

### Paso 3 — NAT DNS redirect (VLAN 10)

*Firewall → NAT → Port Forward*

| Campo | Valor |
|:---|:---|
| **Interface** | `LAN` |
| **Protocol** | `TCP/UDP` |
| **Source** | `192.168.10.0/24` |
| **Destination port** | `53` |
| **Redirect target IP** | `192.168.10.1` |
| **Redirect target port** | `53` |
| **Description** | `Forzar DNS VLAN10 → pfSense` |

> **Por qué es necesario:** Los clientes Linux modernos con `systemd-resolved` pueden ignorar el DNS enviado por DHCP. Esta regla intercepta cualquier consulta DNS de la VLAN 10 y la redirige a pfSense.

### Flujo completo de resolución DNS

```
Cliente VLAN 10 (192.168.10.x)
        │  DNS query → erp.odoo.tfg.com (hacia cualquier servidor)
        ▼  pfSense intercepta por NAT Port Forward :53
[ pfSense DNS Resolver ]
        │  Host Override → erp.odoo.tfg.com = 192.168.30.10
        ▼
Cliente recibe: 192.168.30.10
        │  HTTPS → 192.168.30.10:443
        ▼
[ Nginx → Odoo :8069 ] ✅
```

---

## Resumen de la arquitectura de seguridad

```
Internet (WAN)
      │  Solo puertos 80/443 abiertos al público
      ▼
  [ pfSense ]
      │
      ├─── VLAN 10 / LAN (192.168.10.0/24) ──► Clientes / Trabajadores
      │         │ Puede acceder a Odoo (80/443/8069/8072)
      │         │ Puede navegar por Internet
      │         │ NO puede acceder a VLAN 40 (Admin) ← NUEVO
      │         │ NO puede iniciar conexiones a DMZ directamente
      │
      ├─── VLAN 30 / DMZ (192.168.30.0/24) ──► Servidor Debian + contenedores
      │         │ Puede salir a Internet (HTTP/HTTPS/DNS/SMTP)
      │         │ NO puede alcanzar VLAN 10 (anti-pivoting)
      │         │ NO puede alcanzar VLAN 40 (Admin) ← NUEVO
      │         │ Puerto 5432 PostgreSQL: nunca expuesto
      │
      └─── VLAN 40 / Admin (192.168.40.0/24) ──► Máquinas Admin y DBA
                │ Puede hacer SSH al servidor (Admin y DBA)
                │ Puede acceder a panel Odoo :8069 (solo Admin)
                │ Puede salir a Internet (actualizaciones)
                │ NINGUNA otra VLAN puede alcanzarla
```

---

## Cómo configurar la VLAN 40 en pfSense desde cero

### Paso 1 — Crear la VLAN
*Interfaces → Assignments → VLANs → Add*

| Campo | Valor |
|---|---|
| Parent interface | Interfaz física (ej. `em0`) |
| VLAN tag | `40` |
| Description | `VLAN_Admin` |

### Paso 2 — Asignar la interfaz
*Interfaces → Assignments → Add*
- Seleccionar la VLAN 40 recién creada → **Add**
- Ir a **Interfaces → OPT2** → Enable ✅
- IPv4 Configuration Type: `Static IPv4`
- IPv4 Address: `192.168.40.1 / 24`
- Description: `OPT2_Admin`
- **Save** → **Apply Changes**

### Paso 3 — Configurar DHCP (opcional, mejor IP estática)
*Services → DHCP Server → OPT2*
- Enable ✅
- Range: `192.168.40.100` — `192.168.40.200`
- Reservas estáticas:
  - Admin: MAC de la máquina admin → `192.168.40.11`
  - DBA: MAC de la máquina DBA → `192.168.40.12`

### Paso 4 — Añadir reglas de firewall
*Firewall → Rules → OPT2* → añadir las reglas de la tabla de la sección OPT2.

### Paso 5 — Añadir reglas de bloqueo inter-VLAN
- En *Firewall → Rules → LAN*: añadir regla `192.168.10.0/24 → 192.168.40.0/24 BLOCK`
- En *Firewall → Rules → OPT1*: añadir regla `192.168.30.0/24 → 192.168.40.0/24 BLOCK`

---

## Acciones completadas

- [x] Limpiar reglas EasyRule duplicadas en OPT1.
- [x] Configurar DNS Resolver con Host Override `erp.odoo.tfg.com → 192.168.30.10`.
- [x] Regla NAT DNS redirect en Port Forward para VLAN 10.
- [x] Actualizar `server_name` de Nginx a `erp.odoo.tfg.com`.
- [x] Verificar orden correcto en OPT1 (bloques antes que permisos).
- [x] **Crear VLAN 40 (OPT2) para administración separada.**
- [x] **Añadir reglas de bloqueo VLAN30→VLAN40 y VLAN10→VLAN40.**
- [x] **Eliminar exposición SSH por WAN — acceso solo desde VLAN 40.**
