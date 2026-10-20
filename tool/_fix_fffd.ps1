$ErrorActionPreference = 'Stop'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$mapPath = Join-Path $root 'tool\_fffd_map.txt'

# Map format (UTF-8, one record per line):
#   <relative dart path>|<1-based line number>|<replacement text>
# A replacement text of "__DELETE__" removes the line.

$records = [System.IO.File]::ReadAllLines($mapPath, [System.Text.Encoding]::UTF8)
$byFile = @{}
foreach ($rec in $records) {
  if ([string]::IsNullOrWhiteSpace($rec)) { continue }
  $parts = $rec -split '\|', 3
  if ($parts.Count -lt 3) { throw "bad record: $rec" }
  $f = $parts[0]
  $n = [int]$parts[1]
  $text = $parts[2]
  if (-not $byFile.ContainsKey($f)) { $byFile[$f] = @{} }
  $byFile[$f][$n] = $text
}

foreach ($f in $byFile.Keys) {
  $path = Join-Path $root $f
  $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
  $new = @()
  for ($i = 0; $i -lt $lines.Length; $i++) {
    $ln = $i + 1
    if ($byFile[$f].ContainsKey($ln)) {
      $rep = $byFile[$f][$ln]
      if ($rep -ne '__DELETE__') { $new += $rep }
      Write-Output ("{0}:{1} replaced" -f $f, $ln)
    } else {
      $new += $lines[$i]
    }
  }
  [System.IO.File]::WriteAllLines($path, $new, (New-Object System.Text.UTF8Encoding($false)))
}
Write-Output 'DONE'
