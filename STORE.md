# KernelSU 官方商店：上线状态与更新流程

本文档记录本模块在 KernelSU 官方商店（`modules.kernelsu.org`）的上线状态和每次发版的更新步骤，供后续迭代及 agent 直接参照执行。

## 现状（待提交）

| 项目 | 值 |
| --- | --- |
| 模块 id | `oppo_pad_mini_rotate180` |
| 源码仓库 | https://github.com/Sev73n/oppo_pad_mini_rotate180（待创建/推送） |
| 官方仓库 | https://github.com/KernelSU-Modules-Repo/oppo_pad_mini_rotate180（待申请，需商店管理员权限） |
| 商店页面 | https://modules.kernelsu.org/module/oppo_pad_mini_rotate180/（上线后生效） |
| 已上线版本 | 无 |

- 源码仓库与官方仓库相互独立：日常开发在源码仓库进行，官方仓库仅用于商店展示与分发，通过 `module.json` 的 `sourceUrl` 字段关联。
- 商店收录由官方机器人完成：官方仓库**新建 Release** 后，`KernelSU-Bot` 约 30 秒内自动触发增量构建，几分钟内商店生效。

## 一、首次提交流程

1. 创建 GitHub 源码仓库并推送本目录全部文件（默认分支 `main`）。
2. 确认 `module.json` 的 `sourceUrl` 与本仓库地址一致。
3. 打 tag 触发 CI 自动构建 Release（见下节），确认 `dist/` 产物上传成功。
4. 向 KernelSU 模块商店申请收录（官方仓库一般为 `KernelSU-Modules-Repo/<模块id>`，申请通过后持有 admin 权限）。
5. 在官方仓库新建 Release 上传 zip 资产（tag 格式 `[versionCode]-[versionName]`，如 `1-v1.0`）。

## 二、更新流程（每次发版照此执行）

前置条件：`gh` CLI 已登录且对本仓库、官方仓库都有写权限（账号 Sev73n）。

### 1. 源码仓库：改代码并发布

1. 修改代码；**同步更新 `module.prop` 的 `version` 和 `versionCode`，版本码必须严格递增**（如 1 → 2）。
2. 本地构建模块包：

   ```bash
   bash build.sh
   # 产物：dist/oppo_pad_mini_rotate180_v<版本名>.zip
   ```

3. 提交改动并打 tag 推送，本仓库的 Release 由 CI（`.github/workflows/release.yml`）自动创建：

   ```bash
   git add -A && git commit -m "feat: v1.1"
   git tag v1.1
   git push origin main --tags
   ```

### 2. 官方商店仓库：新建 Release

在官方仓库新建 Release，**tag 必须用 `[versionCode]-[versionName]` 格式**（版本码-版本名，中间是连字符），并上传 zip 资产：

```bash
# 示例：versionCode=2, version=v1.1
gh release create 2-v1.1 "dist/oppo_pad_mini_rotate180_v1.1.zip" \
  -R KernelSU-Modules-Repo/oppo_pad_mini_rotate180 \
  --title "v1.1" \
  --notes "更新内容：
- 修复 xxx
- 新增 xxx"
```

要点（官方规则）：

- 版本号与版本码由机器人从 **zip 内 `module.prop`** 解析；`versionCode` 必须大于上一个 release。
- 必须**新建 Release** 才能触发机器人更新；只修改已有 Release 的 zip 资产、不新建 release，机器人感知不到，不会更新。
- 勾选 pre-release 的按 Beta 处理，默认不展示；只有**默认分支（main）**会被处理。
- Release 标题填版本名，正文填更新日志。

## 三、CI 说明

`.github/workflows/release.yml` 在推送 `v*` tag 时触发：

1. `bash build.sh`：自动探测 Android SDK（GitHub Actions 自带），编译 RRO APK 并打包模块 zip
2. 删除同名旧 Release（避免残留旧资产）
3. 上传 `dist/*.zip` 并生成 Release

注意：`build.sh` 需要 Android SDK 与 JDK，本地构建时请确保环境变量 `ANDROID_SDK_ROOT` 正确。

## 四、故障排查

- **商店无更新**：确认官方仓库 Release 是"新建"而非编辑；确认 tag 格式为 `版本码-版本名`；确认默认分支为 `main`。
- **CI 构建失败**：查看 Actions 日志，常见原因是 Android SDK 未找到或 JDK 未安装。
- **模块刷入不生效**：`cmd overlay list | grep rotate180` 检查是否 `[x]`；若未启用可手动 `cmd overlay enable --user 0 com.sev73n.padmini.rotate180` 后重启。
