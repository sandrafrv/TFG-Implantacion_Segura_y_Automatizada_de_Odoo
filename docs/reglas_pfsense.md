# Configuración de Reglas en pfSense (Firewall y NAT)

Este documento detalla las reglas exactas que debéis configurar en la interfaz web de pfSense para que la arquitectura de red (WAN, LAN y DMZ) funcione correctamente y de forma segura.

---

## 1. Reglas Generales de Salida a Internet (Outbound)
Por defecto, pfSense bloquea todo el tráfico que entra, pero permite que las redes internas salgan a Internet. 
*Aseguraos de que existen estas reglas (se suelen crear solas al configurar las interfaces):*

### Interfaz LAN (VLAN 10)
| Action | Protocol | Source | Port | Destination | Port | Gateway | Descripción |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ✅ Pass | IPv4 * | LAN net | * | * | * | * | Default allow LAN to any rule (Salida a Internet) |

### Interfaz DMZ (VLAN 30)
| Action | Protocol | Source | Port | Destination | Port | Gateway | Descripción |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ✅ Pass | IPv4 * | DMZ net | * | * | * | * | Permitir a la DMZ descargar paquetes (Salida a Internet) |

---

## 2. Reglas de Seguridad (Aislamiento de Redes)
La DMZ **NUNCA** debe poder iniciar una conexión hacia la red interna de la empresa (LAN). Si hackean el servidor web (Debian), el hacker no debe poder saltar a los PCs de los trabajadores.

**Debéis ir a `Firewall > Rules > DMZ` y CADA UNA DE ESTAS REGLAS DEBE ESTAR ARRIBA DEL TODO (El orden importa en pfSense):**

| Action | Protocol | Source | Port | Destination | Port | Gateway | Descripción |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ❌ Reject | IPv4 * | DMZ net | * | LAN net | * | * | **BLOQUEO:** Evitar que la DMZ alcance a los clientes (Anti-pivoting) |
| ❌ Reject | IPv4 TCP | DMZ net | * | DMZ address | 443, 80 | * | **BLOQUEO:** Evitar que la DMZ entre al panel web de pfSense |
| ❌ Reject | IPv4 TCP | DMZ net | * | DMZ address | 22 | * | **BLOQUEO:** Evitar que la DMZ entre al SSH de pfSense |

---

## 3. Publicación del ERP (Port Forwarding / NAT)
Para que cuando alguien de fuera teclee vuestra IP pública (o dominio) llegue al Odoo que está en la DMZ, hay que hacer un DNAT (Destination NAT).

**Debéis ir a `Firewall > NAT > Port Forward` y añadir estas dos reglas:**

### Regla 1: Redirección HTTP (Para que Nginx atrape a los despistados)
* **Interface:** WAN
* **Protocol:** TCP
* **Source:** Any (*)
* **Destination:** WAN Address
* **Destination port range:** HTTP (80)
* **Redirect target IP:** `192.168.30.10` (La IP de vuestro Debian)
* **Redirect target port:** HTTP (80)
* **Description:** NAT HTTP a Nginx DMZ
* *(Nota: Dejad marcada la opción 'Filter rule association: Add associated filter rule' para que pfSense abra el firewall solo)*

### Regla 2: Redirección HTTPS (El tráfico web real)
* **Interface:** WAN
* **Protocol:** TCP
* **Source:** Any (*)
* **Destination:** WAN Address
* **Destination port range:** HTTPS (443)
* **Redirect target IP:** `192.168.30.10` (La IP de vuestro Debian)
* **Redirect target port:** HTTPS (443)
* **Description:** NAT HTTPS a Nginx DMZ

---

## 4. Acceso Administrativo (LAN a DMZ)
Los trabajadores de Recursos Humanos (LAN) deben poder entrar a la web de Odoo, y vosotrxs (Administradores en la LAN) debéis poder entrar por SSH y a Cockpit.
*Como la regla "Default allow LAN to any" ya deja salir tráfico a cualquier lado, esto funcionará solo. Pero si queréis ser puristas (y sacar un 10 en seguridad), deberíais borrar la regla "Default allow LAN to any" en la interfaz LAN y crear estas:*

**En `Firewall > Rules > LAN`:**

| Action | Protocol | Source | Port | Destination | Port | Descripción |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| ✅ Pass | IPv4 TCP | LAN net | * | `192.168.30.10` | 443 | Clientes a Odoo Web (Seguro) |
| ✅ Pass | IPv4 TCP | LAN net | * | `192.168.30.10` | 80 | Clientes a Odoo Web (Redirección) |
| ✅ Pass | IPv4 TCP | IP de Admin | * | `192.168.30.10` | 22 | Mantenimiento SSH (Solo tú) |
| ✅ Pass | IPv4 TCP | IP de Admin | * | `192.168.30.10` | 9090 | Panel Web Cockpit (Solo tú) |
| ✅ Pass | IPv4 * | LAN net | * | * (Excepto RFC1918) | * | Salida a Internet genérica de los clientes |
