$ErrorActionPreference = 'Continue'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$log = Join-Path $root 'logcat_dump.txt'
$pat = 'nguyên tử|Thuyết tiến hóa|Vũ trụ|lesson|Lesson|bài học'
$hits = Select-String -Path $log -Pattern $pat -Encoding utf8 | Select-Object -Last 30
foreach ($h in $hits) { Write-Output $h.Line }
Write-Output '--- FFFD check ---'
$fffd = Select-String -Path $log -Pattern ([char]0xFFFD) -Encoding utf8 | Select-Object -Last 10
Write-Output ("FFFD lines = " + ($fffd | Measure-Object).Count)
