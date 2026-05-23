# Correcciones de red — Vagrant + VMware + pfSense

**Fecha:** 23 mayo 2026  
**Commits:** `17bdb5b` → `0662990` → `2ae1e17` → `b034487` → (limpieza final)  
**Archivos afectados:**
- [`Vagrantfile`](../../Vagrantfile)
- [`vagrant/provision_debian.sh`](../provision_debian.sh)  ← no es un error, la ruta es relativa al .md
- [`vagrant/provision_postgres.sh`](../provision_postgres.sh)

---

## Arquitectura de red del TFG

```
Host Windows (VMware Workstation)
│
├─ pfSense (4 adaptadores)
│   ├─ eth0  WAN  → NAT VMware (salida a Internet)
│   ├─ eth1  VLAN 10  → LAN Segment 1 (192.168.10.0/24 — Usuarios)
│   ├─ eth2  VLAN 30  → LAN Segment 2 (192.168.30.0/24 — DMZ/Odoo)
│   └─ eth3  VLAN 40  → LAN Segment 3 (192.168.40.0/24 — Admin/PG)
│
├─ odoo-server  (Debian 12)
│   ├─ eth0  NAT Vagrant (SSH/provisioning, solo durante vagrant up)
│   └─ eth1  VLAN 30  → LAN Segment 2 (192.168.30.10)
│
└─ db-server  (Debian 12)
    ├─ eth0  NAT Vagrant (SSH/provisioning, solo durante vagrant up)
    └─ eth1  VLAN 40  → LAN Segment 3 (192.168.40.10)
```

pfSense actúa como único router entre VLANs y proporciona la salida a Internet a las VMs Debian a través de su WAN (eth0 NAT).

---

## Bug 1 — Gateway configurado AL FINAL del provisioning (CRÍTICO)

### Síntoma
APT, Docker, git clone y el runner fallaban porque intentaban conectarse a Internet **antes** de que se configurara el gateway de pfSense. Si el provisioning fallaba a mitad, la red nunca se configuraba.

### Causa raíz
El bloque de configuración de rutas (`ip route del/add`) estaba al final de ambos scripts, después de todos los `apt-get install`, `curl`, `git clone`, etc.

### Solución — `provision_debian.sh` y `provision_postgres.sh`

**Antes** (al final del script, ~línea 240):
```bash
# ── Configurar rutas de red permanentes ──
ip route del default dev ${NAT_IFACE} 2>/dev/null || true
ip route add default via ${VLAN_GW} dev ${VLAN_IFACE} 2>/dev/null || true
```

**Después** (justo tras las validaciones, ~línea 66):
```bash
# ── Configurar gateway pfSense ANTES de cualquier descarga ──
# CRÍTICO: debe hacerse aquí para que APT, Docker, git clone y el
# runner puedan salir a internet a través de pfSense desde el inicio.
echo "  [NET] Configurando gateway pfSense (${VLAN_GW}) en ${VLAN_IFACE}..."
ip route del default dev "${NAT_IFACE}" 2>/dev/null || true
ip route add default via "${VLAN_GW}" dev "${VLAN_IFACE}" 2>/dev/null || true
```

La sección al final del script pasó a llamarse **"Persistir rutas"** y solo escribe el fichero `/etc/network/interfaces.d/vlan*-routes` para que las rutas sobrevivan reinicios, sin volver a aplicarlas (idempotente).

---

## Bug 2 — `set -e` incompleto en provision_postgres.sh

### Síntoma
Si fallaba cualquier comando en el script de PostgreSQL, podía continuar silenciosamente sin detectar variables no definidas ni fallos en pipes.

### Causa raíz
`provision_postgres.sh` usaba `set -e` pero no `-u` (detección de variables no definidas) ni `-o pipefail` (fallo en pipes). `provision_debian.sh` sí tenía `set -euo pipefail`.

### Solución — `provision_postgres.sh` línea 6

```bash
# ANTES
set -e

# DESPUÉS
set -euo pipefail
```

---

## Bug 3 — MACVLAN con parent incorrecto (`eth1.30`)

### Síntoma
La red Docker MACVLAN `macvlan_vlan30` fallaba al crearse con el error:
```
Error response from daemon: failed to create the macvlan port: device or resource busy
```
o simplemente no encontraba la interfaz padre.

### Causa raíz
El script usaba `parent=${VLAN_IFACE}.30` (es decir, `eth1.30`), que es una **subinterfaz VLAN tagged** de Linux. Esto solo existe cuando el switch/hypervisor entrega tráfico con tag 802.1q. En VMware con LAN Segment (o Custom VMnet), la interfaz llega **sin tag** directamente como `eth1`.

### Solución — `provision_debian.sh` ~línea 184

```bash
# ANTES
-o "parent=${VLAN_IFACE}.30"    # → busca eth1.30 (no existe)

# DESPUÉS
-o "parent=${VLAN_IFACE}"       # → usa eth1 directamente
```

---

## Bug 4 — Cockpit no instalado en provision_postgres.sh

### Síntoma
Las ACLs del TFG contemplan acceso a Cockpit en `192.168.40.10:9090` (VM PostgreSQL), pero el paquete no se instalaba en esa VM.

### Causa raíz
`provision_debian.sh` sí instalaba `cockpit`, pero `provision_postgres.sh` solo instalaba `curl ca-certificates gnupg`.

### Solución — `provision_postgres.sh` ~línea 77

```bash
# ANTES
apt-get "${APT_OPTS[@]}" install -y curl ca-certificates gnupg --no-install-recommends

# DESPUÉS
apt-get "${APT_OPTS[@]}" install -y curl ca-certificates gnupg cockpit --no-install-recommends

# Habilitar Cockpit (acceso previsto en 192.168.40.10:9090 según ACLs del TFG)
systemctl enable --now cockpit.socket
```

---

## Bug 5 — `vagrant-vmware-desktop` ignora `gateway:` y `netmask:`

### Síntoma
Vagrant procesaba el Vagrantfile sin errores, pero las VMs no tenían el gateway configurado.

### Causa raíz
El plugin `vagrant-vmware-desktop` **no implementa** los parámetros `gateway:` y `netmask:` en `vm.network "private_network"`. Los acepta sin error pero los ignora completamente.

### Solución — `Vagrantfile` odoo-server y db-server

```ruby
# ANTES
deb.vm.network "private_network", ip: "192.168.30.10",
  vmware__vmnet: "VMnet2",
  netmask: "255.255.255.0",
  gateway: "192.168.30.1"          # ← ignorado

# DESPUÉS
deb.vm.network "private_network", ip: "192.168.30.10",
  auto_config: false               # provision_debian.sh gestiona la red
```

Con `auto_config: false`, Vagrant no intenta configurar la red en absoluto. Los scripts de provisioning (con el Bug 1 ya corregido) se encargan de todo.

---

## Bug 6 — Adaptadores en modo Custom en lugar de LAN Segment

### Síntoma
VMware Workstation mostraba los adaptadores de red de las VMs en modo **Custom (VMnetX)** en lugar de **LAN Segment**. Las VMs no podían comunicarse entre sí a través de pfSense. Había que cambiarlo a mano en la UI de VMware cada vez que se destruía y recreaba una VM.

### Causa raíz (parte A) — `vmware__vmnet` en Vagrantfile
Cuando `private_network` incluye `vmware__vmnet: "VMnetX"`, el plugin conecta el adaptador a ese VMnet **ignorando cualquier override VMX posterior**. Aunque en el `provider` block se especificara `connectionType = "pvn"`, el plugin sobreescribía con `connectionType = "custom"` al procesar la directiva de red.

### Causa raíz (parte B) — Falta de soporte nativo de LAN Segments
`vagrant-vmware-desktop` no tiene una opción `lan_segment:` ni equivalente. La única forma de forzar LAN Segments es mediante **VMX overrides** en el `provider` block, pero requiere que `vmware__vmnet` esté ausente.

### Causa raíz (parte C) — Trigger `setup_vmnet.ps1`
El Vagrantfile incluía un trigger `before :up` que ejecutaba `setup_vmnet.ps1` para configurar VMnet1/2/3 como redes hostonly. Con LAN Segments (que no usan VMnets), este trigger era innecesario y potencialmente confuso.

### Solución — PVN IDs en el Vagrantfile

VMware identifica los LAN Segments por un **PVN ID** (Private Virtual Network ID): 16 bytes en hexadecimal. Todas las VMs que comparten el mismo PVN ID en un adaptador quedan conectadas al mismo LAN Segment, sin necesidad de configuración adicional en VMware.

```ruby
# Constantes definidas al inicio del Vagrantfile
PVNID_VLAN10 = "52 54 AB 10 00 00 00 00-00 00 00 00 00 00 00 10"
PVNID_VLAN30 = "52 54 AB 30 00 00 00 00-00 00 00 00 00 00 00 30"
PVNID_VLAN40 = "52 54 AB 40 00 00 00 00-00 00 00 00 00 00 00 40"
```

Aplicados en cada `provider` block:

```ruby
# pfSense
v.vmx["ethernet1.connectionType"] = "pvn"
v.vmx["ethernet1.pvnID"]          = PVNID_VLAN10
v.vmx["ethernet2.connectionType"] = "pvn"
v.vmx["ethernet2.pvnID"]          = PVNID_VLAN30
v.vmx["ethernet3.connectionType"] = "pvn"
v.vmx["ethernet3.pvnID"]          = PVNID_VLAN40

# odoo-server
v.vmx["ethernet1.connectionType"] = "pvn"
v.vmx["ethernet1.pvnID"]          = PVNID_VLAN30

# db-server
v.vmx["ethernet1.connectionType"] = "pvn"
v.vmx["ethernet1.pvnID"]          = PVNID_VLAN40
```

El trigger `config.trigger.before :up` que llamaba a `setup_vmnet.ps1` se eliminó completamente.

### Mapeo ethernet por VM

| VM | ethernet0 | ethernet1 | ethernet2 | ethernet3 |
|---|---|---|---|---|
| pfSense | WAN/NAT | LAN Seg 1 (VLAN10) | LAN Seg 2 (VLAN30) | LAN Seg 3 (VLAN40) |
| odoo-server | NAT Vagrant | LAN Seg 2 (VLAN30) | — | — |
| db-server | NAT Vagrant | LAN Seg 3 (VLAN40) | — | — |

---

## Resumen de commits

| Commit | Descripción | Bugs |
|---|---|---|
| `17bdb5b` | fix(provision): 5 bugs críticos de red y configuración | #1 #2 #3 #4 |
| `0662990` | fix(vagrantfile): auto_config: false en odoo-server y db-server | #5 |
| `2ae1e17` | feat: migrar a LAN Segments via PVN ID | #6 |
| `b034487` | fix(vagrantfile): eliminar trigger setup_vmnet | #6 |
| (limpieza) | Eliminar últimos vmware__vmnet de VMs Debian | #6 |

---

## Flujo completo tras las correcciones

```
vagrant up pfsense
  → pfSense arranca con eth1/eth2/eth3 en LAN Segments (pvn)
  → NAT WAN activo en eth0

vagrant up db-server
  → eth0: NAT Vagrant (SSH disponible)
  → eth1: LAN Segment VLAN40 (mismo pvnID que pfSense eth3)
  → provisioning:
      1. ip route → gateway 192.168.40.1 (pfSense)
      2. apt install postgresql-16 cockpit ✓
      3. systemctl enable postgresql cockpit ✓
      4. gh runner registrado en GitHub ✓
      5. Rutas persistidas en /etc/network/interfaces.d/vlan40-routes

vagrant up odoo-server
  → eth0: NAT Vagrant (SSH disponible)
  → eth1: LAN Segment VLAN30 (mismo pvnID que pfSense eth2)
  → provisioning:
      1. ip route → gateway 192.168.30.1 (pfSense)
      2. apt install docker cockpit ✓
      3. git clone repo privado via PAT ✓
      4. docker network create macvlan (parent=eth1, sin .30) ✓
      5. docker compose up -d ✓
      6. gh runner registrado en GitHub ✓
      7. Rutas persistidas en /etc/network/interfaces.d/vlan30-routes
```

**Resultado final:**
- `ping 192.168.30.1` desde odoo-server → ✓ (pfSense VLAN30)
- `ping 192.168.40.1` desde db-server → ✓ (pfSense VLAN40)
- `ping 8.8.8.8` desde ambas VMs → ✓ (via pfSense WAN)
- `ping 192.168.40.10` desde odoo-server → ✓ (inter-VLAN via pfSense)
