# JellyMaku

JellyMaku 是面向 **Windows 10/11** 的 Jellyfin 桌面播放器，基于 [Fladder](https://github.com/DonutWare/Fladder)（Flutter/Dart，GPL-3.0）二次开发，并集成了弹弹play 兼容的 danmu_api 弹幕、Anime4K GLSL 超分和 Jellyfin SyncPlay 一起看能力。

> **当前状态：v0.1.0 Windows 正式版**
> 首个非 Beta 正式版，Stage A 功能验收通过；提供 Windows x64 便携包与 Inno Setup 安装器。SyncPlay/超分原始证据归档与安装器签名仍待收尾。
>
> [下载最新正式版](https://github.com/tang-bai/JellyMaku/releases/tag/v0.1.0) · [完整文档](docs/jellymaku/README.md) · [构建说明](docs/jellymaku/BUILD_WINDOWS.md)

## 项目简介

JellyMaku 的目标是做一个 Windows 上开箱即用的 Jellyfin 播放器：

- 使用 Fladder 作为 Jellyfin 客户端基座，保留其媒体库、播放、字幕、音轨等能力；
- 针对番剧/剧集场景增强弹幕体验；
- 使用 libmpv + GLSL shader 做视频超分；
- 通过 Jellyfin SyncPlay 支持一起看；
- 以 Windows 桌面端为主要交付目标，提供安装器和便携包。

## 已实现功能

### Jellyfin 客户端基座

- Fladder 源码导入，并已合并上游 Fladder develop de7b5a2a。
- Jellyfin 登录、媒体库浏览、搜索、收藏、详情页、播放。
- 视频播放、暂停、seek、字幕切换、音轨/字幕轨选择、切集。
- 已通过 NAS 上的 Jellyfin 12.2 登录/播放/暂停/seek 自动验证；字幕切换、切集、弹幕叠加层已手动验证；安装版字幕补测通过（2026-10-23）。

### 弹幕（danmu_api）

- 默认使用公共 danmu_api：https://danmu.api.tangbai.cc，无需 AppId/AppSecret。
- 设置中可切换到自建 danmu_api；自建服务若设置 TOKEN，将 /{TOKEN} 放在服务器地址路径中。
- 自动匹配：优先 POST /api/v2/match，失败后回退 search/episodes。
- 手动匹配：搜索番剧/分集并保存映射。
- 支持 URL 型弹幕来源，以及 renren/hanjutv 等复合 ID 的 segmentcomment。
- 本地弹幕导入：支持 Bilibili XML 和 danmu_api 兼容 JSON。
- Flutter CustomPainter 弹幕叠加层：滚动/顶部/底部、字体、颜色、透明度、描边、显示区域、速度、偏移。
- 弹幕合并、去重、数量限制、屏蔽词、按类型显示/隐藏。
- 弹幕缓存；缓存 key 使用服务器地址 + 分集 URL 哈希，避免跨服务器串数据。
- 暂停时冻结弹幕时钟；恢复播放不拉扯；弹幕匀速推进；轨道和文本布局缓存。
- 弹幕设置、手动匹配对话框已支持中英双语；弹幕相关按钮/提示已接入 ARB。

### 视频超分

- Anime4K GLSL shader 超分，支持四档：
  - Fast 2x：Anime4K Upscale CNN x2 M；
  - Balanced 2x：Anime4K Restore CNN M + Upscale CNN x2 M；
  - Strong 2x：Anime4K Restore CNN L + Upscale CNN x2 M；
  - 4x：Anime4K Restore CNN M + Upscale CNN x2 M ×2。
- 播放器底栏可直接切换档位，菜单显示实际使用的模型名称。
- 已完成四档截图和 GPU 粗测（Strong 约 23% GPU、JellyMaku 进程约 4.3%），但尚未采集 FPS/掉帧。

### SyncPlay 一起看

- 已导入 Fladder SyncPlay PR #735 的代码和界面。
- 支持 SyncPlay 组、播放队列、播放/暂停/seek 同步等基础流程。
- 用户实机确认双客户端联调通过（2026-10-23）；原始日志/误差/截图待归档。

### Windows 与播放器体验

- Windows x64 Release 构建；窗口标题、关于页、更新入口已改为 JellyMaku 品牌。
- 提供 Inno Setup 安装器和便携包。
- SMTC 媒体控制初始化；Windows URL 协议注册。
- 点击画面暂停；暂停/恢复弹幕连续；弹幕轨道稳定；侧栏展开/折叠动画。
- 播放页 `SDR HD` 徽章可打开实时播放信息（码率/下载速度/缓冲/丢帧/硬解/帧率/加载耗时），用户实机确认 + 安装版 E2E 通过。
- 安装器当前未签名，Windows SmartScreen 可能提示；已提供可选 Authenticode 签名脚本，需用户受信任证书。

## 已验证

- dart analyze lib test：0 issue。
- beta.4 发布包：137 项测试（136 通过 + 1 个手动联网探针跳过）。
- 当前 HEAD（2026-10-23）：157 项测试通过 + 1 个手动联网探针跳过。
- Windows Release 构建成功（当前 HEAD，2026-10-23）。
- NAS Jellyfin 12.2：登录、媒体库（电影 191 条、剧集 5380 条）、播放、暂停、seek 已验证。
- NAS 环境手动确认：字幕切换、切集、弹幕叠加层；安装版字幕补测通过（2026-10-23）。
- 弹幕性能基准：5000 条解析约 52–55ms，首帧约 15–17ms，后续帧约 1.0–1.1ms（测试环境，非播放器内 FPS）。
- 用户实机确认：SyncPlay 双客户端联调、超分性能、播放信息面板通过（2026-10-23）。
- 安装版主链路 E2E：安装/自动登录/播放/暂停/seek/弹幕/Anime4K/播放信息通过（2026-10-23）。

## 已实现但仍有证据缺口

- **SyncPlay**：用户确认双客户端联调通过；缺原始日志/位置误差/截图归档。
- **超分**：四档可切换、截图完成、用户确认性能通过；缺 FPS/掉帧原始数据和不同 GPU 对比。
- **公共 danmu_api**：接口在可用网络下实测通过，但公共实例可能受网络、证书或源站风控影响；失败时可改用自建实例。
- **安装器**：安装版主链路 E2E 通过（登录/播放/暂停/seek/弹幕/超分/播放信息）；字幕补测通过；签名脚本已备，受信任证书未提供。
- **播放信息面板**：用户确认 + 安装版 E2E 通过；截图/实时数值已采集。
- **Fladder 上游能力**：多窗口媒体会话、深链等上游新功能在真实 Jellyfin 下的行为未逐一验证。

## 尚未实现

- **Bangumi Stage B**：番剧时间表、以图搜番、Bangumi 评论均未开始。
- **FSRCNNX / ArtCNN**：当前只实现 Anime4K，其他 shader 方案未接入。
- **发送弹幕**：danmu_api 只读，JellyMaku 不提供发送弹幕功能。
- **自动更新**：未实现；安装器和便携包需要手动下载更新。
- **安装器签名**：未签名；`tools/sign-release.ps1` 已提供，需受信任代码签名证书。
- **全局中文 ARB**：`zh` / `zh_Hant` 当前 1188 个 ARB 键已补齐；后续上游新增文案需同步。
- **RTX VSR**：不作为 v1 支持项；media_kit 的 ANGLE/OpenGL 路径无法可靠承载 d3d11vpp，已记录失败实验，不要期待该功能。

## 安装与使用

### 下载

从 [GitHub Releases](https://github.com/tang-bai/JellyMaku/releases/tag/v0.1.0) 下载：

- JellyMaku-0.1.0-windows-x64-setup.exe：安装版；
- JellyMaku-0.1.0-windows-x64-portable.zip：便携版，解压后运行 JellyMaku.exe。

要求：Windows 10/11 x64、可访问的 Jellyfin 服务器。

### 首次使用

1. 启动 JellyMaku，添加 Jellyfin 服务器并登录。
2. 打开任意视频，底栏可打开弹幕设置和超分菜单。
3. 弹幕默认使用公共 danmu_api；如不可用，在弹幕设置中改为自建 danmu_api 地址。
4. 如需本地弹幕，可在弹幕设置中导入 XML/JSON 文件。

## 从源码构建

~~~powershell
# 建议使用 ASCII 路径，例如 L:\JellyMaku
$env:PUB_CACHE = "K:\.pub-cache"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:PATH = "K:\tools\nuget;" + $env:PATH
$env:CL = "/utf-8"

.\.flutter\bin\flutter.bat pub get
.\.flutter\bin\dart.bat analyze lib test
.\.flutter\bin\flutter.bat test --no-pub
.\.flutter\bin\flutter.bat build windows --release --no-pub
& .\tools\pack.ps1 -Version 0.1.0
~~~

详细依赖、原生库和常见构建问题见 [BUILD_WINDOWS.md](docs/jellymaku/BUILD_WINDOWS.md)。

## 已知限制

- Beta 版本，功能和接口仍可能变化。
- 弹幕来自第三方聚合源，源站可用性、地区和反爬策略会影响结果；公共实例不保证稳定。
- 不提供 Jellyfin 以外的媒体服务器支持。
- 不提供弹幕发送、弹幕举报或账号系统。
- 超分效果依赖 GPU 和视频分辨率，4x 档位开销较高。
- 真实 Jellyfin 环境、网络环境和不同 GPU 的表现仍需更多验证。

## 文档与许可

- [文档索引](docs/jellymaku/README.md)
- [弹幕设计](docs/jellymaku/DANMAKU.md)
- [超分说明](docs/jellymaku/SR.md)
- [构建说明](docs/jellymaku/BUILD_WINDOWS.md)
- [实施状态](docs/jellymaku/IMPLEMENTATION.md)
- [许可与署名](docs/jellymaku/LICENSING.md)
- [Agent 规则](AGENTS.md)

JellyMaku 以 GPL-3.0 分发；Fladder、SyncPlay PR #735、Kazumi、Anime4K、danmu_api 等上游项目的许可和署名见 [LICENSING.md](docs/jellymaku/LICENSING.md)。
