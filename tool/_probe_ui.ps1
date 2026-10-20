param([string]$Out = 'ui_probe.xml', [switch]$NoLaunch)
$ErrorActionPreference = 'Continue'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$pkg = 'com.mindkeeper.mind_keeper'

# Wake up + dismiss keyguard (no PIN on test device)
adb shell input keyevent KEYCODE_WAKEUP | Out-Null
Start-Sleep -Seconds 1
adb shell wm dismiss-keyguard | Out-Null
adb shell input swipe 540 1800 540 400 300 | Out-Null
Start-Sleep -Seconds 2

if (-not $NoLaunch) {
  adb shell am force-stop $pkg | Out-Null
  adb shell am start -n $pkg/.MainActivity | Out-Null
  Start-Sleep -Seconds 9
}
adb shell uiautomator dump /sdcard/probe.xml | Out-Null
adb pull /sdcard/probe.xml (Join-Path $root $Out) | Out-Null

$path = Join-Path $root $Out
if (-not (Test-Path $path)) { Write-Output 'DUMP FAILED'; exit 1 }
$xml = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
$nodes = [regex]::Matches($xml, '<node[^>]*>')
foreach ($n in $nodes) {
  $s = $n.Value
  $text = ''
  if ($s -match 'text="([^"]*)"') { $text = $Matches[1] }
  $desc = ''
  if ($s -match 'content-desc="([^"]*)"') { $desc = $Matches[1] }
  $cls = ''
  if ($s -match 'class="([^"]*)"') { $cls = $Matches[1] }
  $clickable = ''
  if ($s -match 'clickable="([^"]*)"') { $clickable = $Matches[1] }
  $bounds = ''
  if ($s -match 'bounds="([^"]*)"') { $bounds = $Matches[1] }
  if ($text -ne '' -or $desc -ne '') {
    $label = if ($text -ne '') { $text } else { $desc }
    Write-Output ("[{0}] clickable={1} bounds={2} :: {3}" -f $cls, $clickable, $bounds, $label)
  }
}
