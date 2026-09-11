#!/system/bin/sh
# KernelSU / Magisk 模块：开机后创建 fabricated overlay 并启用。
# 使用 FabricatedOverlay（Android 13+ 运行时覆盖层），不走 /vendor/overlay APK 路径，
# 避免 KernelSU 挂载时机晚于 PackageManager 扫描导致 APK 无法注册的问题。
# FabricatedOverlay 由 OverlayManagerService 直接管理并持久化到 overlays.xml。
# 注意：开机时 OMS 会清除所有 shell 拥有的 fabricated overlay，因此每次重启
# 都需要重新创建（service.sh 开机执行，机制上一致）。

MODDIR=${0%/*}
OVERLAY_NS="com.android.shell"

# 等待系统启动完成
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 120 ]; do
    sleep 2
    i=$((i + 1))
done
sleep 5

# --- 1. 首次启动：把开发者选项中的「模拟屏幕缺口」恢复为设备默认值 ---
FLAG="$MODDIR/.cutout_reset_done"
if [ ! -f "$FLAG" ]; then
    for pkg in $(cmd overlay list --user 0 2>/dev/null \
        | grep -o 'com\.android\.internal\.display\.cutout\.emulation\.[a-zA-Z]*' | sort -u); do
        cmd overlay disable --user 0 "$pkg" 2>/dev/null || true
    done
    settings delete global emulate_display_cutout 2>/dev/null || true
    : > "$FLAG"
fi

# --- 2. 创建 FabricatedOverlay（仅当不存在时） ---
# 创建两个 overlay，分别覆盖 config_mainBuiltInDisplayCutout 及其 RectApproximation
CUTOUT_SPEC='M -33,0 L -33,105 L 33,105 L 33,0 Z M 0,0 L 1,0 L 1,1 L 0,1 Z @left'
OVERLAY_NAMES=""
for name in rotate180cutout rotate180rect; do
    case "$name" in
        rotate180cutout) RESNAME="config_mainBuiltInDisplayCutout" ;;
        rotate180rect)   RESNAME="config_mainBuiltInDisplayCutoutRectApproximation" ;;
    esac
    if ! cmd overlay list --user 0 2>/dev/null | grep -qF "${OVERLAY_NS}:${name}"; then
        cmd overlay fabricate --target android --name "$name" \
            "android:string/${RESNAME}" string "$CUTOUT_SPEC" 2>/dev/null || true
    fi
    cmd overlay enable --user 0 "${OVERLAY_NS}:${name}" 2>/dev/null || true
    OVERLAY_NAMES="${OVERLAY_NAMES}${name} "
done

# 输出调试日志（非必要，方便用户查看是否生效）
log -t rotate180 "Fabricated overlays created & enabled: $OVERLAY_NAMES"