#!/usr/bin/env bash
# 构建 rotate180 模块 zip。
# 模块使用 FabricatedOverlay（运行时覆盖层）绕过 ColorOS 的 180° 旋转限制，
# 不需要编译 APK，因此不再需要 Android SDK / JDK。
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "python 未找到" >&2; exit 1; }

echo "== 模块打包 =="
"$PY" build_module.py
echo "完成: dist/ 下的 zip"