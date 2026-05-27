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
        inline: "powershell -ExecutionPolicy Bypass -Command \"" \
                "$h = @{'Authorization'='Bearer #{GH_PAT}';'Accept'='application/vnd.github+json'}; " \
                "$r = (Invoke-RestMethod 'https://api.github.com/repos/#{GH_REPO}/actions/runners' -Headers $h).runners " \
                "| Where-Object { $_.name -eq 'db-runner' }; " \
                "if ($r) { Invoke-RestMethod -Method DELETE " \
                "-Uri ('https://api.github.com/repos/#{GH_REPO}/actions/runners/' + $r.id) -Headers $h; " \
                "Write-Host '[OK] db-runner eliminado de GitHub' } " \
                "else { Write-Host '[INFO] db-runner no encontrado en GitHub' }\""
      }
    end

    db.vm.provision "shell",
      path:       "vagrant/provision_postgres.sh",
      privileged: true,
      env: {
        "POSTGRES_PASSWORD" => ENV["POSTGRES_PASSWORD"]  || "changeme_db",
        "GH_PAT"            => ENV["GH_PAT"]             || "",
        "GH_RUNNER_TOKEN"   => ENV["GH_RUNNER_TOKEN_DB"] || "",
        "RUNNER_NAME"       => "db-runner"
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
        inline: "powershell -ExecutionPolicy Bypass -Command \"" \
                "$h = @{'Authorization'='Bearer #{GH_PAT}';'Accept'='application/vnd.github+json'}; " \
                "$r = (Invoke-RestMethod 'https://api.github.com/repos/#{GH_REPO}/actions/runners' -Headers $h).runners " \
                "| Where-Object { $_.name -eq 'odoo-runner' }; " \
                "if ($r) { Invoke-RestMethod -Method DELETE " \
                "-Uri ('https://api.github.com/repos/#{GH_REPO}/actions/runners/' + $r.id) -Headers $h; " \
                "Write-Host '[OK] odoo-runner eliminado de GitHub' } " \
                "else { Write-Host '[INFO] odoo-runner no encontrado en GitHub' }\""
      }
    end

    deb.vm.provision "shell",
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
  end

end