
# 弹幕设计（DanDanPlay + Flutter 叠加层）

> 状态：v1 核心 + Kazumi 对齐增强已实现（2026-10-20）：DDP 签名/缓存/自动匹配/手动匹配 UI/去重合并/本地 XML·JSON 导入/自建 DDP 兼容服务器（danmu_api）/叠加层/设置/DPAPI。
> 未完成：真实 DDP 凭证联调、真实 Jellyfin 播放器 E2E。
> 不提供发送弹幕（DDP 无发送 API；入口已移除）。
> 目标：在 Fladder 上实现弹弹play 弹幕：自动/手动匹配、滚动/顶部/底部、来源/类型过滤、样式/偏移、缓存/降级。
> 参考：Kazumi 的 DDP 客户端/解析/来源过滤/合并去重（GPL-3.0）；渲染仍为 Flutter CustomPainter，不引入 canvas_danmaku。

## 1. 为什么不使用 ASS secondary subtitle

- media_kit 的 Windows 渲染路径使用 libass/隐藏 Flutter 字幕层；external ASS + secondary-sid 需要操作 track-list，兼容性和调试成本高。
- Flutter 叠加层可实时改样式/开关，不重新加载；与 Fladder UI 一致。
- 只绘制活跃评论（通常 <100 条），性能可控。
- 代价：不能点击弹幕、不能高级 ASS 特效、mpv 截图不含弹幕（需外部截屏）。

## 2. DanDanPlay API

### 2.1 认证

- 需要 AppId + AppSecret；签名模式：
  - X-AppId
  - X-Timestamp（UTC 秒）
  - X-Signature = base64(sha256(AppId + Timestamp + Path + AppSecret))
  - Path 以 / 开头，不含 query。
- 桌面客户端推荐签名模式；AppSecret 不硬编码、不入库。
- 公开接口不需要用户 JWT，但仍需应用身份头；无头请求实测 403。
- 本地文件导入不需要任何凭证（见 §3.1），用于离线/无凭证演示。

### 2.2 端点

| 用途 | 端点 | 说明 |
|---|---|---|
| 搜索番剧（手动匹配） | GET /api/v2/search/episodes?anime=...&v2=true | 返回 animes[]（animeId/animeTitle/typeDescription） |
| 分集列表（手动匹配） | GET /api/v2/bangumi/{animeId} | bangumi.episodes[]（episodeId/episodeTitle） |
| 搜索剧集（自动匹配） | GET /api/v2/search/episodes?anime=...&episode=... | 候选 |
| 评论 | GET /api/v2/comment/{episodeId}?withRelated=true&chConvert=1 | 弹幕列表；withRelated 合并第三方源 |
| 评论（URL） | GET /api/v2/comment?url=<原始页面>&withRelated=true | danmu_api 用这个最稳；官方 DDP 不支持 |
| 连接测试 | 搜索一个固定关键词 | UI Test connection |

### 2.3 错误

- 401/403：Missing Authentication Headers / Invalid Timestamp / Invalid AppId / Invalid Signature / Invalid AppSecret。
- 429：配额/限流；读取 Retry-After。
- 网络/超时：提示；使用缓存（若有）。
- 时钟偏差：提示校准系统时间。
- 失败短缓存 10 分钟，避免反复请求；用户可强制刷新（重新加载）。

### 2.4 缓存

- comments/<episodeId>-<chconvert>.json；TTL 默认 7 天。
- mapping.json：itemId → episodeId/shift/source/updatedAt；手动匹配写在这里，清除匹配即删除该键。
- failures.json：短 TTL（未实现，失败仅提示）。
- 原子写；损坏 JSON 容错；清缓存入口（未做 UI，服务层有 clear）。
- 本地文件不写 comments/mapping 缓存；只在播放时读取解析。
- DDP 请求只带标题/TMDB/集号/hash，不带 Jellyfin token/服务器地址。

### 2.5 自建 DDP 兼容服务器（danmu_api）

- 设置 → 高级 → 「弹幕服务器地址」填 `http://danmu.api.tangbai.cc`，AppId/AppSecret 留空即可。
- 免签名：客户端只在 AppId/AppSecret 都非空时才发 `X-AppId/X-Timestamp/X-Signature`。
- 搜索：`/api/v2/search/episodes?anime=...&v2=true` 返回 `animes[].episodes[]`，分集自带原始 `url`。
- 拉弹幕：优先 `/api/v2/comment?url=<分集 url>`；danmu_api 的 `/comment/{id}` 依赖它自己的内存映射，直接请求常为空。
- 手动匹配：danmu_api 没有 `/api/v2/bangumi/{animeId}`（404），客户端直接用搜索结果里的分集。
- 缓存：URL 型结果的 episodeId 只在该服务器内有意义，不写数值 key 缓存，避免换服务器串数据。
- HTTPS：证书必须与域名匹配。实测 `danmu.api.tangbai.cc` 证书 hostname mismatch，Dart 报 `HandshakeException`；请用 `http://` 或修复证书。
- 已实测（2026-10-20）：搜索“孤独摇滚”返回 9 条候选，用 URL 拉取 759 条弹幕并全部解析成功。
- 错误恢复：URL 路由失败/返回 0 条 → 回退 `/comment/{id}`；仍失败/0 条 → 按标题+集号重搜，按 B 站→巴哈→其他排序，最多试 5 个 http(s) 候选。

## 3. 匹配

优先级：

1. 本地文件（localFile，source=local，不需要凭证）。
2. 手动映射（mapping.json，source=manual）。
3. 可选文件 hash（/match，未实现）。
4. TMDB/ProviderIds（字段已采集，未参与匹配）。
5. 系列名/标题 + 集号（search/episodes；轻量打分：优先 B 站/巴哈、避开电影/剧场版与非目标来源）。
6. 无匹配 → 候选/手动匹配（弹窗）。

手动匹配流程（与 Kazumi 一致的三步）：

1. 设置弹窗 →「手动匹配…」，预填系列名/标题。
2. 搜索番剧 → 选择条目（animeId）。
3. 选择分集（episodeId）→ 写 mapping 并 reload(force)。
4. 「清除匹配」删除映射，回到自动匹配。

### 3.1 本地导入

- 设置弹窗选择 `.xml`（Bilibili）或 `.json`（DDP/缓存），路径存 `localFile`。
- 本地文件优先于在线匹配，不需要 AppId；清除文件后恢复 DDP/手动映射。
- Bilibili XML：`<d p="time,mode,fontsize,color,...">text</d>`——注意 color 是第 4 段，与 DDP 的 `time,mode,color,uid` 不同，解析器分开处理。
- DDP JSON：`{"comments":[{"p","m"}]}`、裸数组，或本项目缓存的 `{"danmakus":[...]}`。
- 解析后统一 `source=local`，由「本地导入」开关控制显示；不写 comments/mapping 缓存。
- 限制：一个条目一个文件；不做目录扫描/文件名自动匹配；XML 用正则解析，不引入 XML 依赖。

MediaInfo：

- itemId、name、seriesName、originalTitle、episode、season、tmdbId、isMovie、fileName、fileSize、duration。
- 当前采集：itemId/name/seriesName/episode/season/isMovie/duration/tmdbId。

低置信度必须人工确认；不静默绑定错误条目。自动匹配仍取第一条候选，属于已知弱点（见 §10）。

## 4. 评论解析

- p 字段：time,mode,color,uid；m 为文本。
- **来源**：withRelated=true 时 DDP 会把 BiliBili/Gamer 等第三方弹幕聚合进同一列表；实测 p[3] 是十六进制用户 id（不是来源标签），客户端无法按站过滤。uid 原样保留用于屏蔽；本地导入单独标记 source=local。
- **本地文件**：XML/JSON 解析后归一为同一模型，source=local，uid 保留文件里的用户字段。
- 模式：1/2/3 滚动、4 底部、5 顶部（按 DDP 约定归一）。
- 颜色：十进制 RGB；透明度由设置。
- 文本：去控制字符、限制 200 字、屏蔽词过滤。
- 偏移：offsetSeconds + match.shift；负数丢弃。
- chConvert：0/1/2 由 DDP 服务端处理。
- 去重：
  - 始终做精确去重（uid + 绝对时间 + 文本）。
  - 可选「合并重复弹幕」：全角转半角、去空白/符号、连续重复字符压缩到 3 个，5 秒窗口内相同文本合并为「文本 xN」顶部白字（Kazumi 规则）。
- 条数：maxComments 均匀采样。

**实时过滤**：顶/底/滚动与本地导入开关不参与解析，而在绘制时用 isDanmakuVisible() 判断；播放中切换立即生效。时间偏移/屏蔽词/合并/条数变化触发 300ms 防抖重载。

## 5. Flutter 叠加层

### 5.1 组件

- DanmakuController：评论列表、样式、状态、generation。
- DanmakuOverlay：ConsumerStatefulWidget + Ticker；读取 mediaPlaybackProvider 的 position/playing/rate。
- DanmakuPainter：CustomPainter；TextPainter 缓存（含描边副本）；RepaintBoundary；IgnorePointer。
- 插入 VideoPlayer Stack：视频之上、控制条之下。

### 5.2 时间同步

- 播放时：effectiveTime = lastPosition + (now - lastUpdate) * rate；Ticker 每帧刷新。
- 暂停：停止插值，保持当前时间。
- seek/切集/倍速：重置/重算。
- 活跃集合：按 startTime 排序 + 二分查找；只绘制 [start, start+duration]。
- 顶部/底部固定行；滚动 lane 分配；隐藏的评论不占轨道，避免切换开关后留空洞。
- 轨道满时复用最早结束的轨道（等价 Kazumi 的 massiveMode 常开）；不丢弃弹幕。
- 倍速：显示时钟按 rate 前进、弹幕时长按视频时间计，等价于 Kazumi「跟随倍速」常开。
- 显示区域限制在视频上部；底部留给字幕/控制条。

### 5.3 样式

- 字号/字体/透明度/显示区域/滚动时长（现有）。
- 颜色开关：关闭后统一白色。
- 描边：独立描边 TextPainter（strokeWidth 0–6），有描边时不再叠加阴影。
- 合并重复弹幕统一白色顶部（与 Kazumi 一致）。

### 5.4 性能

- 5000 条解析 <200ms（Dart VM 基准）。
- 只绘制活跃评论；TextPainter 缓存；lane 布局缓存（key 含类型/本地开关）。
- 大字号/高 DPI 下限制最大条数；必要时降采样。
- 性能测试记录到 artifacts/perf（未做）。

## 6. UI/设置

- 播放器按钮/菜单：Toggle、Settings。
- 状态行：ready/loading/no_match/no_credentials/error；显示当前匹配标题与手动/自动。
- 设置页：
  - 高级折叠：弹幕服务器地址（官方或自建 danmu_api）、AppId/AppSecret（可选）、Test connection。自建服务器可留空 AppId。
  - 字体/字号/透明度/速度/区域/偏移/描边/颜色。
  - 顶/底/滚动开关；本地导入开关。第三方弹幕由 DDP 聚合，无法按站单独开关。
  - 合并重复弹幕；简繁；自动匹配/hash/最大条数/缓存天数（字段存在）。
  - 手动匹配… / 重新加载 / 清除匹配。
  - 本地 XML/JSON：选择文件… / 清除本地文件；来源区新增「本地导入」开关。
  - 清缓存（未做 UI）。
- 手动匹配对话框（三步）：搜索番剧 → 选择分集（支持标题筛选）→ 应用。
- 本地导入：Bilibili XML / DDP JSON（未做）。
- 快捷键可选 Ctrl+D（未做）；避免冲突。

## 7. 生命周期/并发

- 每次播放 generation；旧请求完成丢弃。
- 后台线程/异步；不阻塞 mpv/UI。
- 切集/停止取消请求、清理状态。
- mpv 重启/重新打开后重载。
- 设置变更：解析类防抖重载；样式类直接重绘，不破坏播放位置。
- 手动匹配：写 mapping → 清空 state → 强制 load；旧 generation 失效。

## 8. 隐私/合规

- 标注“弹弹play开放弹幕网络 www.dandanplay.com”。
- 弹幕功能免费；禁止未授权商用。
- AppSecret DPAPI；日志脱敏。
- 不把 Jellyfin token/服务器地址发给 DDP。
- 缓存有限；不批量抓取；遵守配额。

## 9. 测试/验收

- 单测（danmaku_test.dart 11 条 + local_import_test.dart 5 条 + danmaku_ui_test.dart 3 条 widget）：
  - 签名固定向量；手动匹配 searchAnime/getEpisodes 解析与请求路径。
  - 解析/模式/偏移/屏蔽/精确去重/来源/合并规则/实时可见性。
  - 本地 XML/JSON：模式/颜色/实体解码/去重/坏格式；本地来源可见性。
  - 设置序列化（不落 AppSecret；新字段 round-trip）。
  - Widget：设置弹窗（AppId 默认折叠/展开可见）、手动匹配首屏。
- Mock DDP：签名头、search/comment、401/403/429/空评论/无匹配（部分）。
- 本地 Jellyfin：弹幕加载、主字幕共存、seek/pause/切集、设置变更（未做）。
- 5000 条性能；截图（未做）。
- Gate：核心测试全绿；Mock E2E；无凭证/无匹配/错误不阻塞播放；缓存正确失效。

## 10. 已知限制

- 自动匹配只取第一条候选，遇到同名片目可能匹配错；请用「手动匹配」。
- **DDP 不提供来源标签**：实测缓存响应 3975/3975 条 p[3] 都是十六进制用户 id，BiliBili/Gamer 弹幕已被聚合进同一列表；客户端不能按站过滤，也不应把“关闭弹弹play”做成隐藏全部。此前三分支来源开关已移除。
- 不提供发送弹幕/回复/举报；DDP 没有发送 API，入口已移除。
- 本地导入一次一个文件，不做目录扫描/文件名自动匹配；XML 用容错正则解析，极端命名空间可能失败。
- 特殊 ASS 特效不还原；截图默认不含弹幕层。
- DDP 在线匹配需要用户凭证；无凭证时可用本地导入，或填自建 danmu_api 服务器（免签名）。
- 自建服务器的 URL 型弹幕不写缓存；danmu_api 的 episodeId 不跨服务器稳定，换服务器后需重新匹配。
- HTTPS 证书必须匹配域名；当前 danmu.api.tangbai.cc 证书 hostname mismatch，需用 http:// 或修证书。

## 11. 与 Kazumi 实现的对应关系

| 能力 | Kazumi | JellyMaku |
|---|---|---|
| 拉取 | /comment/{episodeId}，withRelated+chConvert | 相同 |
| episodeId | animeId*10000+4 位集号 | 走 search/episodes 返回的 episodeId（不拼 ID） |
| 来源过滤 | 假定 p[3] 是来源标签 | 实测 p[3] 是 uid，无法按站过滤；只区分在线/本地 |
| 手动匹配 | 三步搜索 | 三步对话框 + mapping 持久化 |
| 去重合并 | 归一化 + 5s 窗口 + xN | 相同，默认关闭 |
| 本地导入 | 无 | 设置选择 Bilibili XML / DDP JSON，source=local |
| 自建服务器 | 无 | 支持 danmu_api：URL 拉弹幕、免 AppId；官方 DDP 仍走签名 |
| 发送 | 本地回显 / SyncPlay 聊天 | 不提供（入口已移除） |
| 渲染 | canvas_danmaku（Ticker+CustomPaint） | 自绘 CustomPainter + 独立显示时钟 |
| 暂停 | canvas.pause() | 冻结显示时钟 |
