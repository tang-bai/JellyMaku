
# Kazumi 三项能力专项分析：番剧时间表、图片识别、Bangumi 评论

> 历史说明（2026-10-20）：弹幕数据源已改为 danmu_api；文中弹幕对比仅作历史记录。
> 状态：调研/可行性分析（2026-10-19）。
> 结论：三项都可以做，但都依赖 Bangumi 网络可达性；当前网络下评论不能开箱即用。

## 0. 结论摘要

| 能力 | Kazumi 实现 | 移植到 Fladder 的可行性 | 主要风险 |
|---|---|---|---|
| 番剧时间表 | Bangumi Next `/p1/calendar` + 官方搜索补季 | **高**：数据/排序/过滤逻辑清晰，UI 重写 | Bangumi 不可达；标题↔Jellyfin 映射 |
| 图片识别 | trace.moe `/search?anilistInfo=2` → AniList 标题 → 站内搜索 | **高**：trace.moe 可用；Jellyfin 本地匹配容易 | 无直接 Bangumi ID；隐私/配额 |
| Bangumi 评论 | Next `/p1/subjects/{id}/comments`、`/p1/episodes/{id}/comments` | **中**：模型/交互可移植；接口非官方 OpenAPI | 当前网络不可达；镜像评论 401；映射/SP |
| 弹幕/超分（附加） | 在线弹幕 + canvas_danmaku；Anime4K + glsl-shaders | **高**：可直接参考/复用 | GPL 署名；media_kit 渲染差异 |

**不建议把 Kazumi 作为基座**：它没有 Jellyfin 登录/库/播放上报，且“一起看”使用公共 SyncPlay 服务器，与 Jellyfin SyncPlay 不兼容；改成 Jellyfin 客户端约 3–4 周且风险高。

## 1. Kazumi 项目

- 仓库：https://github.com/Predidit/Kazumi
- 许可证：GPL-3.0
- 技术：Flutter/Dart，flutter_modular + MobX，media_kit，Hive，Dio
- 定位：基于自定义 XPath 规则的番剧采集/在线观看，不是 Jellyfin 客户端。
- 规模：约 3.8 万 stars，825 个 tracked 文件。
- 相关能力：番剧时间表、图片识别、Bangumi 元数据/评论、在线弹幕、Anime4K、公共 SyncPlay、下载、投屏。

## 2. 番剧时间表

### 2.1 实现

- 当前季：GET `https://next.bgm.tv/p1/calendar`（Kazumi 通过镜像/加速访问）；返回 1–7 的列表，每项含 `subject`。
- 非当前季：POST `https://api.bgm.tv/v0/search/subjects`，`filter.type=[2]`、`air_date` 日期范围，分页 4 页 × 20；再按放送日期分组。
- 镜像：GET `https://api.kazumi.fyi/kazumi/v1/calendar/season?start=...&end=...`，不需要签名。
- 排序/过滤：评分、热度、默认；在追、弃番、已看；数据来自 Bangumi subject 的 rating/collection。
- 关键代码：
  - lib/pages/timeline/timeline_controller.dart
  - lib/pages/timeline/timeline_page.dart
  - lib/pages/timeline/timeline_week_selector.dart
  - lib/request/apis/bangumi_api.dart
  - lib/bean/card/bangumi_timeline_card.dart

### 2.2 移植设计

- Fladder 新增 SchedulePage（导航页/标签），Riverpod provider 管理日历、排序、过滤、缓存。
- 当前季直接 `/p1/calendar`；非当前季用官方搜索按 air_date 补；缓存 12–24h。
- 与 Jellyfin 库匹配：
  - 已保存 mapping → 标题+年份+集数 → 人工绑定。
  - 卡片显示“在库/未入库/已看/弃番”；点击进入 Jellyfin 详情或 Bangumi 链接。
- Gate：当前季 7 天展示、排序/过滤/跳转/缓存；无网/401 提示。

### 2.3 可行性

- 数据逻辑简单，移植成本低；主要风险是 Bangumi 网络与标题映射。
- 官方 v0 `/calendar` 是 legacy 接口；当前网络不可达；可用代理/自建镜像。

## 3. 图片识别番剧

### 3.1 实现

- 本地文件：POST `https://api.trace.moe/search?anilistInfo=2`，body 为图片字节，Content-Type: image/jpeg。
- 图片 URL：POST `/search?anilistInfo=2&url=...`（不传 body）。
- 返回：`frameCount`、`error`、`result[]`；result 含 `anilist`（标题、synonyms、episodes、duration）、`episode`、`from`、`at`、`similarity`、`filename`。
- Kazumi 选择结果后，只把标题回填到站内搜索，再搜索自己的视频源；**没有 AniList→Bangumi ID 映射**。
- 关键代码：
  - lib/pages/search/image_search_page.dart
  - lib/pages/search/image_search_widgets.dart
  - lib/modules/search/image_search_module.dart
  - lib/request/apis/trace_api.dart
  - lib/request/clients/trace_client.dart

### 3.2 移植设计

- 搜索页新增“以图搜番”Tab/对话框；本地图片或 URL；预览；首次上传同意。
- trace.moe 串行请求、按图片 SHA-256 缓存、quota/error 提示；不做自动/批量上传。
- 匹配：
  - Jellyfin：用 AniList 标题/synonyms 搜索本地库（Series/Movie），展示候选；有集数时提示定位。
  - Bangumi：仅当 Bangumi 可达时用标题搜索；否则显示 AniList/trace.moe 链接。
  - 不自动绑定/不自动播放。
- Gate：选图 → 识别 → Jellyfin 候选/跳转；隐私/配额提示。

### 3.3 可行性

- trace.moe 实测可用：quota=100、concurrency=1（按 IP，无 API key）。
- 识别准确率受截图质量/作品年代影响；需要人工确认。
- 映射到 Jellyfin 可用标题/别名/年份；映射到 Bangumi 只能标题搜索+人工确认。

## 4. Bangumi 评论

### 4.1 实现

- 主题评论：GET `https://next.bgm.tv/p1/subjects/{subjectId}/comments?limit=20&offset=...`；返回 `list`/`total`；字段含 user、rate、comment、updatedAt。
- 分集吐槽：GET `https://next.bgm.tv/p1/episodes/{episodeId}/comments`；返回数组，含 content、createdAt、user、replies。
- 角色评论：GET `/p1/characters/{id}/comments`（可选）。
- 集数映射：GET `https://api.bgm.tv/v0/episodes?subject_id=...&limit=100&offset=...`；EpisodeInfo 使用 id/sort/type/name/name_cn。
- 渲染：BBCode + 用户头像 + 回复展开；只读。
- 关键代码：
  - lib/request/apis/bangumi_api.dart
  - lib/modules/comments/*
  - lib/pages/info/info_comments_view.dart
  - lib/pages/player/episode_comments_*
  - lib/bean/card/user_comments_card.dart
  - lib/bbcode/*

### 4.2 网络实测（关键）

| 端点 | 结果 |
|---|---|
| api.bgm.tv / next.bgm.tv / bgm.tv | 连接超时（HTTP 000） |
| api.kazumi.fyi/p1/calendar | 200 |
| api.kazumi.fyi/p1/subjects/253 | 200 |
| api.kazumi.fyi/v0/episodes?subject_id=253 | 200 |
| api.kazumi.fyi/p1/subjects/253/comments | 401 invalid request signature |
| api.kazumi.fyi/p1/episodes/1027/comments | 401 invalid request signature |
| api.kazumi.fyi/v0/search/subjects | 405/401（需签名） |

- 官方 v0 OpenAPI 确认没有 comments 路径；评论只能走 Next `/p1`（非官方 OpenAPI）或网页。
- Kazumi 的镜像签名使用私有凭证（bangumi_mirror_credentials），**不可复用/逆向**。
- 结论：评论必须有用户代理/VPN、自建反向代理，或经授权的镜像；否则只能 Mock/离线演示。

### 4.3 移植设计

- 数据层：BangumiService 支持官方 v0 + Next p1；可配置 API Base/HTTP 代理；1 req/s；缓存 1–7 天。
- 映射：
  - Series/Movie → subject：标题+年份+ProviderIds/infobox 交叉验证；人工确认。
  - Episode → Bangumi episode：按 sort/type；SP/OP/ED 单独；不能用 offset=episode-1。
- UI：
  - 详情页“Bangumi 评论”Tab：评分、用户、日期、BBCode、分页。
  - 播放器“分集吐槽”Sheet：按集加载、回复展开、只读。
  - BBCode v1 支持粗体/斜体/下划线/删除线/颜色/链接/引用/剧透/图片；安全过滤；暂不引入 ANTLR 全量解析器。
- 网络门槛：连接测试失败隐藏/提示；不影响播放。
- Gate：Mock/代理下评论可读；无网优雅降级；不冒充可用。

## 5. Kazumi 代码复用与许可

| 模块 | 复用方式 | 注意 |
|---|---|---|
| 时间表数据/排序/过滤 | 移植逻辑，重写 Riverpod/UI | 保留 API 参数/日期算法 |
| 图片识别 API/模型 | 移植 Dart 模型/请求 | trace.moe 配额/隐私 |
| 评论模型/UI 结构 | 移植模型/交互，重写组件 | Next API 不稳定；BBCode 简化 |
| 弹幕解析/屏蔽 | 已移植（2026-10-20）：合并去重、手动匹配；渲染仍用 CustomPainter | 实测旧弹幕 p[3] 是 uid，Kazumi 的来源标签假设不成立，未移植按站过滤 |
| Anime4K shader/服务 | 复用资产/加载思路 | GPL/Anime4K 许可；渲染验证 |
| 一起看 | 不复用 | Kazumi 公共 SyncPlay，Jellyfin 用 PR #735 |
| 图标/字体/美术 | 不复制 | Kazumi 有单独版权限制 |

Kazumi 为 GPL-3.0，代码移植/衍生需保留许可与署名；不要复制其受限图标/字体/美术。

## 6. 最终建议

- 采用 **Fladder + PR #735** 作为基座；Kazumi 作为功能参考/移植来源。
- Stage A 先交付核心播放器；Stage B 以**条件功能**方式加入时间表/图片识别/评论。
- 评论功能在实现前先确认用户有可用 Bangumi 网络路径；否则只做 Mock/架构预留，不承诺可用。
- 时间表可先接镜像/代理；图片识别先做 trace.moe + Jellyfin 本地匹配，Bangumi 映射可选。
