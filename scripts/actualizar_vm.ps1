# ============================================================
# SCRIPT: actualizar_vm.ps1
# DESCRIPCION: Sincroniza el codigo local a la VM odoo-server
#       y re-ejecuta deploy.sh sin necesitar internet.
#
# USO (desde la raiz del proyecto):
#  .\scripts\actualizar_vm.ps1
#  powershell -ExecutionPolicy Bypass -File scripts\actualizar_vm.ps1
# ============================================================

$ErrorActionPreference = 'Stop'

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VM_IP    = '192.168.30.10'
$VM_USER   = 'vagrant'
$SSH_KEY   = Join-Path $ProjectRoot '.vagrant\machines\odoo-server\vmware_desktop\private_key'
$REMOTE_DIR = '/opt/erp-odoo'

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ' Actualizando odoo-server...'        -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# ── 1. Comprobar clave SSH ────────────────────────────────────
Write-Host '[1/4] Comprobando acceso SSH...' -ForegroundColor Yellow

if (-not (Test-Path $SSH_KEY)) {
  Write-Host ' [ERROR] Clave SSH no encontrada.' -ForegroundColor Red
  Write-Host " Buscada en: $SSH_KEY"       -ForegroundColor Red
  Write-Host ' Asegurate de estar en la raiz del proyecto.' -ForegroundColor Red
  exit 1
}

$sshArgs = @('-i', $SSH_KEY, '-o', 'StrictHostKeyChecking=no', '-o', 'BatchMode=yes')
$target = "$VM_USER@$VM_IP"

$sshTest = & ssh @sshArgs $target 'echo OK' 2>&1
if ($sshTest -notmatch 'OK') {
  Write-Host ' [ERROR] No se puede conectar a la VM por SSH.' -ForegroundColor Red
  Write-Host '     Comprueba que la VM esta corriendo.'  -ForegroundColor Red
  exit 1
}
Write-Host ' [OK] Conexion SSH establecida.' -ForegroundColor Green

# ── 2. Sincronizar carpetas de codigo por SCP ─────────────────
Write-Host ''
Write-Host '[2/4] Sincronizando codigo por SCP...' -ForegroundColor Yellow
Write-Host ' (scripts/, docker/, vagrant/, .github/, .env.example)' -ForegroundColor Gray

Set-Location $ProjectRoot

# Asegurar que vagrant es propietario del directorio remoto antes de copiar.
# Es necesario porque deploy.sh crea/modifica archivos como root, dejando
# ficheros con root:root que scp no puede sobreescribir como vagrant.
Write-Host ' Ajustando permisos en la VM...' -ForegroundColor Gray
& ssh @sshArgs $target "sudo chown -R vagrant:vagrant $REMOTE_DIR" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host ' [ERROR] No se pudieron ajustar los permisos en la VM.' -ForegroundColor Red
  exit 1
}

$DirsToSync = @('scripts', 'docker', 'vagrant', '.github')
$FilesToSync = @('.env.example', 'Vagrantfile')

$scpArgs = @('-i', $SSH_KEY, '-o', 'StrictHostKeyChecking=no')

foreach ($dir in $DirsToSync) {
  if (Test-Path $dir) {
    Write-Host " -> $dir/" -ForegroundColor Gray
    & scp @scpArgs -r $dir "${target}:${REMOTE_DIR}/" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host " [ERROR] Fallo al copiar $dir" -ForegroundColor Red
      exit 1
    }
  }
}

foreach ($file in $FilesToSync) {
  if (Test-Path $file) {
    Write-Host " -> $file" -ForegroundColor Gray
    & scp @scpArgs $file "${target}:${REMOTE_DIR}/" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
      Write-Host " [ERROR] Fallo al copiar $file" -ForegroundColor Red
      exit 1
    }
  }
}

Write-Host ' [OK] Codigo sincronizado.' -ForegroundColor Green

# ── 3. Re-ejecutar deploy.sh en la VM ─────────────────────────
Write-Host ''
Write-Host '[3/4] Ejecutando deploy.sh en la VM...' -ForegroundColor Yellow
Write-Host ' (Puede tardar si hay cambios en contenedores)' -ForegroundColor Gray

$deployCmd = "sudo bash $REMOTE_DIR/scripts/deploy/deploy.sh"
& ssh @sshArgs $target $deployCmd

# ── 4. Resultado ─────────────────────────────────────────────
# El health check lo realiza deploy.sh internamente desde la propia VM.
# Desde Windows no hay ruta directa a la red interna (192.168.30.x),
# por lo que la verificacion remota no es posible.
Write-Host ''
if ($LASTEXITCODE -eq 0) {
  Write-Host '=============================================' -ForegroundColor Green
  Write-Host ' [OK] Actualizacion completada.'       -ForegroundColor Green
  Write-Host ' Accede desde la red interna:'        -ForegroundColor Green
  Write-Host ' https://erp.odoo.com'          -ForegroundColor Green
  Write-Host '=============================================' -ForegroundColor Green
} else {
  Write-Host '=============================================' -ForegroundColor Red
  Write-Host ' [ERROR] deploy.sh termino con errores.'   -ForegroundColor Red
  Write-Host ' Revisa los logs en la VM:'         -ForegroundColor Red
  Write-Host ' docker logs odoo-web --tail 50'       -ForegroundColor Red
  Write-Host '=============================================' -ForegroundColor Red
  exit 1
}