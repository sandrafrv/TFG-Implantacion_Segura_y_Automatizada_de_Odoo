# ============================================================
# Vagrantfile — TFG Implantación Segura y Automatizada de Odoo
# Uso: vagrant up
# Crea: VM pfSense + VM Odoo+Nginx + VM PostgreSQL
#
# REQUISITOS PREVIOS:
#   winget install HashiCorp.Vagrant
#   vagrant plugin install vagrant-vmware-desktop
#
# VARIABLES DE ENTORNO (opcionales; si no se pasan, usa valores demo):
#   POSTGRES_PASSWORD    → contraseña de la BD
#   ODOO_MASTER_PASSWORD → contraseña maestra de Odoo
# ============================================================

Vagrant.configure("2") do |config|

  # --------------------------------------------------------
  # VM 1 — pfSense (Firewall / VPN / Router)
  # WAN: red pública
  # VMnet1 → VLAN 10: usuarios  (192.168.10.x)
  # VMnet2 → VLAN 40: admin     (192.168.40.x)
  # --------------------------------------------------------
  config.vm.define "pfsense" do |pf|
    pf.vm.box              = "dlee35/pfsense"
    pf.vm.box_check_update = false
    pf.vm.hostname         = "pfsense-tfg"

    # Fix: Desactivar la carpeta compartida por defecto para evitar que se quede colgado en FreeBSD
    pf.vm.synced_folder ".", "/vagrant", disabled: true

    pf.vm.network "private_network", ip: "192.168.10.1",
      vmware__vmnet: "VMnet1", auto_config: false
    pf.vm.network "private_network", ip: "192.168.30.1",
      vmware__vmnet: "VMnet2", auto_config: false
    pf.vm.network "private_network", ip: "192.168.40.1",
      vmware__vmnet: "VMnet3", auto_config: false

    pf.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "TFG-pfSense"
      v.memory = 1024
      v.cpus   = 1
      v.gui    = true
    end

    # Fix: Subir el script directamente y provisionar
    pf.vm.provision "file", source: "scripts/deploy/generate_pfsense_config.sh", destination: "/tmp/generate_pfsense_config.sh"
    pf.vm.provision "shell", path: "vagrant/provision_pfsense.sh"
  end

  # --------------------------------------------------------
  # VM 2 — Debian 12 (Odoo 17 + Nginx)
  # DMZ — VLAN 30
  #   nginx-proxy  192.168.30.20  → HTTPS :443
  #   odoo-web     192.168.30.21  → Odoo  :8069 (interno)
  #   Cockpit      192.168.30.21  → panel :9090
  # --------------------------------------------------------
  config.vm.define "odoo-server" do |deb|
    deb.vm.box              = "bento/debian-12"
    deb.vm.box_check_update = false
    deb.vm.hostname         = "odoo-server-tfg"

    deb.vm.network "private_network", ip: "192.168.30.10",
      vmware__vmnet: "VMnet2"

    deb.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "TFG-Odoo-Server"
      v.memory = 4096
      v.cpus   = 2
      v.gui    = true
    end

    deb.vm.provision "shell",
      path:       "vagrant/provision_debian.sh",
      privileged: true,
      env: {
        "POSTGRES_PASSWORD"    => ENV["POSTGRES_PASSWORD"]    || "changeme_db",
        "ODOO_MASTER_PASSWORD" => ENV["ODOO_MASTER_PASSWORD"] || "changeme_master",
        "POSTGRES_HOST"        => "192.168.40.10"
      }
  end

  # --------------------------------------------------------
  # VM 3 — Debian 12 (PostgreSQL 16)
  # VLAN 40 — Administración
  #   postgresql   192.168.40.10  → BD aislada :5432
  #   backups      /backups/      → copias automáticas
  #   Cockpit      192.168.40.10  → panel      :9090
  # --------------------------------------------------------
  config.vm.define "db-server" do |db|
    db.vm.box              = "bento/debian-12"
    db.vm.box_check_update = false
    db.vm.hostname         = "db-server-tfg"

    db.vm.network "private_network", ip: "192.168.40.10",
      vmware__vmnet: "VMnet3"

    db.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"] = "TFG-DB-Server"
      v.memory = 2048
      v.cpus   = 1
      v.gui    = true
    end

    db.vm.provision "shell",
      path:       "vagrant/provision_postgres.sh",
      privileged: true,
      env: {
        "POSTGRES_PASSWORD" => ENV["POSTGRES_PASSWORD"] || "changeme_db"
      }
  end

end
