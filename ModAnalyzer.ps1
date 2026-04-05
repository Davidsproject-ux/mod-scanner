# ===============================================
# Made by David
# Cloudsmp.net Cheat finder
# Minecraft Mod Scanner (Launcher Edition)
# ===============================================

# --- Passwortschutz ---
$PasswordInput = Read-Host "Enter password"
if ($PasswordInput -ne "cloudsmp") {
    Write-Host "Incorrect password!" -ForegroundColor Red
    exit
}

# --- Config ---
$Hours = 3
$TimeThreshold = (Get-Date).AddHours(-$Hours)

# --- Launcher Mod Paths ---
$LauncherPaths = @{
    "Lunar Client"  = "$env:USERPROFILE\.lunarclient\offline\multiver"
    "Feather Client"= "$env:USERPROFILE\.feather\instances"
    "Prism Client"  = "$env:APPDATA\PrismLauncher\instances"
    "MultiMC"       = "$env:USERPROFILE\MultiMC\instances"
}

$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')
$IllegalModNames = @('clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst','baritone','xray','killaura','nuker','velocity','speed','cheat','hack','phobos','forcefield','matrix')

# --- Functions ---
function Is-IllegalMod {
    param([string]$Name)
    $lower = $Name.ToLower()
    foreach ($keyword in $IllegalModNames) {
        if ($lower -like "*${keyword}*") { return $true }
    }
    return $false
}

function Show-Header {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor DarkGray
    Write-Host 'Made by David' -ForegroundColor Magenta
    Write-Host 'Cloudsmp.net Cheat finder' -ForegroundColor Cyan
    Write-Host 'Minecraft Launcher Mod Scanner' -ForegroundColor Green
    Write-Host '==============================================' -ForegroundColor DarkGray
}

function Show-LoadingText {
    $text = 'Scanning launchers...'
    foreach ($ch in $text.ToCharArray()) {
        Write-Host -NoNewline $ch -ForegroundColor Yellow
        Start-Sleep -Milliseconds 50
    }
    Write-Host ''
    Start-Sleep -Milliseconds 300
    Write-Host 'Done scanning.' -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
}

function Get-ModFiles {
    param([string]$RootPath)
    if (-not (Test-Path $RootPath)) { return @() }
    $mods = Get-ChildItem -Path $RootPath -Recurse -File | Where-Object { $_.Extension -in $ModExtensions } | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName
            Name = $_.Name
            Modified = $_.LastWriteTime
        }
    }
    return $mods | Sort-Object Modified -Descending
}

function Get-PrismModsPath {
    $prismRoot = $LauncherPaths["Prism Client"]
    if (-not (Test-Path $prismRoot)) { return $null }

    $versions = Get-ChildItem -Path $prismRoot -Directory | Select-Object -ExpandProperty Name
    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) {
        $chosenVersion = $versions[0]
    } else {
        Write-Host "Multiple Prism versions found:" -ForegroundColor Cyan
        $i = 1
        foreach ($v in $versions) {
            Write-Host "  [$i] $v"
            $i++
        }
        $choice = Read-Host "Which version do you want to scan? Enter number"
        $chosenVersion = $versions[$choice - 1]
    }

    $modsPath = Join-Path $prismRoot "$chosenVersion\minecraft\mods"
    return $modsPath
}

# --- Main ---
Show-Header
Show-LoadingText

foreach ($launcher in $LauncherPaths.Keys) {

    $path = $LauncherPaths[$launcher]

    # Prism Launcher Besonderheit
    if ($launcher -eq "Prism Client") {
        $path = Get-PrismModsPath
        if (-not $path) {
            Write-Host "`nNo Prism mods found." -ForegroundColor Yellow
            continue
        }
    }

    Write-Host "`n$launcher Mods:" -ForegroundColor Cyan
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray

    $mods = Get-ModFiles -RootPath $path
    if ($mods.Count -eq 0) {
        Write-Host "  No mods found." -ForegroundColor Yellow
    } else {
        foreach ($mod in $mods) {
            $color = if (Is-IllegalMod $mod.Name) { 'Red' } else { 'Green' }
            Write-Host "  $($mod.Name)" -ForegroundColor $color
            Start-Sleep -Seconds 1
            Write-Host "    $($mod.Path)" -ForegroundColor DarkGray
            Start-Sleep -Seconds 1
        }
        Write-Host "  ...$($mods.Count) mods total" -ForegroundColor Cyan
    }
}

Write-Host "`nScan complete." -ForegroundColor Green
