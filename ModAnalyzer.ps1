# ==============================================
# Made by David
# Cloudsmp.net Cheat finder
# Minecraft Mod Scanner (Launcher-only)
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
$Hours = 3
$TimeThreshold = (Get-Date).AddHours(-$Hours)

$LauncherPaths = @{
    "Lunar Client"    = "$env:USERPROFILE\.lunarclient\offline\multiver"
    "Feather Client"  = "$env:USERPROFILE\FeatherClient\mods"
    "Prism Client"    = "$env:USERPROFILE\PrismClient\mods"
    "MultiMC"         = "$env:USERPROFILE\MultiMC\instances"
    "Vanilla MC"      = "$env:APPDATA\.minecraft\mods"
}

$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')
$IllegalModNames = @(
    'clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst',
    'baritone','xray','killaura','nuker','velocity','speed','cheat','hack',
    'phobos','forcefield','matrix'
)

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
    Write-Host '==============================================' -ForegroundColor Blue
    Write-Host 'Made by David' -ForegroundColor Red
    Write-Host 'Cloudsmp.net Cheat finder' -ForegroundColor Cyan
    Write-Host 'Minecraft Mod Scanner (Launcher-only)' -ForegroundColor Yellow
    Write-Host '==============================================' -ForegroundColor Blue
}

function Animate-Loading {
    param([string]$Text = "Loading mods...", [int]$Speed = 50)
    $spinner = @('|','/','-','\')
    for ($i=0; $i -lt 30; $i++) {
        $frame = $spinner[$i % $spinner.Length]
        Write-Host -NoNewline ("`r$frame $Text") -ForegroundColor Yellow
        Start-Sleep -Milliseconds $Speed
    }
    Write-Host "`rDone loading.`n" -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
}

function Get-ModFiles {
    param([string]$Path, [string]$Launcher)
    $allMods = @()
    if (-not (Test-Path $Path)) { return $allMods }
    $mods = Get-ChildItem -Path $Path -Recurse -File |
        Where-Object { $_.Extension -in $ModExtensions -and $_.LastWriteTime -ge $TimeThreshold } |
        ForEach-Object { [PSCustomObject]@{ Launcher=$Launcher; Path=$_.FullName; Name=$_.Name; Modified=$_.LastWriteTime } }
    return $mods | Sort-Object Modified -Descending
}

# ================= Main =================
Show-Header
Animate-Loading -Text "Scanning launcher mod folders..."

$allMods = @()
foreach ($launcher in $LauncherPaths.Keys) {
    $allMods += Get-ModFiles -Path $LauncherPaths[$launcher] -Launcher $launcher
}

# -------- Mods nach Launcher sortieren --------
$launchersOrdered = @("Lunar Client","Feather Client","Prism Client","MultiMC","Vanilla MC")
foreach ($launcher in $launchersOrdered) {
    $mods = $allMods | Where-Object { $_.Launcher -eq $launcher }
    if ($mods.Count -eq 0) { continue }

    Write-Host "`n=== $launcher Mods ===" -ForegroundColor Cyan
    $counter = 0
    foreach ($mod in $mods) {
        $color = if (Is-IllegalMod $mod.Name) { 'Red' } else { 'Green' }
        Write-Host ("  {0,-50}" -f $mod.Name) -ForegroundColor $color
        Write-Host ("    {0}" -f $mod.Path) -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 30  # kleine Animation beim Anzeigen
        $counter++
        if ($counter -ge 50) { Write-Host "  ...and $($mods.Count - 50) more mod files" -ForegroundColor Cyan; break }
    }
}

Write-Host "`nScan abgeschlossen!!" -ForegroundColor Red
