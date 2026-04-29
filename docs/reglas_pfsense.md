# Configuración de Reglas en pfSense (Firewall y NAT)

Este documento detalla todas las reglas configuradas en pfSense para la arquitectura de red del proyecto TFG.
La infraestructura cuenta con tres interfaces: **WAN** (red pública), **LAN** (red interna 192.168.10.0/24) y **OPT1/DMZ** (zona desmilitarizada 192.168.30.0/24).

> **Nota:** En pfSense, el orden de las reglas importa. Se evalúan de arriba a abajo y se aplica la primera que coincide.

---

## Interfaz WAN
*Firewall → Rules → WAN*

Controla el tráfico que entra desde Internet hacia la red.

| # | Estado | Protocolo | Source | Puerto | Destino | Puerto | Descripción |
|---|:---:|:---:|:---|:---:|:---|:---:|:---|
| 1 | ❌ Block | * | RFC 1918 networks | * | * | * | Block private networks *(auto)* |
| 2 | ❌ Block | * | Reserved / Not assigned by IANA | * | * | * | Block bogon networks *(auto)* |
| 3 | ❌ Block | IPv4 * | * | * | * | * | **Bloquear todo lo demás** *(regla final de denegación)* |
| 4 | ✅ Pass | IPv4 TCP | * | * | WAN address | 80 (HTTP) | HTTP — redirige a HTTPS |
| 5 | ✅ Pass | IPv4 TCP | * | * | WAN address | 443 (HTTPS) | HTTPS público hacia Odoo |
| 6 | ✅ Pass | IPv4 TCP | * | * | 192.168.30.10 | 80 (HTTP) | NAT HTTP → Nginx Odoo |
| 7 | ✅ Pass | IPv4 TCP | * | * | 192.168.30.10 | 443 (HTTPS) | NAT HTTPS → Nginx Odoo |
| 8 | ✅ Pass | IPv4 TCP | 192.168.163.140 | * | 192.168.30.10 | 22 (SSH) | NAT SSH admin *(restringido a IP de administrador)* |
| 9 | ✅ Pass | IPv4 TCP | 192.168.163.140 | * | 192.168.30.10 | 9090 | NAT Cockpit admin panel *(restringido a IP de administrador)* |

### ⚠️ Puntos clave — WAN
- Las reglas **Block private networks** y **Block bogon networks** son generadas automáticamente por pfSense al activar la opción en la interfaz WAN. Protegen contra spoofing de IPs privadas/reservadas.
- La regla `Bloquear todo lo demás` (regla 3, con ❌) debe estar **al final** para actuar como "default deny" explícito.
- El acceso SSH y Cockpit está **restringido** a la IP `192.168.163.140` (IP del administrador). Nunca abrir estos puertos a `*`.

---

## Interfaz LAN
*Firewall → Rules → LAN*

Controla el tráfico que sale desde la red interna de clientes (192.168.10.0/24).

| # | Estado | Protocolo | Source | Puerto | Destino | Puerto | Descripción |
|---|:---:|:---:|:---|:---:|:---|:---:|:---|
| 1 | ✅ Pass | * | * | * | LAN Address | 443 / 80 | **Anti-Lockout Rule** *(auto — acceso al panel pfSense)* |
| 2 | ~~Pass~~ | IPv4 * | LAN subnets | * | * | * | ~~Default allow LAN to any rule~~ *(desactivada — reemplazada por reglas específicas)* |
| 3 | ✅ Pass | IPv6 * | LAN subnets | * | * | * | Default allow LAN IPv6 to any rule |
| 4 | ✅ Pass | IPv4 TCP | LAN subnets | * | 192.168.30.10 | 80 (HTTP) | LAN a Odoo HTTP |
| 5 | ✅ Pass | IPv4 TCP | LAN subnets | * | 192.168.30.10 | 443 (HTTPS) | LAN a Odoo HTTPS |
| 6 | ✅ Pass | IPv4 TCP | LAN subnets | * | 192.168.30.10 | 8069 | Clientes → Odoo puerto nativo |
| 7 | ✅ Pass | IPv4 TCP | LAN subnets | * | 192.168.30.10 | 8072 | WebSocket Odoo *(live chat)* |
| 8 | ✅ Pass | IPv4 * | LAN subnets | * | * | * | LAN → Internet *(navegación general)* |
| 9 | ❌ Block | IPv4 * | 192.168.30.0/24 | * | * | * | Bloquear acceso directo a DMZ |

### ⚠️ Puntos clave — LAN
- La regla **Anti-Lockout** (regla 1) la genera pfSense automáticamente y **no se debe borrar** para no perder el acceso al panel de administración.
- La **"Default allow LAN to any"** está **desactivada** (en gris). Se ha sustituido por reglas más específicas (reglas 4–8) para un control más granular.
- La regla 9 bloquea que cualquier IP de la DMZ intente comunicarse directamente hacia la LAN (anti-pivoting adicional desde LAN).

---

## Interfaz OPT1 / DMZ — Orden correcto de reglas
*Firewall → Rules → OPT1*

Controla el tráfico que sale desde el servidor Debian en la DMZ (192.168.30.0/24).

> **⚠️ El orden es crítico.** Los bloques deben ir ANTES que los permisos. pfSense evalúa las reglas de arriba a abajo y aplica la primera que coincide.

### Orden correcto (de arriba a abajo)

| Posición | Acción | Protocolo | Source | Destino | Puerto | Descripción |
|:---:|:---:|:---:|:---|:---|:---:|:---|
| **1** | ❌ Block | IPv4 * | DMZ subnets | 192.168.10.0/24 | * | **DMZ NO puede atacar LAN** ← ¡PRIMERO! |
| **2** | ❌ Block | IPv4 * | DMZ subnets | 192.168.10.1 | * | **DMZ NO puede acceder a pfSense LAN** |
| **3** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 80 (HTTP) | Servidor → actualizaciones internet |
| **4** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 443 (HTTPS) | Servidor → actualizaciones internet |
| **5** | ✅ Pass | IPv4 UDP | DMZ subnets | * | 53 (DNS) | DNS resolución de nombres |
| **6** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 25 (SMTP) | Envío de emails desde Odoo |
| **7** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 465 (SMTP/S) | Envío de emails desde Odoo |
| **8** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 587 (SUBMISSION) | Envío de emails desde Odoo |
| **9** | ✅ Pass | IPv4 TCP | DMZ subnets | * | 5432 | PostgreSQL *(si BD es externa)* |
| **10** | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** ← ¡ÚLTIMO! |

### Cómo limpiar y reordenar en pfSense

**Paso 1 — Eliminar reglas EasyRule duplicadas e innecesarias**

En `Firewall → Rules → OPT1`, **borrar (🗑)** las siguientes reglas `Passed via EasyRule`:
- `IPv4 TCP / * / 80` × 2 → eliminar ambas (la regla 3 las sustituye)
- `IPv4 TCP / * / 443` × 2 → eliminar ambas (la regla 4 las sustituye)
- `IPv4 TCP / * / 53` × 2 → eliminar ambas (la regla 5 las sustituye)
- `IPv4 * / * / *` (allow all) → **eliminar obligatoriamente** — es demasiado permisiva

**Paso 2 — Reordenar con arrastre (☰)**

Arrastra las reglas para dejarlas en el orden de la tabla anterior:
1. `❌ DMZ NO puede atacar LAN` → arriba del todo
2. `❌ DMZ NO puede acceder a pfSense LAN` → segunda posición
3. Las reglas `✅ Pass` de HTTP, HTTPS, DNS, SMTP, PostgreSQL en el medio
4. `❌ Bloquear todo lo demás` → última posición

**Paso 3 — Guardar y aplicar**

Pulsar **Save** → luego **Apply Changes** (botón verde en la parte superior).

### Lógica de evaluación del firewall

```
Tráfico desde servidor DMZ (192.168.30.10)
         │
         ▼
[Pos. 1] ¿Va hacia LAN (192.168.10.0/24)?  ──► ❌ BLOQUEADO (anti-pivoting)
         │ No
         ▼
[Pos. 2] ¿Va hacia pfSense LAN (10.1)?     ──► ❌ BLOQUEADO (protege pfSense)
         │ No
         ▼
[Pos. 3] ¿Es TCP puerto 80?                ──► ✅ PERMITIDO (actualizaciones)
[Pos. 4] ¿Es TCP puerto 443?               ──► ✅ PERMITIDO (actualizaciones)
[Pos. 5] ¿Es UDP puerto 53?                ──► ✅ PERMITIDO (DNS)
[Pos. 6-8] ¿Es SMTP/465/587?              ──► ✅ PERMITIDO (emails Odoo)
[Pos. 9]   ¿Es TCP puerto 5432?            ──► ✅ PERMITIDO (PostgreSQL)
         │ No coincide con ninguna
         ▼
[Pos. 10] Cualquier otro tráfico           ──► ❌ BLOQUEADO (deny-all)
```

---

## NAT — Port Forwarding
*Firewall → NAT → Port Forward*

| Interfaz | Protocolo | Source | Destino | Puerto origen | Redirige a | Puerto destino | Descripción |
|:---:|:---:|:---:|:---|:---:|:---|:---:|:---|
| WAN | TCP | * | WAN address | 80 (HTTP) | 192.168.30.10 | 80 | NAT HTTP → Nginx Odoo |
| WAN | TCP | * | WAN address | 443 (HTTPS) | 192.168.30.10 | 443 | NAT HTTPS → Nginx Odoo |
| WAN | TCP | 192.168.163.140 | 192.168.30.10 | 22 (SSH) | 192.168.30.10 | 22 | NAT SSH admin *(restringido)* |
| WAN | TCP | 192.168.163.140 | 192.168.30.10 | 9090 | 192.168.30.10 | 9090 | NAT Cockpit admin panel *(restringido)* |

---

## Resumen de la arquitectura de seguridad

```
Internet (WAN)
      │
      │ Solo puertos 80/443 abiertos al público
      │ SSH/9090 solo desde IP admin (192.168.163.140)
      ▼
  [ pfSense ]
      │
      ├─── LAN (192.168.10.0/24) ──► Clientes / Trabajadores
      │         │
      │         │ Puede acceder a Odoo (80/443/8069/8072)
      │         │ Puede navegar por Internet
      │         │ NO puede iniciar conexiones a DMZ directamente (regla 9)
      │
      └─── DMZ (192.168.30.0/24) ──► Servidor Debian (192.168.30.10)
                │
                │ Puede salir a Internet (HTTP/HTTPS/DNS/SMTP)
                │ NO puede alcanzar la LAN (192.168.10.0/24) ← anti-pivoting
                │ NO puede acceder al panel de pfSense (192.168.10.1)
```

---

## Acciones pendientes / mejoras recomendadas

- [ ] **Limpiar reglas EasyRule duplicadas** en OPT1: hay HTTP, HTTPS y DNS repetidos. Consolidar en una sola regla por protocolo/puerto.
- [ ] **Eliminar o restringir** la regla `Passed via EasyRule` con `IPv4 *` (allow all) en OPT1 — es demasiado permisiva.
- [ ] **Verificar el orden** en OPT1: las reglas de bloqueo (B1, B2) deben estar antes de las reglas de permiso.
- [ ] Confirmar si la regla `IPv4 *` al final de WAN (Bloquear todo lo demás) está correctamente posicionada como última regla.
- [ ] Documentar la IP real del administrador (`192.168.163.140`) en el inventario del proyecto.
