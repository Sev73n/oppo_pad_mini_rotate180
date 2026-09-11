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

## 背景：为什么需要这个模块

*以下经历整理自作者的语音记录。*

入手 OPPO Pad Mini 后发现它**只能三向旋转**（0° / 90° / 270°），倒过来用都不行，具体困扰是：

- **充电 / 摆放不便**：充电口在固定一边，插上线就只能朝一个方向摆，想换个方向就"倒立"了；
- **锁屏上下颠倒**：倒着拿平板时，锁屏画面也跟着颠倒，看着很别扭。

### 为什么 OPPO 要屏蔽 180°？

经过实验排查（结合 `dumpsys` 与 overlay 探测）确认：这不是设置开关问题，而是 ColorOS 在**系统代码里写死**的拦截——挖孔摄像头居中位于屏幕顶部，一旦 180° 倒置，摄像头会转到屏幕**底部**，OPPO 担心此时手势上滑会经过摄像头区域、产生**断触**风险，于是直接把 180° 禁止掉了。

### 官方留的口子：开发者选项

`开发者选项 → 模拟屏幕缺口 → 边角刘海屏（Corner）`：开启后系统会把屏幕虚拟成"大屏"、为摄像头让出空隙，从而放行 180° 旋转，但代价是：

- 状态栏变宽约 **2mm**（126px，原为 105px）——并非所有人都能接受；
- 需要**重启**后才生效。

> ⚠️ 本模块会在首次重启后**自动将「模拟屏幕缺口」恢复为设备默认值**（仅一次），
> 你可以直接刷入、重启，无需手动改回去。卸载后该设置保持默认，如需宽状态栏可自行重开。

### 本模块的做法（大白话原理）

系统判定"能否 180° 旋转"的关键是——**挖孔在不在屏幕正中间**：在正中就禁止。

本模块通过 RRO（Runtime Resource Overlay，运行时资源覆盖）给挖孔路径旁悄悄加了一个 **1×1 像素的隐形角标**，让系统算出"挖孔不在正中"→ 拦截失效 → 180° 解锁。全程**不修改任何系统文件**，挖孔的实际显示区域、状态栏高度完全不变，视觉零差异。

技术细节见下节「原理」。

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

> 💡 **首次重启时模块会自动处理开发者选项**：把「模拟屏幕缺口」恢复为设备默认值（仅一次，无副作用），
> 随后由模块负责解锁 180°。刷入时安装脚本会显示对应进度提示。

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