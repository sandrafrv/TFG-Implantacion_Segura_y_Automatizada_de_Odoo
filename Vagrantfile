# ============================================================
# Vagrantfile — TFG Implantación Segura y Automatizada de Odoo
# Uso: vagrant up
# Crea: VM Odoo+Nginx + VM PostgreSQL  (pfSense: VM manual)
#
# REQUISITOS PREVIOS:
#   winget install HashiCorp.Vagrant
#   vagrant plugin install vagrant-vmware-desktop
#
# VARIABLES DE ENTORNO (obligatorias):
#   GH_PAT                → Personal Access Token con scope repo
#   GH_RUNNER_TOKEN_ODOO  → Registration token para odoo-server
#   GH_RUNNER_TOKEN_DB    → Registration token para db-server
#
# VARIABLES DE ENTORNO (opcionales; si no se pasan, usa valores demo):
#   POSTGRES_PASSWORD    → contraseña de la BD
#   ODOO_MASTER_PASSWORD → contraseña maestra de Odoo
#
# IMPORTANTE — orden de arranque:
#   1. Encender pfSense manualmente en VMware
#   2. vagrant up db-server      ← SIEMPRE primero
#   3. vagrant up odoo-server
#
# RED:
#   eth0 → NAT VMware (solo para provisioning inicial — se elimina como gateway)
#   eth1 → VMnet personalizada (gateway: pfSense)
#
#   Al finalizar el provisioning, pfSense queda como único gateway.
#   Persistencia garantizada mediante 3 capas:
#     1. dhclient exit hook  → actúa en cada renovación DHCP de eth0
#     2. systemd oneshot     → actúa en cada arranque del sistema
#     3. interfaces.d        → gateway declarativo en eth1.cfg
# ============================================================
Vagrant.configure("2") do |config|

  GH_PAT  = ENV["GH_PAT"] || ""
  GH_REPO = "sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo"

  # ── db-server definido PRIMERO ──────────────────────────────
  config.vm.define "db-server" do |db|
    db.vm.box              = "bento/debian-12"
    db.vm.box_check_update = false
    db.vm.hostname         = "db-server-tfg"

    db.vm.network "private_network",
      ip:      "192.168.40.10",
      netmask: "255.255.255.0"

    db.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"]              = "TFG-DB-Server"
      v.memory = 2048
      v.cpus   = 1
      v.gui    = true
      v.vmx["ethernet1.connectionType"] = "custom"
      v.vmx["ethernet1.vnet"]           = "vmnet3"
    end

    db.trigger.before :destroy do |trigger|
      trigger.name     = "Desregistrar db-runner"
      trigger.on_error = :continue
      trigger.run = {
        path: "vagrant/deregister_runner.ps1",
        args: ["db-runner", GH_PAT, GH_REPO]
      }
    end

    # ── Provisioner 1: PostgreSQL + GitHub Runner ────────────
    db.vm.provision "shell",
      name:       "provision-postgres",
      path:       "vagrant/provision_postgres.sh",
      privileged: true,
      env: {
        "POSTGRES_PASSWORD" => ENV["POSTGRES_PASSWORD"]  || "changeme_db",
        "GH_PAT"            => ENV["GH_PAT"]             || "",
        "GH_RUNNER_TOKEN"   => ENV["GH_RUNNER_TOKEN_DB"] || "",
        "RUNNER_NAME"       => "db-runner"
      }

    # ── Provisioner 2: Deshabilitar NAT como gateway ─────────
    # Se ejecuta DESPUÉS del provisioning principal.
    # eth0 (NAT) se usó durante el provisioning para descargar
    # paquetes. Al terminar, pfSense pasa a ser el único gateway.
    #
    # Persistencia (3 capas, ver vagrant/disable_nat_gateway.sh):
    #   1. dhclient exit hook  → elimina ruta NAT en cada renovación DHCP
    #   2. systemd oneshot     → elimina ruta NAT en cada arranque
    #   3. interfaces.d/eth1   → gateway declarativo apuntando a pfSense
    #
    # Para re-aplicar en VMs ya creadas:
    #   vagrant provision db-server --provision-with disable-nat-gateway
    db.vm.provision "shell",
      name:       "disable-nat-gateway",
      path:       "vagrant/disable_nat_gateway.sh",
      privileged: true,
      env: {
        "PFSENSE_GW"        => "192.168.40.1",
        "VLAN_IFACE"        => "eth1",
        "VLAN_IP"           => "192.168.40.10",
        "VLAN_MASK"         => "255.255.255.0",
        "EXTRA_ROUTE"       => "192.168.30.0/24",
        "DOCKER_MASQUERADE" => "false"
      }
  end

  # ── odoo-server (definido SEGUNDO) ──────────────────────────
  config.vm.define "odoo-server" do |deb|
    deb.vm.box              = "bento/debian-12"
    deb.vm.box_check_update = false
    deb.vm.hostname         = "odoo-server-tfg"

    deb.vm.network "private_network",
      ip:      "192.168.30.10",
      netmask: "255.255.255.0"

    deb.vm.provider "vmware_desktop" do |v|
      v.vmx["displayName"]              = "TFG-Odoo-Server"
      v.memory = 4096
      v.cpus   = 2
      v.gui    = true
      v.vmx["ethernet1.connectionType"] = "custom"
      v.vmx["ethernet1.vnet"]           = "vmnet2"
    end

    deb.trigger.before :destroy do |trigger|
      trigger.name     = "Desregistrar odoo-runner"
      trigger.on_error = :continue
      trigger.run = {
        path: "vagrant/deregister_runner.ps1",
        args: ["odoo-runner", GH_PAT, GH_REPO]
      }
    end

    # ── Provisioner 1: Odoo + Nginx + GitHub Runner ──────────
    deb.vm.provision "shell",
      name:       "provision-odoo",
      path:       "vagrant/provision_debian.sh",
      privileged: true,
      env: {
        "POSTGRES_PASSWORD"    => ENV["POSTGRES_PASSWORD"]    || "changeme_db",
        "ODOO_MASTER_PASSWORD" => ENV["ODOO_MASTER_PASSWORD"] || "changeme_master",
        "POSTGRES_HOST"        => "192.168.40.10",
        "GH_PAT"               => ENV["GH_PAT"]               || "",
        "GH_RUNNER_TOKEN"      => ENV["GH_RUNNER_TOKEN_ODOO"] || "",
        "RUNNER_NAME"          => "odoo-runner"
      }

    # ── Provisioner 2: Deshabilitar NAT como gateway ─────────
    # Igual que db-server pero con la subred DMZ (192.168.30.x).
    # DOCKER_MASQUERADE=true: los contenedores Odoo (172.18.0.0/16)
    # deben aparecer con la IP del host ante pfSense; sin MASQUERADE,
    # pfSense ve 172.18.0.x como origen y bloquea el tráfico.
    #
    # Para re-aplicar en VMs ya creadas:
    #   vagrant provision odoo-server --provision-with disable-nat-gateway
    deb.vm.provision "shell",
      name:       "disable-nat-gateway",
      path:       "vagrant/disable_nat_gateway.sh",
      privileged: true,
      env: {
        "PFSENSE_GW"        => "192.168.30.1",
        "VLAN_IFACE"        => "eth1",
        "VLAN_IP"           => "192.168.30.10",
        "VLAN_MASK"         => "255.255.255.0",
        "EXTRA_ROUTE"       => "192.168.40.0/24",
        "DOCKER_MASQUERADE" => "true"
      }
  end

end