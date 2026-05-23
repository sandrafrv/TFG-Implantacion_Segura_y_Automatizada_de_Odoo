# Guía: Crear una Vagrant Box de pfSense personalizada

> **Objetivo:** Instalar pfSense desde la ISO oficial en VMware Workstation, aplicar
> toda la configuración del proyecto (interfaces, ACLs, NAT, DNS) y empaquetar la VM
> como un archivo `.box` para que Vagrant la use directamente sin pasos manuales.
>
> **Resultado final:** `config/pfsense-tfg.box` → subida a GitHub Releases →
> Vagrantfile la descarga automáticamente con `vagrant up pfsense`.

---

## Resumen del proceso

```
[Fase 1] Crear VM en VMware Workstation desde la ISO
[Fase 2] Instalar pfSense + configurar desde cero (ver CONFIGURACION_PFSENSE_MANUAL.md)
[Fase 3] Preparar la VM para Vagrant (SSH + usuario vagrant)
[Fase 4] Empaquetar con vagrant package → genera .box
[Fase 5] Subir el .box a GitHub Releases
[Fase 6] Actualizar el Vagrantfile para usar tu box
```

---

## FASE 1 — Crear la VM en VMware Workstation

### 1.1 Configuración de la VM

*File → New Virtual Machine → Custom (Advanced)*

| Parámetro | Valor |
|---|---|
| Compatibility | Workstation 17.x |
| Install OS | Installer disc image file (ISO) |
| ISO | `netgate-installer-v1.1.1-RELEASE-amd64.iso` |
| Guest OS | Other → **FreeBSD 14 64-bit** |
| VM Name | `TFG-pfSense-base` |
| Location | Donde quieras (NO dentro del repo) |
| Processors | 1 CPU, 1 Core |
| RAM | **1024 MB** |
| Network | **Do not add a network connection** (las añadiremos después) |
| SCSI | LSI Logic (BusLogic también vale) |
| Virtual Disk | **8 GB**, Single file |

### 1.2 Añadir las 4 interfaces de red (ANTES de arrancar)

*VM → Settings → Add → Network Adapter* (añadir 3 veces más)

| Adaptador | Tipo VMware | Rol |
|---|---|---|
| Network Adapter 1 | NAT | WAN (salida a Internet del host) |
| Network Adapter 2 | **VMnet1** (Host-only) | LAN — VLAN 10 clientes |
| Network Adapter 3 | **VMnet2** (Host-only) | OPT1 — VLAN 30 DMZ |
| Network Adapter 4 | **VMnet3** (Host-only) | OPT2 — VLAN 40 Admin |

> Si VMnet1/2/3 no existen, créalas antes en *Edit → Virtual Network Editor*
> (el script `scripts/setup_vmnet.ps1` del proyecto las configura automáticamente).

---

## FASE 2 — Instalar pfSense

### 2.1 Arrancar la VM e instalar

1. Arrancar la VM → arrancará el instalador de pfSense
2. Aceptar los términos de copyright → **Install pfSense**
3. Keymap → **Spanish** (o la que prefieras)
4. Partitioning → **Auto (ZFS)** → `da0` → Aceptar y continuar
5. Esperar la instalación (~2-3 minutos)
6. Cuando pregunte "Reboot" → **Reboot**
7. ⚠️ Expulsar la ISO antes del siguiente arranque (*VM → Settings → CD/DVD → Use physical drive o quitar el ISO*)

### 2.2 Configuración inicial por consola

Al arrancar pfSense por primera vez te preguntará:

```
Should VLANs be set up now? → n (No)

Enter the WAN interface name: em0
Enter the LAN interface name: em1
Enter the Optional 1 interface name: em2
Enter the Optional 2 interface name: em3
Do you want to proceed? → y
```

pfSense asignará:
- WAN → em0 (DHCP, toma IP de VMware NAT)
- LAN → em1 (192.168.1.1 por defecto — lo cambiaremos)
- OPT1 → em2
- OPT2 → em3

### 2.3 Configurar IPs desde la consola pfSense

En el menú principal de pfSense, opción **2) Set interface(s) IP address**:

**Opción 2 → LAN:**
- IPv4: `192.168.10.1`
- Subnet: `24`
- Gateway: (dejar vacío)
- IPv6: (dejar vacío → n)
- DHCP Server: `y`
  - Start: `192.168.10.100`
  - End: `192.168.10.200`
- HTTP/HTTPS → `n` (usaremos HTTPS por defecto)

**Opción 2 → OPT1 (DMZ):**
- IPv4: `192.168.30.1`
- Subnet: `24`
- Gateway: (vacío)
- DHCP: `n` (IPs estáticas en DMZ)

**Opción 2 → OPT2 (Admin):**
- IPv4: `192.168.40.1`
- Subnet: `24`
- DHCP: `y`
  - Start: `192.168.40.10`
  - End: `192.168.40.50`

---

## FASE 3 — Configuración completa desde el panel web

Accede al panel desde tu navegador en el host:

```
https://192.168.1.1   ← (IP NAT de VMware, la LAN temporal)
Usuario: admin
Password: pfsense
```

> Aplica TODAS las reglas del documento `docs/guias/CONFIGURACION_PFSENSE_MANUAL.md`.
> Esto incluye: interfaces definitivas, DHCP, DNS Resolver, Aliases, NAT y todas las ACLs.

---

## FASE 4 — Preparar la VM para Vagrant (SSH + usuario vagrant)

> ⚠️ Esta fase es **imprescindible** para que `vagrant package` funcione correctamente.
> Sin SSH, Vagrant no puede comunicarse con la VM ni aplicar el provisioning.

### 4.1 Habilitar SSH en pfSense

*System → Advanced → Admin Access*

| Campo | Valor |
|---|---|
| Enable Secure Shell | ✅ Marcar |
| SSHd Key Only | **Password or Public Key** |
| SSH port | `22` |

**Save** y confirmar que el servicio sshd arranca.

### 4.2 Crear el usuario `vagrant` en pfSense

*System → User Manager → Users → + Add*

| Campo | Valor |
|---|---|
| Username | `vagrant` |
| Password | `vagrant` |
| Full Name | `Vagrant User` |
| Group Membership | `admins` |

**Save**.

### 4.3 Añadir la clave SSH pública de Vagrant

*System → User Manager → Users → vagrant → Edit*

En el campo **Authorized SSH Keys**, pegar la clave pública oficial de Vagrant:

```
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
```

**Save**.

### 4.4 Verificar conectividad SSH desde el host

Desde Git Bash o PowerShell (en el host, mientras la VM tiene la LAN en VMnet1):

```bash
# La IP de acceso es la de la interfaz OPT2 (VLAN 40 Admin) o WAN NAT
ssh -o StrictHostKeyChecking=no vagrant@192.168.40.1
# Password: vagrant
# Debe conectar y mostrar el menú de pfSense
```

### 4.5 Configurar sudoers para el usuario vagrant

Desde la consola de pfSense (opción 8 → Shell) o via SSH:

```sh
# En pfSense (FreeBSD)
echo "vagrant ALL=(ALL) NOPASSWD: ALL" >> /usr/local/etc/sudoers.d/vagrant
chmod 440 /usr/local/etc/sudoers.d/vagrant
```

---

## FASE 5 — Empaquetar la VM con vagrant package

> ⚠️ Antes de empaquetar, asegúrate de que la VM está **apagada** (no suspendida).

### 5.1 Apagar pfSense limpiamente

En el menú de consola pfSense → **Opción 5) Halt system**

### 5.2 Encontrar el nombre de la VM en VMware

```powershell
# Listar VMs registradas en VMware
& "C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe" list
```

Busca la línea con `TFG-pfSense-base`.

### 5.3 Empaquetar con vagrant package

```powershell
# Desde la raíz del proyecto
cd "C:\Users\sandra\Desktop\Ante proyecto\TFG-ASIRB"

# Empaquetar la VM (sustituye el path por el real de tu VM)
vagrant package \
  --base "TFG-pfSense-base" \
  --output "config/pfsense-tfg.box" \
  --vagrantfile "vagrant/Vagrantfile.pfsense-box"
```

> ⏳ El proceso tarda 3-8 minutos. Genera un archivo `.box` (~600MB-1GB).

### 5.4 Verificar el .box generado

```powershell
# Añadir al catálogo local de Vagrant para probar
vagrant box add --name "tfg/pfsense" config/pfsense-tfg.box --force

# Verificar que se añadió
vagrant box list
# Debe aparecer: tfg/pfsense (vmware_desktop, 0)
```

---

## FASE 6 — Subir el .box a GitHub Releases

> GitHub Releases permite alojar archivos grandes (hasta 2GB). Es el método estándar
> para distribuir Vagrant boxes desde repositorios privados de GitHub.

### 6.1 Crear un Release en GitHub

1. Ve a tu repo: `https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo`
2. **Releases → Draft a new release**
3. Tag: `v1.0-pfsense-box` (crear nuevo tag)
4. Title: `pfSense Vagrant Box v1.0 — TFG ASIR`
5. Description:
   ```
   Box de pfSense 2.7.x preconfigurada con:
   - 4 interfaces: WAN (NAT), LAN/VLAN10, OPT1/DMZ, OPT2/Admin
   - Reglas firewall completas (ACLs del proyecto TFG)
   - DHCP, DNS Resolver, NAT Port Forward
   - Usuario vagrant con clave insecure + sudo NOPASSWD
   ```
6. **Attach binaries**: arrastrar `config/pfsense-tfg.box`
7. ✅ **Set as a pre-release** (hasta que el TFG esté terminado)
8. **Publish release**

### 6.2 Obtener la URL directa del .box

Tras publicar, la URL del archivo tendrá este formato:
```
https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo/releases/download/v1.0-pfsense-box/pfsense-tfg.box
```

---

## FASE 7 — Actualizar el Vagrantfile

El Vagrantfile ya está actualizado para usar la box desde GitHub Releases.
Ver las instrucciones en `vagrant/Vagrantfile.pfsense-box` para el bloque exacto.

**Resumen del cambio en el Vagrantfile:**

```ruby
# ANTES (box pública que no soporta provisioning):
pf.vm.box = "dlee35/pfsense"
pf.vm.communicator = "none"

# DESPUÉS (tu box privada desde GitHub Releases con SSH):
pf.vm.box = "tfg/pfsense"
pf.vm.box_url = "https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo/releases/download/v1.0-pfsense-box/pfsense-tfg.box"
pf.vm.communicator = "ssh"
pf.ssh.username = "vagrant"
pf.ssh.password = "vagrant"
# + provisioning automático con generate_pfsense_config.sh
```

---

## Flujo de uso tras crear la box

```bash
# 1. Generar el XML de configuración (solo si hay cambios)
bash scripts/deploy/generate_pfsense_config.sh

# 2. Levantar pfSense (descarga la box de GitHub la primera vez, ~1GB)
vagrant up pfsense

# 3. Levantar el resto
vagrant up db-server
vagrant up odoo-server
```

---

## Notas importantes

### .gitignore
El archivo `.box` NO debe subirse al repositorio Git (es demasiado grande).
Ya está en el `.gitignore` del proyecto:
```
config/*.box
config/pfsense_config.xml
```

### Reutilizar la box localmente
Si ya tienes la box descargada localmente, Vagrant no la volverá a descargar:
```powershell
vagrant box add --name "tfg/pfsense" config/pfsense-tfg.box
# Vagrant usará la copia local en lugar de descargar de GitHub
```

### Actualizar la box (versión nueva)
Cuando necesites actualizar la configuración:
1. Arranca la VM `TFG-pfSense-base` existente y haz los cambios
2. Apaga → `vagrant package` → nuevo `.box`
3. Crea un nuevo Release en GitHub con tag `v1.1-pfsense-box`
4. Actualiza `box_url` en el Vagrantfile
5. `vagrant box update` en los equipos que la usen

---

*Configuración manual pfSense: [`CONFIGURACION_PFSENSE_MANUAL.md`](CONFIGURACION_PFSENSE_MANUAL.md)*
*Vagrantfile con la nueva box: [`Vagrantfile`](../../Vagrantfile)*
*Script de importación XML: [`generate_pfsense_config.sh`](../../scripts/deploy/generate_pfsense_config.sh)*
