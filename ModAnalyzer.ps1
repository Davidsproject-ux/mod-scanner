# ===============================================
# Made by David
# Minecraft Mod Scanner (Launcher Edition)
# ===============================================

# --- Header / Loading ---
function Show-Header {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor DarkRed
    Write-Host 'Made by David' -ForegroundColor Red
    Write-Host 'Cheat finder' -ForegroundColor Red
    Write-Host 'Are you a cheater?😒' -ForegroundColor DarkRed
    Write-Host '==============================================' -ForegroundColor DarkRed
}

Show-Header

# --- Passwort ---
$PasswordInput = Read-Host "Enter password"
if ($PasswordInput -ne "cloudsmp") {
    Write-Host "Incorrect password!" -ForegroundColor Red
    exit
}

# --- Config ---
$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')
$IllegalModNames = @(
    'clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst',
    'baritone','xray','killaura','nuker','velocity','speed','cheat','hack',
    'phobos','forcefield','matrix'
)

# --- Launcher Paths ---
$LauncherPaths = @{
    "Vanilla"        = "$env:APPDATA\.minecraft\mods"
    "Lunar Client"   = "$env:USERPROFILE\.lunarclient\offline\multiver"
    "Feather Client" = "$env:USERPROFILE\.feather\user-mods"
    "Prism Client"   = "$env:APPDATA\PrismLauncher\instances"
    "MultiMC"        = "$env:USERPROFILE\MultiMC\instances"
    "Modrinth"       = "$env:APPDATA\ModrinthApp\profiles"
    "CurseForge"     = "$env:USERPROFILE\curseforge\minecraft\Instances"
}

# --- Functions ---
function Is-IllegalMod {
    param([string]$Name)
    $lower = $Name.ToLower()
    foreach ($keyword in $IllegalModNames) {
        if ($lower -like "*$keyword*") { return $true }
    }
    return $false
}

function Get-ModFiles {
    param([string]$RootPath)
    if (-not (Test-Path $RootPath)) { return @() }
    Get-ChildItem -Path $RootPath -Recurse -File |
        Where-Object { $_.Extension -in $ModExtensions } |
        Sort-Object LastWriteTime -Descending
}

function Select-Instance {
    param($RootPath, $Name, $SubPath)
    if (-not (Test-Path $RootPath)) { return $null }

    $list = Get-ChildItem $RootPath -Directory | Select-Object -Expand Name
    if ($list.Count -eq 0) { return $null }

    if ($list.Count -eq 1) {
        $chosen = $list[0]
    } else {
        Write-Host "`n$Name versions:" -ForegroundColor Cyan
        for ($i=0;$i -lt $list.Count;$i++) { Write-Host "[$($i+1)] $($list[$i])" }
        $input = Read-Host "Select"
        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            if ($idx -ge 0 -and $idx -lt $list.Count) { $chosen = $list[$idx] } else { $chosen = $list[0] }
        } else {
            $chosen = $list | Where-Object { $_ -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $list[0] }
        }
    }

    return Join-Path $RootPath "$chosen\$SubPath"
}

function Get-FeatherModsPath {
    $root = "$env:USERPROFILE\.feather\user-mods"
    if (-not (Test-Path $root)) { return $null }

    $versions = Get-ChildItem $root -Directory | Select-Object -Expand Name
    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) {
        $chosen = $versions[0]
    } else {
        Write-Host "`nFeather versions:" -ForegroundColor Cyan
        for ($i=0;$i -lt $versions.Count;$i++) { Write-Host "[$($i+1)] $($versions[$i])" }
        $input = Read-Host "Select version"
        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            if ($idx -ge 0 -and $idx -lt $versions.Count) { $chosen = $versions[$idx] } else { $chosen = $versions[0] }
        } else {
            $chosen = $versions | Where-Object { $_ -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $versions[0] }
        }
    }

    return Join-Path $root $chosen
}

# --- Start Scan ---
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

    Write-Host "`n$($launcher):" -ForegroundColor Cyan

    if (-not $path -or -not (Test-Path $path)) {
        Write-Host "No mods found" -ForegroundColor Yellow
        continue
    }

    $mods = Get-ModFiles $path

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
