$ErrorActionPreference = 'Stop'
$root = 'D:\JOB\mind_kepper\mind_keeper'
$path = Join-Path $root 'lib\features\ai\mock_ai_provider.dart'
$blockPath = Join-Path $root 'tool\_mock_suggest_topics.txt'

$lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
$block = [System.IO.File]::ReadAllLines($blockPath, [System.Text.Encoding]::UTF8)

$start = -1
for ($i = 0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match 'Future<List<AiTopicSuggestion>> suggestTopics') { $start = $i; break }
}
if ($start -lt 0) { throw 'suggestTopics not found' }
# The @override line sits directly above the signature.
if ($lines[$start - 1].Trim() -ne '@override') { throw 'unexpected layout' }

$end = -1
for ($i = $start; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -eq '  }') { $end = $i; break }
}
if ($end -lt 0) { throw 'method end not found' }
Write-Output ("Replacing lines {0}..{1}" -f ($start - 1), ($end + 1))

$new = @()
$new += $lines[0..($start - 2)]
$new += $block
$new += $lines[($end + 1)..($lines.Length - 1)]

[System.IO.File]::WriteAllLines($path, $new, (New-Object System.Text.UTF8Encoding($false)))
Write-Output 'OK'
