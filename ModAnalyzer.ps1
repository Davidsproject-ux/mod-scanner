# ================= Main =================
Show-Header
Animate-Loading -Text "Scanning all launcher mod folders..."

# --- Vanilla Minecraft ---
$vanillaPaths = @(
    "$env:APPDATA\.minecraft\mods",
    "$env:APPDATA\.minecraft\resourcepacks",
    "$env:APPDATA\.minecraft\config"
)
Scan-Launcher -Name "Vanilla Minecraft" -Paths $vanillaPaths

# --- Lunar Client ---
$lunarPaths = @(
    "$env:USERPROFILE\.lunarclient\offline\multiver",
    "$env:USERPROFILE\.lunarclient\profiles"
)
Scan-Launcher -Name "Lunar Client" -Paths $lunarPaths

# --- MultiMC ---
$multiMCPaths = @("$env:USERPROFILE\MultiMC\instances")
Scan-Launcher -Name "MultiMC" -Paths $multiMCPaths

# --- Feather ---
$featherPath = Get-Feather
if ($featherPath) { Scan-Launcher -Name "Feather" -Paths @($featherPath) }

# --- Prism ---
function Get-Prism {
    $root = "$env:USERPROFILE\.prism\user-mods"
    if (!(Test-Path $root)) { return $null }

    $versions = Get-ChildItem $root -Directory
    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) { $chosen = $versions[0] } else {
        Write-Host "`nPrism Versions:" -ForegroundColor Cyan
        for ($i=0;$i -lt $versions.Count;$i++) { Write-Host "[$($i+1)] $($versions[$i].Name)" }
        $input = Read-Host "Select Prism version"
        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            if ($idx -ge 0 -and $idx -lt $versions.Count) { $chosen = $versions[$idx] } else { $chosen = $versions[0] }
        } else {
            $chosen = $versions | Where-Object { $_.Name -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $versions[0] }
        }
    }

    $base = $chosen.FullName
    $possiblePaths = @($base, "$base\mods", "$base\.minecraft\mods")
    foreach ($p in $possiblePaths) {
        if (Test-Path $p) {
            $mods = Get-ChildItem $p -Recurse -Include *.jar -File -ErrorAction SilentlyContinue
            if ($mods.Count -gt 0) { Write-Host "Found Prism mods in: $p" -ForegroundColor Green; return $p }
        }
    }

    Write-Host "No Prism mods found!" -ForegroundColor Yellow
    return $base
}
$prismPath = Get-Prism
if ($prismPath) { Scan-Launcher -Name "Prism" -Paths @($prismPath) }

Write-Host "`nScan abgeschlossen." -ForegroundColor Green
