# Made by David
# Cloudsmp.net Cheat finder
# Minecraft Mod Scanner (Launcher-only)
# Passwort: cloudsmp

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

# Launcher Mod-Ordner ONLY (keine Downloads)
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

# --- Header / Loading ---
function Show-Header {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor DarkRed
    Write-Host 'Made by David' -ForegroundColor Red
    Write-Host 'Cloudsmp.net Cheat finder' -ForegroundColor Red
    Write-Host 'Bist du ein Cheater?😒' -ForegroundColor Blue
    Write-Host '==============================================' -ForegroundColor DarkRed
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

# --- Feather FIX ---
function Get-Feather {

    $root = "$env:USERPROFILE\.feather\user-mods"
    if (!(Test-Path $root)) { return $null }

    $versions = Get-ChildItem $root -Directory
    if ($versions.Count -eq 0) { return $null }

    if ($versions.Count -eq 1) {
        $chosen = $versions[0]
    } else {
        Write-Host "`nFeather Versions:" -ForegroundColor Cyan
        for ($i=0;$i -lt $versions.Count;$i++) {
            Write-Host "[$($i+1)] $($versions[$i].Name)"
        }

        $input = Read-Host "Select version"

        if ($input -match '^\d+$') {
            $idx = [int]$input - 1
            if ($idx -ge 0 -and $idx -lt $versions.Count) {
                $chosen = $versions[$idx]
            } else {
                $chosen = $versions[0]
            }
        } else {
            $chosen = $versions | Where-Object { $_.Name -like "$input*" } | Select-Object -First 1
            if (-not $chosen) { $chosen = $versions[0] }
        }
    }

    # 🔥 AUTO DETECT Feather Mods
    $base = $chosen.FullName

    $possiblePaths = @(
        $base,
        "$base\mods",
        "$base\.minecraft\mods"
    )

    foreach ($p in $possiblePaths) {
        if (Test-Path $p) {
            $mods = Get-ChildItem $p -Recurse -Include *.jar -File -ErrorAction SilentlyContinue
            if ($mods.Count -gt 0) {
                Write-Host "Found Feather mods in: $p" -ForegroundColor Green
                return $p
            }
        }
    }

    Write-Host "No Feather mods found!" -ForegroundColor Yellow
    return $base
}

# ================= Main =================
Show-Header
Animate-Loading -Text "Scanning launcher mod folders..."

# Alle Launcher-Ordner + Feather hinzufügen
$allPaths = $LauncherPaths + @(Get-Feather)

$mods         = Get-ModFiles -RootPaths $allPaths
$texturePacks = Get-TexturePacks -RootPaths $allPaths

# -------- Texture Packs --------
Write-Host "TEXTUREPACKS" -ForegroundColor Magenta
if ($texturePacks.Count -eq 0) {
    Write-Host "  Keine Texturepacks gefunden." -ForegroundColor DarkGray
} else {
    $texturePacks | ForEach-Object {
        Write-Host "  $($_.Name)" -ForegroundColor Magenta
        Write-Host "    $($_.Path)" -ForegroundColor DarkGray
    }
}

# -------- Mods --------
Write-Host "`nMODS" -ForegroundColor Cyan
if ($mods.Count -eq 0) {
    Write-Host "  Keine Mods in Launcher-Ordnern gefunden." -ForegroundColor DarkGray
} else {
    $counter = 0
    foreach ($mod in $mods) {
        $color = if (Is-IllegalMod $mod.Name) { 'Red' } else { 'Green' }
        Write-Host ("  {0,-50}" -f $mod.Name) -ForegroundColor $color
        Write-Host ("    {0}" -f $mod.Path) -ForegroundColor DarkGray
        Start-Sleep -Milliseconds 50  # kleine Animation beim Anzeigen
        $counter++
        if ($counter -ge 50) { Write-Host "  ...and $($mods.Count - 50) more mod files" -ForegroundColor Cyan; break }
    }
}

Write-Host "`nScan abgeschlossen." -ForegroundColor Green
