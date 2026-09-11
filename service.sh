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

# 启用 overlay（重复启用无副作用）
cmd overlay enable --user 0 com.sev73n.padmini.rotate180
