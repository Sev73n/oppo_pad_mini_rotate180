#!/system/bin/sh
# KernelSU / Magisk 模块安装时的自定义脚本（进度提示）
# 模块使用 FabricatedOverlay（运行时覆盖层）解锁四向旋转，
# 不再需要编译 APK 和 Android SDK。

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

ui_print "== OPPO Pad Mini 四向旋转解锁 =="
ui_print "  → 模块将在首次重启后自动解锁 180° 旋转"
ui_print "  → 同时自动恢复打孔屏模拟为设备默认值"
ui_print "  → 无需编译 APK，无需 SDK，无状态栏加宽"
