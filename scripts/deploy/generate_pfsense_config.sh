#!/bin/sh
# ============================================================
# SCRIPT: generate_pfsense_config.sh
# DESCRIPCIÓN: Genera un config.xml completo para pfSense
#   con todas las reglas del proyecto TFC.
#   Arquitectura: bridge Docker + port mapping (sin MACVLAN).
#   Nginx y Odoo usan la IP del host (192.168.30.10).
# USO: ./scripts/deploy/generate_pfsense_config.sh
# ============================================================

set -eu

# ── Variables de red ──────────────────────────────────────────
HOSTNAME="pfsense-tfc"
DOMAIN="local"
TIMEZONE="Europe/Madrid"

# Interfaces físicas (adaptadores VMware: em0=WAN, em1=LAN, em2=DMZ, em3=ADMIN)
WAN_IF="em0"
LAN_IF="em1"
DMZ_IF="em2"
ADMIN_IF="em3"

# IPs de gateways por interfaz
LAN_IP="192.168.10.1"
LAN_SUBNET="24"
DMZ_IP="192.168.30.1"
DMZ_SUBNET="24"
ADMIN_IP="192.168.40.1"
ADMIN_SUBNET="24"

# DHCP: LAN para clientes, ADMIN para administradores
LAN_DHCP_START="192.168.10.100"
LAN_DHCP_END="192.168.10.200"
ADMIN_DHCP_START="192.168.40.10"
ADMIN_DHCP_END="192.168.40.50"

# IPs de servidores
# ARQUITECTURA ACTUAL (v2.0 — sin MACVLAN):
#   Nginx y Odoo corren en Docker bridge en odoo-server.
#   Nginx expone :80/:443 del HOST via port mapping.
#   No existen IPs .20 ni .21 — solo la IP del host .10.
SERVER_IP="192.168.30.10"   # odoo-server: nginx expone :80/:443, Odoo interno :8069
PGSQL_IP="192.168.40.10"    # db-server: PostgreSQL 16 nativo

# DNS Override: resuelve erp.odoo.tfc.com → host odoo-server
DNS_HOST="erp"
DNS_DOMAIN="odoo.tfc"
DNS_TARGET="${SERVER_IP}"   # 192.168.30.10 — Nginx port mapping en el host

OUTPUT_FILE="config/pfsense_config.xml"

mkdir -p "$(dirname "$OUTPUT_FILE")"

# ── Bloque XML: Sistema ───────────────────────────────────────
# FIX v1: bcrypt-hash con valor placeholder inválido sustituido por hash
#   real (coste 10) de la contraseña provisional "pfsense2024".
#   IMPORTANTE: cambiar contraseña en el primer login tras importar.
# FIX v2: <timeservers> duplicado dentro de <system> eliminado.
cat > "$OUTPUT_FILE" << XMLEOF
<?xml version="1.0"?>
<pfsense>
 <version>24.0</version>
 <lastchange></lastchange>
 <system>
  <hostname>${HOSTNAME}</hostname>
  <domain>${DOMAIN}</domain>
  <timezone>${TIMEZONE}</timezone>
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
   <bcrypt-hash>\$2b\$10\$NZZJNp0sOiKvxgmMg3I10OKuseNxul2PwlGsc/6vknFGb9X8VvvrS</bcrypt-hash>
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

# ── Interfaces ────────────────────────────────────────────────
{
cat << XMLEOF
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

# ── DHCP ──────────────────────────────────────────────────────
cat << XMLEOF
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

# ── DNS Resolver (Unbound) ────────────────────────────────────
# Host Override: erp.odoo.tfc.com → 192.168.30.10 (host odoo-server)
# Redirección DNS forzada: intercepta consultas externas en LAN y ADMIN
cat << XMLEOF
 <unbound>
  <enable>on</enable>
  <active_interface>lan,opt1,opt2,lo0</active_interface>
  <outgoing_interface>wan</outgoing_interface>
  <dnssec>off</dnssec>
  <hosts>
   <host>${DNS_HOST}</host>
   <domain>${DNS_DOMAIN}</domain>
   <ip>${DNS_TARGET}</ip>
   <descr>Odoo ERP — odoo-server host (Nginx port mapping 80/443)</descr>
  </hosts>
 </unbound>
XMLEOF

# ── NAT Port Forward ──────────────────────────────────────────
# WAN:80/443 → SERVER_IP:80/443 (nginx-proxy vía Docker port mapping)
# Redirección DNS: intercepta consultas :53 que salgan fuera
cat << XMLEOF
 <nat>
  <!-- WAN → odoo-server: Nginx expone :80/:443 del host vía Docker port mapping -->
  <rule>
   <source>
    <any></any>
   </source>
   <destination>
    <network>wanip</network>
    <port>80</port>
   </destination>
   <protocol>tcp</protocol>
   <target>${SERVER_IP}</target>
   <local-port>80</local-port>
   <interface>wan</interface>
   <descr>NAT HTTP WAN to odoo-server (nginx port mapping)</descr>
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
   <target>${SERVER_IP}</target>
   <local-port>443</local-port>
   <interface>wan</interface>
   <descr>NAT HTTPS WAN to odoo-server (nginx port mapping)</descr>
   <associated-rule-id>nat</associated-rule-id>
  </rule>
  <!-- Forzar DNS interno: intercepta :53 externo en VLAN 10 y VLAN 40 -->
  <rule>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <not></not>
    <network>lan</network>
    <port>53</port>
   </destination>
   <protocol>tcp/udp</protocol>
   <target>${LAN_IP}</target>
   <local-port>53</local-port>
   <interface>lan</interface>
   <descr>Redirect DNS VLAN10 to pfSense (fuerza DNS interno)</descr>
  </rule>
  <rule>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <not></not>
    <network>opt2</network>
    <port>53</port>
   </destination>
   <protocol>tcp/udp</protocol>
   <target>${ADMIN_IP}</target>
   <local-port>53</local-port>
   <interface>opt2</interface>
   <descr>Redirect DNS VLAN40 to pfSense (fuerza DNS interno)</descr>
  </rule>
 </nat>
XMLEOF

# ── Aliases ───────────────────────────────────────────────────
# NOTA v2.0: Con bridge Docker, solo existe una IP real en la DMZ:
#   SERVER_IP (192.168.30.10) = odoo-server host.
#   Nginx y Odoo comparten la IP del host (port mapping).
cat << XMLEOF
 <aliases>
  <!-- odoo-server: host Debian donde corren nginx-proxy y odoo-web (Docker bridge) -->
  <alias>
   <name>Odoo_Server</name>
   <type>host</type>
   <address>${SERVER_IP}</address>
   <descr>odoo-server host — Nginx :80/:443 (port mapping) + Odoo :8069 (interno)</descr>
  </alias>
  <!-- db-server: PostgreSQL 16 nativo en VLAN 40 -->
  <alias>
   <name>PostgreSQL_VM</name>
   <type>host</type>
   <address>${PGSQL_IP}</address>
   <descr>db-server — PostgreSQL 16 nativo VLAN 40</descr>
  </alias>
  <!-- Redes por VLAN -->
  <alias>
   <name>VLAN_Clientes</name>
   <type>network</type>
   <address>192.168.10.0/24</address>
   <descr>VLAN 10 — PCs empleados</descr>
  </alias>
  <alias>
   <name>VLAN_DMZ</name>
   <type>network</type>
   <address>192.168.30.0/24</address>
   <descr>VLAN 30 — DMZ (odoo-server)</descr>
  </alias>
  <alias>
   <name>VLAN_Admin</name>
   <type>network</type>
   <address>192.168.40.0/24</address>
   <descr>VLAN 40 — Administración y Base de Datos</descr>
  </alias>
 </aliases>
XMLEOF

# ── Firewall Rules ────────────────────────────────────────────
# ORDEN CRÍTICO: los BLOCK van siempre ANTES que los PASS.
#
# FIX v3: <destination> con solo <port> sin dirección es inválido en pfSense.
#   Las reglas de salida a Internet usan <any></any> como destino.
# FIX v4: pfSense panel se referencia con <network>(self)</network>,
#   no con la IP de la interfaz en el destino de reglas allow-admin.
# FIX v5: Regla Odoo→PostgreSQL usa SERVER_IP como origen
#   (los contenedores Docker salen con la IP del host, no con IP propia).
cat << XMLEOF
 <filter>
  <!-- ═══════ WAN ═══════════════════════════════════════════ -->
  <!-- Solo HTTP/HTTPS público; todo lo demás bloqueado -->
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
   <descr>WAN: Allow HTTP publico (redirige a HTTPS via Nginx)</descr>
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
   <descr>WAN: Allow HTTPS publico → Odoo via Nginx</descr>
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
   <descr>WAN: Deny all (excepto 80/443 arriba)</descr>
  </rule>

  <!-- ═══════ LAN / VLAN 10 — Clientes ═══════════════════════ -->
  <!-- BLOQUEOS primero (orden crítico) -->
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
   <descr>LAN: Block → VLAN Admin/BD (anti-pivoting)</descr>
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
   <descr>LAN: Block SSH a odoo-server</descr>
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
   <descr>LAN: Block Cockpit a odoo-server</descr>
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
    <port>8069</port>
   </destination>
   <descr>LAN: Block acceso directo a Odoo (solo via Nginx)</descr>
  </rule>
  <!-- PERMISOS: solo Odoo e Internet -->
  <rule>
   <type>pass</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <address>${SERVER_IP}</address>
    <port>80</port>
   </destination>
   <descr>LAN: Allow HTTP → odoo-server (Nginx port mapping)</descr>
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
    <address>${SERVER_IP}</address>
    <port>443</port>
   </destination>
   <descr>LAN: Allow HTTPS → odoo-server (Nginx port mapping)</descr>
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
    <any></any>
    <port>80</port>
   </destination>
   <descr>LAN: Allow HTTP Internet (navegacion)</descr>
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
    <any></any>
    <port>443</port>
   </destination>
   <descr>LAN: Allow HTTPS Internet (navegacion)</descr>
  </rule>
  <rule>
   <type>pass</type>
   <interface>lan</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>udp</protocol>
   <source>
    <network>lan</network>
   </source>
   <destination>
    <network>lanip</network>
    <port>53</port>
   </destination>
   <descr>LAN: Allow DNS → pfSense (forzado por NAT redirect)</descr>
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
   <descr>LAN: Deny all (resto)</descr>
  </rule>

  <!-- ═══════ OPT1 / DMZ / VLAN 30 ════════════════════════════ -->
  <!-- BLOQUEOS anti-pivoting primero (CRÍTICO) -->
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
   <descr>DMZ: Block → VLAN 10 (anti-pivoting)</descr>
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
   <descr>DMZ: Block → pfSense LAN gateway</descr>
  </rule>
  <!-- Regla explícita Odoo→PostgreSQL ANTES del bloque general a VLAN40 -->
  <!-- FIX v5: origen es SERVER_IP (los contenedores salen con la IP del host) -->
  <rule>
   <type>pass</type>
   <interface>opt1</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <address>${SERVER_IP}</address>
   </source>
   <destination>
    <address>${PGSQL_IP}</address>
    <port>5432</port>
   </destination>
   <descr>DMZ: Allow odoo-server → PostgreSQL VLAN 40 (Odoo→BD)</descr>
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
   <descr>DMZ: Block → VLAN Admin (resto, excepto regla Odoo→PG arriba)</descr>
  </rule>
  <!-- Salida mínima a Internet para actualizaciones del servidor -->
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
   <descr>DMZ: Allow HTTP salida (actualizaciones Docker/apt)</descr>
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
   <descr>DMZ: Allow HTTPS salida (GitHub Actions, Docker Hub, apt)</descr>
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
   <descr>DMZ: Allow DNS salida</descr>
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
   <descr>DMZ: Deny all (resto)</descr>
  </rule>

  <!-- ═══════ OPT2 / VLAN 40 — Admin + BD ═════════════════════ -->
  <!-- Acceso total a gestión: pfSense panel, SSH, Cockpit, PostgreSQL, Odoo admin -->
  <!-- FIX v4: panel pfSense referenciado con <network>(self)</network> -->
  <rule>
   <type>pass</type>
   <interface>opt2</interface>
   <ipprotocol>inet</ipprotocol>
   <protocol>tcp</protocol>
   <source>
    <network>opt2</network>
   </source>
   <destination>
    <network>(self)</network>
    <port>443</port>
   </destination>
   <descr>ADMIN: Allow → panel pfSense HTTPS (acceso exclusivo VLAN40)</descr>
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
   <descr>ADMIN: Allow SSH → odoo-server</descr>
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
   <descr>ADMIN: Allow Cockpit → odoo-server</descr>
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
    <port>443</port>
   </destination>
   <descr>ADMIN: Allow HTTPS → odoo-server (Nginx admin panel completo)</descr>
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
   <descr>ADMIN: Allow DBA → PostgreSQL directo</descr>
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
   <descr>ADMIN: Allow HTTP Internet (actualizaciones)</descr>
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
   <descr>ADMIN: Allow HTTPS Internet (actualizaciones)</descr>
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
   <descr>ADMIN: Allow DNS</descr>
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
   <descr>ADMIN: Block → VLAN 10 (segmentacion estricta)</descr>
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
   <descr>ADMIN: Deny all (resto)</descr>
  </rule>
 </filter>
</pfsense>
XMLEOF
} >> "$OUTPUT_FILE"

echo ""
echo "[OK] Archivo generado: $OUTPUT_FILE"
echo ""
echo "=== Instrucciones de importacion ==="
echo "1. Copiar el archivo a un USB o compartirlo por red"
echo "2. En pfSense: Diagnostics → Backup/Restore"
echo "3. Pestana 'Restore Backup Configuration'"
echo "4. Seleccionar el archivo y pulsar 'Restore Configuration'"
echo "5. pfSense se reiniciara con la configuracion aplicada"
echo ""
echo "=== Post-importacion ==="
echo "6. Cambiar la contrasena admin en el primer login (password actual: pfsense2024)"
echo "7. Verificar acceso desde VLAN 40: https://${ADMIN_IP}"
echo "8. Verificar DNS: nslookup erp.odoo.tfc.com  →  ${DNS_TARGET}"
echo "9. Verificar NAT: curl -k https://${SERVER_IP}  →  debe devolver Odoo"