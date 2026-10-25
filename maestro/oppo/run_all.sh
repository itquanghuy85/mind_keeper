#!/usr/bin/env bash
# Chạy toàn bộ test Maestro trên OPPO qua USB.
#   bash maestro/oppo/run_all.sh [serial]
# Mặc định lấy serial đầu tiên trong `adb devices`. Không xóa dữ liệu máy.
set -u
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")"
# Maestro CLI that cai o C:/job/toolchain/maestro (goi npm "maestro" trong PATH la ban hong).
export PATH="/c/job/toolchain/maestro/maestro/bin:/c/job/toolchain/java/jdk-17.0.20.1+1/bin:$PATH"
export JAVA_HOME="${JAVA_HOME:-C:/job/toolchain/java/jdk-17.0.20.1+1}"
PKG=com.mindkeeper.mind_keeper
SERIAL="${1:-$(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}')}"
[ -z "$SERIAL" ] && { echo "Không thấy máy. Bật Tùy chọn nhà phát triển → Gỡ lỗi USB."; exit 2; }
export ANDROID_SERIAL="$SERIAL"
QUICK_ID="${QUICK_ID:-ki_1792508769543576683}"   # kiến thức "Cơ bản về Lich Su Va"
echo "Thiết bị: $SERIAL"
adb shell input keyevent 224; adb shell input swipe 540 2000 540 800   # đánh thức máy
fail=0
for f in 01_home 02_topics 03_review; do
  maestro --device "$SERIAL" test $f.yaml || fail=1
done
# Flow 4: mô phỏng chạm thông báo bằng adb (app đã tắt = cold start).
adb shell am force-stop $PKG
adb shell am start -n $PKG/.MainActivity -a SELECT_NOTIFICATION --es payload "quick:$QUICK_ID" >/dev/null
maestro --device "$SERIAL" test 04_notification_quick.yaml || fail=1
exit $fail
