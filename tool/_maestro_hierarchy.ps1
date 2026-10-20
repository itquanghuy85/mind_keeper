$ErrorActionPreference = 'Continue'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$base = 'C:\Users\Mr Huy\.maestro\tests'
$run = Get-ChildItem $base -Directory | Sort-Object Name -Descending | Select-Object -First 1
Write-Output ("run = " + $run.FullName)
$path = $null
if ($args.Count -gt 0 -and (Test-Path $args[0])) { $path = $args[0] }
else {
  $f = Get-ChildItem $run.FullName -Recurse -Filter '*.json' |
       Where-Object { $_.DirectoryName -like '*screen-hierarchy*' } |
       Sort-Object Name | Select-Object -First 1
  if ($f) { $path = $f.FullName }
}
if (-not $path) { Write-Output 'NO HIERARCHY FILE'; exit 1 }
Write-Output ("file = " + $path)
$j = Get-Content $path -Raw -Encoding utf8 | ConvertFrom-Json
$found = New-Object System.Collections.ArrayList
function Walk($node) {
  if ($null -eq $node) { return }
  $a = $node.attributes
  if ($a) {
    $label = $null
    foreach ($k in @('text','content-desc','accessibilityText','label','title','name','hint','value')) {
      $v = $a.$k
      if ($v -and $v -ne '' -and $v -ne 'false' -and $v -ne 'true') { $label = "$k=$v"; break }
    }
    if ($label) {
      [void]$found.Add(("{0} | {1} | {2}" -f $a.class, $a.bounds, $label))
    }
  }
  if ($node.children) { foreach ($c in $node.children) { Walk $c } }
}
Walk $j
Write-Output ("nodes with label = " + $found.Count)
$found | Select-Object -First 60 | ForEach-Object { Write-Output $_ }
