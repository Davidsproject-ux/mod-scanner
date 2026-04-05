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
$IllegalModNames = @('clickcrystal','meteor','impact','future','aristois','liquidbounce','wurst','baritone','xray','killaura','nuker','velocity','speed','cheat','hack','phobos','forcefield','matrix')
$TimeThreshold = (Get-Date).AddHours(-$Hours)

function Is-IllegalMod {
    param([string]$Name)
    $lower = $Name.ToLower()
    foreach ($keyword in $IllegalModNames) {
        if ($lower -like "*${keyword}*") {
            return $true
        }
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
    Write-Host 'Loading mods...' -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    Write-Host 'Done loading.' -ForegroundColor Green
    Write-Host '----------------------------------------------' -ForegroundColor DarkGray
}

function Get-ModFiles {
    param([string]$RootPath)
    $mods = Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
        $_.Extension -in $ModExtensions
    } | ForEach-Object {
        [PSCustomObject]@{
            Path = $_.FullName
            Modified = $_.LastWriteTime
            Name = $_.Name
        }
    }
    return $mods | Sort-Object Modified -Descending
}

function Get-RecentChanges {
    param([string]$RootPath, [DateTime]$Threshold)
    $changes = @()
    Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
        $_.LastWriteTime -ge $Threshold
    } | ForEach-Object {
        $changes += [PSCustomObject]@{
            Path = $_.FullName
            Modified = $_.LastWriteTime
        }
    }
    return $changes | Sort-Object Modified -Descending
}

function Get-TexturePacks {
    param([string]$RootPath)
    $packs = @()
    Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
        ($_.Extension -in @('.zip', '.rar')) -and
        ($_.Name -match '(?i)(resource|texture|pack)')
    } | ForEach-Object {
        $packs += [PSCustomObject]@{
            Path = $_.FullName
            Modified = $_.LastWriteTime
        }
    }
    return $packs | Sort-Object Modified -Descending
}

function Get-RecentlyOpenedFiles {
    param([string]$RootPath, [DateTime]$Threshold)
    $opened = @()
    Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
        $_.LastAccessTime -ge $Threshold
    } | ForEach-Object {
        $opened += [PSCustomObject]@{
            Path = $_.FullName
            Accessed = $_.LastAccessTime
        }
    }
    return $opened | Sort-Object Accessed -Descending
}

function Get-DeletedEntries {
    param([string]$LogPath, [DateTime]$Threshold)
    if (-not (Test-Path $LogPath)) {
        Write-Warning "Deleted log file not found: $LogPath"
        return @()
    }
    $deletions = @()
    Get-Content $LogPath | ForEach-Object {
        if ($_ -match '(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}).*(delete|deleted|löschen)') {
            $ts = [DateTime]::Parse($matches[1])
            if ($ts -ge $Threshold) {
                $deletions += [PSCustomObject]@{
                    Timestamp = $ts
                    Line = $_
                }
            }
        }
    }
    return $deletions | Sort-Object Timestamp -Descending
}

function Get-ServerLogEntries {
    param([string]$LogPath, [string]$PlayerName, [DateTime]$Threshold)
    if (-not (Test-Path $LogPath)) {
        Write-Warning "Server log file not found: $LogPath"
        return @()
    }
    $entries = @()
    Get-Content $LogPath | ForEach-Object {
        if ($_ -match '(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2})') {
            $ts = [DateTime]::Parse($matches[1])
            if ($ts -ge $Threshold -and (-not $PlayerName -or $_.ToLower().Contains($PlayerName.ToLower()))) {
                $entries += [PSCustomObject]@{
                    Timestamp = $ts
                    Line = $_
                }
            }
        }
    }
    return $entries | Sort-Object Timestamp -Descending
}

if (-not $Quiet) {
    Show-Header
    Write-Host "Path: $Path" -ForegroundColor White
    Write-Host "Hours: $Hours" -ForegroundColor White
    Write-Host ""
    Show-LoadingText
    Write-Host "Scanning path: $Path" -ForegroundColor Green
    Write-Host "=============================================="
    Write-Host ""
}

$texturePacks = Get-TexturePacks -RootPath $Path
$mods = Get-ModFiles -RootPath $Path
$recent = Get-RecentlyOpenedFiles -RootPath $Path -Threshold (Get-Date).AddHours(-2)

Write-Host "TEXTUREPACKS" -ForegroundColor Magenta
Write-Host '----------------------------------------------' -ForegroundColor DarkGray
$texturePacks | Select-Object -First 20 | ForEach-Object {
    Write-Host ("  {0,-19}  {1}" -f $_.Modified.ToString("yyyy-MM-dd HH:mm:ss"), $_.Path) -ForegroundColor Magenta
}
if ($texturePacks.Count -gt 20) {
    Write-Host "  ...and $($texturePacks.Count - 20) more texturepack files" -ForegroundColor Magenta
}
Write-Host ""

Write-Host "MODS" -ForegroundColor Cyan
Write-Host '----------------------------------------------' -ForegroundColor DarkGray
$mods | Select-Object -First 50 | ForEach-Object {
    $color = if (Is-IllegalMod $_.Name) { 'Red' } else { 'Green' }
    Write-Host ("  {0,-19}  {1}" -f $_.Modified.ToString("yyyy-MM-dd HH:mm:ss"), $_.Path) -ForegroundColor $color
}
if ($mods.Count -gt 50) {
    Write-Host "  ...and $($mods.Count - 50) more mod files" -ForegroundColor Cyan
}
Write-Host ""

Write-Host "ZU LETZT GEÖFFNETE DATEIEN (letzte 2 Stunden)" -ForegroundColor Yellow
Write-Host '----------------------------------------------' -ForegroundColor DarkGray
$recent | Select-Object -First 20 | ForEach-Object {
    Write-Host ("  {0,-19}  {1}" -f $_.Accessed.ToString("yyyy-MM-dd HH:mm:ss"), $_.Path) -ForegroundColor Yellow
}
if ($recent.Count -gt 20) {
    Write-Host "  ...and $($recent.Count - 20) more files" -ForegroundColor Yellow
}
Write-Host ""

if ($DeletedLog) {
    $deletions = Get-DeletedEntries -LogPath $DeletedLog -Threshold $TimeThreshold
    Write-Host "Deletion entries in the last $Hours hours: $($deletions.Count)"
    $deletions | Select-Object -First 20 | ForEach-Object {
        Write-Host ("  {0,-19}  {1}" -f $_.Timestamp.ToString("yyyy-MM-dd HH:mm:ss"), $_.Line)
    }
    if ($deletions.Count -gt 20) {
        Write-Host "  ...and $($deletions.Count - 20) more entries"
    }
    Write-Host ""
}

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
    Write-Host ""
}

if (-not $Quiet) {
    Write-Host "Done."
}
