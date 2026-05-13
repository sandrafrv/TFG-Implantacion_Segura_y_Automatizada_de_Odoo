# Guía Paso a Paso: Aislamiento del Servidor y Red de Administración (VLAN 40)

Esta guía explica desde cero cómo separar tu infraestructura para que **solo un administrador desde una red especial (VLAN 40)** pueda gestionar el cortafuegos y los servidores, limitando al máximo los privilegios de los usuarios normales (VLAN 10) y la salida a internet del propio servidor (DMZ).

Como solo tenemos **un ordenador Lubuntu** para hacer pruebas, el orden de los pasos es crítico para evitar quedarnos sin acceso a nuestro propio sistema ("lockout").

---

## FASE 1: Preparar la nueva red de Administradores (VLAN 40)

Aún no vamos a mover el Lubuntu. Entraremos a pfSense (`https://192.168.10.1`) desde el Lubuntu estando en la red de clientes (VLAN 10).

### 1. Configurar la interfaz OPT2 (VLAN 40)
Si en tu hipervisor (Proxmox / VirtualBox) ya conectaste una tercera interfaz de red a pfSense:
1. En pfSense, ve a **Interfaces → Assignments**.
2. Añade la nueva interfaz disponible (normalmente será `OPT2`).
3. Ve a **Interfaces → OPT2**, marca **"Enable Interface"** y ponle la descripción `VLAN_ADMIN`.
4. En **IPv4 Configuration Type**, selecciona `Static IPv4`.
5. En **IPv4 Address**, escribe `192.168.40.1` y en el desplegable de la derecha elige `/24`.
6. Clic en **Save** y luego en **Apply Changes**.

### 2. Configurar el servidor DHCP en la VLAN 40
Para que cuando pasemos nuestro Lubuntu a esta red se conecte automáticamente:
1. Ve a **Services → DHCP Server → OPT2 (VLAN_ADMIN)**.
2. Marca la casilla **Enable DHCP server on OPT2 interface**.
3. En la sección **Range**, pon desde `192.168.40.10` hasta `192.168.40.50`.
4. En **DNS Servers**, escribe `192.168.40.1`.
5. Clic en **Save**.

### 3. Dar permisos temporales de acceso a la VLAN 40
Queremos que el administrador pueda entrar al pfSense cuando nos mudemos de red:
1. Ve a **Firewall → Rules → OPT2**.
2. Añade una regla (`+ Add`):
   - **Action:** Pass
   - **Protocol:** Any (Luego la endureceremos, ahora es para pruebas).
   - **Source:** `OPT2 subnets`
   - **Destination:** Any
3. Clic en **Save** y **Apply Changes**.

---

## FASE 2: Restringir Internet en el Servidor (Mínimo Necesario)

El servidor en la DMZ (192.168.30.10) solo debe poder actualizar sistema y descargar de GitHub/Docker, nada más.

1. En pfSense, ve a **Firewall → Aliases → IP**.
2. Añade un nuevo alias (`+ Add`):
   - **Name:** `SERVICIOS_PERMITIDOS_DMZ`
   - **Type:** Host(s)
   - Añade en las casillas (usa el botón `+ Add Host`):
     - `github.com`
     - `api.github.com`
     - `objects.githubusercontent.com`
     - `raw.githubusercontent.com`
     - `registry-1.docker.io`
     - `auth.docker.io`
     - `production.cloudflare.docker.com`
     - `deb.debian.org`
3. Guarda el alias.
4. Ve a **Firewall → Rules → DMZ (OPT1)**.
5. Edita las reglas que permiten tráfico HTTP/HTTPS (puertos 80 y 443) hacia fuera.
6. Cambia el campo **Destination** de `Any` a `Single host or alias` y escribe `SERVICIOS_PERMITIDOS_DMZ`.
7. **Importante:** Al final del todo debe haber una regla de **Bloqueo a Todo (Deny All)**:
   - Action: Block, Protocol: Any, Source: Any, Destination: Any.
8. Clic en **Save** y **Apply Changes**.

---

## FASE 3: Restringir a los clientes de la VLAN 10

Los clientes (como el Lubuntu ahora mismo) NO deben poder acceder a pfSense, ni a la administración por SSH.

1. Ve a **Firewall → Rules → LAN**.
2. Asegúrate de tener **solamente** reglas que permitan:
   - Ir a Odoo: HTTP (80) y HTTPS (443) apuntando a la IP `192.168.30.10`.
   - Ir a Odoo (nativo): Puerto `8069`.
   - Ir a LDAP para login: Puerto `389` apuntando al contenedor LDAP (`192.168.30.22`).
   - Tráfico a Internet genérico (navegación).
3. Añade una regla de **Bloqueo (Block)** al principio del todo para que la LAN no pueda conectarse nunca al servidor por SSH (puerto 22) o Cockpit (puerto 9090).

---

## FASE 4: Securizar pfSense con LDAP (Usuarios del ERP)

Vamos a configurar pfSense para que lea los usuarios del servidor en la DMZ.

1. Ve a **System → User Manager → Authentication Servers**.
2. Añade el servidor (`+ Add`):
   - **Name:** `OpenLDAP DMZ`
   - **Type:** LDAP
   - **Hostname:** `192.168.30.22` (IP de tu contenedor LDAP).
   - **Port:** `389`
   - **Transport:** TCP - Standard
   - **Base DN:** `dc=tfg,dc=com`
   - **Authentication containers:** `ou=usuarios,dc=tfg,dc=com`
   - **Bind credentials:** `cn=admin,dc=tfg,dc=com` y tu contraseña del LDAP.
   - **User naming attribute:** `uid`
   - **Group naming attribute:** `cn`
   - **Group member attribute:** `member`
3. Clic en **Save**.
4. Ve a **System → User Manager → Groups**. Crea un grupo llamado exactamente **`admin`** y asígnale en "Assigned Privileges" el privilegio **"WebCfg - All pages"**.
5. Ve a **System → User Manager → Settings**. Cambia el "Authentication Server" a `OpenLDAP DMZ`. **Save**.

---

## FASE 5: Bloquear el acceso de pfSense a los Clientes (Desactivar Anti-Lockout)

**CUIDADO AQUÍ:** Una vez hagamos esto, si cerramos la pestaña no podremos volver a entrar a pfSense desde la IP de clientes (`192.168.10.1`).

1. Ve a **System → Advanced → Admin Access**.
2. Baja hasta encontrar **Disable webConfigurator anti-lockout rule**. Marca esa casilla.
3. Clic en **Save**.
4. *(A partir de ahora, el único lugar seguro para acceder a pfSense es conectándose a la VLAN 40).*

---

## FASE 6: Mudanza a la Red de Administración y Pruebas

Llegó el momento. Como solo tenemos una máquina cliente (Lubuntu), vamos a sacarla de la red de usuarios normales y meterla en la de administradores.

1. Abre tu hipervisor (VirtualBox o Proxmox).
2. Ve a la configuración de la máquina virtual de tu **Lubuntu**.
3. En el apartado de **Red**, cambia la interfaz para que ahora apunte a la **VLAN 40** (en vez de a la VLAN 10).
4. Vuelve al Lubuntu y abre una terminal. Ejecuta estos comandos para refrescar la IP:
   ```bash
   sudo dhclient -r
   sudo dhclient
   ```
5. Comprueba tu IP ejecutando `ip a`. Debería darte una del rango `192.168.40.X`.
6. Abre el navegador en Lubuntu y entra en **`https://192.168.40.1`**.
7. Te saldrá el panel de pfSense. Intenta acceder con un usuario "normal" del LDAP (ej: `dba`); **debe rechazarlo**.
8. Intenta acceder con el usuario `admin` del LDAP; **debe dejarte entrar**.
9. Comprueba desde tu terminal en Lubuntu que puedes hacer ping y conexión SSH al servidor (`ssh usuario@192.168.30.10`), demostrando que como Administrador tienes acceso total a la DMZ.
