# Helper nghiem thu (ADB + uiautomator) - dung tam thoi, KHONG commit
$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Get-UiText {
    param([string]$Tag = 'ui')
    $stamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $remote = "/sdcard/$Tag`_$stamp.xml"
    adb shell uiautomator dump $remote 2>&1 | Out-Null
    $local = Join-Path $PSScriptRoot "nghiemthu_$Tag`_$stamp.xml"
    adb shell cat $remote 2>&1 | Out-Null
    adb pull $remote $local 2>&1 | Out-Null
    $raw = [System.IO.File]::ReadAllText($local, [System.Text.Encoding]::UTF8)
    $texts = [regex]::Matches($raw, 'text="([^"]*)"') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_.Length -gt 0 }
    $descs = [regex]::Matches($raw, 'content-desc="([^"]*)"') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_.Length -gt 0 }
    $all = @($texts) + @($descs)
    $all | ForEach-Object { ($_ -replace '&#10;', "`n") -replace '&amp;', '&' }
}

function Find-UiNode {
    param([string]$Pattern, [string]$Tag = 'ui')
    $stamp = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $remote = "/sdcard/$Tag`_$stamp.xml"
    adb shell uiautomator dump $remote 2>&1 | Out-Null
    $local = Join-Path $PSScriptRoot "nghiemthu_$Tag`_$stamp.xml"
    adb pull $remote $local 2>&1 | Out-Null
    $raw = [System.IO.File]::ReadAllText($local, [System.Text.Encoding]::UTF8)
    foreach ($m in [regex]::Matches($raw, '<node[^>]*>')) {
        $n = $m.Value
        $d = [regex]::Match($n, 'content-desc="([^"]*)"')
        $t = [regex]::Match($n, 'text="([^"]*)"')
        $b = [regex]::Match($n, 'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"')
        $label = if ($d.Groups[1].Value.Length -gt 0) { $d.Groups[1].Value } else { $t.Groups[1].Value }
        if ($label -match $Pattern -and $b.Success) {
            $x = ([int]$b.Groups[1].Value + [int]$b.Groups[3].Value) / 2
            $y = ([int]$b.Groups[2].Value + [int]$b.Groups[4].Value) / 2
            return [pscustomobject]@{ Label = $label; X = [int]$x; Y = [int]$y }
        }
    }
    return $null
}

function Tap-Ui {
    param([string]$Pattern, [int]$WaitMs = 1200)
    $n = Find-UiNode -Pattern $Pattern
    if ($null -eq $n) { Write-Output "NOT_FOUND: $Pattern"; return $false }
    Write-Host "TAP: $($n.Label) @ $($n.X),$($n.Y)"
    adb shell input tap $n.X $n.Y | Out-Null
    Start-Sleep -Milliseconds $WaitMs
    return $true
}

function Get-LogErrors {
    param([int]$Lines = 300)
    adb logcat -d -t $Lines 2>&1 | Select-String -Pattern 'FATAL|E/flutter|AndroidRuntime.*Exception|overflow|Exception caught by|════' | ForEach-Object { $_.Line }
}
