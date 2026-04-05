# ===============================================
# Made by David
# Cloudsmp.net Cheat finder
# Minecraft Mod Scanner (Launcher Edition)
# ===============================================

# Passwort
$PasswordInput = Read-Host "Enter password"
if ($PasswordInput -ne "cloudsmp") {
    Write-Host "Incorrect password!" -ForegroundColor Red
    exit
}

# Config
$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')
$IllegalModNames = @('clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst','baritone','xray','killaura','nuker','velocity','speed','cheat','hack','phobos','forcefield','matrix')

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

# Scan Geschwindigkeit
$SleepLoading = 5
$SleepModDisplay = 0

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

    return Get-ChildItem -Path $RootPath -Recurse -File |
        Where-Object { $_.Extension -in $ModExtensions } |
        Sort-Object LastWriteTime -Descending
}

# --- Universal Instance / Version Selector ---
function Select-Instance {
    param($RootPath, $LauncherName, $ModsSubPath)

    if (-not (Test-Path $RootPath)) { return $null }

    $instances = Get-ChildItem -Path $RootPath -Directory | Select-Object -ExpandProperty Name
    if ($instances.Count -eq 0) { return $null }

    if ($instances.Count -eq 1) {
        $chosen = $instances[0]
    } else {
        Write-Host "`nMultiple $LauncherName versions/profiles found:" -ForegroundColor Cyan
        for ($i=0;$i -lt $instances.Count;$i++) {
            Write-Host "[$($i+1)] $($instances[$i])"
        }

        $choice = Read-Host "Select number or name"
        if ($choice -match '^\d+$') {
            $index = [int]$choice - 1
            $chosen = if ($index -ge 0 -and $index -lt $instances.Count) { $instances[$index] } else { $instances[0] }
        } else {
            $chosen = $instances | Where-Object { $_ -like "$choice*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $instances[0] }
        }
    }

    return Join-Path $RootPath "$chosen\$ModsSubPath"
}

# --- Feather Mods Path ---
function Get-FeatherModsPath {
    $root = "$env:USERPROFILE\.feather\user-mods"
    if (-not (Test-Path $root)) { return $null }

    $versions = Get-ChildItem $root -Directory | Select-Object -ExpandProperty Name
    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) {
        $chosenVersion = $versions[0]
    } else {
        Write-Host "`nFeather versions found:" -ForegroundColor Cyan
        for ($i=0;$i -lt $versions.Count;$i++) {
            Write-Host "[$($i+1)] $($versions[$i])"
        }

        $input = Read-Host "Select version (number or name)"
        if ($input -match '^\d+$') {
            $index = [int]$input - 1
            $chosenVersion = if ($index -ge 0 -and $index -lt $versions.Count) { $versions[$index] } else { $versions[0] }
        } else {
            $chosenVersion = $versions | Where-Object { $_ -like "$input*" } | Select-Object -First 1
            if (-not $chosenVersion) { $chosenVersion = $versions[0] }
        }
    }

    return Join-Path $root $chosenVersion
}

# --- Header / Loading ---
function Show-Header {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor DarkRed
    Write-Host 'Made by David' -ForegroundColor Red
    Write-Host 'Cloudsmp.net Cheat finder' -ForegroundColor Red
    Write-Host 'Bist du ein Cheater?😒' -ForegroundColor Blue
    Write-Host '==============================================' -ForegroundColor DarkRed
}

function Show-LoadingText {
    $text = 'Scanning launchers...'
    foreach ($ch in $text.ToCharArray()) {
        Write-Host -NoNewline $ch -ForegroundColor Yellow
        Start-Sleep -Milliseconds $SleepLoading
    }
    Write-Host ''
    Write-Host 'Done scanning.' -ForegroundColor DarkRed
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
}

# --- Main ---
Show-Header
Show-LoadingText

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

    Write-Host "`n$launcher Mods:" -ForegroundColor Cyan

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
        Write-Host "  $($mod.Name)" -ForegroundColor $color
        Write-Host "    $($mod.FullName)" -ForegroundColor DarkGray
        Start-Sleep -Milliseconds $SleepModDisplay
    }

    Write-Host "  ...$($mods.Count) mods total" -ForegroundColor Cyan
}

Write-Host "`nScan complete." -ForegroundColor Green
