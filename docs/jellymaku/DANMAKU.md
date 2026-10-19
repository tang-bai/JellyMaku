
# 弹幕设计（DanDanPlay + Flutter 叠加层）

> 状态：Draft。
> 目标：在 Fladder 上实现弹弹play 弹幕：自动/手动匹配、滚动/顶部/底部、样式/过滤/偏移、缓存/降级。
> 参考：Kazumi 的 DDP 客户端/解析/屏蔽实现（GPL-3.0），但渲染改为 Flutter CustomPainter。

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

### 2.2 端点

| 用途 | 端点 | 说明 |
|---|---|---|
| 文件匹配 | POST /api/v2/match | 可选 hash/文件名 |
| 搜索剧集 | GET /api/v2/search/episodes?anime=...&episode=... | 候选 |
| 评论 | GET /api/v2/comment/{episodeId}?withRelated=true&chConvert=1 | 弹幕列表 |
| 连接测试 | 搜索一个固定关键词 | UI Test connection |

### 2.3 错误

- 401/403：Missing Authentication Headers / Invalid Timestamp / Invalid AppId / Invalid Signature / Invalid AppSecret。
- 429：配额/限流；读取 Retry-After。
- 网络/超时：提示；使用缓存（若有）。
- 时钟偏差：提示校准系统时间。
- 失败短缓存 10 分钟，避免反复请求；用户可强制刷新。

### 2.4 缓存

- comments/<episodeId>-<chconvert>.json；TTL 默认 7 天。
- mapping.json：serverId:itemId → episodeId/shift/source/updatedAt。
- failures.json：短 TTL。
- 原子写；损坏 JSON 容错；清缓存入口。
- DDP 请求只带标题/TMDB/集号/hash，不带 Jellyfin token/服务器地址。

## 3. 匹配

优先级：

1. 手动映射。
2. 可选文件 hash（/match）。
3. TMDB/ProviderIds。
4. 系列名/标题 + 集号。
5. 无匹配 → 候选/手动匹配。

MediaInfo：

- itemId、name、seriesName、originalTitle、episode、season、tmdbId、isMovie、fileName、fileSize、duration。

低置信度必须人工确认；不静默绑定错误条目。

## 4. 评论解析

- p 字段：time,mode,color,uid,...；m 为文本。
- 模式：1/2/3 滚动、4 底部、5 顶部（按 DDP 约定归一）。
- 颜色：十进制 RGB；透明度由设置。
- 文本：去控制字符、限制长度、XML/HTML 安全。
- 过滤：屏蔽词/用户、模式、最大条数、均匀采样。
- 偏移：danmaku_offset + match shift。
- chConvert：0/1/2 由 DDP 服务端处理。
- 去重：同用户+文本+时间窗口（建议改为 last-seen map，避免桶边界问题）。

## 5. Flutter 叠加层

### 5.1 组件

- DanmakuController：评论列表、样式、状态、generation。
- DanmakuOverlay：ConsumerStatefulWidget + Ticker；读取 mediaPlaybackProvider 的 position/playing/rate。
- DanmakuPainter：CustomPainter；TextPainter 缓存；RepaintBoundary；IgnorePointer。
- 插入 VideoPlayer Stack：视频之上、控制条之下。

### 5.2 时间同步

- 播放时：effectiveTime = lastPosition + (now - lastUpdate) * rate；Ticker 每帧刷新。
- 暂停：停止插值，保持当前时间。
- seek/切集/倍速：重置/重算。
- 活跃集合：按 startTime 排序 + 二分查找；只绘制 [start, start+duration]。
- 顶部/底部固定行；滚动 lane 分配；避免重叠。
- 显示区域限制在视频上部；底部留给字幕/控制条。

### 5.3 性能

- 5000 条解析 <200ms（Dart VM 基准）。
- 只绘制活跃评论；TextPainter 缓存；避免每帧重建列表。
- 大字号/高 DPI 下限制最大条数；必要时降采样。
- 性能测试记录到 artifacts/perf。

## 6. UI/设置

- 播放器按钮/菜单：Toggle、Match…、Reload、Settings。
- 状态 badge：ready/loading/no_match/no_credentials/error。
- 设置页：
  - AppId/AppSecret（留空保留；DPAPI）。
  - Test connection、API Base（高级）。
  - 字体/字号/透明度/速度/区域/偏移。
  - 屏蔽词/用户、简繁、自动匹配、hash、最大条数、缓存天数。
  - 本地 XML/JSON 文件；清缓存。
- 手动匹配对话框：预填作品/集号；搜索候选；shift；Use this/clear。
- 本地导入：Bilibili XML / DDP JSON；无凭证演示。
- 快捷键可选 Ctrl+D；避免冲突。

## 7. 生命周期/并发

- 每次播放 generation；旧请求完成丢弃。
- 后台线程/异步；不阻塞 mpv/UI。
- 切集/停止取消请求、清理状态。
- mpv 重启/重新打开后重载。
- 设置变更重新生成/重绘，不破坏播放位置。

## 8. 隐私/合规

- 标注“弹弹play开放弹幕网络 www.dandanplay.com”。
- 弹幕功能免费；禁止未授权商用。
- AppSecret DPAPI；日志脱敏。
- 不把 Jellyfin token/服务器地址发给 DDP。
- 缓存有限；不批量抓取；遵守配额。

## 9. 测试/验收

- 单测：签名固定向量、Path 去 query、错误映射、解析/过滤/偏移/去重、缓存 key、布局。
- Mock DDP：签名头、search/comment/match、401/403/429/空评论/无匹配。
- 本地 Jellyfin：弹幕加载、主字幕共存、seek/pause/切集、设置变更。
- 5000 条性能；截图。
- Gate：核心测试全绿；Mock E2E；无凭证/无匹配/错误不阻塞播放；缓存正确失效。

## 10. 已知限制

- 不支持发送弹幕/回复/举报。
- 特殊 ASS 特效不还原。
- 截图默认不含弹幕层；需外部截屏。
- DDP 需要用户凭证；无凭证时仅本地导入/ Mock。
