# 安装 JellyMaku

JellyMaku 当前只发布 **Windows 10/11 x64** Beta。其他平台不是本项目的验收目标。

## 下载

从 [GitHub Releases](https://github.com/tang-bai/JellyMaku/releases) 下载最新版本：

- **安装版**：`JellyMaku-<version>-windows-x64-setup.exe`，运行后按向导安装。
- **便携版**：`JellyMaku-<version>-windows-x64-portable.zip`，解压后运行 `JellyMaku.exe`。

当前安装器未签名，Windows SmartScreen 可能提示；请只从本仓库 Releases 下载。

## 要求

- Windows 10/11 x64。
- 可访问的 Jellyfin 服务器（已在 Jellyfin 12.2 上验证主要播放流程）。
- 使用弹幕时需要能访问 danmu_api；默认公共实例为 `https://danmu.api.tangbai.cc`，也可在设置中改为自建实例。
- 超分需要支持 GLSL 的 GPU/驱动；Anime4K 4x 对 GPU 开销较高。

## 首次使用

1. 启动 JellyMaku，添加 Jellyfin 服务器并登录。
2. 打开视频，底栏可打开弹幕设置、超分菜单和播放信息。
3. 弹幕默认使用公共 danmu_api；不可用时可在弹幕设置中改地址或导入本地 XML/JSON。
4. 一起看（SyncPlay）需要所有成员登录同一台 Jellyfin 服务器。

## 已知限制

- Beta 版本，功能/接口可能变化。
- SyncPlay 真实双客户端、超分 FPS/掉帧、安装目录完整 E2E 尚未验收。
- 不提供发送弹幕、自动更新或安装器签名。
- 详细状态见 [docs/jellymaku/ROADMAP.md](docs/jellymaku/ROADMAP.md)。

## 从源码构建

见 [docs/jellymaku/BUILD_WINDOWS.md](docs/jellymaku/BUILD_WINDOWS.md)。仓库路径建议使用 ASCII 路径（如 `L:\JellyMaku`）。
