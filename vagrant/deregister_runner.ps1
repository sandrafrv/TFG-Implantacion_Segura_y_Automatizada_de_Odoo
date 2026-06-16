# ============================================================
# vagrant/deregister_runner.ps1
# Desregistra un GitHub Actions runner de la API de GitHub.
# Llamado desde el trigger before :destroy del Vagrantfile.
#
# Uso: deregister_runner.ps1 <RunnerName> <GhPat> <GhRepo>
#
# Por que fichero .ps1 y no inline:
#   El inline pasa por bash (Git Bash de Windows) antes de
#   llegar a PowerShell. Bash expande $r, $h, $runners, $_
#   como variables de shell (vacias o con valores inesperados),
#   rompiendo el script de PowerShell con errores de parseo.
#   Un fichero .ps1 lo ejecuta Vagrant directamente con
#   PowerShell.exe -ExecutionPolicy Bypass -File, sin bash.
# ============================================================

param(
    [Parameter(Mandatory = $true)][string]$RunnerName,
    [string]$GhPat  = "",
    [string]$GhRepo = ""
)

# Si no hay PAT, salir silenciosamente
if ([string]::IsNullOrEmpty($GhPat)) {
    Write-Host "[SKIP] GH_PAT no definido - se omite desregistro de $RunnerName"
    exit 0
}

$ErrorActionPreference = 'Continue'

$headers = @{
    'Authorization' = "Bearer $GhPat"
    'Accept'        = 'application/vnd.github+json'
}

# Obtener lista de runners del repositorio
try {
    $runners = (Invoke-RestMethod `
        -Uri     "https://api.github.com/repos/$GhRepo/actions/runners" `
        -Headers $headers).runners
} catch {
    Write-Host "[WARN] No se pudo consultar runners: $($_.Exception.Message)"
    exit 0
}

# Buscar el runner por nombre
$runner = $runners | Where-Object { $_.name -eq $RunnerName }

if ($runner) {
    try {
        Invoke-RestMethod `
            -Method  DELETE `
            -Uri     "https://api.github.com/repos/$GhRepo/actions/runners/$($runner.id)" `
            -Headers $headers | Out-Null
        Write-Host "[OK] $RunnerName eliminado de GitHub (id=$($runner.id))"
    } catch {
        Write-Host "[WARN] No se pudo eliminar $RunnerName`: $($_.Exception.Message)"
    }
} else {
    Write-Host "[INFO] $RunnerName no encontrado en GitHub (ya estaba eliminado)"
}
