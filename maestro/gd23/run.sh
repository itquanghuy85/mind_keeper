#!/usr/bin/env bash
# Chạy các flow Maestro GĐ23 trên thiết bị qua USB.
#   bash maestro/gd23/run.sh [serial] [flow ...]
# Không xóa dữ liệu máy. Cần: mock AI server + adb reverse (xem 02_add_course.yaml).
# Flow 04 cần ITEM_ID (course_items.id của mẩu đã có nội dung).
set -u
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
export PATH="/c/job/toolchain/maestro/maestro/bin:/c/job/toolchain/java/jdk-17.0.20.1+1/bin:$PATH"
export JAVA_HOME="${JAVA_HOME:-C:/job/toolchain/java/jdk-17.0.20.1+1}"
export JAVA_OPTS='-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8'
PKG=com.mindkeeper.mind_keeper
SERIAL="${1:-$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')}"
shift || true
[ -z "$SERIAL" ] && { echo "Không thấy máy."; exit 2; }
export ANDROID_SERIAL="$SERIAL"
adb -s "$SERIAL" shell input keyevent 224
sleep 1
adb -s "$SERIAL" shell input swipe 540 2000 540 800   # mở khóa (vuốt, máy không đặt mã)
sleep 1
FLOWS=("$@")
[ ${#FLOWS[@]} -eq 0 ] && FLOWS=(01_home_redesign 02_add_course 03_read_course_item)
fail=0
for f in "${FLOWS[@]}"; do
  echo "=== $f"
  if [ "$f" = "04_notification_course" ]; then
    [ -z "${ITEM_ID:-}" ] && { echo "Thiếu ITEM_ID"; fail=1; continue; }
    adb -s "$SERIAL" shell am force-stop $PKG
    adb -s "$SERIAL" shell am start -n $PKG/.MainActivity -a SELECT_NOTIFICATION --es payload "course:$ITEM_ID" >/dev/null
  fi
  EXTRA=()
  [ -n "${OUT_DIR:-}" ] && EXTRA=(--test-output-dir "$OUT_DIR")
  maestro --device "$SERIAL" test "${EXTRA[@]}" "$f.yaml" || fail=1
done
exit $fail
