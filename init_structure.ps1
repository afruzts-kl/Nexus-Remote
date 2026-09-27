param()

$ErrorActionPreference = 'Stop'
Write-Host "Creating repository directory structure..."
$root = "c:\Users\Zeyrox Viper\Desktop\PC MONITOR\nexus-remote"
$dirs = @(
    "$root\mobile",
    "$root\windows-agent",
    "$root\protocol",
    "$root\docs",
    "$root\scripts"
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
}
Write-Host "Directory structure created at $root"
