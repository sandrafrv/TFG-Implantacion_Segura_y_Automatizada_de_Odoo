# Explicación: Provisioning de pfSense (`provision_pfsense.sh`)

El script `vagrant/provision_pfsense.sh` automatiza la configuración de la VM de firewall/router basada en pfSense. Es ejecutado de forma transparente por Vagrant durante la fase de aprovisionamiento de la VM `vm-pfsense` (la **VM 1 — Firewall**).

---

## Estrategia de Aprovisionamiento

A diferencia de las VMs Debian, pfSense (basado en FreeBSD) tiene un sistema de configuración centralizado en un único archivo XML: `/cf/conf/config.xml`.

La estrategia adoptada en este proyecto es:
1. **Generación previa (Off-VM):** El script `scripts/deploy/generate_pfsense_config.sh` se ejecuta en la máquina anfitriona antes del `vagrant up`. Este script recopila las variables de entorno, IP de subredes y credenciales, y genera un archivo `config/pfsense_config.xml` válido.
2. **Transferencia por Vagrant:** Vagrant (vía el plugin de shell) inyecta este XML pre-generado dentro de la VM pfSense temporalmente en `/tmp/pfsense_config.xml`.
3. **Aplicación por Script:** Finalmente, `provision_pfsense.sh` se ejecuta.

---

## Qué hace paso a paso

### 1. Comprobación del archivo de configuración
El script comprueba si el archivo pre-generado `/tmp/pfsense_config.xml` fue inyectado correctamente.

### 2. Aplicación y Recarga (Caso de Éxito)
```bash
if [ -f /tmp/pfsense_config.xml ]; then
    cp /tmp/pfsense_config.xml /cf/conf/config.xml
    nohup /etc/rc.reload_all > /dev/null 2>&1 &
```
Si el archivo existe, sobrescribe la configuración activa de pfSense (`/cf/conf/config.xml`). 
Posteriormente, recarga todos los servicios (`rc.reload_all`) para aplicar los cambios de red, reglas de firewall y NAT. Se ejecuta con `nohup` y en segundo plano (`&`) para evitar que la conexión SSH de Vagrant se congele y cause un timeout.

### 3. Fallback (Aviso de Configuración Manual)
Si no se encuentra el XML (por ejemplo, porque el usuario no ejecutó el generador previamente), el script no falla, sino que muestra un aviso en consola con los pasos manuales que deben realizarse a través de la interfaz web de pfSense para que el laboratorio funcione:
- Configuración de Interfaces (VLAN 10, VLAN 30, VLAN 40).
- Reglas NAT para el acceso HTTPs/VPN.
- Reglas de filtrado para el aislamiento de la Base de Datos (VLAN 30 -> VLAN 40).

---

## Resultado Final

Tras su ejecución exitosa, el pfSense asume la dirección `192.168.30.1` en la DMZ y `192.168.40.1` en la red de BD, actuando como gateway central y protegiendo de forma estricta las bases de datos contra cualquier red no autorizada.
