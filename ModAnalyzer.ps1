#==============================================
# Made by David
# Cloudsmp.net Cheat finder
# Minecraft Mod Scanner (Launcher Edition)
#==============================================

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
    "Prism Client"  = "$env:USERPROFILE\.PrismLauncher\instances\<Version>\minecraft\mods"
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

# --- Main ---
Show-Header
Show-LoadingText

foreach ($launcher in $LauncherPaths.Keys) {
    $path = $LauncherPaths[$launcher]
    Write-Host "`n$launcher Mods:" -ForegroundColor Cyan
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
    $mods = Get-ModFiles -RootPath $path
    if ($mods.Count -eq 0) {
        Write-Host "  No mods found." -ForegroundColor Yellow
    } else {
        $mods | ForEach-Object {
            $color = if (Is-IllegalMod $_.Name) { 'Red' } else { 'Green' }
            Write-Host "  $($_.Name)" -ForegroundColor $color
        }
        Write-Host "  ...$($mods.Count) mods total" -ForegroundColor Cyan
    }
}

Write-Host "`nScan complete." -ForegroundColor Green
