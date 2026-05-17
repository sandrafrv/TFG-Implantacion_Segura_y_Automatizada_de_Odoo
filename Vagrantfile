# ============================================================
# Vagrantfile — TFG Implantación Segura y Automatizada de Odoo
# Uso: vagrant up
# Crea: VM pfSense + VM Odoo+Nginx + VM PostgreSQL
#
# REQUISITOS PREVIOS:
#   winget install HashiCorp.Vagrant
#   vagrant plugin install vagrant-vmware-desktop
#
# VARIABLES DE ENTORNO (obligatorias para repo privado y runners):
#   GH_PAT                → Personal Access Token con scope repo
#   GH_RUNNER_TOKEN_ODOO  → Registration token para odoo-server
#   GH_RUNNER_TOKEN_DB    → Registration token para db-server
#                           (GitHub → Settings → Actions → Runners → New → token)
#
# VARIABLES DE ENTORNO (opcionales; si no se pasan, usa valores demo):
#   POSTGRES_PASSWORD    → contraseña de la BD
#   ODOO_MASTER_PASSWORD → contraseña maestra de Odoo
#
# Ejemplo de uso:
#   $env:GH_PAT="ghp_xxx"
#   $env:GH_RUNNER_TOKEN_ODOO="AXXXXX"
#   $env:GH_RUNNER_TOKEN_DB="AYYYYY"
#   $env:POSTGRES_PASSWORD="s3cr3t"
#   vagrant up pfsense
#   vagrant up db-server
#   vagrant up odoo-server
# ============================================================
Vagrant.configure("2") do |config|

  GH_PAT  = ENV["GH_PAT"] || ""
  GH_REPO = "sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo"

  # ── Fijar subredes VMnets antes de levantar cualquier VM ─────
  # Evita que tras un destroy+up las VMnets queden con subredes
  # incorrectas y se pierda el acceso desde Windows a las VMs.
  # El script comprueba primero si ya están bien — si lo están,
  # no reinicia servicios VMware ni toca nada.
  config.trigger.before :up do |trigger|
    trigger.name = "Configurar VMnets"
    trigger.run  = {
      inline: "powershell -ExecutionPolicy Bypass " \
              "-Command \"Start-Process powershell " \
              "-ArgumentList '-ExecutionPolicy Bypass " \
              "-File scripts/setup_vmnet.ps1' " \
              "-Verb RunAs -Wait\""
    }
  end

  # --------------------------------------------------------
  # VM 1 — pfSense (Firewall / VPN / Router)
  # WAN: red pública
  # VMnet1 → VLAN 10: usuarios  (192.168.10.x)
  # VMnet2 → VLAN 30: DMZ       (192.168.30.x)
  # VMnet3 → VLAN 40: admin     (192.168.40.x)
  # --------------------------------------------------------
  config.vm.define "pfsense" do |pf|
    pf.vm.box              = "dlee35/pfsense"
    pf.vm.box_check_update = false
    pf.vm.hostname         = "pfsense-tfg"

    pf.vm.synced_folder ".", "/vagrant", disabled: true
    # pfSense no tiene usuario vagrant con SSH funcional.
    # El config.xml se importa manualmente desde la WebGUI:
    #   https://192.168.40.1 → Diagnostics → Backup/Restore
    pf.vm.communicator = "none"

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
  end

  # --------------------------------------------------------
  # VM 2 — Debian 12 (Odoo 17 + Nginx)
  # DMZ — VLAN 30
  #   nginx-proxy  192.168.30.20  → HTTPS :443
  #   odoo-web     192.168.30.21  → Odoo  :8069 (interno)
  #   Cockpit      192.168.30.10  → panel :9090
  # Runner: odoo-runner (self-hosted, linux, odoo)
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

    deb.trigger.before :destroy do |trigger|
      trigger.name = "Desregistrar odoo-runner de GitHub"
      trigger.run_remote = {
        inline: <<-SHELL
          RUNNER_NAME="odoo-runner"
          GH_PAT="#{GH_PAT}"
          GH_REPO="#{GH_REPO}"

          RUNNER_ID=$(curl -fsSL \
            -H "Authorization: Bearer ${GH_PAT}" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/${GH_REPO}/actions/runners" \
            | grep -B1 '"name": "'${RUNNER_NAME}'"' \
            | grep '"id"' | grep -o '[0-9]*')

          if [ -n "$RUNNER_ID" ]; then
            echo "  [RUNNER] Desregistrando '${RUNNER_NAME}' (ID: ${RUNNER_ID})..."
            curl -fsSL -X DELETE \
              -H "Authorization: Bearer ${GH_PAT}" \
              -H "Accept: application/vnd.github+json" \
              "https://api.github.com/repos/${GH_REPO}/actions/runners/${RUNNER_ID}"
            echo "  [RUNNER] Runner eliminado de GitHub."
          else
            echo "  [RUNNER] '${RUNNER_NAME}' no encontrado en GitHub, nada que eliminar."
          fi
        SHELL
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

  # --------------------------------------------------------
  # VM 3 — Debian 12 (PostgreSQL 16)
  # VLAN 40 — Administración
  #   postgresql   192.168.40.10  → BD aislada :5432
  #   backups      /backups/      → copias automáticas
  #   Cockpit      192.168.40.10  → panel      :9090
  # Runner: db-runner (self-hosted, linux, db)
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

    db.trigger.before :destroy do |trigger|
      trigger.name = "Desregistrar db-runner de GitHub"
      trigger.run_remote = {
        inline: <<-SHELL
          RUNNER_NAME="db-runner"
          GH_PAT="#{GH_PAT}"
          GH_REPO="#{GH_REPO}"

          RUNNER_ID=$(curl -fsSL \
            -H "Authorization: Bearer ${GH_PAT}" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/${GH_REPO}/actions/runners" \
            | grep -B1 '"name": "'${RUNNER_NAME}'"' \
            | grep '"id"' | grep -o '[0-9]*')

          if [ -n "$RUNNER_ID" ]; then
            echo "  [RUNNER] Desregistrando '${RUNNER_NAME}' (ID: ${RUNNER_ID})..."
            curl -fsSL -X DELETE \
              -H "Authorization: Bearer ${GH_PAT}" \
              -H "Accept: application/vnd.github+json" \
              "https://api.github.com/repos/${GH_REPO}/actions/runners/${RUNNER_ID}"
            echo "  [RUNNER] Runner eliminado de GitHub."
          else
            echo "  [RUNNER] '${RUNNER_NAME}' no encontrado en GitHub, nada que eliminar."
          fi
        SHELL
      }
    end

    db.vm.provision "shell",
      path:       "vagrant/provision_postgres.sh",
      privileged: true,
      env: {
        "POSTGRES_PASSWORD" => ENV["POSTGRES_PASSWORD"]   || "changeme_db",
        "GH_PAT"            => ENV["GH_PAT"]              || "",
        "GH_RUNNER_TOKEN"   => ENV["GH_RUNNER_TOKEN_DB"]  || "",
        "RUNNER_NAME"       => "db-runner"
      }
  end

end
