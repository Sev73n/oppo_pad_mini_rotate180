#!/system/bin/sh
# KernelSU / Magisk 模块：开机后启用 rotate180 overlay
# 说明：overlay 的启用状态本身会持久化（/data/system/overlays.xml），
#       本脚本是幂等的保险措施（例如系统更新、清除数据后可自动恢复）。

MODDIR=${0%/*}

# 等待系统启动完成
i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 120 ]; do
    sleep 2
    i=$((i + 1))
done
sleep 5

# 首次启动（刷入后第一次重启）：把开发者选项中的「模拟屏幕缺口」恢复为设备默认值。
# 该选项的本质是启用系统 RRO（类别 com.android.internal.display_cutout_emulation，
# 如 corner/double/tall），会把状态栏额外抬高约 2mm，与模块叠加时破坏"无损"效果。
# 这里禁用当前启用的模拟缺口 overlay（对未启用者禁用无副作用）；仅执行一次，
# 用模块目录内的标记文件防重复。卸载后设置保持默认，用户如需宽状态栏可自行重开。
FLAG="$MODDIR/.cutout_reset_done"
if [ ! -f "$FLAG" ]; then
    for pkg in $(cmd overlay list --user 0 2>/dev/null \
        | grep -o 'com\.android\.internal\.display\.cutout\.emulation\.[a-zA-Z]*' | sort -u); do
        cmd overlay disable --user 0 "$pkg" 2>/dev/null || true
    done
    # 兼容旧版 ROM 的全局开关（存在才删）
    settings delete global emulate_display_cutout 2>/dev/null || true
    : > "$FLAG"
fi

# 启用 overlay（重复启用无副作用）
cmd overlay enable --user 0 com.sev73n.padmini.rotate180
