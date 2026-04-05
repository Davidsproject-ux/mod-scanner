# Made by David
# Cloudsmp.net Cheat finder

param(
    [string]$Path = $(Get-Location).Path,
    [double]$Hours = 3.0,
    [string]$ServerLog,
    [string]$Player,
    [string]$DeletedLog,
    [switch]$Quiet
)

$ModExtensions = @('.jar', '.litemod', '.mcpack', '.mcaddon', '.modpack')
$IllegalModNames = @(
    'clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst',
    'baritone','xray','killaura','nuker','velocity','speed','cheat','hack',
    'phobos','forcefield','matrix'
)
$TimeThreshold = (Get-Date).AddHours(-$Hours)

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
    Write-Host 'Minecraft Mod Scanner' -ForegroundColor Green
    Write-Host '==============================================' -ForegroundColor DarkGray
}

function Show-LoadingText {
    $text = 'Loading mods...'
    foreach ($ch in $text.ToCharArray()) {
        Write-Host -NoNewline $ch -ForegroundColor Yellow
        Start-Sleep -Milliseconds 80
    }
    Write-Host ''
    Start-Sleep -Milliseconds 400
    Write-Host 'Done loading.' -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
}

function Get-ModFiles {
    param([string]$RootPath)
    Get-ChildItem -Path $RootPath -Recurse -File |
    Where-Object { $_.Extension -in $ModExtensions } |
    ForEach-Object {
        [PSCustomObject]@{
            Path     = $_.FullName
            Name     = $_.Name
            Modified = $_.LastWriteTime
        }
    } | Sort-Object Modified -Descending
}

function Get-TexturePacks {
    param([string]$RootPath)
    Get-ChildItem -Path $RootPath -Recurse -File |
    Where-Object {
        ($_.Extension -in @('.zip', '.rar')) -and
        ($_.Name -match '(?i)(resource|texture|pack)')
    } |
    ForEach-Object {
        [PSCustomObject]@{
            Path     = $_.FullName
            Name     = $_.Name
            Modified = $_.LastWriteTime
        }
    } | Sort-Object Modified -Descending
}

function Get-DeletedEntries {
    param([string]$LogPath, [DateTime]$Threshold)
    if (-not (Test-Path $LogPath)) {
        Write-Warning "Deleted log file not found: $LogPath"
        return @()
    }
    Get-Content $LogPath | ForEach-Object {
        if ($_ -match '(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}).*(delete|deleted|löschen)') {
            $ts = [DateTime]::Parse($matches[1])
            if ($ts -ge $Threshold) {
                [PSCustomObject]@{
                    Timestamp = $ts
                    Line      = $_
                }
            }
        }
    } | Sort-Object Timestamp -Descending
}

function Get-ServerLogEntries {
    param([string]$LogPath, [string]$PlayerName, [DateTime]$Threshold)
    if (-not (Test-Path $LogPath)) {
        Write-Warning "Server log file not found: $LogPath"
        return @()
    }
    Get-Content $LogPath | ForEach-Object {
        if ($_ -match '(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})') {
            $ts = [DateTime]::Parse($matches[1])
            if ($ts -ge $Threshold -and (-not $PlayerName -or $_.ToLower().Contains($PlayerName.ToLower()))) {
                [PSCustomObject]@{
                    Timestamp = $ts
                    Line      = $_
                }
            }
        }
    } | Sort-Object Timestamp -Descending
}

# ===================== Main =====================

if (-not $Quiet) {
    Show-Header
    Write-Host "Path: $Path" -ForegroundColor White
    Write-Host "Hours: $Hours" -ForegroundColor White
    Write-Host ""
    Show-LoadingText
}

$texturePacks = Get-TexturePacks -RootPath $Path
$mods         = Get-ModFiles -RootPath $Path

# -------- Texture Packs --------
Write-Host "TEXTUREPACKS" -ForegroundColor Magenta
$texturePacks | Select-Object -First 20 | ForEach-Object {
    Write-Host "  $($_.Name)" -ForegroundColor Magenta
    Write-Host "    $($_.Path)" -ForegroundColor DarkGray
}

# -------- Mods --------
Write-Host "MODS" -ForegroundColor Cyan
$mods | Select-Object -First 50 | ForEach-Object {
    $color = if (Is-IllegalMod $_.Name) { 'Red' } else { 'Green' }
    Write-Host "  $($_.Name)" -ForegroundColor $color
    Write-Host "    $($_.Path)" -ForegroundColor DarkGray
}

# -------- Deleted Entries --------
if ($DeletedLog) {
    $deletions = Get-DeletedEntries -LogPath $DeletedLog -Threshold $TimeThreshold
    Write-Host "Deletion entries in the last $Hours hours: $($deletions.Count)"
    $deletions | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  {0,-19}  {1}" -f $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"), $_.Line)
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
    }
    if ($entries.Count -gt 20) {
        Write-Host "  ...and $($entries.Count - 20) more lines"
    }
}

if (-not $Quiet) { Write-Host "Done." }
