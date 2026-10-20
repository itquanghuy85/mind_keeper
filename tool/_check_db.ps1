$ErrorActionPreference = 'Continue'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$bytes = [System.IO.File]::ReadAllBytes((Join-Path $root 'device.db'))
$text = [System.Text.Encoding]::UTF8.GetString($bytes)
$fffd = [char]0xFFFD

# Vietnamese diacritics + letters used in real text
$viet = 'a-zA-Zàáâãèéêìíòóôõùúýăđĩũơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ'

$corrupt = 0
$clean = 0
$examples = @()
$idx = 0
while ($true) {
  $i = $text.IndexOf($fffd, $idx)
  if ($i -lt 0) { break }
  $s = [Math]::Max(0, $i - 30)
  $e = [Math]::Min($text.Length, $i + 31)
  $near = $text.Substring($s, $e - $s)
  # real corruption => neighbouring chars are Vietnamese letters, not NUL/binary
  $isText = $near -match "[$viet]"
  if ($isText) {
    $corrupt++
    if ($examples.Count -lt 10) {
      $out = ''
      foreach ($ch in $near.ToCharArray()) {
        $c = [int]$ch
        if ($c -lt 32 -or $c -gt 126) { $out += ('\u{0:X4}' -f $c) } else { $out += $ch }
      }
      $examples += ("@{0}: {1}" -f $i, $out)
    }
  } else { $clean++ }
  $idx = $i + 1
}
Write-Output ("FFFD in Vietnamese-text context = {0}  <-- must be 0" -f $corrupt)
Write-Output ("FFFD in binary/NUL context      = {0}  (SQLite page structure, harmless)" -f $clean)
foreach ($e in $examples) { Write-Output $e }

Write-Output ''
Write-Output '=== lesson text integrity: full paragraph of each new lesson ==='
foreach ($n in @('Nguyên tử và phân tử', 'Thuyết tiến hóa', 'Vũ trụ và các thiên hà')) {
  $i = $text.IndexOf($n)
  if ($i -lt 0) { Write-Output ("NOT FOUND: " + $n); continue }
  $s = [Math]::Max(0, $i)
  $e = [Math]::Min($text.Length, $i + 700)
  $seg = $text.Substring($s, $e - $s)
  # cut at first control char
  $cut = $seg.IndexOf([char]0)
  if ($cut -gt 0) { $seg = $seg.Substring(0, $cut) }
  Write-Output ("--- " + $seg)
}
