# OPPO Pad Mini 四向旋转解锁

一个 KernelSU / Magisk 模块，解锁 ColorOS 平板被拦截的 **180° 倒置旋转**（四向自动旋转），且 **视觉无副作用**。

| | |
| --- | --- |
| 模块 id | `oppo_pad_mini_rotate180` |
| 适配设备 | OPPO Pad Mini（OPD2515），ColorOS 16 / Android 16 |
| 前置条件 | KernelSU / Magisk（需 root） |
| 实测效果 | 自动旋转支持 0° / 90° / 180° / 270°，状态栏高度与原始一致 |

## 效果

- ✅ 自动旋转时支持 **180° 倒置**（原厂默认只允许三个方向）
- ✅ 状态栏高度（105px）与界面 insets 保持原样，无任何视觉变化
- ✅ 前置摄像头、触摸、游戏、全屏应用均不受影响
- ✅ 不改动系统文件，随时可卸载恢复

## 原理

ColorOS 16 在 `system_server` 的 `oplus-services.jar` 中增加了一个拦截钩子：

```
OplusRotationAnimationManager.needBlockAllowAllRotations(allowAll, 1)
  → 平板 + 挖孔居中？ → 拦截，强制返回 0（禁止 180°）
```

*这个拦截与任何设置项无关，是在代码层写死的。*

模块通过 RRO（Runtime Resource Overlay）覆盖系统挖孔路径定义 
`config_mainBuiltInDisplayCutout`：**在原居中挖孔路径旁边加一个 1×1px 的隐形角标**，
使挖孔包围盒从居中变为不居中，拦截条件失效。

同时挖孔 insets 保持原样（顶部 105px、无侧边内缩），因此 **视觉上完全无变化**。
详细分析见 [STORE.md](STORE.md) 中的原理说明。

## 安装

1. 下载 [Releases](https://github.com/Sev73n/oppo_pad_mini_rotate180/releases) 中的 zip 包
2. 在 KernelSU / Magisk 管理器中「从本地安装」
3. **重启**

> ⚠️ **首次安装后可能需要重启两次**：
> 第一次重启时模块的 overlay 才被系统扫描到（开机挂载），`service.sh` 会在开机后自动启用它（状态持久化到 `/data/system/overlays.xml`）；
> 第二次重启时系统在开机早期即读到"非居中挖孔"，180° 判定通过。
>
> 若第一次重启后 180° 不可用，**再重启一次**即可。

### 与开发者选项的关系

「开发者选项 → 模拟屏幕缺口 → 边角刘海屏（Corner）」也能解锁 180°，但代价是状态栏升高 2mm（126px vs 原 105px）。
本模块是"无损版"。两者选一即可，**不要同时启用**。

## 验证

```sh
# overlay 已启用（应显示 [x]）
adb shell cmd overlay list | grep rotate180

# 系统已解锁 180°（应显示 mAllowAllRotations=true）
adb shell dumpsys window | grep mAllowAllRotations

# 挖孔 insets 与原始一致（顶部应为 105px）
adb shell dumpsys window displays | grep -m1 mDisplayCutout
```

物理验证：开启自动旋转 → 把平板上下倒置 180° → 屏幕应跟随旋转。

## 卸载

- KernelSU / Magisk 管理器中删除模块 → 重启，自动恢复
- 临时禁用（不删模块）：

  ```sh
  cmd overlay disable --user 0 com.sev73n.padmini.rotate180
  ```

## 构建

```sh
bash build.sh
# 产物：dist/oppo_pad_mini_rotate180_v1.0.zip
```

依赖：Python 3、Android SDK（aapt2 / zipalign / apksigner）、JDK（java）。Windows 下使用 Git Bash。

## 仓库结构

```
.
├── overlay/                        RRO 覆盖层源码
│   ├── AndroidManifest.xml
│   └── res/values/strings.xml
├── META-INF/com/google/android/     Magisk / KernelSU 安装脚本
├── module.prop                      模块元信息
├── module.json                      商店元信息
├── service.sh                       开机自动启用 overlay
├── build.sh                         编译脚本
├── build_module.py                  打包脚本
├── rotation.keystore                自签名密钥（已提交，详见 README 备注）
├── .github/workflows/release.yml   CI 自动构建
├── README.md
├── STORE.md                        商店上线流程与更新指南
├── LICENSE                          MIT
├── .gitattributes
└── .gitignore
```

关于 `rotation.keystore`：这是自签名调试密钥（密码 `android`），仅用于给 RRO APK 签名，**无安全价值**。纳管以保证构建可复现。

## 已知限制

- 挖孔坐标基于 OPPO Pad Mini（1680×2520 @420dpi）实测；其他机型需调整 `overlay/res/values/strings.xml`
- 首次安装需重启两次（原因见"安装"）
- 原理依赖当前版本 ColorOS 拦截逻辑，系统大版本更新后可能失效
- OTA 升级后 overlay 状态保留，无需重新刷入

## 提交商店

见 [STORE.md](STORE.md)。

## 协议

[MIT License](LICENSE)