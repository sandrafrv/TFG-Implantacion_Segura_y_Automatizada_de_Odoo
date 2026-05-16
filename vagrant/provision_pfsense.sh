#!/bin/sh
# ============================================================
# SCRIPT: vagrant/provision_pfsense.sh
# DESCRIPCION: Provisioning de la VM pfSense.
#              Aplica el config.xml subido directamente por Vagrant.
#              El XML se genera en el PC antes del vagrant up con:
#                bash scripts/deploy/generate_pfsense_config.sh
# ============================================================
set -e

echo "=========================================="
echo " Provisioning pfSense..."
echo "=========================================="

# El config.xml lo sube Vagrant directamente desde config/pfsense_config.xml
# (generado previamente en el PC con generate_pfsense_config.sh)
if [ -f /tmp/pfsense_config.xml ]; then
    cp /tmp/pfsense_config.xml /cf/conf/config.xml
    echo "[OK] Configuracion pfSense aplicada desde config.xml."
    # En segundo plano para no colgar la conexion SSH de Vagrant al recargar la red
    nohup /etc/rc.reload_all > /dev/null 2>&1 &
else
    echo ""
    echo "[AVISO] No se encontro config.xml."
    echo "        Asegurate de ejecutar antes del vagrant up:"
    echo "          bash scripts/deploy/generate_pfsense_config.sh"
    echo ""
    echo "        O configura pfSense manualmente:"
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