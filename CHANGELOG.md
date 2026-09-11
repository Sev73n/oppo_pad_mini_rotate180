# Changelog

所有模块版本的变更记录。格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循语义化版本。

## [v1.3] - 2026-09-11

### 修复

- **彻底解决模块不生效问题**：改用 FabricatedOverlay（`cmd overlay fabricate`，Android 13+ 运行时覆盖层）替代 APK 方案。
- 原因：KernelSU Ultra 的 Hybrid Mount 挂载 `/vendor/overlay` 的时机晚于 PackageManager 扫描，
  APK 无法注册为系统 overlay（`cmd overlay enable` 一直报 "commit failed"）；同时 APK 的
  SELinux 标签（`vendor_file`）与系统 overlay（`vendor_overlay_file`）不一致。
- FabricatedOverlay 由 OverlayManagerService 直接管理，不经过 PMS 扫描、不受签名与
  SELinux 标签限制；开机时 OMS 会清除 shell 拥有的 fabricated overlay，因此
  `service.sh` 在每次开机后重新创建并启用（幂等）。
- 实测：OPPO Pad Mini（OPD2515 / ColorOS 16）刷入后重启一次即可四向旋转，
  状态栏无加宽，打孔屏模拟自动恢复为设备默认值。

### 变更

- 移除 APK 构建：`overlay/` 源码与 `rotation.keystore` 不再需要，已从仓库删除。
- `build.sh` 不再依赖 Android SDK / JDK / aapt2，仅需 Python 3。
- 模块体积从约 11 KB 缩小到约 3.6 KB。
- CI 构建时间从 ~30s 缩短到 ~12s。

## [v1.2] - 2026-09-11

### 修复

- 新增 `customize.sh`：KernelSU 安装 zip 时不执行 `update-binary`，导致刷入时无进度提示；
  现在 KernelSU / Magisk 都会执行 `customize.sh` 显示提示。
- `service.sh` 首次启动自动恢复开发者选项中的「模拟屏幕缺口」为设备默认值
  （禁用 `com.android.internal.display.cutout.emulation.*` 系统 overlay），
  避免状态栏加宽；用标记文件保证仅执行一次。

## [v1.1] - 2026-09-11

### 新增

- 首次启动自动处理打孔屏模拟设置（一次性，恢复设备默认值）。

## [v1.0] - 2026-09-11

### 新增

- 首个版本：通过 RRO APK（`/vendor/overlay`）解锁 OPPO Pad Mini 的 180° 倒置旋转。
- 包含完整构建脚本（Android SDK + aapt2）、CI 自动发布、商店提交文档（STORE.md）。

[v1.3]: https://github.com/Sev73n/oppo_pad_mini_rotate180/releases/tag/v1.3
[v1.2]: https://github.com/Sev73n/oppo_pad_mini_rotate180/releases/tag/v1.2
[v1.1]: https://github.com/Sev73n/oppo_pad_mini_rotate180/releases/tag/v1.1
[v1.0]: https://github.com/Sev73n/oppo_pad_mini_rotate180/releases/tag/v1.0
