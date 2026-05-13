# Configuración de Reglas en pfSense (Firewall y NAT)

Este documento detalla todas las reglas configuradas en pfSense para la arquitectura de red del proyecto TFG.
La infraestructura cuenta con tres interfaces: **WAN** (red pública), **LAN** (red interna 192.168.10.0/24) y **OPT1/DMZ** (zona desmilitarizada 192.168.30.0/24).

> **Nota:** En pfSense, el orden de las reglas importa. Se evalúan de arriba a abajo y se aplica la primera que coincide.

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
| 7 | ✅ Pass | IPv4 TCP | `192.168.163.140` | 192.168.30.10 | 22 | NAT SSH admin (restringido) |
| 8 | ✅ Pass | IPv4 TCP | `192.168.163.140` | 192.168.30.10 | 9090 | NAT Cockpit admin panel |
| 9 | ❌ Block | IPv4 * | * | * | * | **Bloquear todo lo demás** |

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

### Conclusión Técnica sobre Endurecimiento Saliente (Egress Filtering)

Durante la fase de endurecimiento de la red DMZ, se evaluó la restricción del tráfico de salida hacia Internet bajo una política de "Mínimo Privilegio" (Zero Trust). Los resultados y decisiones tomadas se detallan a continuación:

1. **Limitación de FQDN:** El filtrado basado en dominios estáticos (FQDN) en pfSense resultó insuficiente para servicios de CI/CD como GitHub Actions, debido al uso de subdominios dinámicos y CDNs de baja latencia (`*.actions.githubusercontent.com`, `*.blob.core.windows.net`).
2. **Evaluación de pfBlockerNG (ASN):** Se intentó implementar filtrado de salida basado en ASN mediante pfBlockerNG-devel, configurando los sistemas autónomos AS36459 (GitHub) y AS8075 (Microsoft/Azure). 
3. **Dependencia de Terceros:** La solución requiere un token de API externo de `IPinfo.io` para resolver los rangos CIDR de cada ASN de forma dinámica, lo que introduce una dependencia de un servicio de terceros no gestionado localmente.
4. **Decisión Final:** Por motivos de estabilidad y autonomía de la infraestructura, se pospone la integración de ASN como mejora futura, manteniendo provisionalmente una regla de salida permisiva por el puerto **TCP 443 (HTTPS)** hacia `Any`. Esto garantiza el funcionamiento del despliegue automatizado mientras se mantiene el bloqueo absoluto de todos los demás protocolos y puertos no esenciales.

*Nota:* Esta decisión técnica ha sido documentada para su defensa en la memoria del TFG, destacando el equilibrio necesario entre seguridad extrema y operatividad del servicio.

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

## DNS — Resolución de Nombres para Odoo (proceso completo)
*Services → DNS Resolver + Firewall → NAT → Port Forward*

Esta sección documenta el proceso completo de configuración DNS para que los clientes de la VLAN 10 (192.168.10.0/24) accedan a Odoo mediante `https://erp.odoo.tfg.com` en lugar de por IP directa.

---

### Paso 1 — Host Override en el DNS Resolver

*Services → DNS Resolver → Host Overrides → + Add*

Asocia el nombre de dominio con la IP del servidor Odoo en la DMZ (VLAN 30):

| Campo | Valor |
|:---|:---|
| **Host** | `erp.odoo` |
| **Domain** | `tfg.com` |
| **IP Address** | `192.168.30.10` |
| **Description** | `Servidor Odoo ERP - DMZ` |

➡️ **Save** → **Apply Changes**

---

### Paso 2 — DNS Server en el DHCP de la LAN

*Services → DHCP Server → LAN → sección "Server Options"*

Configurar pfSense como servidor DNS que reciben todos los clientes de la VLAN 10 por DHCP:

| Campo | Valor |
|:---|:---|
| **DNS Server 1** | `192.168.10.1` |

➡️ **Save** → **Apply Changes**

> **Por qué es necesario:** Sin esto, los clientes usarán DNS públicos (8.8.8.8, etc.) que no conocen el Host Override interno y resolverán el dominio a una IP de internet incorrecta.

---

### Paso 3 — Regla NAT: Interceptar todo el DNS de la VLAN 10

*Firewall → NAT → Port Forward → + Add*

**Problema real encontrado durante el TFG:** Los clientes Linux modernos (Lubuntu, Ubuntu, Debian) utilizan `systemd-resolved` con `127.0.0.53` como stub DNS local. Este servicio puede ignorar el DNS enviado por DHCP y reenviar consultas a servidores DNS públicos externos, haciendo que `erp.odoo.tfg.com` resuelva a una IP real de internet (`185.151.30.174`) en lugar de a `192.168.30.10`.

**Solución implementada:** Regla NAT de redirección que intercepta **cualquier consulta DNS** de la VLAN 10, sin importar a qué servidor DNS vaya dirigida:

| Campo | Valor |
|:---|:---|
| **Interface** | `LAN` |
| **Protocol** | `TCP/UDP` |
| **Source** | `LAN subnets` (`192.168.10.0/24`) |
| **Source Ports** | `*` |
| **Destination** | `*` (cualquier IP exterior) |
| **Destination port** | `53 (DNS)` |
| **Redirect target IP** | `192.168.10.1` |
| **Redirect target port** | `53` |
| **Description** | `Forzar DNS VLAN10 → pfSense` |

➡️ **Save** → **Apply Changes**

> **Efecto:** Cualquier paquete UDP/TCP al puerto 53 desde la VLAN 10 es redirigido a pfSense (`192.168.10.1`), que responde con el Host Override correcto. Da igual que el cliente use 8.8.8.8, 1.1.1.1 o `127.0.0.53` — pfSense siempre intercepta y responde con `192.168.30.10`.

---

### Flujo completo de resolución DNS con la arquitectura real

```
Cliente VLAN 10 (192.168.10.101 — Lubuntu con systemd-resolved)
        │
        │  1. Pregunta DNS: "¿dónde está erp.odoo.tfg.com?"
        │     systemd-resolved envía la consulta a 8.8.8.8:53
        │
        ▼ pfSense intercepta (Regla NAT Port Forward — LAN TCP/UDP :53)
        │
        │  2. Redirige a sí mismo → 192.168.10.1:53
        ▼
[ pfSense DNS Resolver ]
        │
        │  3. Consulta el Host Override → encuentra erp.odoo.tfg.com
        │     Responde: 192.168.30.10
        ▼
Cliente recibe la IP: erp.odoo.tfg.com = 192.168.30.10
        │
        │  4. El cliente abre conexión HTTPS hacia 192.168.30.10:443
        │     (permitida por reglas de firewall LAN→DMZ puerto 443)
        ▼
[ Nginx — 192.168.30.10:443 ]
        │  proxy_pass → http://odoo:8069
        ▼
[ Contenedor Odoo :8069 ] ✅ — Login de Odoo 17
```

---

### Paso 4 — Actualizar server_name en Nginx (servidor Debian)

La configuración de Nginx debe coincidir con el dominio del Host Override.
Ejecutar en el servidor Debian (`192.168.30.10`):

```bash
# Verificar el valor actual
grep server_name /opt/erp-odoo/config_nginx/*.conf

# Actualizar al dominio correcto si es necesario
sudo sed -i 's/erp.techsolutions.local/erp.odoo.tfg.com/g' /opt/erp-odoo/config_nginx/*.conf

# Confirmar el cambio
grep server_name /opt/erp-odoo/config_nginx/*.conf
# Debe mostrar: server_name erp.odoo.tfg.com;

# Recargar Nginx sin cortar el servicio
docker exec nginx-proxy nginx -s reload

# Validar sintaxis de configuración
docker exec nginx-proxy nginx -t
# OK: "nginx: configuration file test is successful"
```

---

### Verificación final — desde el cliente Lubuntu (VLAN 10)

```bash
# 1. Verificar que DNS resuelve a la IP interna (no a internet)
nslookup erp.odoo.tfg.com
# Debe devolver → Address: 192.168.30.10

# 2. Verificar acceso HTTPS al servidor
curl -k -I https://erp.odoo.tfg.com
# Debe devolver → HTTP/2 200 o HTTP/1.1 302

# 3. Abrir en navegador (siempre con https://)
# https://erp.odoo.tfg.com
```

### ⚠️ Puntos clave

- **La regla NAT Port Forward** (Paso 3) es imprescindible en entornos con clientes Linux modernos (`systemd-resolved`). Sin ella, el DNS interno no funciona aunque el DHCP esté bien configurado.
- **El DNS Resolver** debe estar activo: `Services → DNS Resolver → General Settings → Enable ✅` con interfaz LAN incluida.
- **`server_name` de Nginx** debe coincidir con el dominio del Host Override (`erp.odoo.tfg.com`).
- **En el navegador** siempre escribir con `https://` para que no lo interprete como búsqueda.
- El dominio `tfg.com` existe en internet; la regla NAT garantiza que pfSense responda antes que cualquier DNS público.

---


## Acciones pendientes / mejoras recomendadas

- [x] **Limpiar reglas EasyRule duplicadas** en OPT1: hay HTTP, HTTPS y DNS repetidos. Consolidar en una sola regla por protocolo/puerto.
- [x] **Eliminar o restringir** la regla `Passed via EasyRule` con `IPv4 *` (allow all) en OPT1 — es demasiado permisiva.
- [x] **Configurar DNS Resolver** con Host Override `erp.odoo.tfg.com → 192.168.30.10` para resolución de nombres interna.
- [x] **Regla NAT DNS redirect** en Port Forward para interceptar consultas DNS de VLAN 10 y forzarlas a pfSense.
- [x] **Actualizar server_name de Nginx** a `erp.odoo.tfg.com` en el servidor Debian.
- [x] **Verificar el orden** en OPT1: las reglas de bloqueo (B1, B2) deben estar antes de las reglas de permiso. (¡Correcto en las capturas!)
- [x] Confirmar si la regla `IPv4 *` al final de WAN (Bloquear todo lo demás) está correctamente posicionada como última regla. (¡Detectado como erróneo! Ver aviso arriba).
- [x] Documentar la IP real del administrador (`192.168.163.140`) en el inventario del proyecto.

---

## Interfaz OPT2 / VLAN 40 — Red de Administración

*Firewall → Interfaces → Assignments → + Añadir OPT2*

La VLAN 40 (`192.168.40.0/24`) es la **red de gestión del servidor**. Solo desde aquí se puede:
- Conectar por SSH al servidor Debian
- Acceder a Cockpit (`:9090`)
- Administrar el panel de base de datos de Odoo (`/web/database`)
- Gestionar el directorio LDAP con privilegios de administrador

> [!IMPORTANT]
> Esta VLAN no existe en el diagrama original del TFG pero sí en el diseño IaC actualizado (mayo 2026). Requiere un adaptador de red adicional en la VM pfSense y en las máquinas de administración.

### Configuración de la interfaz OPT2

*Interfaces → OPT2*

| Campo | Valor |
|-------|-------|
| IPv4 Configuration | Static IPv4 |
| IPv4 Address | `192.168.40.1` / `24` |
| Description | `VLAN_ADMIN` |

**DHCP OPT2** (*Services → DHCP Server → OPT2*):

| Campo | Valor |
|-------|-------|
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server | `192.168.40.1` |

### Reglas de Firewall → OPT2 (VLAN 40)

| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|---|:---:|:---:|:---|:---|:---:|:---|
| 1 | ✅ Pass | TCP | VLAN 40 | 192.168.30.10 | 22 | SSH al servidor Debian |
| 2 | ✅ Pass | TCP | VLAN 40 | 192.168.30.10 | 9090 | Cockpit — gestión visual |
| 3 | ✅ Pass | TCP | VLAN 40 | 192.168.30.20 | 443 | Odoo admin completo (sin restricciones Nginx) |
| 4 | ✅ Pass | TCP | VLAN 40 | 192.168.30.22 | 389 | LDAP admin (lectura + escritura) |
| 5 | ✅ Pass | TCP | VLAN 40 | 192.168.30.22 | 636 | LDAPS admin (cifrado) |
| 6 | ✅ Pass | TCP | VLAN 40 | * | 80, 443 | Actualizaciones internet |
| 7 | ✅ Pass | UDP | VLAN 40 | * | 53 | DNS resolución |
| 8 | ❌ Block | * | VLAN 40 | 192.168.10.0/24 | * | Anti-pivoting a VLAN 10 |
| 9 | ❌ Block | * | VLAN 40 | * | * | Deny all |

### Reglas adicionales VLAN 10 → LDAP

Añadir a las reglas de **Interfaz LAN (VLAN 10)**:

| # | Acción | Protocolo | Origen | Destino | Puerto | Descripción |
|---|:---:|:---:|:---|:---|:---:|:---|
| + | ✅ Pass | TCP | LAN subnets | 192.168.30.22 | 389 | LDAP autenticación (cn=readonly) |
| + | ❌ Block | TCP | LAN subnets | 192.168.30.22 | 636 | LDAPS admin bloqueado desde VLAN 10 |

### Tabla MACVLAN actualizada

Con la incorporación de OpenLDAP, la tabla de IPs MACVLAN queda:

| Contenedor | Red interna (`odoo_net`) | Red MACVLAN (`macvlan_vlan30`) | Acceso |
|:---|:---|:---|:---|
| `odoo_erp` (PostgreSQL) | 172.19.0.x | ❌ Sin IP pública | Solo contenedores internos |
| `odoo-web` (Odoo 17) | 172.19.0.3 | `192.168.30.21` | VLAN 10 + VLAN 40 vía Nginx |
| `openldap` (LDAP) | 172.19.0.5 | `192.168.30.22` | VLAN 10 (:389 readonly), VLAN 40 (:389/:636 admin) |
| `nginx-proxy` (Nginx) | 172.19.0.4 | `192.168.30.20` | Todos (80/443) |

---

## Securización del Panel de Administración de pfSense

Actualmente, pfSense es accesible desde la VLAN 10 (LAN) gracias a la regla *Anti-Lockout*. Para cumplir con el requerimiento de que **solo se pueda acceder desde la VLAN 40 y únicamente por el usuario admin (no dba)**, debemos aplicar seguridad en dos capas: Red (Firewall) y Aplicación (Autenticación LDAP).

### Capa 1: Restricción por Red (Firewall)

1. **Crear regla de acceso en VLAN 40 (OPT2):**
   *Firewall → Rules → OPT2*
   Añade una regla al principio:
   - **Action:** Pass
   - **Protocol:** TCP
   - **Source:** `VLAN_ADMIN subnets` (VLAN 40)
   - **Destination:** `This Firewall (self)`
   - **Destination Port:** HTTPS (443)

2. **Deshabilitar acceso desde VLAN 10 (LAN):**
   *System → Advanced → Admin Access*
   - Marca la casilla: **Disable webConfigurator anti-lockout rule**.
   - ⚠️ *Peligro:* Haz esto **solo después** de comprobar que puedes entrar a pfSense desde una IP de la VLAN 40. De lo contrario, te quedarás fuera del cortafuegos.

Con esto, si el usuario `dba` o cualquier otro intenta entrar a `https://192.168.10.1` desde la LAN, el firewall descartará la conexión silenciosamente.

### Capa 2: Restricción por Autenticación (LDAP en pfSense)

Para diferenciar entre el usuario `admin` y `dba` (ambos pertenecen a la VLAN 40), conectaremos pfSense a nuestro servidor OpenLDAP de la DMZ (`192.168.30.22`).

1. **Añadir el servidor LDAP:**
   *System → User Manager → Authentication Servers → + Add*
   - **Descriptive name:** `OpenLDAP DMZ`
   - **Type:** LDAP
   - **Hostname:** `192.168.30.22`
   - **Port value:** 389
   - **Transport:** TCP - Standard
   - **Base DN:** `dc=tfg,dc=com`
   - **Authentication containers:** `ou=usuarios,dc=tfg,dc=com`
   - **Bind credentials:** `cn=admin,dc=tfg,dc=com` / *(tu_contraseña)*
   - **User naming attribute:** `uid`
   - **Group naming attribute:** `cn`
   - **Group member attribute:** `member`

2. **Configurar privilegios del grupo admin:**
   *System → User Manager → Groups → + Add*
   - Crea un grupo llamado exactamente **`admin`** (para que coincida con LDAP).
   - En *Assigned Privileges*, dale el privilegio **WebCfg - All pages** (Administrador total).
   - No crees el grupo `dba` en pfSense (o créalo pero sin ningún privilegio asignado).

3. **Activar LDAP para el login:**
   *System → User Manager → Settings*
   - **Authentication Server:** Selecciona `OpenLDAP DMZ`.
   - Guarda los cambios.

**Resultado final:** 
Cualquier persona en la VLAN 40 puede ver la pantalla de login de pfSense. Pero si el usuario `dba` introduce sus credenciales LDAP, pfSense lo validará, verá que no pertenece al grupo con privilegios de `WebCfg` y le denegará el acceso. Solo el usuario `admin` podrá entrar.
