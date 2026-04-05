# ===============================================
# Made by David
# Cloudsmp.net Cheat finder
# ===============================================

# Passwort
if ((Read-Host "Enter password") -ne "cloudsmp") {
    Write-Host "Wrong password" -ForegroundColor Red
    exit
}

# Config
$ModExtensions = @('.jar','.litemod','.mcpack','.mcaddon','.modpack')
$IllegalMods = @('meteor','impact','wurst','aristois','liquidbounce','xray','killaura','hack','cheat','baritone')

# Launcher Paths
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

function Is-Illegal {
    param($name)
    $n = $name.ToLower()
    foreach ($b in $IllegalMods) {
        if ($n -like "*$b*") { return $true }
    }
    return $false
}

function Get-Mods {
    param($path)
    if (!(Test-Path $path)) { return @() }

    Get-ChildItem $path -Recurse -File |
    Where-Object { $_.Extension -in $ModExtensions }
}

function Select-Instance {
    param($root,$sub)

    if (!(Test-Path $root)) { return $null }

    $list = Get-ChildItem $root -Directory
    if ($list.Count -eq 0) { return $null }

    if ($list.Count -eq 1) {
        return Join-Path $list[0].FullName $sub
    }

    for ($i=0;$i -lt $list.Count;$i++) {
        Write-Host "[$($i+1)] $($list[$i].Name)"
    }

    $c = Read-Host "Select"
    if ($c -match '^\d+$') {
        return Join-Path $list[[int]$c-1].FullName $sub
    }

    return Join-Path $list[0].FullName $sub
}

# --- Feather FIX ---
function Get-Feather {

    $root = "$env:USERPROFILE\.feather\user-mods"
    if (!(Test-Path $root)) { return $null }

    $versions = Get-ChildItem $root -Directory
    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) {
        $chosen = $versions[0]
    } else {
        Write-Host "`nFeather Versions:" -ForegroundColor Cyan
        for ($i=0;$i -lt $versions.Count;$i++) {
            Write-Host "[$($i+1)] $($versions[$i].Name)"
        }

        $input = Read-Host "Select version"

        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            if ($idx -ge 0 -and $idx -lt $versions.Count) {
                $chosen = $versions[$idx]
            } else {
                $chosen = $versions[0]
            }
        } else {
            $chosen = $versions | Where-Object { $_.Name -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $versions[0] }
        }
    }

    return $chosen.FullName
}

# --- Start ---
Clear-Host
Write-Host "Scanning..." -ForegroundColor Yellow

foreach ($launcher in $LauncherPaths.Keys) {

    $path = $null

    switch ($launcher) {
        "Vanilla"        { $path = $LauncherPaths[$launcher] }
        "Lunar Client"   { $path = $LauncherPaths[$launcher] }
        "Prism Client"   { $path = Select-Instance $LauncherPaths[$launcher] "minecraft\mods" }
        "MultiMC"        { $path = Select-Instance $LauncherPaths[$launcher] "minecraft\mods" }
        "Modrinth"       { $path = Select-Instance $LauncherPaths[$launcher] "mods" }
        "CurseForge"     { $path = Select-Instance $LauncherPaths[$launcher] "mods" }
        "Feather Client" { $path = Get-Feather }
    }

    Write-Host "`n${launcher}:" -ForegroundColor Cyan

    if (!$path -or !(Test-Path $path)) {
        Write-Host "No mods found" -ForegroundColor Yellow
        continue
    }

    $mods = Get-Mods $path

    if ($mods.Count -eq 0) {
        Write-Host "No mods found" -ForegroundColor Yellow
        continue
    }

    foreach ($mod in $mods) {
        if (Is-Illegal $mod.Name) {
            Write-Host $mod.Name -ForegroundColor Red
        } else {
            Write-Host $mod.Name -ForegroundColor Green
        }
    }

    Write-Host "$($mods.Count) mods found" -ForegroundColor DarkGray
}

Write-Host "`nScan complete." -ForegroundColor Green
