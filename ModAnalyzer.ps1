# ===============================================
# Made by David
# Minecraft Mod Scanner (Launcher Edition) - FIXED
# ===============================================

# --- Header ---
function Show-Header {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor DarkRed
    Write-Host 'Minecraft Mod Scanner' -ForegroundColor Red
    Write-Host '==============================================' -ForegroundColor DarkRed
}

Show-Header

# --- Passwort ---
$PasswordInput = Read-Host "Enter password"
if ($PasswordInput -ne "fisch") {
    Write-Host "Incorrect password!" -ForegroundColor Red
    exit
}

# ===============================================
# CONFIG (FIXED)
# ===============================================

$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')

$IllegalModNames = @(
    'clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst',
    'baritone','xray','killaura','nuker','velocity','speed','cheat','hack',
    'phobos','forcefield','matrix'
)

$LauncherPaths = @{
    "Vanilla"        = Join-Path $env:APPDATA ".minecraft\mods"
    "Lunar Client"   = Join-Path $env:USERPROFILE ".lunarclient\offline\multiver"
    "Feather Client" = Join-Path $env:USERPROFILE ".feather\user-mods"
    "Prism Client"   = Join-Path $env:APPDATA "PrismLauncher\instances"
    "MultiMC"        = Join-Path $env:USERPROFILE "MultiMC\instances"
    "Modrinth"       = Join-Path $env:APPDATA "ModrinthApp\profiles"
    "CurseForge"     = Join-Path $env:USERPROFILE "curseforge\minecraft\Instances"
}

# ===============================================
# FUNCTIONS
# ===============================================

function Is-IllegalMod {
    param([string]$Name)

    $lower = $Name.ToLowerInvariant()

    foreach ($keyword in $IllegalModNames) {
        if ($lower -like "*$keyword*") {
            return $true
        }
    }

    return $false
}

function Get-ModFiles {
    param([string]$RootPath)

    if (-not (Test-Path $RootPath)) { return @() }

    return @(Get-ChildItem -Path $RootPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Extension -in $ModExtensions } |
        Sort-Object LastWriteTime -Descending)
}

function Select-Instance {
    param($RootPath, $Name, $SubPath)

    if (-not (Test-Path $RootPath)) { return $null }

    $list = @(Get-ChildItem $RootPath -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)

    if ($list.Count -eq 0) { return $null }

    if ($list.Count -eq 1) {
        $chosen = $list[0]
    }
    else {
        Write-Host "`n$Name versions:" -ForegroundColor Cyan

        for ($i = 0; $i -lt $list.Count; $i++) {
            Write-Host "[$($i+1)] $($list[$i])"
        }

        $input = Read-Host "Select"

        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            $chosen = if ($idx -ge 0 -and $idx -lt $list.Count) { $list[$idx] } else { $list[0] }
        }
        else {
            $chosen = $list | Where-Object { $_ -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $list[0] }
        }
    }

    return Join-Path $RootPath (Join-Path $chosen $SubPath)
}

function Get-FeatherModsPath {
    $root = "$env:USERPROFILE\.feather\user-mods"

    if (-not (Test-Path $root)) { return $null }

    $versions = @(Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)

    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) {
        $chosen = $versions[0]
    }
    else {
        Write-Host "`nFeather versions:" -ForegroundColor Cyan

        for ($i = 0; $i -lt $versions.Count; $i++) {
            Write-Host "[$($i+1)] $($versions[$i])"
        }

        $input = Read-Host "Select version"

        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            $chosen = if ($idx -ge 0 -and $idx -lt $versions.Count) { $versions[$idx] } else { $versions[0] }
        }
        else {
            $chosen = $versions | Where-Object { $_ -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $versions[0] }
        }
    }

    return Join-Path $root $chosen
}

# ===============================================
# START SCAN
# ===============================================

Write-Host "`nScanning launchers..." -ForegroundColor Yellow

foreach ($launcher in $LauncherPaths.Keys) {

    $root = $LauncherPaths[$launcher]
    $path = $null

    switch ($launcher) {
        "Vanilla"        { $path = $root }
        "Lunar Client"   { $path = $root }
        "Prism Client"   { $path = Select-Instance $root "Prism" "minecraft\mods" }
        "MultiMC"        { $path = Select-Instance $root "MultiMC" "minecraft\mods" }
        "Modrinth"       { $path = Select-Instance $root "Modrinth" "mods" }
        "CurseForge"     { $path = Select-Instance $root "CurseForge" "mods" }
        "Feather Client" { $path = Get-FeatherModsPath }
    }

    # 🔥 FIXED LINE (NO MORE $launcher: CRASH)
    Write-Host ("`n{0}:" -f $launcher) -ForegroundColor Cyan

    if (-not $path -or -not (Test-Path $path)) {
        Write-Host "No mods found" -ForegroundColor Yellow
        continue
    }

    $mods = @(Get-ModFiles $path)

    if ($mods.Count -eq 0) {
        Write-Host "No mods found" -ForegroundColor Yellow
        continue
    }

    foreach ($mod in $mods) {
        $color = if (Is-IllegalMod $mod.Name) { "Red" } else { "Green" }
        Write-Host $mod.Name -ForegroundColor $color
    }

    Write-Host "$($mods.Count) mods found" -ForegroundColor DarkGray
}

Write-Host "`nScan complete." -ForegroundColor Green
