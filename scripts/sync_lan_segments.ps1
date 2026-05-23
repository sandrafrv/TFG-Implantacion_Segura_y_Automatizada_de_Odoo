# ============================================================
# scripts/sync_lan_segments.ps1
#
# PROPOSITO:
#   VMware genera sus propios pvnIDs en el primer arranque,
#   ignorando los que define el Vagrantfile. Este script lee
#   los pvnIDs que VMware asigno a pfSense y los copia en
#   las VMs Debian, dejando todas en el mismo LAN Segment.
#
# USO (ejecutar despues de vagrant up pfsense):
#   .\scripts\sync_lan_segments.ps1
#
# REQUISITOS:
#   - Las 3 VMs deben estar APAGADAS antes de ejecutar.
#   - Ejecutar como Administrador o usuario con acceso a los VMX.
# ============================================================

# ── Rutas a los VMX ──────────────────────────────────────────
# Ajusta estos nombres si VMware creo las VMs con nombres distintos.
$vmDir    = "$env:USERPROFILE\Documents\Virtual Machines"
$pfxVMX   = Get-ChildItem "$vmDir\Pfsense\*.vmx"   | Select-Object -First 1
$odooVMX  = Get-ChildItem "$vmDir\bdd\*.vmx"        | Select-Object -First 1
$dbVMX    = Get-ChildItem "$vmDir\Server-db\*.vmx"  | Select-Object -First 1

if (-not $pfxVMX)  { Write-Error "No se encontro VMX de pfSense en $vmDir\Pfsense";   exit 1 }
if (-not $odooVMX) { Write-Error "No se encontro VMX de odoo-server en $vmDir\bdd";   exit 1 }
if (-not $dbVMX)   { Write-Error "No se encontro VMX de db-server en $vmDir\Server-db"; exit 1 }

Write-Host "============================================="
Write-Host " Sincronizando LAN Segments entre VMs..."
Write-Host "============================================="
Write-Host "  pfSense VMX  : $($pfxVMX.FullName)"
Write-Host "  odoo VMX     : $($odooVMX.FullName)"
Write-Host "  db VMX       : $($dbVMX.FullName)"
Write-Host ""

# ── Leer pvnIDs de pfSense ───────────────────────────────────
function Get-PvnID {
    param([string]$vmxPath, [string]$ethernetN)
    $line = Get-Content $vmxPath | Where-Object { $_ -match "^${ethernetN}\.pvnID\s*=" }
    if ($line) {
        return ($line -split "=", 2)[1].Trim().Trim('"')
    }
    return $null
}

function Set-PvnID {
    param([string]$vmxPath, [string]$ethernetN, [string]$pvnID)
    $content = Get-Content $vmxPath -Raw
    $pattern = "(?m)^${ethernetN}\.pvnID\s*=.*$"
    $newLine  = "${ethernetN}.pvnID = `"$pvnID`""
    if ($content -match $pattern) {
        $content = $content -replace $pattern, $newLine
    } else {
        $content += "`n$newLine"
    }
    Set-Content -Path $vmxPath -Value $content -NoNewline
}

$pvn_eth1 = Get-PvnID -vmxPath $pfxVMX.FullName -ethernetN "ethernet1"
$pvn_eth2 = Get-PvnID -vmxPath $pfxVMX.FullName -ethernetN "ethernet2"
$pvn_eth3 = Get-PvnID -vmxPath $pfxVMX.FullName -ethernetN "ethernet3"

Write-Host "  [pfSense] ethernet1 pvnID = $pvn_eth1  (VLAN10)"
Write-Host "  [pfSense] ethernet2 pvnID = $pvn_eth2  (VLAN30)"
Write-Host "  [pfSense] ethernet3 pvnID = $pvn_eth3  (VLAN40)"
Write-Host ""

if (-not $pvn_eth2) { Write-Error "pfSense no tiene pvnID en ethernet2 (VLAN30). Asegurate de que pfSense estuvo arrancado al menos una vez."; exit 1 }
if (-not $pvn_eth3) { Write-Error "pfSense no tiene pvnID en ethernet3 (VLAN40). Idem."; exit 1 }

# ── Aplicar pvnIDs en odoo-server (debe compartir ethernet2 de pfSense = VLAN30) ──
Write-Host "  [odoo-server] Aplicando pvnID VLAN30 en ethernet1..."
Set-PvnID -vmxPath $odooVMX.FullName -ethernetN "ethernet1" -pvnID $pvn_eth2
Write-Host "  [odoo-server] ethernet1 pvnID = $pvn_eth2  OK"
Write-Host ""

# ── Aplicar pvnIDs en db-server (debe compartir ethernet3 de pfSense = VLAN40) ──
Write-Host "  [db-server] Aplicando pvnID VLAN40 en ethernet1..."
Set-PvnID -vmxPath $dbVMX.FullName -ethernetN "ethernet1" -pvnID $pvn_eth3
Write-Host "  [db-server] ethernet1 pvnID = $pvn_eth3  OK"
Write-Host ""

Write-Host "============================================="
Write-Host " Verificacion final:"
Write-Host "============================================="
Write-Host "  VLAN30 (DMZ/Odoo):"
Write-Host "    pfSense  eth2 = $pvn_eth2"
Write-Host "    odoo-srv eth1 = $(Get-PvnID $odooVMX.FullName 'ethernet1')"
Write-Host "  VLAN40 (Admin/PG):"
Write-Host "    pfSense  eth3 = $pvn_eth3"
Write-Host "    db-srv   eth1 = $(Get-PvnID $dbVMX.FullName 'ethernet1')"
Write-Host ""
Write-Host "[DONE] Ahora arranca las VMs: vagrant up odoo-server db-server" -ForegroundColor Green
