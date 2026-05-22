#!/bin/sh
# ============================================================
# SCRIPT: generate_pfsense_config.sh
# DESCRIPCIÓN: Genera un config.xml completo para pfSense
#              con todas las reglas del proyecto TFG.
#              Importar en: Diagnostics → Backup/Restore
# USO: ./scripts/deploy/generate_pfsense_config.sh
# ============================================================

set -eu

# ── Variables de red ──
WAN_IF="em0"
LAN_IF="em1"
DMZ_IF="em2"
ADMIN_IF="em3"

LAN_IP="192.168.10.1"
LAN_SUBNET="24"
LAN_DHCP_START="192.168.10.100"
LAN_DHCP_END="192.168.10.200"

DMZ_IP="192.168.30.1"
DMZ_SUBNET="24"
SERVER_IP="192.168.30.10"
NGINX_IP="192.168.30.20"
# shellcheck disable=SC2034
ODOO_IP="192.168.30.21"

ADMIN_IP="192.168.40.1"
ADMIN_SUBNET="24"
ADMIN_DHCP_START="192.168.40.10"
ADMIN_DHCP_END="192.168.40.50"

HOSTNAME="pfsense"
DOMAIN="tfg.com"
TIMEZONE="Europe/Madrid"
DNS_HOST="erp.odoo"
DNS_DOMAIN="tfg.com"
DNS_TARGET="$NGINX_IP"    # nginx-proxy MACVLAN — punto de entrada HTTP/HTTPS

# ── Contraseña admin (hash bcrypt de "pfsense") ──
# IMPORTANTE: Cambiar en el primer login
# shellcheck disable=SC2016
ADMIN_HASH='$2b$10$XnBAqMBPIZoGweMJsHLx9OFXzO/UMMBNkSYUFODjWsXsgYyMoGxIy'

# ── Archivo de salida ──
OUTPUT_DIR="$(cd "$(dirname "$0")/../.." && pwd)/config"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/pfsense_config.xml"

echo "=== Generador de config.xml para pfSense ==="
echo "Archivo de salida: $OUTPUT_FILE"

# ── Timestamp ──
# shellcheck disable=SC2034
TS=$(date +%s)

cat > "$OUTPUT_FILE" << 'XMLEOF'
<?xml version="1.0"?>
<pfsense>
  <version>24.0</version>
  <lastchange></lastchange>
XMLEOF


{
# ── System ──
cat << XMLEOF
  <system>
    <optimization>normal</optimization>
    <hostname>${HOSTNAME}</hostname>
    <domain>${DOMAIN}</domain>
    <timeservers>pool.ntp.org</timeservers>
    <timezone>${TIMEZONE}</timezone>
    <language>es_ES</language>
    <dnsallowoverride>on</dnsallowoverride>
    <disablechecksumoffloading>on</disablechecksumoffloading>
    <webgui>
      <protocol>https</protocol>
      <port>443</port>
      <max_procs>2</max_procs>
      <noantilockout/>
    </webgui>
    <user>
      <name>admin</name>
      <descr><![CDATA[System Administrator]]></descr>
      <scope>system</scope>
      <groupname>admins</groupname>
      <bcrypt-hash>${ADMIN_HASH}</bcrypt-hash>
      <uid>0</uid>
      <priv>page-all</priv>
    </user>
    <group>
      <name>admins</name>
      <description><![CDATA[System Administrators]]></description>
      <scope>system</scope>
      <gid>1999</gid>
      <member>0</member>
      <priv>page-all</priv>
    </group>
    <disablenatreflection>yes</disablenatreflection>
    <bogonsinterval>monthly</bogonsinterval>
  </system>
XMLEOF

# ── Interfaces ──
cat << XMLEOF
  <interfaces>
    <wan>
      <enable/>
      <if>${WAN_IF}</if>
      <descr><![CDATA[WAN]]></descr>
      <ipaddr>dhcp</ipaddr>
      <dhcphostname/>
      <blockpriv/>
      <blockbogons/>
      <spoofmac/>
    </wan>
    <lan>
      <enable/>
      <if>${LAN_IF}</if>
      <descr><![CDATA[LAN]]></descr>
      <ipaddr>${LAN_IP}</ipaddr>
      <subnet>${LAN_SUBNET}</subnet>
      <spoofmac/>
    </lan>
    <opt1>
      <enable/>
      <if>${DMZ_IF}</if>
      <descr><![CDATA[DMZ]]></descr>
      <ipaddr>${DMZ_IP}</ipaddr>
      <subnet>${DMZ_SUBNET}</subnet>
      <spoofmac/>
    </opt1>
    <opt2>
      <enable/>
      <if>${ADMIN_IF}</if>
      <descr><![CDATA[VLAN_ADMIN]]></descr>
      <ipaddr>${ADMIN_IP}</ipaddr>
      <subnet>${ADMIN_SUBNET}</subnet>
      <spoofmac/>
    </opt2>
  </interfaces>
XMLEOF

# ── DHCP ──
cat << XMLEOF
  <dhcpd>
    <lan>
      <enable/>
      <range>
        <from>${LAN_DHCP_START}</from>
        <to>${LAN_DHCP_END}</to>
      </range>
      <gateway>${LAN_IP}</gateway>
      <dnsserver>${LAN_IP}</dnsserver>
    </lan>
    <opt2>
      <enable/>
      <range>
        <from>${ADMIN_DHCP_START}</from>
        <to>${ADMIN_DHCP_END}</to>
      </range>
      <dnsserver>${ADMIN_IP}</dnsserver>
    </opt2>
  </dhcpd>
XMLEOF

# ── DNS Resolver ──
cat << XMLEOF
  <unbound>
    <enable>on</enable>
    <dnssec/>
    <active_interface>lan,opt1,opt2,lo0</active_interface>
    <outgoing_interface>wan</outgoing_interface>
    <hosts>
      <host>${DNS_HOST}</host>
      <domain>${DNS_DOMAIN}</domain>
      <ip>${DNS_TARGET}</ip>
      <descr><![CDATA[Servidor Odoo ERP - DMZ]]></descr>
    </hosts>
  </unbound>
XMLEOF

# ── NAT Port Forward ──
cat << XMLEOF
  <nat>
    <outbound>
      <mode>automatic</mode>
    </outbound>
    <rule>
      <descr><![CDATA[HTTP publico - Nginx Odoo]]></descr>
      <interface>wan</interface>
      <protocol>tcp</protocol>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>80</port>
      </destination>
      <target>${NGINX_IP}</target>
      <local-port>80</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
    <rule>
      <descr><![CDATA[HTTPS publico - Nginx Odoo]]></descr>
      <interface>wan</interface>
      <protocol>tcp</protocol>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>443</port>
      </destination>
      <target>${NGINX_IP}</target>
      <local-port>443</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
    <rule>
      <descr><![CDATA[Forzar DNS VLAN 10 a pfSense]]></descr>
      <interface>lan</interface>
      <protocol>tcp/udp</protocol>
      <source>
        <network>lan</network>
      </source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <target>${LAN_IP}</target>
      <local-port>53</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
    <rule>
      <descr><![CDATA[Forzar DNS VLAN 40 a pfSense]]></descr>
      <interface>opt2</interface>
      <protocol>tcp/udp</protocol>
      <source>
        <network>opt2</network>
      </source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <target>${ADMIN_IP}</target>
      <local-port>53</local-port>
      <associated-rule-id>pass</associated-rule-id>
    </rule>
  </nat>
XMLEOF

# ── Aliases (para reglas más limpias) ──
cat << XMLEOF
  <aliases>
    <alias>
      <name>Servidor_Debian</name>
      <type>host</type>
      <address>${SERVER_IP}</address>
      <descr><![CDATA[Servidor Debian DMZ (192.168.30.10)]]></descr>
    </alias>
    <alias>
      <name>Nginx_Proxy</name>
      <type>host</type>
      <address>${NGINX_IP}</address>
      <descr><![CDATA[Nginx Reverse Proxy MACVLAN (192.168.30.20)]]></descr>
    </alias>
    <alias>
      <name>Odoo_Web</name>
      <type>host</type>
      <address>${ODOO_IP}</address>
      <descr><![CDATA[Odoo ERP MACVLAN (192.168.30.21)]]></descr>
    </alias>
    <alias>
      <name>PostgreSQL_VM</name>
      <type>host</type>
      <address>192.168.40.10</address>
      <descr><![CDATA[PostgreSQL 16 nativo VLAN 40 (192.168.40.10)]]></descr>
    </alias>
    <alias>
      <name>VLAN_Clientes</name>
      <type>network</type>
      <address>192.168.10.0/24</address>
      <descr><![CDATA[Red VLAN 10 - Clientes]]></descr>
    </alias>
    <alias>
      <name>VLAN_Admin</name>
      <type>network</type>
      <address>192.168.40.0/24</address>
      <descr><![CDATA[Red VLAN 40 - Administracion y BD]]></descr>
    </alias>
  </aliases>
XMLEOF

# ── Firewall Rules ──
cat << XMLEOF
  <filter>
    <!-- ===================== WAN ===================== -->
    <!-- WAN Pos.3: HTTP publico -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>wan</interface>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>80</port>
      </destination>
      <descr><![CDATA[HTTP publico - redirige a HTTPS]]></descr>
    </rule>
    <!-- WAN Pos.4: HTTPS publico -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>wan</interface>
      <source><any/></source>
      <destination>
        <network>wanip</network>
        <port>443</port>
      </destination>
      <descr><![CDATA[HTTPS publico - Odoo]]></descr>
    </rule>
    <!-- WAN Pos.5: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>wan</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Bloquear todo lo demas WAN]]></descr>
    </rule>

    <!-- ===================== LAN (VLAN 10) ===================== -->
    <!-- LAN Pos.1: Bloquear acceso a VLAN Admin -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>192.168.40.0/24</address>
      </destination>
      <descr><![CDATA[Bloquear acceso a VLAN Admin]]></descr>
    </rule>
    <!-- LAN Pos.2: Bloquear SSH al servidor -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>22</port>
      </destination>
      <descr><![CDATA[Bloquear SSH al servidor]]></descr>
    </rule>
    <!-- LAN Pos.3: Bloquear Cockpit -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>9090</port>
      </destination>
      <descr><![CDATA[Bloquear Cockpit]]></descr>
    </rule>

    <!-- LAN Pos.5: Bloquear PostgreSQL -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>192.168.30.0/24</address>
        <port>5432</port>
      </destination>
      <descr><![CDATA[Bloquear PostgreSQL]]></descr>
    </rule>
    <!-- LAN Pos.7: Odoo HTTP via Nginx -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${NGINX_IP}</address>
        <port>80</port>
      </destination>
      <descr><![CDATA[Odoo HTTP via Nginx]]></descr>
    </rule>
    <!-- LAN Pos.8: Odoo HTTPS via Nginx -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination>
        <address>${NGINX_IP}</address>
        <port>443</port>
      </destination>
      <descr><![CDATA[Odoo HTTPS via Nginx]]></descr>
    </rule>

    <!-- LAN Pos.10: Navegacion general Internet -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><network>lan</network></source>
      <destination><any/></destination>
      <descr><![CDATA[Navegacion general Internet]]></descr>
    </rule>
    <!-- LAN Pos.11: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>lan</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Deny all LAN]]></descr>
    </rule>

    <!-- ===================== OPT1 / DMZ (VLAN 30) ===================== -->
    <!-- ORDEN CRITICO: bloqueos anti-pivoting PRIMERO, luego PASS Odoo→PG, luego bloqueo VLAN40 -->

    <!-- DMZ Pos.1: Anti-pivoting a VLAN 10 ← PRIMERO -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <address>192.168.10.0/24</address>
      </destination>
      <descr><![CDATA[DMZ NO puede atacar VLAN 10 (anti-pivoting)]]></descr>
    </rule>
    <!-- DMZ Pos.2: DMZ no accede a pfSense LAN -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <address>${LAN_IP}</address>
      </destination>
      <descr><![CDATA[DMZ NO puede acceder a pfSense (192.168.10.1)]]></descr>
    </rule>
    <!-- DMZ Pos.3: PASS Odoo-web -> PostgreSQL externo ← excepcion explicita antes del bloqueo VLAN40 -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt1</interface>
      <source>
        <address>${ODOO_IP}</address>
      </source>
      <destination>
        <address>192.168.40.10</address>
        <port>5432</port>
      </destination>
      <descr><![CDATA[Odoo-web (192.168.30.21) -> PostgreSQL VLAN 40 (192.168.40.10:5432)]]></descr>
    </rule>
    <!-- DMZ Pos.4: Anti-pivoting a VLAN Admin ← despues del PASS Odoo→PG -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <address>192.168.40.0/24</address>
      </destination>
      <descr><![CDATA[DMZ NO puede acceder a VLAN Admin (excepto regla Odoo->PG)]]></descr>
    </rule>
    <!-- DMZ Pos.5: Actualizaciones HTTP -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <any/>
        <port>80</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTP (DMZ)]]></descr>
    </rule>
    <!-- DMZ Pos.6: Actualizaciones HTTPS -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <any/>
        <port>443</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTPS (DMZ)]]></descr>
    </rule>
    <!-- DMZ Pos.7: DNS resolucion -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>udp</protocol>
      <interface>opt1</interface>
      <source><network>opt1</network></source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <descr><![CDATA[DNS resolucion de nombres (DMZ)]]></descr>
    </rule>
    <!-- DMZ Pos.8: Deny all ← ULTIMO -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt1</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Bloquear todo lo demas DMZ (deny-all)]]></descr>
    </rule>

    <!-- ===================== OPT2 / VLAN 40 (Admin) ===================== -->
    <!-- ADMIN Pos.1: Panel pfSense -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <network>(self)</network>
        <port>443</port>
      </destination>
      <descr><![CDATA[Panel pfSense - acceso exclusivo VLAN 40]]></descr>
    </rule>
    <!-- ADMIN Pos.2: SSH al servidor Debian -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>22</port>
      </destination>
      <descr><![CDATA[SSH al servidor Debian]]></descr>
    </rule>
    <!-- ADMIN Pos.3: Cockpit -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${SERVER_IP}</address>
        <port>9090</port>
      </destination>
      <descr><![CDATA[Cockpit - gestion visual]]></descr>
    </rule>
    <!-- ADMIN Pos.4: Nginx/Odoo admin completo -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>${NGINX_IP}</address>
        <port>443</port>
      </destination>
      <descr><![CDATA[Nginx/Odoo admin completo (MACVLAN 192.168.30.20)]]></descr>
    </rule>
    <!-- ADMIN Pos.5: DBA acceso directo a PostgreSQL -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>192.168.40.10</address>
        <port>5432</port>
      </destination>
      <descr><![CDATA[Acceso DBA directo a PostgreSQL (192.168.40.10:5432)]]></descr>
    </rule>

    <!-- ADMIN Pos.6: Internet + DNS -->
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <any/>
        <port>80</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTP Admin]]></descr>
    </rule>
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>tcp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <any/>
        <port>443</port>
      </destination>
      <descr><![CDATA[Actualizaciones HTTPS Admin]]></descr>
    </rule>
    <rule>
      <type>pass</type>
      <ipprotocol>inet</ipprotocol>
      <protocol>udp</protocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <any/>
        <port>53</port>
      </destination>
      <descr><![CDATA[DNS resolucion Admin]]></descr>
    </rule>
    <!-- ADMIN Pos.8: Anti-pivoting a VLAN 10 -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt2</interface>
      <source><network>opt2</network></source>
      <destination>
        <address>192.168.10.0/24</address>
      </destination>
      <descr><![CDATA[Anti-pivoting a VLAN 10]]></descr>
    </rule>
    <!-- ADMIN Pos.9: Deny all -->
    <rule>
      <type>block</type>
      <ipprotocol>inet</ipprotocol>
      <interface>opt2</interface>
      <source><any/></source>
      <destination><any/></destination>
      <descr><![CDATA[Deny all VLAN Admin]]></descr>
    </rule>
  </filter>
XMLEOF

# ── Cerrar XML ──
cat << 'XMLEOF'
</pfsense>
XMLEOF
} >> "$OUTPUT_FILE"

echo ""
echo "[OK] Archivo generado: $OUTPUT_FILE"
echo ""
echo "=== Instrucciones de importacion ==="
echo "1. Copiar el archivo a un USB o compartirlo por red"
echo "2. En pfSense: Diagnostics → Backup/Restore"
echo "3. Pestaña 'Restore Backup Configuration'"
echo "4. Seleccionar el archivo y pulsar 'Restore Configuration'"
echo "5. pfSense se reiniciara con la configuracion aplicada"
echo ""
echo "=== Post-importacion ==="
echo "6. Cambiar la contrasena admin en el primer login"
echo "7. Verificar acceso desde VLAN 40: https://192.168.40.1"
