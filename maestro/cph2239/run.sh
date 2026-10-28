#!/usr/bin/env bash
# Chạy flow smoke Maestro trên CPH2239 qua USB.
#   bash maestro/cph2239/run.sh [serial]
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
adb -s "$SERIAL" shell input swipe 540 2000 540 800
sleep 1
maestro --device "$SERIAL" test "01_smoke.yaml"
echo "exit=$?"
