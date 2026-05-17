# ============================================================
# scripts/setup_vmnet.ps1
# Fija las subredes de VMnet1/2/3 antes de 'vagrant up'
# Se ejecuta automaticamente via trigger del Vagrantfile.
#
# MAPEO:
#   VMnet1 → 192.168.10.0/24  (VLAN 10 - Usuarios)
#   VMnet2 → 192.168.30.0/24  (VLAN 30 - DMZ / Odoo)
#   VMnet3 → 192.168.40.0/24  (VLAN 40 - Admin / PostgreSQL)
# ============================================================

# ── Verificar que se ejecuta como Administrador ────────────
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[ERROR] Este script debe ejecutarse como Administrador." -ForegroundColor Red
    exit 1
}

$networkingFile = "C:\ProgramData\VMware\networking"
$vmnetcfg       = "C:\Program Files (x86)\VMware\VMware Workstation\vmnetcfg.exe"

# ── Configuracion deseada ────────────────────────────
$desired = @{
    "1" = @{ Subnet = "192.168.10.0"; Netmask = "255.255.255.0"; Type = "hostonly" }
    "2" = @{ Subnet = "192.168.30.0"; Netmask = "255.255.255.0"; Type = "hostonly" }
    "3" = @{ Subnet = "192.168.40.0"; Netmask = "255.255.255.0"; Type = "hostonly" }
}

Write-Host "============================================="
Write-Host " Verificando configuracion de VMnets..."
Write-Host "============================================="

if (-not (Test-Path $networkingFile)) {
    Write-Host "[ERROR] No se encontro el fichero: $networkingFile" -ForegroundColor Red
    exit 1
}

$content = Get-Content $networkingFile -Raw

# ── Comprobar si ya estan bien configuradas ────────────────
# Si todas las subredes ya son correctas, salir sin tocar nada
# (evita reiniciar servicios con VMs corriendo)
$allCorrect = $true
foreach ($num in $desired.Keys) {
    $subnet = $desired[$num].Subnet
    if ($content -notmatch "VNET_${num}_HOSTONLY_SUBNET\s*=\s*$([regex]::Escape($subnet))") {
        $allCorrect = $false
        break
    }
}

if ($allCorrect) {
    Write-Host "[OK] VMnets ya estan correctamente configuradas. No se necesita accion." -ForegroundColor Green
    exit 0
}

Write-Host "[INFO] Se necesitan cambios. Aplicando configuracion..."

# ── Detener servicios VMware ────────────────────────────
Write-Host "[INFO] Deteniendo servicios VMware..."
$services = @("VMwareHostd", "VMnetDHCP", "VMware NAT Service", "VMAuthdService")
foreach ($svc in $services) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq "Running") {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  [STOP] $svc"
    }
}
Start-Sleep -Seconds 2

# ── Aplicar cambios en el fichero networking ────────────────
foreach ($num in $desired.Keys) {
    $subnet  = $desired[$num].Subnet
    $netmask = $desired[$num].Netmask

    # Subnet
    $pattern = "(?m)^(VNET_${num}_HOSTONLY_SUBNET\s*=\s*).*$"
    if ($content -match "VNET_${num}_HOSTONLY_SUBNET") {
        $content = $content -replace $pattern, "VNET_${num}_HOSTONLY_SUBNET = $subnet"
    } else {
        $content += "`nVNET_${num}_HOSTONLY_SUBNET = $subnet"
    }

    # Netmask
    $patternMask = "(?m)^(VNET_${num}_HOSTONLY_NETMASK\s*=\s*).*$"
    if ($content -match "VNET_${num}_HOSTONLY_NETMASK") {
        $content = $content -replace $patternMask, "VNET_${num}_HOSTONLY_NETMASK = $netmask"
    } else {
        $content += "`nVNET_${num}_HOSTONLY_NETMASK = $netmask"
    }

    # Tipo hostonly
    if ($content -notmatch "VNET_${num}_VIRTUAL_ADAPTER") {
        $content += "`nVNET_${num}_VIRTUAL_ADAPTER = yes"
    }

    Write-Host "  [SET] VMnet${num} → $subnet / $netmask (hostonly)"
}

Set-Content -Path $networkingFile -Value $content -Encoding ASCII
Write-Host "[OK] Fichero networking actualizado."

# ── Aplicar con vmnetcfg si existe ────────────────────────
if (Test-Path $vmnetcfg) {
    Write-Host "[INFO] Aplicando cambios con vmnetcfg..."
    Start-Process -FilePath $vmnetcfg -ArgumentList "--configure" -Wait -NoNewWindow
}

# ── Reiniciar servicios en orden correcto ──────────────────
# Orden: VMAuthdService → VMnetDHCP → NAT → VMwareHostd
Write-Host "[INFO] Reiniciando servicios VMware..."
$startOrder = @("VMAuthdService", "VMnetDHCP", "VMware NAT Service", "VMwareHostd")
foreach ($svc in $startOrder) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Write-Host "  [START] $svc"
    }
}
Start-Sleep -Seconds 3

# ── Verificacion final ────────────────────────────────────
# Si algo fallo, exit 1 hace que el trigger de Vagrant tambien
# falle y avise antes de continuar con vagrant up.
Write-Host ""
Write-Host "============================================="
Write-Host " Verificacion final:"
Write-Host "============================================="
$contentFinal = Get-Content $networkingFile -Raw
$allOk = $true
foreach ($num in $desired.Keys) {
    $subnet = $desired[$num].Subnet
    if ($contentFinal -match "VNET_${num}_HOSTONLY_SUBNET\s*=\s*$([regex]::Escape($subnet))") {
        Write-Host "  [OK] VMnet${num} → $subnet" -ForegroundColor Green
    } else {
        Write-Host "  [ERROR] VMnet${num} → no se aplico correctamente" -ForegroundColor Red
        $allOk = $false
    }
}

if ($allOk) {
    Write-Host ""
    Write-Host "[DONE] VMnets configuradas correctamente." -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "[ERROR] Algunos cambios no se aplicaron. Revisa manualmente VMware Network Editor." -ForegroundColor Red
    exit 1
}
