$ErrorActionPreference = 'Stop'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$path = Join-Path $root 'lib\features\lessons\lesson_discover_screen.dart'
$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)

# Delete _ModeTile class (last block) and the now-unused _generate method.
# Work from the bottom up so earlier indices stay valid.
$modeTileStart = -1
for ($i = 0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match '^class _ModeTile ') { $modeTileStart = $i; break }
}
if ($modeTileStart -lt 0) { throw '_ModeTile not found' }
# Drop the blank line before the class too.
$new = @()
$new += $lines[0..($modeTileStart - 2)]

$genStart = -1
for ($i = 0; $i -lt $new.Length; $i++) {
  if ($new[$i] -match 'Future<void> _generate\(') { $genStart = $i; break }
}
if ($genStart -lt 0) { throw '_generate not found' }
# Find its closing brace at indent 2.
$genEnd = -1
for ($i = $genStart; $i -lt $new.Length; $i++) {
  if ($new[$i] -eq '  }') { $genEnd = $i; break }
}
if ($genEnd -lt 0) { throw '_generate end not found' }
Write-Output ("Removing _generate lines {0}..{1}" -f ($genStart + 1), ($genEnd + 1))
Write-Output ("Removing _ModeTile lines {0}..end" -f ($modeTileStart + 1))

$final = @()
$final += $new[0..($genStart - 1)]
$final += $new[($genEnd + 1)..($new.Length - 1)]
[System.IO.File]::WriteAllLines($path, $final, (New-Object System.Text.UTF8Encoding($false)))
Write-Output 'OK'
