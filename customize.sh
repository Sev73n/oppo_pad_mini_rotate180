#!/system/bin/sh
# KernelSU / Magisk 模块安装时的自定义脚本（进度提示）
# KernelSU 安装 zip 时只执行本文件（若存在）；Magisk 的 install_module 也会 source 它。
# 文件提取与权限由安装框架自动完成，这里仅输出提示。

command -v ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

ui_print "== 打孔屏模拟设置处理 =="
ui_print "  → 将在首次重启后自动把打孔屏模拟恢复为设备默认值"
ui_print "  → 随后由模块无伤解锁四向旋转（无状态栏加宽）"
ui_print "  → 仅一次，卸载后设置保持默认"
