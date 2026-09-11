#!/usr/bin/env bash
# 构建 rotate180 RRO APK 并打包为 KernelSU / Magisk 模块 zip。
# 支持 Windows (Git Bash) / Linux 双平台。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

# ---------- 平台 ----------
EXE=""
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) EXE=".exe";; esac
path_fix() {
    if [ "$EXE" = ".exe" ]; then cygpath -m "$1"; else printf '%s' "$1"; fi
}

# ---------- Android SDK ----------
SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [ -z "$SDK" ] || [ ! -d "$SDK/build-tools" ]; then
    for c in "${LOCALAPPDATA:-}/Android/Sdk" "$HOME/Android/Sdk" \
        /usr/local/lib/android/sdk; do
        [ -d "$c/build-tools" ] && { SDK="$c"; break; }
    done
fi
[ -d "$SDK/build-tools" ] || { echo "错误: 未找到 Android SDK，请设置 ANDROID_SDK_ROOT" >&2; exit 1; }

# ---------- Java ----------
JAVA=""
if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java$EXE" ]; then
    JAVA="$JAVA_HOME/bin/java$EXE"
elif command -v java >/dev/null 2>&1; then
    JAVA="$(command -v java)"
elif [ -x "/c/Program Files/Android/Android Studio/jbr/bin/java.exe" ]; then
    JAVA="/c/Program Files/Android/Android Studio/jbr/bin/java.exe"
fi
[ -n "$JAVA" ] || { echo "错误: 未找到 java" >&2; exit 1; }
JAVA="$(path_fix "$JAVA")"

# ---------- 选工具 ----------
BT_DIR="$(ls -1 "$SDK/build-tools" | while read -r n; do [ -d "$SDK/build-tools/$n" ] && echo "$n"; done | sort -V | tail -n1)"
API=""
for p in $(ls -1 "$SDK/platforms" | sed -n 's/^android-\([0-9][0-9.]*\)$/\1/p' | sort -rn); do
    [ -f "$SDK/platforms/android-$p/android.jar" ] && { API="$p"; break; }
done
[ -n "$API" ] || { echo "错误: 没有可用的 android.jar" >&2; exit 1; }

AAPT2="$(path_fix "$SDK/build-tools/$BT_DIR/aapt2$EXE")"
ZIPALIGN="$(path_fix "$SDK/build-tools/$BT_DIR/zipalign$EXE")"
APKSIGNER_JAR="$(path_fix "$SDK/build-tools/$BT_DIR/lib/apksigner.jar")"
ANDROID_JAR="$(path_fix "$SDK/platforms/android-$API/android.jar")"

echo "== 工具链 ==
  aapt2       : $AAPT2
  zipalign    : $ZIPALIGN
  apksigner   : $APKSIGNER_JAR
  android.jar : android-$API
  java        : $JAVA"

# 构建
rm -rf build; mkdir -p build
"$AAPT2" compile --dir overlay/res -o build/compiled.zip
"$AAPT2" link -o build/rotate180.unsigned.apk -I "$ANDROID_JAR" \
    --manifest overlay/AndroidManifest.xml --auto-add-overlay build/compiled.zip
"$ZIPALIGN" -f 4 build/rotate180.unsigned.apk build/rotate180.aligned.apk
"$JAVA" -jar "$APKSIGNER_JAR" sign \
    --ks "$(path_fix "${HERE}/rotation.keystore")" --ks-pass pass:android --key-pass pass:android \
    --out build/rotate180.apk build/rotate180.aligned.apk
"$JAVA" -jar "$APKSIGNER_JAR" verify build/rotate180.apk

# 打包
echo "== 打包 =="
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "python 未找到" >&2; exit 1; }
"$PY" build_module.py
echo "完成: dist/ 下的 zip"