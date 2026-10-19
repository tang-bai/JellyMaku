
# 目标架构

> 状态：Draft。以下为计划架构；源码尚未导入 Fladder。

## 1. 总体结构

~~~text
Flutter UI（Fladder 页面 / Riverpod）
  ├─ 库/详情/播放/下载/设置（复用 Fladder）
  ├─ DanmakuOverlay（CustomPainter，叠加在视频上）
  ├─ Video Enhancement（libmpv glsl-shaders）
  ├─ SyncPlay group sheet / badge（PR #735）
  └─ Bangumi（时间表/图片识别/评论，条件功能）
        │
  MediaControlsWrapper
        ├─ LibMPV（media_kit Player + VideoController）
        │    ├─ libmpv：视频/音频/字幕/hwdec/glsl-shaders
        │    └─ Flutter texture（DXGI/ANGLE）
        ├─ DanmakuController（DDP + 缓存 + 布局）
        ├─ SyncPlayController（WebSocket + REST + 时间同步）
        └─ BangumiService（v0 + Next p1 + 缓存/代理）
              │
        Jellyfin 12.2        DanDanPlay        Bangumi        trace.moe
~~~

## 2. 模块职责

| 模块 | 职责 | 计划位置 |
|---|---|---|
| Fladder 核心 | Jellyfin 登录/库/播放/下载/设置 | 原 Fladder lib/、windows/ |
| 弹幕 | DDP 签名、匹配、解析、缓存、叠加层、手动匹配/本地导入 | lib/danmaku/、lib/providers/danmaku_provider.dart、lib/screens/video_player/components/danmaku_* |
| 超分 | profile、shader 资产、glsl-shaders 应用、诊断 | lib/video/enhancement.dart、lib/wrappers/players/lib_mpv.dart、assets/shaders/ |
| 一起看 | SyncPlay WebSocket/REST/时间同步/命令调度/组 UI | PR #735 的 lib/providers/syncplay/*、lib/providers/websocket/* |
| Bangumi | 时间表、图片识别、评论、映射、缓存、网络代理 | lib/bangumi/、lib/screens/schedule/、lib/screens/search/image_search_*、lib/screens/details/... |
| 设置 | 弹幕/超分/Bangumi 配置持久化 | lib/models/settings/、lib/providers/settings/ |
| 品牌/打包 | 名称/exe/安装器/更新检查 | windows/、lib/util/application_info.dart、windows_setup.iss |

## 3. 播放与弹幕数据流

1. 用户从 Fladder 库选择条目 → PlaybackModel → MediaControlsWrapper.loadVideo。
2. LibMPV 初始化 media_kit Player + VideoController；加载视频/字幕。
3. VideoPlayer 监听 playBackModel 变化 → DanmakuService.start(item)。
4. DanmakuService：
   - 读取 DanmakuSettings；无 AppId/Secret 且无本地文件 → disabled/no_credentials。
   - 匹配：手动映射 → TMDB/ProviderIds → 标题+集号 → 可选 hash。
   - 获取评论（DDP 或本地 XML/JSON）→ 解析/过滤/偏移/采样 → 缓存。
   - 生成 DanmakuTrack（内存列表）→ DanmakuController。
5. DanmakuOverlay：
   - 读取 mediaPlaybackProvider 的 position/playing/rate。
   - Ticker 插值 + 二分查找活跃评论；预计算 lane；CustomPainter 绘制。
   - 暂停/seek/切集/倍速时重算；IgnorePointer。
6. 设置变更实时更新样式；手动匹配写 mapping 并 reload。

失败路径：任一步失败 → 状态/提示 → 不加载弹幕 → 播放继续。

## 4. 超分数据流

1. VideoPlayerSettings 包含 VideoEnhancementProfile（off/anime4k/fsrcnnx/artcnn）。
2. LibMPV.init/load 后调用 VideoEnhancement.apply(player, profile)。
3. 首次使用把 assets/shaders 复制到应用缓存目录（libmpv 需要真实路径）。
4. 通过 command(['change-list','glsl-shaders','clr','']) 清空，再 append 每个 shader 路径。
5. 关闭时清空；切换时重建；失败回退 off 并提示。
6. RTX VSR：仅做实验 spike，不作为 v1 验收；media_kit ANGLE/OpenGL 路径可能不兼容 d3d11vpp。

## 5. SyncPlay 数据流

- 复用 PR #735：
  - REST：List/New/Join/Leave/Pause/Unpause/Seek/Stop/Buffering/Ready/SetNewQueue/Queue/Ping。
  - WebSocket：/socket?ApiKey=...&deviceId=...；处理 SyncPlayCommand/SyncPlayGroupUpdate/ForceKeepAlive/KeepAlive。
  - TimeSync：/GetUtcTime 的 T2/T3 估算 offset/ping；命令按 When 调度。
- 组内本地暂停/seek → SyncPlay API；服务器广播 → 所有客户端应用。
- DanmakuOverlay 跟随 player position；SyncPlay 的 seek/pause 自然驱动弹幕重算。
- 不修改 Jellyfin 协议/服务端；不新增端口。

## 6. Bangumi 数据流

- BangumiService：v0（subjects/episodes/search/calendar）与 Next p1（calendar/comments）；可配置 API Base/HTTP 代理；1 req/s 限流；缓存。
- BangumiMappingStore：Jellyfin serverId/itemId ↔ Bangumi subject/episode；confidence/source/manual。
- 时间表：/p1/calendar → 按 weekday 分组 → 与 Jellyfin 库匹配 → SchedulePage。
- 图片识别：trace.moe → AniList 标题 → Jellyfin 本地搜索/ Bangumi 搜索（若可达）→ 用户选择。
- 评论：subject/episode → Next p1 comments → BBCode 子集 → 详情 Tab/播放器 Sheet。
- 网络不可达：状态/错误提示；模块可关闭；不影响播放。

## 7. 计划的文件布局

~~~text
lib/
  danmaku/
    models.dart
    ddp_client.dart
    comment_parser.dart
    matcher.dart
    cache.dart
    service.dart
    secret_store.dart
  providers/
    danmaku_provider.dart
    settings/danmaku_settings_provider.dart
  screens/
    video_player/components/danmaku_overlay.dart
    video_player/components/danmaku_match_dialog.dart
    settings/danmaku_settings_page.dart
  video/
    enhancement.dart
  bangumi/
    client.dart
    models.dart
    mapping_store.dart
    cache.dart
    connectivity.dart
    comments.dart
  screens/
    schedule/schedule_page.dart
    search/image_search_page.dart
    details/components/bangumi_comments_tab.dart
    video_player/components/episode_comments_sheet.dart
assets/
  shaders/anime4k/
  shaders/fsrcnnx/
  shaders/artcnn/
test/
  danmaku/
  video/
  bangumi/
tool/
  mock_ddp.dart
  mock_bangumi.dart
  mock_trace.dart
tools/
  bootstrap.ps1
  setup-jellyfin.ps1
  test.ps1
  pack.ps1
  bangumi-proxy/worker.js
~~~

## 8. 关键不变量

- 弹幕只叠加，不拦截指针；不覆盖 Jellyfin 主字幕。
- 弹幕/超分/SyncPlay/Bangumi 失败不影响基础播放。
- DDP 请求不带 Jellyfin token/服务器地址；AppSecret 不入日志。
- AppSecret 在 Windows 用 DPAPI；其他平台回退并警告。
- 不修改 media_kit 渲染器；超分只改 libmpv 属性。
- 不修改 Jellyfin SyncPlay 协议；只做客户端。
- Bangumi 映射低置信度必须人工确认；不静默绑定。
- 不复制 Kazumi 受限资产；代码复用需 GPL 署名。

## 9. 设置与存储

- 弹幕设置：SharedPreferences（AppSecret 单独 DPAPI blob）。
- 超分 profile：VideoPlayerSettingsModel（freezed/g）。
- Bangumi 设置：SharedPreferences；API Base/代理；缓存路径。
- 缓存：应用支持目录下 danmaku/、bangumi/；原子写；TTL；清缓存入口。
- 测试可用 JELLYMAKU_DATA_DIR/--dataDir 隔离（计划）。

## 10. 错误处理

| 场景 | 行为 |
|---|---|
| 无 DDP 凭证 | 弹幕 disabled/no_credentials；设置页提示；不请求 |
| DDP 401/403/429 | 显示凭证/配额错误；使用缓存（若有）；短退避 |
| 无匹配 | 提示手动匹配；不影响播放 |
| 本地 XML 解析失败 | 提示；保留原状态 |
| shader 加载失败 | 回退 off/上一个 profile；提示 |
| SyncPlay WebSocket 断开 | 重连/提示；本地播放可继续 |
| Bangumi 不可达 | 模块显示配置提示；不影响播放 |
| 映射低置信度 | 人工确认；不加载错误评论 |
