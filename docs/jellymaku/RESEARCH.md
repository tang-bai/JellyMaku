
# 开源项目与 API 调研（2026-10-19）

> 目的：为 JellyMaku 的 Fladder 基座、弹幕、超分、SyncPlay、Bangumi 模块提供选型依据。本文区分“实测事实”和“计划/假设”。

## 1. 结论

- **基座**：DonutWare/Fladder（Flutter/Dart，GPL-3.0）。已有 Jellyfin 客户端、现代 UI、media_kit/libmpv、下载/同步、Trickplay、媒体段跳过。
- **SyncPlay**：复用 Fladder PR #735（Jellyfin SyncPlay，WebSocket + REST + 时间同步 + UI + 文档），不重写。
- **弹幕**：Dart DDP 客户端 + Flutter CustomPainter 叠加层；参考 Kazumi 的 DDP 解析/屏蔽/简繁。
- **超分**：media_kit/libmpv 的 glsl-shaders；复用 default-shader-pack/Kazumi 的 Anime4K 资产；RTX VSR 不作为 v1 验收。
- **Bangumi 增值**：Kazumi 的时间表/图片识别/评论实现可参考/移植；评论依赖 Bangumi Next p1，当前网络不可达，必须用户代理/自建镜像。
- **不选**：Kazumi 作为基座（无 Jellyfin 集成、公共 SyncPlay 不兼容）、jellyfin-desktop（Qt/C++ 扩展成本高）、mpv.net（无 Jellyfin）、服务端弹幕插件（不符合客户端自带需求）。

## 2. Fladder

| 项目 | 实测 |
|---|---|
| 仓库 | https://github.com/DonutWare/Fladder |
| 许可证 | GPL-3.0 |
| 语言/框架 | Dart/Flutter，Riverpod，Chopper，Drift |
| 默认分支 | develop |
| 最新 release | v0.11.1（2026-09-08） |
| develop HEAD | de7b5a2a23f16f5f3bb164ec0baedf50941e4808（2026-10-18） |
| 平台 | Windows、macOS、Linux、Android/TV、iOS、Web |
| 播放 | media_kit（Windows 默认 libMPV），另有 libMDK/native |
| 已有 | 登录/多账号、库/详情、直连/转码/离线、下载/同步、Trickplay、媒体段、Seerr、键盘快捷键 |
| 缺失 | 弹幕、超分、SyncPlay、Bangumi 模块、应用内聊天 |

关键代码：

- lib/wrappers/players/base_player.dart：播放器抽象。
- lib/wrappers/players/lib_mpv.dart：media_kit Player + VideoController；通过 NativePlayer.setProperty/command/observeProperty 暴露 libmpv。
- lib/providers/video_player_provider.dart：播放生命周期/状态。
- lib/screens/video_player/video_player_controls.dart：播放器控制条。
- lib/screens/video_player/components/video_player_next_wrapper.dart：视频/控制/覆盖层 Stack。
- lib/screens/settings/player_settings_page.dart：播放设置。
- windows/CMakeLists.txt、windows/windows_setup.iss：Windows 构建/安装器。

## 3. Fladder SyncPlay PR #735

| 项目 | 实测 |
|---|---|
| PR | https://github.com/DonutWare/Fladder/pull/735 |
| 状态 | open，mergeable clean（相对 base），lint check 通过 |
| head | 79e249ebf99ecc8dc8f0d5d43c3604ace45fbba9 |
| 提交 | 15 |
| 内容 | WebSocket、NTP 式时间同步、命令调度/去重、缓冲等待、REST 组管理、FAB/组面板、Android 原生播放器、1523 行协议文档 |
| 关键文件 | lib/providers/websocket/jellyfin_websocket.dart；lib/providers/syncplay/*；docs/syncplay-implementation.md |
| Jellyfin 12 | WebSocket token 改为 ApiKey 查询参数；旧 api_key 已禁用 |

结论：直接复用/合并；需解决与最新 develop 的冲突，验证 Windows/libMPV 回调。

## 4. Kazumi

| 项目 | 实测 |
|---|---|
| 仓库 | https://github.com/Predidit/Kazumi |
| 许可证 | GPL-3.0 |
| 技术栈 | Flutter/Dart，flutter_modular + MobX，media_kit，Hive，Dio |
| 定位 | 自定义 XPath 规则的番剧采集/在线观看，不是 Jellyfin 客户端 |
| 规模 | 约 3.8 万 stars，825 个 tracked 文件 |
| 与目标相关 | 番剧时间表、图片识别、Bangumi 评论、弹弹play 弹幕、Anime4K、公共 SyncPlay |

关键代码：

- 时间表：lib/pages/timeline/*、lib/request/apis/bangumi_api.dart、lib/bean/card/bangumi_timeline_card.dart。
- 图片识别：lib/pages/search/image_search_page.dart、lib/modules/search/image_search_module.dart、lib/request/apis/trace_api.dart。
- 评论：lib/modules/comments/*、lib/pages/info/info_comments_view.dart、lib/pages/player/episode_comments_*、lib/bean/card/user_comments_card.dart、lib/bbcode/*。
- 弹幕：lib/request/apis/danmaku_api.dart、lib/modules/danmaku/*、lib/utils/danmaku.dart。
- 超分：lib/pages/player/controller/player_super_resolution.dart、lib/services/shaders/shader_asset_service.dart、assets/shaders/Anime4K_*。
- 一起看：lib/services/player/syncplay_client.dart（公共 SyncPlay，不适用于 Jellyfin）。

详细分析见 KAZUMI.md。

## 5. DanDanPlay Open API

- 官方文档：https://doc.dandanplay.com/open/
- 必须有 AppId + AppSecret；签名模式：X-Signature = base64(sha256(AppId + Timestamp + Path + AppSecret))；Path 不含 query。
- 公开接口（match/search/comment）不需要用户 JWT，但仍需应用身份头；无头请求实测 403。
- 2026-06-25 起应用分层/额度管理；403 带 X-Error-Message；必须缓存、避免批量抓取。
- 合规：标注“弹弹play开放弹幕网络 www.dandanplay.com”；弹幕功能免费；禁止未授权商用；AppSecret 不入库。

## 6. Bangumi API 与网络实测

- 官方 OpenAPI：https://bangumi.github.io/api/ ，v0 有 /calendar、/v0/subjects、/v0/episodes、/v0/search/subjects；**没有 comments**。
- 评论：Kazumi 使用 Next `/p1/subjects/{id}/comments`、`/p1/episodes/{id}/comments`；非官方 OpenAPI，稳定性风险。
- 实测（本机 2026-10-19）：
  - api.bgm.tv、next.bgm.tv、bgm.tv 连接超时。
  - api.kazumi.fyi 的 /p1/calendar、/p1/subjects/{id}、/v0/episodes 可匿名访问。
  - api.kazumi.fyi 的 /p1/.../comments、/v0/search/subjects 返回 401 invalid request signature；镜像凭证不可复用。
- 结论：时间表/图片→Bangumi 映射/评论均需用户代理/自建镜像；评论不能宣称开箱即用。

## 7. trace.moe

- API：https://api.trace.moe/search?anilistInfo=2；支持图片文件 POST 或 url 参数。
- 实测 /me：quota=100、concurrency=1、priority=0（按 IP，无 API key）。
- 返回 AniList 标题/synonyms/episodes、episode、from/at、similarity；没有 Bangumi ID。
- 隐私/配额：用户主动触发、串行、按图片哈希缓存、首次上传同意；不做批量/自动截图上传。

## 8. Jellyfin

- 当前稳定版 12.2（2026-10-05），服务端 net10.0；Windows `jellyfin_12.2-amd64.zip` 需要 .NET 10 runtime。
- SyncPlay 2.0 限制：无新房间 WebSocket 通知、创建/加入不返回完整状态等；PR #735 已按客户端能力处理。
- Jellyfin 12 默认禁用旧 api_key 查询参数；PR #735 使用 ApiKey。

## 9. media_kit / 超分

- media_kit Windows 视频输出使用 ANGLE OpenGL 渲染上下文；Flutter 通过 DXGI shared handle 显示。
- NativePlayer 提供 setProperty/command/observeProperty，可设置 glsl-shaders/vf/hwdec。
- GLSL shader 超分可行；RTX VSR 的 d3d11vpp 依赖 D3D11，当前 ANGLE/OpenGL 路径不可靠，不作为 v1 验收。

## 10. 工具链

- Flutter 3.35.7（Fladder .fvmrc）；本机未安装，下载 zip 到 .flutter。
- VS 2022 BuildTools 已安装，含 C++/Windows SDK；Developer Mode 已启用。
- Jellyfin 12.2 + .NET 10；Inno Setup 未安装；ffmpeg 9.0.1 可用。
- 仓库路径含中文/空格，必要时 subst J: 映射 ASCII 盘符。

## 11. 备选与不选

| 项目 | 结论 |
|---|---|
| jellyfin-desktop | Qt/C++/QML 扩展弹幕成本高；不选 |
| mpv.net | 无 Jellyfin/SyncPlay；不选 |
| cxfksword/jellyfin-plugin-danmu | 服务端插件，DDP 已移除；不选 |
| Kosette/danmaku | 旧 DDP 签名，Rust cplugin；仅参考 |
| Kazumi 作为基座 | 无 Jellyfin 集成、公共 SyncPlay；不选 |
| 自建同步服务器 | 端口/NAT/鉴权成本高；用 Jellyfin SyncPlay |

## 12. 仍需验证

- Flutter 3.35.7 + VS BuildTools 的实际 Windows 构建。
- PR #735 与最新 develop 的合并冲突。
- media_kit glsl-shaders 在 Windows/ANGLE 下的实际效果。
- Bangumi 官方 API 经代理/自建 Worker 的可达性与 Next p1 稳定性。
- trace.moe 实际识别准确率/配额。
- Jellyfin 12.2 的 SyncPlay/登录兼容性。
