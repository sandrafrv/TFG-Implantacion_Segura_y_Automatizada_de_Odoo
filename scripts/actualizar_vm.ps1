# ============================================================
# SCRIPT: actualizar_vm.ps1
# DESCRIPCION: Sincroniza el codigo local a la VM odoo-server
#              y re-ejecuta deploy.sh sin necesitar internet.
#
# USO (desde la raiz del proyecto o desde scripts/):
#   .\scripts\actualizar_vm.ps1
#   powershell -ExecutionPolicy Bypass -File scripts\actualizar_vm.ps1
#
# CONEXION SSH: usa la clave privada de Vagrant en
#   .vagrant\machines\odoo-server\vmware_desktop\private_key
# ============================================================

$ErrorActionPreference = "Stop"

# ── Configuracion de conexion SSH ─────────────────────────────
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VM_IP       = "192.168.30.10"
$VM_USER     = "vagrant"
$SSH_KEY     = Join-Path $ProjectRoot ".vagrant\machines\odoo-server\vmware_desktop\private_key"
$REMOTE_DIR  = "/opt/erp-odoo"

# Opciones SSH comunes (deshabilita verificacion de host para clave autogenerada)
$SSH_OPTS    = @("-i", $SSH_KEY, "-o", "StrictHostKeyChecking=no", "-o", "BatchMode=yes")

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Actualizando odoo-server ($VM_IP)..."       -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# ── 1. Comprobar que la clave SSH existe ─────────────────────
Write-Host "[1/4] Comprobando acceso SSH..." -ForegroundColor Yellow

if (-not (Test-Path $SSH_KEY)) {
    Write-Host "  [ERROR] Clave SSH no encontrada en: $SSH_KEY" -ForegroundColor Red
    Write-Host "          Asegurate de estar en la carpeta raiz del proyecto" -ForegroundColor Red
    exit 1
}

# Test de conectividad SSH
$sshTest = & ssh @SSH_OPTS "$VM_USER@$VM_IP" "echo OK" 2>&1
if ($sshTest -notmatch "OK") {
    Write-Host "  [ERROR] No se puede conectar a la VM por SSH." -ForegroundColor Red
    Write-Host "          Comprueba que la VM esta corriendo: vagrant status" -ForegroundColor Red
    exit 1
}
Write-Host "  [OK] Conexion SSH establecida." -ForegroundColor Green

# ── 2. Sincronizar carpetas de codigo por SCP ─────────────────
# Se copian solo los directorios de codigo, nunca los datos de Odoo
# (odoo-data/, addons/, certs/) para no sobreescribir informacion.
Write-Host ""
Write-Host "[2/4] Sincronizando codigo por SCP..." -ForegroundColor Yellow
Write-Host "  (scripts/, docker/, vagrant/, .github/, .env.example)" -ForegroundColor Gray

Set-Location $ProjectRoot

$DirsToSync = @("scripts", "docker", "vagrant", ".github")
$FilesToSync = @(".env.example", "Vagrantfile")

foreach ($dir in $DirsToSync) {
    if (Test-Path $dir) {
        Write-Host "  -> $dir/" -ForegroundColor Gray
        & scp @SSH_OPTS -r "$dir" "${VM_USER}@${VM_IP}:${REMOTE_DIR}/" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  [ERROR] Fallo al copiar $dir" -ForegroundColor Red
            exit 1
        }
    }
}

foreach ($file in $FilesToSync) {
    if (Test-Path $file) {
        Write-Host "  -> $file" -ForegroundColor Gray
        & scp @SSH_OPTS "$file" "${VM_USER}@${VM_IP}:${REMOTE_DIR}/" 2>&1 | Out-Null
    }
}

Write-Host "  [OK] Codigo sincronizado." -ForegroundColor Green

# ── 3. Re-ejecutar deploy.sh en la VM ─────────────────────────
Write-Host ""
Write-Host "[3/4] Ejecutando deploy.sh en la VM..." -ForegroundColor Yellow
Write-Host "  (Puede tardar si hay cambios en contenedores)" -ForegroundColor Gray

& ssh @SSH_OPTS "$VM_USER@$VM_IP" "sudo bash $REMOTE_DIR/scripts/deploy/deploy.sh"

# ── 4. Health check de Odoo ───────────────────────────────────
Write-Host ""
Write-Host "[4/4] Verificando que Odoo responde..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$OdooOk = $false
for ($i = 1; $i -le 6; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "https://$VM_IP/web/health" `
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
    Write-Host "  [AVISO] Odoo no responde aun." -ForegroundColor Yellow
    Write-Host "          Comprueba: https://erp.odoo.tfg.com" -ForegroundColor Yellow
    Write-Host "  Logs:   ssh -i $SSH_KEY $VM_USER@$VM_IP 'docker logs odoo-web --tail 20'" -ForegroundColor Gray
}
