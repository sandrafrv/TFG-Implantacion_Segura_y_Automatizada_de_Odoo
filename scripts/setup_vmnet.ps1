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

$networkingFileLegacy = "C:\ProgramData\VMware\networking"
$vmnetDhcpFile       = "C:\ProgramData\VMware\vmnetdhcp.conf"
$vmnetNatFile        = "C:\ProgramData\VMware\vmnetnat.conf"
$vmnetcfg            = "C:\Program Files (x86)\VMware\VMware Workstation\vmnetcfg.exe"

# ── Configuracion deseada ────────────────────────────
$desired = @{
    "1" = @{ Subnet = "192.168.10.0"; Netmask = "255.255.255.0"; Type = "hostonly" }
    "2" = @{ Subnet = "192.168.30.0"; Netmask = "255.255.255.0"; Type = "hostonly" }
    "3" = @{ Subnet = "192.168.40.0"; Netmask = "255.255.255.0"; Type = "hostonly" }
}

$mode = if (Test-Path $networkingFileLegacy) {
    "legacy"
} elseif (Test-Path $vmnetDhcpFile) {
    "vmnetdhcp"
} else {
    "missing"
}

function Get-HardwareEthernetLine {
    param([string]$block)
    $line = $block -split "`n" | Where-Object { $_ -match 'hardware ethernet' }
    if ($line) {
        return $line.Trim()
    }
    return "    hardware ethernet 00:50:56:C0:00:01;"
}

function Build-VMnetDhcpBlock {
    param(
        [string]$netNum,
        [string]$subnet,
        [string]$netmask,
        [string]$gateway,
        [string]$hardwareEthernetLine
    )

    $rangeStart = "$($subnet.Substring(0,$subnet.LastIndexOf('.'))).128"
    $rangeEnd   = "$($subnet.Substring(0,$subnet.LastIndexOf('.'))).254"
    $broadcast  = "$($subnet.Substring(0,$subnet.LastIndexOf('.'))).255"

    return @"
# Virtual ethernet segment $netNum
# Updated at $(Get-Date -Format 'MM/dd/yy HH:mm:ss')
subnet $subnet netmask $netmask {
range $rangeStart $rangeEnd;
option broadcast-address $broadcast;
option domain-name-servers $gateway;
option domain-name "localdomain";
default-lease-time 1800;
max-lease-time 7200;
}
host VMnet$netNum {
$hardwareEthernetLine
    fixed-address $gateway;
    option domain-name-servers 0.0.0.0;
    option domain-name "";
}
# End
"@
}

function Update-VMnetDhcpConfig {
    param([string]$content, [string]$netNum, [string]$subnet, [string]$netmask, [string]$gateway)

    $pattern = "(?ms)# Virtual ethernet segment $netNum.*?# End"
    if ([regex]::IsMatch($content, $pattern)) {
        $existing = [regex]::Match($content, $pattern).Value
        $hardwareEthernetLine = Get-HardwareEthernetLine -block $existing
        $replacement = Build-VMnetDhcpBlock -netNum $netNum -subnet $subnet -netmask $netmask -gateway $gateway -hardwareEthernetLine $hardwareEthernetLine
        return [regex]::Replace($content, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement })
    }

    $hardwareEthernetLine = "    hardware ethernet 00:50:56:C0:00:$([string]::Format('{0:D2}',$netNum));"
    $replacement = Build-VMnetDhcpBlock -netNum $netNum -subnet $subnet -netmask $netmask -gateway $gateway -hardwareEthernetLine $hardwareEthernetLine
    return $content.TrimEnd() + "`n`n" + $replacement
}

Write-Host "============================================="
Write-Host " Verificando configuracion de VMnets..."
Write-Host "============================================="

if ($mode -eq 'missing') {
    Write-Host "[ERROR] No se encontro el fichero legacy ni vmnetdhcp.conf en C:\ProgramData\VMware." -ForegroundColor Red
    Write-Host "        Versiones recientes de VMware Workstation usan vmnetdhcp.conf en lugar de networking." -ForegroundColor Yellow
    Write-Host "        Comprueba manualmente la ruta o instala VMware Workstation con las herramientas de red." -ForegroundColor Yellow
    exit 1
}

$configFile = if ($mode -eq 'legacy') { $networkingFileLegacy } else { $vmnetDhcpFile }
$content = Get-Content $configFile -Raw

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

if ($mode -eq 'legacy') {
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
} else {
    foreach ($num in $desired.Keys) {
        $subnet  = $desired[$num].Subnet
        $netmask = $desired[$num].Netmask
        $gateway = "$($subnet.Substring(0,$subnet.LastIndexOf('.'))).1"
        $content  = Update-VMnetDhcpConfig -content $content -netNum $num -subnet $subnet -netmask $netmask -gateway $gateway
        Write-Host "  [SET] VMnet${num} → $subnet / $netmask (hostonly)"
    }
}

Set-Content -Path $configFile -Value $content -Encoding ASCII
Write-Host "[OK] Fichero de configuracion actualizado: $configFile"

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
$contentFinal = Get-Content $configFile -Raw
$allOk = $true
foreach ($num in $desired.Keys) {
    $subnet = $desired[$num].Subnet
    if ($mode -eq 'legacy') {
        if ($contentFinal -match "VNET_${num}_HOSTONLY_SUBNET\s*=\s*$([regex]::Escape($subnet))") {
            Write-Host "  [OK] VMnet${num} → $subnet" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] VMnet${num} → no se aplico correctamente" -ForegroundColor Red
            $allOk = $false
        }
    } else {
        $pattern = "(?ms)# Virtual ethernet segment $num.*?subnet\s+$([regex]::Escape($subnet))\s+netmask"
        if ([regex]::IsMatch($contentFinal, $pattern)) {
            Write-Host "  [OK] VMnet${num} → $subnet" -ForegroundColor Green
        } else {
            Write-Host "  [ERROR] VMnet${num} → no se aplico correctamente" -ForegroundColor Red
            $allOk = $false
        }
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
