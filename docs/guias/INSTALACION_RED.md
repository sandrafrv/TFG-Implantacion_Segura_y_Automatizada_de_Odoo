# Guía de Red — pfSense: Firewall, DHCP, DNS y VLAN 40

**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)

> [!IMPORTANT]
> pfSense debe configurarse **antes** que cualquier otro componente.
> Es el firewall, router, DHCP y servidor DNS de toda la infraestructura.

> [!TIP]
> **¿Quieres automatizar?** El script `scripts/deploy/generate_pfsense_config.sh` genera un
> `config.xml` completo con todas las interfaces, DHCP, DNS, NAT y reglas de firewall documentadas
> a continuación. Impórtalo en **Diagnostics → Backup/Restore** y salta a la [sección 10](#10-autenticación-ldap-en-el-panel-pfsense).
> También disponible como artefacto descargable en el pipeline CI de GitHub Actions.

---

## 1. Crear la VM pfSense en VirtualBox

### Parámetros de la VM

| Campo | Valor |
|:------|:------|
| Nombre | `pfSense-TFG` |
| Tipo | BSD → FreeBSD (64-bit) |
| RAM | 1024 MB |
| CPU | 1 core |
| Disco | 10 GB (VDI, dinámico) |

### Adaptadores de red (¡orden importante!)

| Adaptador | Modo VirtualBox | Interfaz pfSense | Subred |
|:----------|:----------------|:-----------------|:-------|
| Adaptador 1 | **NAT** | `vtnet0` → **WAN** | Internet |
| Adaptador 2 | **Red Interna** → `LAN_10` | `vtnet1` → **LAN** | VLAN 10 clientes (192.168.10.0/24) |
| Adaptador 3 | **Red Interna** → `DMZ_30` | `vtnet2` → **OPT1** | VLAN 30 DMZ (192.168.30.0/24) |
| Adaptador 4 | **Red Interna** → `ADMIN_40` | `vtnet3` → **OPT2** | VLAN 40 admin (192.168.40.0/24) |

> [!NOTE]
> Las otras VMs deben usar los **mismos nombres** de red interna (`LAN_10`, `DMZ_30`, `ADMIN_40`) para que estén en la misma red virtual.

---

## 2. Instalar pfSense

1. Arrancar la VM con la ISO adjunta como unidad óptica
2. Seleccionar **Install pfSense** → aceptar licencia
3. Seleccionar **Auto (UFS)** → **Continue** → esperar instalación (~2 min)
4. **Reboot** → retirar la ISO antes del reinicio

---

## 3. Asignación de Interfaces (Primera Consola)

Al arrancar aparece el asistente de texto. Opción **1 (Assign Interfaces)**:

```
Should VLANs be set up now? → n
Enter the WAN interface name:      vtnet0
Enter the LAN interface name:      vtnet1
Enter the Optional 1 interface:    vtnet2
Enter the Optional 2 interface:    vtnet3
Do you want to proceed? → y
```

Opción **2 (Set Interface IP Addresses)**:
- **LAN** → IP `192.168.10.1`, máscara `/24`, habilitar DHCP: SÍ, rango `192.168.10.100–200`
- **OPT1 (DMZ)** → IP `192.168.30.1`, máscara `/24`, DHCP: NO

La WAN recibe IP por DHCP de VirtualBox automáticamente.

---

## 4. Acceso a la Interfaz Web

Desde una VM conectada a `LAN_10`:
```
URL:      https://192.168.10.1
Usuario:  admin
Password: pfsense  (cambiar en el primer login)
```

Asistente inicial: hostname `pfsense`, dominio `tfg.com`, timezone `Europe/Madrid`, cambiar contraseña.

---

## 5. Configurar Interfaz OPT2 (VLAN 40 — Administración)

*Interfaces → Assignments → añadir `vtnet3` → Guardar*

Ir a *Interfaces → OPT2*:

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Description | `VLAN_ADMIN` |
| IPv4 Configuration Type | Static IPv4 |
| IPv4 Address | `192.168.40.1 / 24` |

**Save** → **Apply Changes**

---

## 6. DHCP por Interfaz

### DHCP LAN (VLAN 10) — *Services → DHCP Server → LAN*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Range | `192.168.10.100 – 192.168.10.200` |
| Gateway | `192.168.10.1` |
| DNS Server 1 | `192.168.10.1` |

### DHCP OPT2 (VLAN 40) — *Services → DHCP Server → OPT2*

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Range | `192.168.40.10 – 192.168.40.50` |
| DNS Server 1 | `192.168.40.1` |

> La DMZ (VLAN 30) **no usa DHCP**. El servidor Debian tiene IP estática.

---

## 7. DNS Resolver — Host Override para Odoo

*Services → DNS Resolver → General Settings*: habilitar en LAN, OPT1, OPT2, Localhost.

*Services → DNS Resolver → Host Overrides → + Add*:

| Campo | Valor |
|:------|:------|
| Host | `erp.odoo` |
| Domain | `tfg.com` |
| IP Address | `192.168.30.10` |
| Description | `Servidor Odoo ERP — DMZ` |

**Save** → **Apply Changes**

---

## 8. NAT — Port Forwarding

*Firewall → NAT → Port Forward*

### WAN → Nginx (acceso público a Odoo)

| Interfaz | Proto | Puerto entrada | Redirige a | Puerto destino |
|:---:|:---:|:---:|:---|:---:|
| WAN | TCP | 80 | `192.168.30.10` | 80 |
| WAN | TCP | 443 | `192.168.30.10` | 443 |

### Forzar DNS interno (interceptar consultas externas)

| Interfaz | Proto | Source | Destino | Puerto | Redirige a |
|:---:|:---:|:---|:---:|:---:|:---|
| LAN | TCP/UDP | `192.168.10.0/24` | Any | 53 | `192.168.10.1` |
| OPT2 | TCP/UDP | `192.168.40.0/24` | Any | 53 | `192.168.40.1` |

> **Por qué es necesario:** Clientes Linux con `systemd-resolved` pueden ignorar el DNS del DHCP y consultar a 8.8.8.8. Esta regla intercepta cualquier consulta DNS y la redirige a pfSense, garantizando que `erp.odoo.tfg.com` resuelva siempre a `192.168.30.10`.

### NAT Outbound — *Firewall → NAT → Outbound → Modo: Automatic*

Con modo automático, pfSense aplica NAT a todas las subnets internas automáticamente.

---

## 9. Reglas de Firewall

> [!IMPORTANT]
> El orden de las reglas es **crítico**. pfSense evalúa de arriba a abajo y aplica la **primera que coincide**.
> Los bloqueos siempre van **antes** que los permisos.

### WAN

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | Redes RFC 1918 | * | * | Block private networks *(auto)* |
| 2 | ❌ Block | * | Redes Bogon | * | * | Block bogon networks *(auto)* |
| 3 | ✅ Pass | TCP | * | WAN address | 80 | HTTP público |
| 4 | ✅ Pass | TCP | * | WAN address | 443 | HTTPS público |
| 5 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |

> Las reglas 1 y 2 se activan en *Interfaces → WAN* marcando "Block private networks" y "Block bogon networks".

### LAN (VLAN 10 — Clientes)

> [!WARNING]
> La **"Default allow LAN to any"** debe estar **desactivada** (en gris/tachada).

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | LAN | `192.168.40.0/24` | * | **Bloquear VLAN Admin** ← ¡primero! |
| 2 | ❌ Block | * | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 | ❌ Block | * | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 | ❌ Block | * | LAN | `192.168.30.22` | 636 | Bloquear LDAPS admin |
| 5 | ❌ Block | * | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 6 | ~~Pass~~ | * | LAN subnets | * | * | ~~Default allow~~ *(desactivar)* |
| 7 | ✅ Pass | TCP | LAN subnets | `192.168.30.10` | 80 | Odoo HTTP vía Nginx |
| 8 | ✅ Pass | TCP | LAN subnets | `192.168.30.10` | 443 | Odoo HTTPS vía Nginx |
| 9 | ✅ Pass | TCP | LAN subnets | `192.168.30.22` | 389 | LDAP auth readonly |
| 10 | ✅ Pass | * | LAN subnets | * | * | Navegación Internet |
| 11 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |

### OPT1 (DMZ / VLAN 30)

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | DMZ | `192.168.10.0/24` | * | **Anti-pivoting a VLAN 10** ← ¡primero! |
| 2 | ❌ Block | * | DMZ | `192.168.10.1` | * | DMZ no accede a pfSense LAN |
| 3 | ❌ Block | * | DMZ | `192.168.40.0/24` | * | **Anti-pivoting a VLAN Admin** |
| 4 | ✅ Pass | TCP | DMZ | * | 80 | Actualizaciones HTTP |
| 5 | ✅ Pass | TCP | DMZ | * | 443 | Actualizaciones HTTPS |
| 6 | ✅ Pass | UDP | DMZ | * | 53 | DNS resolución |
| 7 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |

### OPT2 (VLAN 40 — Admin)

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ✅ Pass | TCP | VLAN 40 | `This Firewall` | 443 | **Panel pfSense** ← exclusivo |
| 2 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit |
| 4 | ✅ Pass | TCP | VLAN 40 | `192.168.30.20` | 443 | Nginx/Odoo admin completo |
| 5 | ✅ Pass | TCP | VLAN 40 | `192.168.30.22` | 389 | LDAP admin |
| 6 | ✅ Pass | TCP | VLAN 40 | `192.168.30.22` | 636 | LDAPS admin (cifrado) |
| 7 | ✅ Pass | TCP/UDP | VLAN 40 | * | 80, 443, 53 | Internet + DNS |
| 8 | ❌ Block | * | VLAN 40 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 9 | ❌ Block | * | VLAN 40 | * | * | **Deny all** ← ¡último! |

---

## 10. Autenticación LDAP en el Panel pfSense

> Realizar este paso **después** de que el contenedor OpenLDAP esté activo (Fase LDAP).

*System → User Manager → Authentication Servers → + Add*:

| Campo | Valor |
|:------|:------|
| Descriptive name | `OpenLDAP DMZ` |
| Type | LDAP |
| Hostname or IP address | `192.168.30.22` |
| Port value | `389` |
| Transport | TCP - Standard |
| Base DN | `dc=tfg,dc=com` |
| Authentication containers | `ou=usuarios,dc=tfg,dc=com` |
| Bind credentials — User DN | `cn=admin,dc=tfg,dc=com` |
| Bind credentials — Password | `<LDAP_ADMIN_PASSWORD>` |
| User naming attribute | `uid` |
| Group naming attribute | `cn` |
| Group member attribute | `member` |

*System → User Manager → Groups → + Add*:
- Nombre: `admin` → Privilegios: **WebCfg - All pages**

*System → User Manager → Settings → Authentication Server*: `OpenLDAP DMZ` → **Save**

---

## 11. Aislamiento del Panel pfSense — Orden Seguro (Anti-Lockout)

> [!CAUTION]
> Seguir este orden exacto. Si desactivas la Anti-Lockout sin tener acceso VLAN 40,
> **perderás el acceso al firewall** y tendrás que restaurar desde la consola de VirtualBox.

### Paso a paso (desde el PC de administración)

**Desde el PC actual (aún en VLAN 10):**

1. *Interfaces → Assignments* → añadir `vtnet3` como OPT2
2. *Interfaces → OPT2* → habilitar, descripción `VLAN_ADMIN`, IP `192.168.40.1/24` → Save
3. *Services → DHCP Server → OPT2* → habilitar, rango `192.168.40.10–50` → Save
4. *Firewall → Rules → OPT2* → añadir regla temporal: Pass, Any, OPT2 subnets → Any → Save

**Mover el PC de administración a la red ADMIN_40 en VirtualBox:**

5. En VirtualBox: configuración de red del PC admin → cambiar a `ADMIN_40`
6. En el PC admin, refrescar IP:
   ```bash
   sudo dhclient -r && sudo dhclient
   ip a   # Debe mostrar 192.168.40.x
   ```
7. Abrir `https://192.168.40.1` → verificar acceso al panel pfSense
8. Aplicar las reglas definitivas de OPT2 (sección 9)

**Desactivar Anti-Lockout (solo tras confirmar acceso desde VLAN 40):**

9. *System → Advanced → Admin Access* → marcar **Disable webConfigurator anti-lockout rule** → Save

**Verificar aislamiento:**
```bash
# Desde el PC admin en VLAN 40 (debe funcionar)
curl -k https://192.168.40.1       # → Panel pfSense ✅
ssh usuario@192.168.30.10          # → SSH al servidor ✅

# Desde un PC en VLAN 10 (debe fallar)
curl -k https://192.168.10.1       # → Sin respuesta ✅
```

---

## 12. Checklist de Verificación pfSense

```
✅ Interfaces asignadas
   ├─ WAN  → IP externa (DHCP/NAT de VirtualBox)
   ├─ LAN  → 192.168.10.1/24  (VLAN 10 clientes)
   ├─ OPT1 → 192.168.30.1/24  (VLAN 30 DMZ)
   └─ OPT2 → 192.168.40.1/24  (VLAN 40 admin)

✅ DHCP
   ├─ LAN  → 192.168.10.100–200, DNS 192.168.10.1
   └─ OPT2 → 192.168.40.10–50,  DNS 192.168.40.1

✅ Firewall Rules (bloqueos ANTES que permisos)
   ├─ WAN  → solo 80/443 + deny all
   ├─ LAN  → bloqueos admin primero + Odoo/Internet + deny all
   ├─ OPT1 → anti-pivoting primero + salida mínima + deny all
   └─ OPT2 → panel pfSense + SSH/Cockpit/LDAP + deny all

✅ NAT Port Forward
   ├─ WAN:80  → 192.168.30.10:80
   ├─ WAN:443 → 192.168.30.10:443
   ├─ LAN DNS:53  → 192.168.10.1
   └─ OPT2 DNS:53 → 192.168.40.1

✅ DNS Resolver — Host Override: erp.odoo.tfg.com → 192.168.30.10
✅ LDAP auth en pfSense (grupo admin con WebCfg - All pages)
✅ Anti-Lockout desactivado (tras confirmar acceso desde VLAN 40)
```

---

**→ Siguiente:** [`INSTALACION_SERVIDOR.md`](INSTALACION_SERVIDOR.md) — Debian + Docker + Odoo

**Referencia completa de reglas:** [`../reglas_pfsense.md`](../reglas_pfsense.md)
