#!/bin/bash
# ============================================================
# SCRIPT: vagrant/provision_pfsense.sh
# DESCRIPCION: Provisioning de la VM pfSense.
#              Aplica la configuracion generada por
#              generate_pfsense_config.sh si esta disponible.
#              Si no, informa de la URL de configuracion manual.
# ============================================================
set -e

echo "=========================================="
echo " Provisioning pfSense..."
echo "=========================================="

# Generar config.xml a partir del script subido a /tmp
if [ -f /tmp/generate_pfsense_config.sh ]; then
    chmod +x /tmp/generate_pfsense_config.sh
    /tmp/generate_pfsense_config.sh
fi

# Aplicar el config.xml generado (se guardara en /config/pfsense_config.xml al ejecutarse desde /tmp)
if [ -f /config/pfsense_config.xml ]; then
    cp /config/pfsense_config.xml /cf/conf/config.xml
    /etc/rc.reload_all
    echo "[OK] Configuracion pfSense aplicada desde config.xml."
else
    echo ""
    echo "[AVISO] No se encontro config.xml generado."
    echo "        Configura pfSense manualmente:"
    echo "          URL:  https://192.168.40.1"
    echo "          User: admin"
    echo "          Pass: pfsense (cambiar en el primer login)"
    echo ""
    echo "  Pasos minimos necesarios:"
    echo "    1. WAN: configurar interfaz de salida a Internet"
    echo "    2. VLAN 10 (192.168.10.0/24)  - Usuarios internos"
    echo "    3. VLAN 30 (192.168.30.0/24)  - DMZ Odoo"
    echo "    4. VLAN 40 (192.168.40.0/24)  - Administracion"
    echo "    5. Regla NAT: WAN:443  -> 192.168.30.20:443"
    echo "    6. Regla NAT: WAN:1194 -> OpenVPN"
    echo "    7. Regla PASS: VLAN30 -> 192.168.40.10:5432"
    echo "    8. Regla BLOCK: VLAN10 -> 192.168.40.10:5432"
fi
