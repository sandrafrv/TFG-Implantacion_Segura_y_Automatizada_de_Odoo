# Guía de Red — pfSense: Firewall, DHCP, DNS y VLAN 40

**← Volver a:** [`docs/INSTALACION_COMPLETA.md`](../INSTALACION_COMPLETA.md)

> [!IMPORTANT]
> pfSense debe configurarse **antes** que cualquier otro componente.
> Es el firewall, router, DHCP y servidor DNS de toda la infraestructura.

> [!TIP]
> **¿Quieres automatizar?** El script `scripts/deploy/generate_pfsense_config.sh` genera un
> `config.xml` completo con todas las interfaces, DHCP, DNS, NAT y reglas de firewall documentadas
> a continuación. Impórtalo en **Diagnostics → Backup/Restore** y salta a la [sección 11](#11-aislamiento-del-panel-pfsense--orden-seguro-anti-lockout).
> También disponible como artefacto descargable en el pipeline CI de GitHub Actions.

---

## 1. Crear la VM pfSense en VMware Workstation

### Parámetros de la VM

| Campo | Valor |
|:------|:------|
| Nombre | `TFG-pfSense` |
| Tipo | FreeBSD 64-bit |
| RAM | 1024 MB |
| CPU | 1 core |
| Disco | 10 GB |

> **Con Vagrant** (`vagrant up pfsense`), la VM se crea automáticamente con la box `dlee35/pfsense`.
> El script `scripts/setup_vmnet.ps1` configura las VMnets antes del `vagrant up`.

### Adaptadores de red — VMware Workstation

| Adaptador | Modo VMware | Interfaz pfSense | Subred |
|:----------|:------------|:-----------------|:-------|
| Adaptador 1 | **NAT** | `em0` → **WAN** | Internet |
| Adaptador 2 | **Host-only** `VMnet1` | `em1` → **LAN** | VLAN 10 clientes (192.168.10.0/24) |
| Adaptador 3 | **Host-only** `VMnet2` | `em2` → **OPT1 (DMZ)** | VLAN 30 DMZ (192.168.30.0/24) |
| Adaptador 4 | **Host-only** `VMnet3` | `em3` → **OPT2 (Admin)** | VLAN 40 admin+BD (192.168.40.0/24) |

> [!NOTE]
> El script `scripts/setup_vmnet.ps1` configura automáticamente VMnet1, VMnet2 y VMnet3 con las subredes correctas.

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
Enter the WAN interface name:      em0
Enter the LAN interface name:      em1
Enter the Optional 1 interface:    em2
Enter the Optional 2 interface:    em3
Do you want to proceed? → y
```

Opción **2 (Set Interface IP Addresses)**:
- **LAN** → IP `192.168.10.1`, máscara `/24`, habilitar DHCP: Sí, rango `192.168.10.100–200`
- **OPT1 (DMZ)** → IP `192.168.30.1`, máscara `/24`, DHCP: NO

La WAN recibe IP por DHCP de VMware NAT automáticamente.

---

## 4. Acceso a la Interfaz Web

Desde una VM conectada a `VMnet1`:
```
URL:      https://192.168.10.1
Usuario:  admin
Password: pfsense  (cambiar en el primer login)
```

Asistente inicial: hostname `pfsense`, dominio `tfg.com`, timezone `Europe/Madrid`, cambiar contraseña.

---

## 5. Configurar Interfaz OPT2 (VLAN 40 — Administración + BD)

*Interfaces → Assignments → añadir `em3` → Guardar*

Ir a *Interfaces → OPT2*:

| Campo | Valor |
|:------|:------|
| Enable | ✅ |
| Description | `VLAN_ADMIN_BD` |
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
| IP Address | `192.168.30.20` |
| Description | `nginx-proxy Odoo ERP — DMZ MACVLAN` |

**Save** → **Apply Changes**

---

## 8. NAT — Port Forwarding

*Firewall → NAT → Port Forward*

### WAN → Nginx (acceso público a Odoo)

| Interfaz | Proto | Puerto entrada | Redirige a | Puerto destino |
|:---:|:---:|:---:|:---|:---:|
| WAN | TCP | 80 | `192.168.30.20` | 80 |
| WAN | TCP | 443 | `192.168.30.20` | 443 |

### Forzar DNS interno (interceptar consultas externas)

| Interfaz | Proto | Source | Destino | Puerto | Redirige a |
|:---:|:---:|:---|:---:|:---:|:---|
| LAN | TCP/UDP | `192.168.10.0/24` | Any | 53 | `192.168.10.1` |
| OPT2 | TCP/UDP | `192.168.40.0/24` | Any | 53 | `192.168.40.1` |

> **Por qué es necesario:** Clientes Linux con `systemd-resolved` pueden ignorar el DNS del DHCP y consultar a 8.8.8.8. Esta regla intercepta cualquier consulta DNS y la redirige a pfSense, garantizando que `erp.odoo.tfg.com` resuelva siempre a `192.168.30.20`.

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
| 1 | ❌ Block | * | LAN | `192.168.40.0/24` | * | **Bloquear VLAN Admin+BD** ← ¡primero! |
| 2 | ❌ Block | * | LAN | `192.168.30.10` | 22 | Bloquear SSH al servidor |
| 3 | ❌ Block | * | LAN | `192.168.30.10` | 9090 | Bloquear Cockpit |
| 4 | ❌ Block | * | LAN | `192.168.30.0/24` | 5432 | Bloquear PostgreSQL |
| 5 | ~~Pass~~ | * | LAN subnets | * | * | ~~Default allow~~ *(desactivar)* |
| 6 | ✅ Pass | TCP | LAN subnets | `192.168.30.20` | 80 | Odoo HTTP vía Nginx (MACVLAN) |
| 7 | ✅ Pass | TCP | LAN subnets | `192.168.30.20` | 443 | Odoo HTTPS vía Nginx (MACVLAN) |
| 8 | ✅ Pass | * | LAN subnets | * | * | Navegación Internet |
| 9 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |

> **LDAP eliminado:** no hay reglas de acceso a `192.168.30.22`.
> Si se despliega LDAP como componente opcional (`extras/ldap/`), añadir regla antes del Deny all.

### OPT1 (DMZ / VLAN 30)

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ❌ Block | * | DMZ | `192.168.10.0/24` | * | **Anti-pivoting a VLAN 10** ← ¡primero! |
| 2 | ❌ Block | * | DMZ | `192.168.10.1` | * | DMZ no accede a pfSense LAN |
| 3 | ✅ Pass | TCP | `192.168.30.21` | `192.168.40.10` | 5432 | **Odoo → PostgreSQL externo** |
| 4 | ❌ Block | * | DMZ | `192.168.40.0/24` | * | **Anti-pivoting a VLAN Admin+BD** |
| 5 | ✅ Pass | TCP | DMZ | * | 80 | Actualizaciones HTTP |
| 6 | ✅ Pass | TCP | DMZ | * | 443 | Actualizaciones HTTPS |
| 7 | ✅ Pass | UDP | DMZ | * | 53 | DNS resolución |
| 8 | ❌ Block | * | * | * | * | **Deny all** ← ¡último! |

> La regla 3 (Odoo→PostgreSQL) debe ir **antes** del bloqueo general a VLAN 40 (regla 4).

### OPT2 (VLAN 40 — Admin + BD)

| # | Acción | Proto | Origen | Destino | Puerto | Descripción |
|:-:|:------:|:-----:|:-------|:--------|:------:|:------------|
| 1 | ✅ Pass | TCP | VLAN 40 | `This Firewall` | 443 | **Panel pfSense** ← exclusivo |
| 2 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 22 | SSH al servidor Debian |
| 3 | ✅ Pass | TCP | VLAN 40 | `192.168.30.10` | 9090 | Cockpit — gestión visual |
| 4 | ✅ Pass | TCP | VLAN 40 | `192.168.30.20` | 443 | Nginx/Odoo admin completo |
| 5 | ✅ Pass | TCP | VLAN 40 | `192.168.40.10` | 5432 | **Acceso DBA directo a PostgreSQL** |
| 6 | ✅ Pass | TCP/UDP | VLAN 40 | * | 80, 443, 53 | Internet + DNS |
| 7 | ❌ Block | * | VLAN 40 | `192.168.10.0/24` | * | Anti-pivoting a VLAN 10 |
| 8 | ❌ Block | * | VLAN 40 | * | * | **Deny all** ← ¡último! |

> **LDAP eliminado:** las reglas de acceso a `192.168.30.22:389/636` han sido retiradas.
> Si se despliega LDAP como componente opcional, añadir antes del Deny all según `extras/ldap/README.md`.

---

## 10. Autenticación LDAP en el Panel pfSense (Opcional)

> [!NOTE]
> **Esta sección es opcional.** LDAP no está en el despliegue principal.
> Solo aplicar si has desplegado OpenLDAP siguiendo `extras/ldap/README.md`.
> El despliegue principal usa cuentas locales de pfSense.

Si decides habilitar LDAP en pfSense: *System → User Manager → Authentication Servers → + Add*

| Campo | Valor |
|:------|:------|
| Descriptive name | `OpenLDAP DMZ` |
| Type | LDAP |
| Hostname or IP | `192.168.30.22` (VM LDAP opcional) |
| Port value | `389` |
| Base DN | `dc=tfg,dc=com` |
| Authentication containers | `ou=usuarios,dc=tfg,dc=com` |
| User naming attribute | `uid` |

Recuerda añadir también las reglas de firewall correspondientes (ver `extras/ldap/README.md`).

---

## 11. Aislamiento del Panel pfSense — Orden Seguro (Anti-Lockout)

> [!CAUTION]
> Seguir este orden exacto. Si desactivas la Anti-Lockout sin tener acceso VLAN 40,
> **perderás el acceso al firewall** y tendrás que restaurar desde la consola de VirtualBox.

### Paso a paso (desde el PC de administración)

**Desde el PC actual (aún en VMnet1):**

1. *Interfaces → Assignments* → añadir `em3` como OPT2
2. *Interfaces → OPT2* → habilitar, descripción `VLAN_ADMIN_BD`, IP `192.168.40.1/24` → Save
3. *Services → DHCP Server → OPT2* → habilitar, rango `192.168.40.10–50` → Save
4. *Firewall → Rules → OPT2* → añadir regla temporal: Pass, Any, OPT2 subnets → Any → Save

**Mover el PC de administración a VMnet3 en VMware:**

5. En VMware Workstation: configuración de red del PC admin → cambiar a `VMnet3`
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
   └─ OPT2 → 192.168.40.1/24  (VLAN 40 admin+BD)

✅ DHCP
   ├─ LAN  → 192.168.10.100–200, DNS 192.168.10.1
   └─ OPT2 → 192.168.40.10–50,  DNS 192.168.40.1

✅ Firewall Rules (bloqueos ANTES que permisos)
   ├─ WAN  → solo 80/443 + deny all
   ├─ LAN  → bloqueos admin+BD primero + Odoo(MACVLAN.20)/Internet + deny all
   ├─ OPT1 → anti-pivoting + Odoo→PG(:5432, regla explícita) + salida mínima + deny all
   └─ OPT2 → panel pfSense + SSH/Cockpit/psql(→PG) + deny all (sin reglas LDAP)

✅ NAT Port Forward
   ├─ WAN:80  → 192.168.30.20:80
   ├─ WAN:443 → 192.168.30.20:443
   ├─ LAN DNS:53  → 192.168.10.1
   └─ OPT2 DNS:53 → 192.168.40.1

✅ DNS Resolver — Host Override: erp.odoo.tfg.com → 192.168.30.20
✅ Anti-Lockout desactivado (tras confirmar acceso desde VLAN 40)
ℹ️  LDAP en pfSense: no configurado — opcional (ver extras/ldap/)
```

---

**→ Siguiente:** [`INSTALACION_SERVIDOR.md`](INSTALACION_SERVIDOR.md) — Debian + Docker + Odoo

**Referencia completa de reglas:** [`../reglas_pfsense.md`](../reglas_pfsense.md)
