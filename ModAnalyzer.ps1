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

# Launcher Mod-Ordner
$LauncherPaths = @(
    "$env:APPDATA\.minecraft\mods",
    "$env:APPDATA\.minecraft\resourcepacks",
    "$env:APPDATA\.minecraft\config",
    "$env:USERPROFILE\.lunarclient\offline\multiver",
    "$env:USERPROFILE\.lunarclient\profiles",
    "$env:USERPROFILE\MultiMC\instances"
)

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

function Get-ModFiles {
    param([string[]]$RootPaths)
    $allMods = @()
    foreach ($RootPath in $RootPaths) {
        if (-not (Test-Path $RootPath)) { continue }
        $mods = Get-ChildItem -Path $RootPath -Recurse -File |
        Where-Object { $_.Extension -in $ModExtensions } |
        ForEach-Object { [PSCustomObject]@{ Path=$_.FullName; Name=$_.Name; Modified=$_.LastWriteTime } }
        $allMods += $mods
    }
    return $allMods | Sort-Object Modified -Descending
}

function Get-TexturePacks {
    param([string[]]$RootPaths)
    $allPacks = @()
    foreach ($RootPath in $RootPaths) {
        if (-not (Test-Path $RootPath)) { continue }
        $packs = Get-ChildItem -Path $RootPath -Recurse -File |
        Where-Object { ($_.Extension -in @('.zip', '.rar')) -and ($_.Name -match '(?i)(resource|texture|pack)') } |
        ForEach-Object { [PSCustomObject]@{ Path=$_.FullName; Name=$_.Name; Modified=$_.LastWriteTime } }
        $allPacks += $packs
    }
    return $allPacks | Sort-Object Modified -Descending
}

function Get-DeletedEntries { param([string]$LogPath, [DateTime]$Threshold)
    if (-not (Test-Path $LogPath)) { return @() }
    Get-Content $LogPath | ForEach-Object {
        if ($_ -match '(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}).*(delete|deleted|löschen)') {
            $ts = [DateTime]::Parse($matches[1])
            if ($ts -ge $Threshold) { [PSCustomObject]@{ Timestamp=$ts; Line=$_ } }
        }
    } | Sort-Object Timestamp -Descending
}

function Get-ServerLogEntries { param([string]$LogPath, [string]$PlayerName, [DateTime]$Threshold)
    if (-not (Test-Path $LogPath)) { return @() }
    Get-Content $LogPath | ForEach-Object {
        if ($_ -match '(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})') {
            $ts = [DateTime]::Parse($matches[1])
            if ($ts -ge $Threshold -and (-not $PlayerName -or $_.ToLower().Contains($PlayerName.ToLower()))) {
                [PSCustomObject]@{ Timestamp=$ts; Line=$_ }
            }
        }
    } | Sort-Object Timestamp -Descending
}

# ================= Main =================
if (-not $Quiet) { Show-Header; Show-LoadingText }

$mods         = Get-ModFiles -RootPaths $LauncherPaths
$texturePacks = Get-TexturePacks -RootPaths $LauncherPaths

# -------- Texture Packs --------
Write-Host "TEXTUREPACKS" -ForegroundColor Magenta
$texturePacks | Select-Object -First 20 | ForEach-Object {
    Write-Host "  $($_.Name)" -ForegroundColor Magenta
    Start-Sleep -Seconds 1.5
    Write-Host "    $($_.Path)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 1.5
}
if ($texturePacks.Count -gt 20) {
    Write-Host "  ...and $($texturePacks.Count - 20) more texturepack files" -ForegroundColor Magenta
}

# -------- Mods --------
Write-Host "MODS" -ForegroundColor Cyan
$mods | Select-Object -First 50 | ForEach-Object {
    $color = if (Is-IllegalMod $_.Name) { 'Red' } else { 'Green' }
    Write-Host "  $($_.Name)" -ForegroundColor $color
    Start-Sleep -Seconds 1.5
    Write-Host "    $($_.Path)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 1.5
}
if ($mods.Count -gt 50) {
    Write-Host "  ...and $($mods.Count - 50) more mod files" -ForegroundColor Cyan
}

# -------- Deleted Entries --------
if ($DeletedLog) {
    $deletions = Get-DeletedEntries -LogPath $DeletedLog -Threshold $TimeThreshold
    Write-Host "Deletion entries in the last $Hours hours: $($deletions.Count)"
    $deletions | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  {0,-19}  {1}" -f $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"), $_.Line)
        Start-Sleep -Seconds 1.5
    }
    if ($deletions.Count -gt 20) {
        Write-Host "  ...and $($deletions.Count - 20) more entries"
    }
}

# -------- Server Log Entries --------
if ($ServerLog) {
    $entries = Get-ServerLogEntries -LogPath $ServerLog -PlayerName $Player -Threshold $TimeThreshold
    $filterText = if ($Player) { " for player `"$Player`"" } else { "" }
    Write-Host "Server log entries$filterText in the last $Hours hours: $($entries.Count)"
    $entries | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  {0,-19}  {1}" -f $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"), $_.Line)
        Start-Sleep -Seconds 1.5
    }
    if ($entries.Count -gt 20) {
        Write-Host "  ...and $($entries.Count - 20) more lines"
    }
}

if (-not $Quiet) { Write-Host "Done." }
