# ============================================================
# SCRIPT: actualizar_vm.ps1
# DESCRIPCION: Sincroniza el codigo local a la VM odoo-server
#              y re-ejecuta deploy.sh sin necesitar internet.
#
# USO: .\scripts\actualizar_vm.ps1
#      o desde la raiz del proyecto:
#      powershell -ExecutionPolicy Bypass -File scripts\actualizar_vm.ps1
#
# EQUIVALENTE A: git pull + sudo bash deploy.sh (sin internet en la VM)
# ============================================================

$ErrorActionPreference = "Stop"

# Directorio raiz del proyecto (donde esta el Vagrantfile)
$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Actualizando odoo-server..."                -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Comprobar que la VM esta corriendo ─────────────────────
Write-Host "[1/3] Comprobando estado de la VM..." -ForegroundColor Yellow
$VmStatus = & vagrant status odoo-server 2>&1 | Select-String "running"
if (-not $VmStatus) {
    Write-Host "  [ERROR] La VM odoo-server no esta corriendo." -ForegroundColor Red
    Write-Host "          Ejecuta: vagrant up odoo-server" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] VM corriendo." -ForegroundColor Green

# ── 2. Sincronizar codigo por rsync (SSH, sin internet en VM) ─
Write-Host ""
Write-Host "[2/3] Sincronizando codigo (vagrant rsync)..." -ForegroundColor Yellow
Write-Host "  (Excluye: .git/, odoo-data/, addons/, certs/)" -ForegroundColor Gray
Set-Location $ProjectRoot
& vagrant rsync odoo-server
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [ERROR] Fallo el rsync. Comprueba que la VM este accesible." -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Codigo sincronizado." -ForegroundColor Green

# ── 3. Re-ejecutar deploy.sh en la VM ─────────────────────────
Write-Host ""
Write-Host "[3/3] Ejecutando deploy.sh en la VM..." -ForegroundColor Yellow
Write-Host "  (Puede tardar si hay cambios en contenedores)" -ForegroundColor Gray

# NOTA: vagrant ssh -c siempre devuelve exit code 1 aunque el script
# interno haya tenido exito. Es un bug conocido de Vagrant.
# Por eso usamos un health check real a Odoo en lugar de $LASTEXITCODE.
& vagrant ssh odoo-server -c "sudo bash /opt/erp-odoo/scripts/deploy/deploy.sh" 2>&1

# Esperar un momento y comprobar salud de Odoo directamente
Write-Host ""
Write-Host "  Verificando que Odoo responde..." -ForegroundColor Gray
Start-Sleep -Seconds 5

$OdooOk = $false
for ($i = 1; $i -le 6; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "https://192.168.30.10/web/health" `
            -SkipCertificateCheck -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        if ($resp.StatusCode -eq 200) { $OdooOk = $true; break }
    } catch { }
    Write-Host "  Intento $i/6 — esperando 5s..." -ForegroundColor Gray
    Start-Sleep -Seconds 5
}

if ($OdooOk) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  [OK] Actualizacion completada."             -ForegroundColor Green
    Write-Host "  URL: https://erp.odoo.tfg.com"             -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  [AVISO] Odoo no responde aun — puede necesitar mas tiempo." -ForegroundColor Yellow
    Write-Host "          Comprueba en: https://erp.odoo.tfg.com"             -ForegroundColor Yellow
    Write-Host "          O mira logs: vagrant ssh odoo-server -c 'docker logs odoo-web --tail 20'" -ForegroundColor Gray
}
