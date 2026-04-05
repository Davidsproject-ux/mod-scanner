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

# --- Scan Geschwindigkeit (in Millisekunden) ---
$SleepLoading = 5      # Ladeanimation pro Buchstabe
$SleepModDisplay = 0   # Pause beim Anzeigen jedes Mods

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

        $choice = Read-Host "Which version do you want to scan? Enter number or version string"

        # Prüfen, ob die Eingabe eine Zahl ist
        if ($choice -as [int]) {
            $index = [int]$choice - 1
            if ($index -ge 0 -and $index -lt $versions.Count) {
                $chosenVersion = $versions[$index]
            } else {
                Write-Host "Invalid number. Using first version." -ForegroundColor Yellow
                $chosenVersion = $versions[0]
            }
        } else {
            # Prüfen, ob die Eingabe als Text existiert
            if ($versions -contains $choice) {
                $chosenVersion = $choice
            } else {
                Write-Host "Version not found. Using first version." -ForegroundColor Yellow
                $chosenVersion = $versions[0]
            }
        }
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
            Start-Sleep -Milliseconds $SleepModDisplay
            Write-Host "    $($mod.Path)" -ForegroundColor DarkGray
        }
        Write-Host "  ...$($mods.Count) mods total" -ForegroundColor Cyan
    }
}

Write-Host "`nScan complete." -ForegroundColor Green
