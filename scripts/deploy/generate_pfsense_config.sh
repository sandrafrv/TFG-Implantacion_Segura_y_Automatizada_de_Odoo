#!/bin/sh
# ============================================================
# SCRIPT: generate_pfsense_config.sh
# DESCRIPCIÓN: Genera un config.xml completo para pfSense
# con todas las reglas del proyecto TFG.
# USO: ./scripts/deploy/generate_pfsense_config.sh
# ============================================================

set -eu

# ── Variables de red ──
HOSTNAME="pfsense-tfg"
DOMAIN="local"
TIMEZONE="Europe/Madrid"

WAN_IF="em0"
LAN_IF="em1"
DMZ_IF="em2"
ADMIN_IF="em3"

LAN_IP="192.168.10.1"
LAN_SUBNET="24"
DMZ_IP="192.168.30.1"
DMZ_SUBNET="24"
ADMIN_IP="192.168.40.1"
ADMIN_SUBNET="24"

LAN_DHCP_START="192.168.10.100"
LAN_DHCP_END="192.168.10.200"
ADMIN_DHCP_START="192.168.40.10"
ADMIN_DHCP_END="192.168.40.50"

SERVER_IP="192.168.30.10"
NGINX_IP="192.168.30.20"
ODOO_IP="192.168.30.21"
PGSQL_IP="192.168.40.10"

DNS_HOST="erp"
DNS_DOMAIN="odoo.tfg"
DNS_TARGET="192.168.30.20"

OUTPUT_FILE="config/pfsense_config.xml"

mkdir -p "$(dirname "$OUTPUT_FILE")"

# ── Inicio del XML ──
# FIX Bug 1: bcrypt-hash con valor placeholder inválido.
#   El hash original "$2y$10$..." no es un hash bcrypt válido y pfSense
#   rechaza la importación o impide el login. Se sustituye por un hash
#   real (coste 10) de la contraseña provisional "pfsense2024".
#   IMPORTANTE: cambia la contraseña en el primer login tras importar.
#
# FIX Bug 2: <timeservers> duplicado dentro de <system>.
#   El tag aparecía en las líneas 13 y 43 del bloque original.
#   Se elimina la segunda ocurrencia (la del final del bloque <system>).
cat > "$OUTPUT_FILE" << 'XMLEOF'
<?xml version="1.0"?>
<pfsense>
 <version>24.0</version>
 <lastchange></lastchange>
 <system>
  <hostname>pfsense-tfg</hostname>
  <domain>local</domain>
  <timezone>Europe/Madrid</timezone>
  <language>es_ES</language>
  <dnsserver></dnsserver>
  <dnsallowoverride>on</dnsallowoverride>
  <dnslocalhost>on</dnslocalhost>
  <time-update-interval>300</time-update-interval>
  <timeservers>pool.ntp.org</timeservers>
  <webgui>
   <protocol>https</protocol>
   <port>443</port>
   <ssl-certref>2</ssl-certref>
  </webgui>
  <disableconsolemenu></disableconsolemenu>
  <user>
   <name>admin</name>
   <descr>System Administrator</descr>
   <scope>system</scope>
   <groupname>admins</groupname>
   <bcrypt-hash>$2b$10$NZZJNp0sOiKvxgmMg3I10OKuseNxul2PwlGsc/6vknFGb9X8VvvrS</bcrypt-hash>
   <uid>0</uid>
   <priv>user-shellcmd-access</priv>
   <page-login>page-all</page-login>
  </user>
  <group>
   <name>admins</name>
   <description>System Administrators</description>
   <scope>system</scope>
   <gid>1999</gid>
   <member>0</member>
   <priv>page-all</priv>
  </group>
  <nextuid>2000</nextuid>
  <nextgid>2000</nextgid>
  <webguicss>pfSense.css</webguicss>
  <dashboardcolumns>2</dashboardcolumns>
  <systemlogsrotate>monthly</systemlogsrotate>
 </system>
XMLEOF

# ── Interfaces ──
cat >> "$OUTPUT_FILE" << XMLEOF
 <interfaces>
  <wan>
   <enable></enable>
   <if>${WAN_IF}</if>
   <ipaddr>dhcp</ipaddr>
   <subnet></subnet>
   <gateway></gateway>
   <blockbogons></blockbogons>
   <dhcphostname></dhcphostname>
   <media></media>
   <mediaopt></mediaopt>
   <dhcp6usev4iface></dhcp6usev4iface>
  </wan>
  <lan>
   <enable></enable>
   <if>${LAN_IF}</if>
   <ipaddr>${LAN_IP}</ipaddr>
   <subnet>${LAN_SUBNET}</subnet>
   <gateway></gateway>
   <spoofmac></spoofmac>
  </lan>
  <opt1>
   <enable></enable>
   <if>${DMZ_IF}</if>
   <descr>DMZ</descr>
   <ipaddr>${DMZ_IP}</ipaddr>
   <subnet>${DMZ_SUBNET}</subnet>
   <gateway></gateway>
  </opt1>
  <opt2>
   <enable></enable>
   <if>${ADMIN_IF}</if>
   <descr>ADMIN</descr>
   <ipaddr>${ADMIN_IP}</ipaddr>
   <subnet>${ADMIN_SUBNET}</subnet>
   <gateway></gateway>
  </opt2>
 </interfaces>
XMLEOF

# ── DHCP ──
cat >> "$OUTPUT_FILE" << XMLEOF
 <dhcpd>
  <lan>
   <enable></enable>
   <range>
    <from>${LAN_DHCP_START}</from>
    <to>${LAN_DHCP_END}</to>
   </range>
   <defaultleasetime>7200</defaultleasetime>
   <maxleasetime>86400</maxleasetime>
   <gateway>${LAN_IP}</gateway>
   <dnsserver>${LAN_IP}</dnsserver>
  </lan>
  <opt2>
   <enable></enable>
   <range>
    <from>${ADMIN_DHCP_START}</from>
    <to>${ADMIN_DHCP_END}</to>
   </range>
   <defaultleasetime>7200</defaultleasetime>
   <maxleasetime>86400</maxleasetime>
   <gateway>${ADMIN_IP}</gateway>
   <dnsserver>${ADMIN_IP}</dnsserver>
  </opt2>
 </dhcpd>
XMLEOF

# ── DNS Resolver ──
cat >> "$OUTPUT_FILE" << XMLEOF
 <unbound>
  <enable>on</enable>
  <active_interface>lan,opt1,opt2,lo0</active_interface>
  <outgoing_interface>wan</outgoing_interface>
  <dnssec>off</dnssec>
  <hosts>
   <host>${DNS_HOST}</host>
   <domain>${DNS_DOMAIN}</domain>
   <ip>${DNS_TARGET}</ip>
   <descr>Odoo ERP</descr>
  </hosts>
 </unbound>
XMLEOF

# ── NAT Port Forward ──
cat >> "$OUTPUT_FILE" << XMLEOF
 <nat>
  <rule>
   <source>
    <any></any>
   </source>
   <destination>
    <network>wanip</network>
    <port>80</port>
   </destination>
   <protocol>tcp</protocol>
   <target>${NGINX_IP}</target>
   <local-port>80</local-port>
   <interface>wan</interface>
   <descr>NAT HTTP to Nginx</descr>
   <associated-rule-id>nat</associated-rule-id>
  </rule>
  <rule>
   <source>
    <any></any>
   </source>
   <destination>
    <network>wanip</network>
    <port>443</port>
   </destination>
   <protocol>tcp</protocol>
   <target>${NGINX_IP}</target>
   <local-port>443</local-port>
   <interface>wan</interface>
   <descr>NAT HTTPS to Nginx</descr>
   <associated-rule-id>nat</associated-rule-id>
  </rule>
 </nat>
XMLEOF

# ── Aliases ──
# FIX: La IP de PostgreSQL ahora usa la variable ${PGSQL_IP} en lugar
#      de estar hardcodeada como 192.168.40.10. Así queda sincronizada
#      con las reglas de firewall que también usan ${PGSQL_IP}.
cat >> "$OUTPUT_FILE" << XMLEOF
 <aliases>
  <alias>
   <name>Servidor_Debian</name>
   <type>host</type>
   <address>${SERVER_IP}</address>
   <descr></descr>
  </alias>
  <alias>
   <name>Nginx_Proxy</name>
   <type>host</type>
   <address>${NGINX_IP}</address>
   <descr></descr>
  </alias>
  <alias>
   <name>Odoo_Web</name>
   <type>host</type>
   <address>${ODOO_IP}</address>
   <descr></descr>
  </alias>
  <alias>
   <name>PostgreSQL_VM</name>
   <type>host</type>
   <address>${PGSQL_IP}</address>
   <descr></descr>
  </alias>
  <alias>
   <name>VLAN_Clientes</name>
   <type>network</type>
   <address>192.168.10.0/24</address>
   <descr></descr>
  </alias>
  <alias>
   <name>VLAN_Admin</name>
   <type>network</type>
   <address>192.168.40.0/24</address>
   <descr></descr>
  </alias>
 </aliases>
XMLEOF

# ── Firewall Rules ──
# FIX Bug 3: Reglas con <destination> que solo tenían <port> sin dirección.
#   pfSense requiere siempre un destino explícito. Se añade <any></any>
#   en todas las reglas de internet (HTTP/HTTPS/DNS) de DMZ y ADMIN.
#
# FIX Bug 4: <address>opt2ip</address> es sintaxis incorrecta.
#   Para referirse a la propia interfaz se usa <network>(self)</network>,
#   o bien la IP directa. Se sustituye por ${ADMIN_IP} en ambas reglas.
cat >> "$OUTPUT_FILE" << XMLEOF
 <filter>
  <rule>
   <type>pass</type>
   <interface>wan</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <any></any>
   </source>
   <destination>
    <network>wanip</network>
    <port>80</port>
   </destination>
   <descr>Allow HTTP WAN</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>wan</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <any></any>
   </source>
   <destination>
    <network>wanip</network>
    <port>443</port>
   </destination>
   <descr>Allow HTTPS WAN</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>wan</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <any></any>
   </source>
   <destination>
    <any></any>
   </destination>
   <descr>Block all other WAN</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>192.168.40.0/24</address>
   </destination>
   <descr>Block LAN to Admin</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>${SERVER_IP}</address>
    <port>22</port>
   </destination>
   <descr>Block SSH to DMZ Server</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>${SERVER_IP}</address>
    <port>9090</port>
   </destination>
   <descr>Block Cockpit to DMZ Server</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>192.168.30.0/24</address>
    <port>5432</port>
   </destination>
   <descr>Block LAN to DMZ PostgreSQL port</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>${NGINX_IP}</address>
    <port>80</port>
   </destination>
   <descr>Allow LAN HTTP to Nginx</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>${NGINX_IP}</address>
    <port>443</port>
   </destination>
   <descr>Allow LAN HTTPS to Nginx</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <any></any>
   </destination>
   <descr>Block all other LAN</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <address>192.168.10.0/24</address>
   </destination>
   <descr>Anti-pivoting: DMZ to LAN</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <address>${LAN_IP}</address>
   </destination>
   <descr>Block DMZ to pfSense LAN</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <address>${ODOO_IP}</address>
   </source>
   <destination>
    <address>${PGSQL_IP}</address>
    <port>5432</port>
   </destination>
   <descr>Allow Odoo to PostgreSQL VLAN 40</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <address>192.168.40.0/24</address>
   </destination>
   <descr>Block DMZ to rest of Admin VLAN</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <any></any>
    <port>80</port>
   </destination>
   <descr>Allow DMZ HTTP</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <any></any>
    <port>443</port>
   </destination>
   <descr>Allow DMZ HTTPS</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>udp</protocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <any></any>
    <port>53</port>
   </destination>
   <descr>Allow DMZ DNS</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>opt1</network>
   </source>
   <destination>
    <any></any>
   </destination>
   <descr>Block all other DMZ</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>${ADMIN_IP}</address>
    <port>443</port>
   </destination>
   <descr>Allow Admin HTTPS to pfSense</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>${ADMIN_IP}</address>
    <port>22</port>
   </destination>
   <descr>Allow Admin SSH to pfSense</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>${SERVER_IP}</address>
    <port>22</port>
   </destination>
   <descr>Allow Admin SSH to DMZ Server</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>${SERVER_IP}</address>
    <port>9090</port>
   </destination>
   <descr>Allow Admin Cockpit to DMZ Server</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>${NGINX_IP}</address>
    <port>443</port>
   </destination>
   <descr>Allow Admin HTTPS to Nginx</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>${PGSQL_IP}</address>
    <port>5432</port>
   </destination>
   <descr>Allow Admin to PostgreSQL</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <any></any>
    <port>80</port>
   </destination>
   <descr>Allow Admin HTTP</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <any></any>
    <port>443</port>
   </destination>
   <descr>Allow Admin HTTPS</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>udp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <any></any>
    <port>53</port>
   </destination>
   <descr>Allow Admin DNS</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <address>192.168.10.0/24</address>
   </destination>
   <descr>Block Admin to LAN</descr>
  </rule>
  <rule>
   <type>block</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <any></any>
   </destination>
   <descr>Block all other Admin</descr>
  </rule>
 </filter>
</pfsense>
XMLEOF

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
echo "6. Cambiar la contrasena admin en el primer login (password actual: pfsense2024)"
echo "7. Verificar acceso desde VLAN 40: https://192.168.40.1"