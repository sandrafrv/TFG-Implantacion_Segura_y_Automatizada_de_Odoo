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
#   bash scripts/deploy/generate_pfsense_config.sh  ← primero en Git Bash
#   vagrant up pfsense
#   vagrant up db-server
#   vagrant up odoo-server
# ============================================================
Vagrant.configure("2") do |config|

  GH_PAT  = ENV["GH_PAT"] || ""
  GH_REPO = "sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo"

  # ── Fijar subredes VMnets antes de levantar cualquier VM ─────
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
  # WAN: red pública (NAT VMware)
  # VMnet1 → VLAN 10: usuarios  (192.168.10.x)
  # VMnet2 → VLAN 30: DMZ       (192.168.30.x)
  # VMnet3 → VLAN 40: admin     (192.168.40.x)
  #
  # BOX PROPIA (recomendado):
  #   Crear la box siguiendo: docs/guias/CREAR_BOX_PFSENSE.md
  #   Subir a GitHub Releases y actualizar PFSENSE_BOX_URL abajo.
  #   La config.xml se importa automáticamente en el vagrant up.
  #     1. bash scripts/deploy/generate_pfsense_config.sh
  #     2. vagrant up pfsense
  #
  # BOX PÚBLICA (fallback, sin SSH ni provisioning automático):
  #   Poner USE_CUSTOM_BOX="" en el entorno o comentar la variable.
  #   La config se importa manualmente: Diagnostics → Backup/Restore.
  # --------------------------------------------------------

  # URL de la box propia en GitHub Releases
  # Actualizar cuando se publique una nueva versión de la box
  PFSENSE_BOX_URL = "https://github.com/sandrafrv/TFG-Implantacion_Segura_y_Automatizada_de_Odoo/releases/download/v1.0-pfsense-box/pfsense-tfg.box"
  USE_CUSTOM_BOX  = ENV.fetch("USE_CUSTOM_BOX", "1")  # "1" = box propia | "" = dlee35/pfsense

  config.vm.define "pfsense" do |pf|

    if USE_CUSTOM_BOX == "1"
      # ── BOX PROPIA — con SSH y provisioning automático ──────
      pf.vm.box              = "tfg/pfsense"
      pf.vm.box_url          = PFSENSE_BOX_URL
      pf.vm.box_check_update = false
      pf.vm.hostname         = "pfsense-tfg"
      pf.vm.synced_folder ".", "/vagrant", disabled: true

      pf.vm.communicator = "ssh"
      pf.ssh.username    = "vagrant"
      pf.ssh.password    = "vagrant"
      pf.ssh.shell       = "sh"
      pf.ssh.insert_key  = true
      # ⚠️ CRÍTICO VMware: Vagrant usa por defecto el adaptador 0 (WAN/NAT).
      # Nuestras ACLs bloquean SSH desde WAN → apuntamos a OPT2 (VLAN 40).
      # El host Windows tiene adaptador virtual en VMnet3 y alcanza 192.168.40.1.
      pf.ssh.host        = "192.168.40.1"
      pf.ssh.port        = 22

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

        # ── Optimizaciones VMware para pfSense / FreeBSD ──────
        # Guest OS: FreeBSD 14 64-bit (mejora compatibilidad drivers em0-em3)
        v.vmx["guestOS"]                    = "freebsd-64"
        # BIOS EFI — el instalador de pfSense 2.7+ lo requiere
        v.vmx["firmware"]                   = "efi"
        # Desactivar VMware tools check (pfSense no los tiene)
        v.vmx["tools.syncTime"]             = "FALSE"
        v.vmx["tools.upgrade.policy"]       = "manual"
        # UUID de disco estable — evita que pfSense renombre interfaces tras reboot
        v.vmx["disk.EnableUUID"]            = "TRUE"
        # Red: forzar vmxnet3 en todos los adaptadores (mayor rendimiento en FreeBSD)
        v.vmx["ethernet0.virtualDev"]       = "vmxnet3"
        v.vmx["ethernet1.virtualDev"]       = "vmxnet3"
        v.vmx["ethernet2.virtualDev"]       = "vmxnet3"
        v.vmx["ethernet3.virtualDev"]       = "vmxnet3"
        # Suprimir advertencias de VMware sobre guest OS no soportado
        v.vmx["msg.autoanswer"]             = "TRUE"
      end

      # Transferir el XML generado por generate_pfsense_config.sh
      pf.vm.provision "file",
        source:      "config/pfsense_config.xml",
        destination: "/tmp/pfsense_config.xml"

      # Aplicar la configuración completa (ACLs, NAT, DNS, DHCP)
      pf.vm.provision "shell",
        path:       "vagrant/provision_pfsense.sh",
        privileged: true

    else
      # ── BOX PÚBLICA — sin SSH, configuración manual ─────────
      # Usar cuando la box propia no está disponible (primer despliegue).
      # Configurar pfSense manualmente: docs/guias/CONFIGURACION_PFSENSE_MANUAL.md
      pf.vm.box              = "dlee35/pfsense"
      pf.vm.box_check_update = false
      pf.vm.hostname         = "pfsense-tfg"
      pf.vm.synced_folder ".", "/vagrant", disabled: true
      pf.vm.communicator = "none"   # Sin SSH → sin provisioning

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
        # Mismas optimizaciones FreeBSD que en el bloque de box propia
        v.vmx["guestOS"]              = "freebsd-64"
        v.vmx["firmware"]             = "efi"
        v.vmx["tools.syncTime"]       = "FALSE"
        v.vmx["tools.upgrade.policy"] = "manual"
        v.vmx["disk.EnableUUID"]      = "TRUE"
        v.vmx["ethernet0.virtualDev"] = "vmxnet3"
        v.vmx["ethernet1.virtualDev"] = "vmxnet3"
        v.vmx["ethernet2.virtualDev"] = "vmxnet3"
        v.vmx["ethernet3.virtualDev"] = "vmxnet3"
        v.vmx["msg.autoanswer"]       = "TRUE"
      end
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
      trigger.name     = "Desregistrar odoo-runner de GitHub"
      trigger.on_error = :continue
      trigger.run = {
        inline: "powershell -ExecutionPolicy Bypass -Command \"" \
                "$headers = @{'Authorization'='Bearer #{GH_PAT}'; 'Accept'='application/vnd.github+json'}; " \
                "$runners = Invoke-RestMethod -Uri 'https://api.github.com/repos/#{GH_REPO}/actions/runners' -Headers $headers; " \
                "$runner = $runners.runners | Where-Object { $_.name -eq 'odoo-runner' }; " \
                "if ($runner) { Invoke-RestMethod -Method DELETE -Uri ('https://api.github.com/repos/#{GH_REPO}/actions/runners/' + $runner.id) -Headers $headers; Write-Host '[RUNNER] odoo-runner eliminado' } " \
                "else { Write-Host '[RUNNER] odoo-runner no encontrado en GitHub' }\""
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
      trigger.name     = "Desregistrar db-runner de GitHub"
      trigger.on_error = :continue
      trigger.run = {
        inline: "powershell -ExecutionPolicy Bypass -Command \"" \
                "$headers = @{'Authorization'='Bearer #{GH_PAT}'; 'Accept'='application/vnd.github+json'}; " \
                "$runners = Invoke-RestMethod -Uri 'https://api.github.com/repos/#{GH_REPO}/actions/runners' -Headers $headers; " \
                "$runner = $runners.runners | Where-Object { $_.name -eq 'db-runner' }; " \
                "if ($runner) { Invoke-RestMethod -Method DELETE -Uri ('https://api.github.com/repos/#{GH_REPO}/actions/runners/' + $runner.id) -Headers $headers; Write-Host '[RUNNER] db-runner eliminado' } " \
                "else { Write-Host '[RUNNER] db-runner no encontrado en GitHub' }\""
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
