# Made by David
# Cloudsmp.net

param(
    [string]$Path = "$env:APPDATA\.minecraft",
    [double]$Hours = 3.0,
    [string]$ServerLog,
    [string]$Player,
    [string]$DeletedLog,
    [switch]$Quiet
)

$ModExtensions = @('.jar', '.litemod', '.zip', '.mcpack', '.mcaddon', '.modpack')
$TimeThreshold = (Get-Date).AddHours(-$Hours)

function Get-ModFiles {
    param([string]$RootPath)
    $mods = @()
    Get-ChildItem -Path $RootPath -Recurse -File | Where-Object {
        $_.Extension -in $ModExtensions
    } | ForEach-Object {
        $modTime = $_.LastWriteTime
        $mods += [PSCustomObject]@{
            Path = $_.FullName
            Modified = $modTime
        }
    }
    return $mods
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
    Write-Host "Minecraft Mod Scanner starting..."
    Write-Host "Path: $Path"
    Write-Host "Hours: $Hours"
    Write-Host ""
}

$mods = Get-ModFiles -RootPath $Path
Write-Host "Found mod files: $($mods.Count)"
$mods | Sort-Object Modified -Descending | Select-Object -First 20 | ForEach-Object {
    Write-Host ("  {0,-19}  {1}" -f $_.Modified.ToString("yyyy-MM-dd HH:mm:ss"), $_.Path)
}
if ($mods.Count -gt 20) {
    Write-Host "  ...and $($mods.Count - 20) more mod files"
}
Write-Host ""

$recent = Get-RecentChanges -RootPath $Path -Threshold $TimeThreshold
Write-Host "Recent changes within $Hours hours: $($recent.Count)"
$recent | Select-Object -First 20 | ForEach-Object {
    Write-Host ("  {0,-19}  {1}" -f $_.Modified.ToString("yyyy-MM-dd HH:mm:ss"), $_.Path)
}
if ($recent.Count -gt 20) {
    Write-Host "  ...and $($recent.Count - 20) more files"
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
