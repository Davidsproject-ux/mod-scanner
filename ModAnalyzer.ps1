# ==============================================
# Made by David
# Cloudsmp.net Cheat finder
# Passwort: cloudsmp
# ==============================================

# ================= Password ==================
$Password = Read-Host -AsSecureString "Bitte Passwort eingeben"
$Bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($Bstr)

if ($UnsecurePassword -ne "cloudsmp") {
    Write-Host "Falsches Passwort! Script wird beendet." -ForegroundColor Red
    exit
}

# ================= Parameters =================
param(
    [double]$Hours = 3.0,
    [string]$ServerLog,
    [string]$Player,
    [string]$DeletedLog,
    [switch]$Quiet
)

# ================= Launcher Paths =================
$Launchers = @{
    "Minecraft"  = "$env:APPDATA\.minecraft"
    "Lunar"      = "$env:USERPROFILE\.lunarclient"
    "Prism"      = "$env:APPDATA\.prismlauncher"
    "MultiMC"    = "$env:USERPROFILE\MultiMC"
}

$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')
$IllegalModNames = @(
    'clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst',
    'baritone','xray','killaura','nuker','velocity','speed','cheat','hack',
    'phobos','forcefield','matrix'
)
$TimeThreshold = (Get-Date).AddHours(-$Hours)

# ================= Functions =================
function Is-IllegalMod { param([string]$Name)
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
    Write-Host '==============================================' -ForegroundColor DarkRed
}

function Show-LoadingText {
    $text = 'Loading mods...'
    foreach ($ch in $text.ToCharArray()) {
        Write-Host -NoNewline $ch -ForegroundColor Yellow
        Start-Sleep -Milliseconds 50
    }
    Write-Host ''
    Start-Sleep -Milliseconds 300
    Write-Host 'Done loading.' -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
}

function Get-ModFilesByLauncher {
    $Result = @{}
    foreach ($launcher in $Launchers.Keys) {
        $path = $Launchers[$launcher]
        $mods = @()
        if (Test-Path $path) {
            $mods = Get-ChildItem -Path $path -Recurse -File |
                Where-Object { $_.Extension -in $ModExtensions } |
                ForEach-Object { [PSCustomObject]@{ Name=$_.Name; Path=$_.FullName } }
        }
        $Result[$launcher] = $mods
    }
    return $Result
}

function Show-ModsAnimated {
    param([hashtable]$LauncherMods)
    foreach ($launcher in $LauncherMods.Keys) {
        Write-Host "`n=== $launcher Mods ===" -ForegroundColor Cyan
        $mods = $LauncherMods[$launcher]
        if ($mods.Count -eq 0) {
            Write-Host "  Keine Mods gefunden." -ForegroundColor DarkGray
            Start-Sleep -Seconds 1
        } else {
            foreach ($mod in $mods) {
                $color = if (Is-IllegalMod $mod.Name) { 'Red' } else { 'Green' }
                Write-Host "  $($mod.Name)" -ForegroundColor $color
                Start-Sleep -Seconds 1
                Write-Host "    $($mod.Path)" -ForegroundColor DarkGray
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ================= Main =================
if (-not $Quiet) { Show-Header; Show-LoadingText }

$LauncherMods = Get-ModFilesByLauncher
Show-ModsAnimated -LauncherMods $LauncherMods

Write-Host "`nScan abgeschlossen!" -ForegroundColor Red
