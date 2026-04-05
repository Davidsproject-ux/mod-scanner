# Cloudsmp Mod Scanner (Stable)

# Passwort
if ((Read-Host "Enter password") -ne "cloudsmp") {
    Write-Host "Wrong password" -ForegroundColor Red
    exit
}

# Config
$ext = @('.jar','.litemod','.mcpack','.mcaddon','.modpack')
$bad = @('meteor','impact','wurst','aristois','liquidbounce','xray','killaura','hack','cheat','baritone')

# Paths
$paths = @{
    "Vanilla" = "$env:APPDATA\.minecraft\mods"
    "Feather" = "$env:USERPROFILE\.feather\user-mods"
    "Prism"   = "$env:APPDATA\PrismLauncher\instances"
}

function Scan($p) {
    if (!(Test-Path $p)) { return @() }
    Get-ChildItem $p -Recurse -File | Where {$_.Extension -in $ext}
}

function Check($n) {
    $l = $n.ToLower()
    foreach ($b in $bad) {
        if ($l -like "*$b*") { return $true }
    }
    return $false
}

function Feather() {
    $root = "$env:USERPROFILE\.feather\user-mods"
    if (!(Test-Path $root)) { return $null }

    $v = Get-ChildItem $root -Directory
    if ($v.Count -eq 0) { return $null }

    if ($v.Count -eq 1) { return $v[0].FullName }

    Write-Host "Feather Versions:" -ForegroundColor Cyan
    for ($i=0;$i -lt $v.Count;$i++) {
        Write-Host "[$($i+1)] $($v[$i].Name)"
    }

    $c = Read-Host "Select"
    if ($c -match '^\d+$') {
        return $v[[int]$c-1].FullName
    }

    return $v[0].FullName
}

function Select($root,$sub) {
    if (!(Test-Path $root)) { return $null }
    $v = Get-ChildItem $root -Directory
    if ($v.Count -eq 0) { return $null }
    if ($v.Count -eq 1) { return "$($v[0].FullName)\$sub" }

    for ($i=0;$i -lt $v.Count;$i++) {
        Write-Host "[$($i+1)] $($v[$i].Name)"
    }

    $c = Read-Host "Select"
    if ($c -match '^\d+$') {
        return "$($v[[int]$c-1].FullName)\$sub"
    }

    return "$($v[0].FullName)\$sub"
}

# Start
Write-Host "Scanning..." -ForegroundColor Yellow

foreach ($k in $paths.Keys) {

    $p = $null

    if ($k -eq "Feather") { $p = Feather }
    elseif ($k -eq "Prism") { $p = Select $paths[$k] "minecraft\mods" }
    else { $p = $paths[$k] }

    Write-Host "`n$k:" -ForegroundColor Cyan

    if (!$p -or !(Test-Path $p)) {
        Write-Host "No mods" -ForegroundColor Yellow
        continue
    }

    $mods = Scan $p
    if ($mods.Count -eq 0) {
        Write-Host "No mods" -ForegroundColor Yellow
        continue
    }

    foreach ($m in $mods) {
        if (Check $m.Name) {
            Write-Host $m.Name -ForegroundColor Red
        } else {
            Write-Host $m.Name -ForegroundColor Green
        }
    }

    Write-Host "$($mods.Count) mods" -ForegroundColor DarkGray
}

Write-Host "Done" -ForegroundColor Green
