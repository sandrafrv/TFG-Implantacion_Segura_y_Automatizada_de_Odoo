# ============================================================
# Vagrantfile — TFG Implantación Segura y Automatizada de Odoo
# Uso: vagrant up
# Crea: VM pfSense + VM Odoo + VM PostgreSQL
# ============================================================
Vagrant.configure("2") do |config|
# --------------------------------------------------------
# VM 1 — pfSense (Firewall / VPN / Router)
# --------------------------------------------------------
config.vm.define "pfsense" do |pf|
pf.vm.box = "ksklareski/pfsense-ce"
pf.vm.box_check_update = false
pf.vm.hostname = "pfsense-tfg"
pf.vm.network "public_network",  bridge: "VMnet0"
pf.vm.network "private_network", ip: "192.168.10.1",
vmware__vmnet: "VMnet1"
pf.vm.network "private_network", ip: "192.168.40.1",
vmware__vmnet: "VMnet2"
pf.vm.provider "vmware_desktop" do |v|
v.vmx["displayName"] = "TFG-pfSense"
v.memory = 1024
v.cpus   = 1
v.gui    
= true
end
pf.vm.provision "shell", path: "vagrant/provision_pfsense.sh"
end
# --------------------------------------------------------
# VM 2 — Debian 12 (Odoo + Nginx)
# --------------------------------------------------------
config.vm.define "odoo-server" do |deb|
deb.vm.box = "debian/bookworm64"
deb.vm.box_check_update = false
deb.vm.hostname = "odoo-server-tfg"
deb.vm.network "private_network", ip: "192.168.30.21",
vmware__vmnet: "VMnet1"
deb.vm.provider "vmware_desktop" do |v|
v.vmx["displayName"] = "TFG-Odoo-Server"
v.memory = 4096
v.cpus   = 2
v.gui    
end
= true
deb.vm.provision "shell",
path: "vagrant/provision_debian.sh",
privileged: true,
env: {
"POSTGRES_PASSWORD"    
=> ENV["POSTGRES_PASSWORD"]    
|| "changeme_db",
"ODOO_MASTER_PASSWORD" => ENV["ODOO_MASTER_PASSWORD"] || "changeme_master",
"POSTGRES_HOST"        
=> "192.168.40.10"
}
end
# --------------------------------------------------------
# VM 3 — Debian 12 (PostgreSQL)
# --------------------------------------------------------
config.vm.define "db-server" do |db|
db.vm.box = "debian/bookworm64"
db.vm.box_check_update = false
db.vm.hostname = "db-server-tfg"
db.vm.network "private_network", ip: "192.168.40.10",
vmware__vmnet: "VMnet2"
db.vm.provider "vmware_desktop" do |v|
v.vmx["displayName"] = "TFG-DB-Server"
v.memory = 2048
v.cpus   = 1
v.gui    
= true
end
db.vm.provision "shell",
path: "vagrant/provision_postgres.sh",
privileged: true,
env: {
"POSTGRES_PASSWORD" => ENV["POSTGRES_PASSWORD"] || "changeme_db"
}
end
end
