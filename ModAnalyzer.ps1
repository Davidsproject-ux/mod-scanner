# --- Header / Loading ---
function Show-Header {
    Clear-Host
    Write-Host '==============================================' -ForegroundColor DarkRed
    Write-Host 'Made by David' -ForegroundColor Red
    Write-Host 'Cloudsmp.net Cheat finder' -ForegroundColor Red
    Write-Host 'Bist du ein Cheater?😒' -ForegroundColor Blue
    Write-Host '==============================================' -ForegroundColor DarkRed
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
