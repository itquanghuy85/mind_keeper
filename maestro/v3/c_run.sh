#!/usr/bin/env bash
# Nghiệm thu C — Quick capture từ share sheet Android (cold + warm start).
#   bash maestro/v3/c_run.sh [serial]
# Mỗi bước: bắn intent ACTION_SEND text/plain vào MainActivity rồi chạy flow Maestro.
set -u
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/../.."
export PATH="/c/job/toolchain/maestro/maestro/bin:/c/job/toolchain/java/jdk-17.0.20.1+1/bin:$PATH"
export JAVA_HOME="${JAVA_HOME:-C:/job/toolchain/java/jdk-17.0.20.1+1}"
export JAVA_OPTS='-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8'
PKG=com.mindkeeper.mind_keeper
S="${1:-$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')}"
OUT="${OUT_DIR:-build/scratch_db/_m}"
LOG="${LOG_DIR:-DOCS/QA/evidence/v3}"
share() { adb -s "$S" shell "am start -a android.intent.action.SEND -t text/plain --es android.intent.extra.TEXT '$1' --es android.intent.extra.SUBJECT '$2' -n $PKG/.MainActivity" >/dev/null; }
run() { maestro --device "$S" test --test-output-dir "$OUT" "maestro/v3/$1.yaml" > "$LOG/maestro_$1${2:-}.log" 2>&1; echo "$1${2:-} exit=$?"; }
warm() { adb -s "$S" shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; sleep 25; }
adb -s "$S" shell input keyevent 224; adb -s "$S" shell input swipe 540 2000 540 800
echo "== WARM: văn bản (app đang chạy)"; warm; share 'Ti thể là nhà máy năng lượng của tế bào. Nó có DNA riêng.' ''; run c_save _warm
echo "== WARM: trùng lặp (cùng văn bản)"; share 'Ti thể là nhà máy năng lượng của tế bào. Nó có DNA riêng.' ''; run c_dup _warm
echo "== WARM: Mở đầy đủ (văn bản)"; share 'Ti thể là nhà máy năng lượng của tế bào. Nó có DNA riêng.' ''; run c_open_text
echo "== COLD: link (app bị giết)"; adb -s "$S" shell am force-stop $PKG; share 'Đọc thêm về giấc ngủ https://example.com/giac-ngu-cold' 'Giấc ngủ cold start'; run c_save _cold
echo "== COLD: trùng link (app bị giết)"; adb -s "$S" shell am force-stop $PKG; share 'Nội dung khác nhưng cùng link https://example.com/giac-ngu-cold' ''; run c_dup _cold
echo "== WARM: Mở đầy đủ (link)"; warm; share 'https://example.com/mo-day-du' ''; run c_open_link
rm -f "$TEMP"/tmp*.apk
