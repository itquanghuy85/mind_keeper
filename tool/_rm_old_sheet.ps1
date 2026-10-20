$ErrorActionPreference = 'Stop'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$path = Join-Path $root 'lib\features\lessons\lesson_discover_screen.dart'
$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)

# Remove the leftover old bottom-sheet block: lines 72..188 (1-based).
$from = 72
$to = 188
Write-Output ("Removing lines {0}..{1}" -f $from, $to)
Write-Output ("  first: " + $lines[$from - 1])
Write-Output ("  last : " + $lines[$to - 1])

$new = @()
$new += $lines[0..($from - 2)]
$new += $lines[$to..($lines.Length - 1)]
[System.IO.File]::WriteAllLines($path, $new, (New-Object System.Text.UTF8Encoding($false)))
Write-Output 'OK'
