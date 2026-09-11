#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 rotate180 模块打包为 KernelSU / Magisk 模块 zip。

产物：dist/<id>_<version>.zip
"""
import os
import re
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))

# (zip 内相对路径)
FILES = [
    "module.prop",
    "customize.sh",
    "service.sh",
    "META-INF/com/google/android/update-binary",
    "META-INF/com/google/android/updater-script",
]

EXEC = {"customize.sh", "service.sh", "META-INF/com/google/android/update-binary"}

DIRS = [
    "META-INF/",
    "META-INF/com/",
    "META-INF/com/google/",
    "META-INF/com/google/android/",
]

S_IFREG = 0o100000
S_IFDIR = 0o040000


def read_prop(key):
    with open(os.path.join(ROOT, "module.prop"), encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith(key + "="):
                return line.split("=", 1)[1]
    return ""


def add_file(z, src, arc):
    zi = zipfile.ZipInfo.from_file(src, arc)
    mode = 0o755 if arc in EXEC else 0o644
    zi.external_attr = (S_IFREG | mode) << 16
    with open(src, "rb") as f:
        z.writestr(zi, f.read())
    print(f"  + {arc} ({mode:o})")


def main():
    mid = re.sub(r"[^A-Za-z0-9_.-]", "_", read_prop("id").strip()) or "module"
    ver = re.sub(r"[^A-Za-z0-9_.-]", "_", read_prop("version").strip()) or "v1.0"

    dist = os.path.join(ROOT, "dist")
    os.makedirs(dist, exist_ok=True)
    out = os.path.join(dist, f"{mid}_{ver}.zip")
    if os.path.exists(out):
        os.remove(out)

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for d in DIRS:
            zi = zipfile.ZipInfo(d)
            zi.external_attr = (S_IFDIR | 0o755) << 16
            z.writestr(zi, b"")
            print(f"  d {d}")
        for rel in FILES:
            add_file(z, os.path.join(ROOT, rel), rel)

    print(f"\n打包完成: {out}")
    print(f"大小: {os.path.getsize(out)} 字节")


if __name__ == "__main__":
    main()
