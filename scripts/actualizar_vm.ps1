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

# Eliminar el flag de usuarios para que se re-ejecute odoo_crear_usuarios.sh
# si hay cambios en la lista de usuarios o sus grupos
& vagrant ssh odoo-server -c @"
  sudo bash /opt/erp-odoo/scripts/deploy/deploy.sh
"@

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  [AVISO] deploy.sh termino con algun error." -ForegroundColor Yellow
    Write-Host "          Revisa los logs con: vagrant ssh odoo-server" -ForegroundColor Yellow
    Write-Host "          y ejecuta: docker logs odoo-web --tail 30" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  [OK] Actualizacion completada."             -ForegroundColor Green
    Write-Host "  URL: https://erp.odoo.tfg.com"             -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
}
