# Helper chạy flutter test trên Windows — workaround bug Flutter 3.41.4:
# flutter_tools crash errno 183 (PathExistsException) khi copy sqlite3.dll
# lên build/native_assets vì file đã tồn tại từ lần chạy trước.
# Fix: kill flutter_tester treo + xóa build/native_assets trước mỗi lần chạy.
# Usage: pwsh -File tool/run_flutter_test.ps1 [args...]
#   vd:  pwsh -File tool/run_flutter_test.ps1 test/core/review_notification_sync_test.dart

$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent

Get-Process flutter_tester -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1
Remove-Item (Join-Path $root 'build\native_assets') -Recurse -Force -ErrorAction SilentlyContinue

Set-Location $root
& flutter test @args
exit $LASTEXITCODE
