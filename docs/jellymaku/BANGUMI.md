
# Bangumi 模块设计（Stage B）

> 状态：Draft / 条件功能。
> 前提：Bangumi API 网络可达（用户代理/VPN/自建反向代理）。当前网络官方 API 不可达，公共镜像的评论/搜索接口要求签名，不可复用。

## 1. 目标

- 番剧时间表：当前季/指定季，按星期展示，标记 Jellyfin 在库/已看/弃番，点击跳转。
- 图片识别：以图搜番，识别结果匹配 Jellyfin 本地库；Bangumi 可达时提供 subject 候选。
- Bangumi 评论：详情页主题评论 + 播放器分集吐槽，只读，BBCode 子集。
- 所有模块可独立关闭；网络不可达不影响播放。

## 2. 网络与 API

### 2.1 端点

| 用途 | 端点 | 说明 |
|---|---|---|
| 当前季日历 | GET https://next.bgm.tv/p1/calendar | Kazumi 使用；非官方 OpenAPI |
| 指定季补全 | POST https://api.bgm.tv/v0/search/subjects | filter.type=[2]、air_date 范围、分页 |
| 条目 | GET https://api.bgm.tv/v0/subjects/{id} | 官方 v0 |
| 剧集 | GET https://api.bgm.tv/v0/episodes?subject_id=... | 官方 v0 |
| 搜索 | POST https://api.bgm.tv/v0/search/subjects | 官方 v0 |
| 主题评论 | GET https://next.bgm.tv/p1/subjects/{id}/comments?limit=20&offset=... | 非官方；只读 |
| 分集评论 | GET https://next.bgm.tv/p1/episodes/{id}/comments | 非官方；只读 |
| 角色评论 | GET https://next.bgm.tv/p1/characters/{id}/comments | 可选 |

### 2.2 网络实测

- 官方 api.bgm.tv / next.bgm.tv / bgm.tv：连接超时。
- api.kazumi.fyi：日历/条目/剧集可匿名；评论/搜索 401 invalid request signature。
- 官方 v0 OpenAPI 没有 comments。
- 结论：必须提供用户代理/自建 Worker；评论功能为条件功能。

### 2.3 设置

- Bangumi 启用开关。
- API Base：官方（默认）或自建 Worker URL。
- HTTP 代理：host:port（Dart HttpClient.findProxy；SOCKS 需额外实现）。
- 连接测试；清缓存；缓存天数。
- 第三方镜像提示（若不实现，不提供默认镜像）。

### 2.4 自建代理模板

提供 `tools/bangumi-proxy/worker.js`：

- 允许路径：
  - GET `/p1/calendar`
  - GET `/p1/subjects/*`（含 `/comments`）
  - GET `/p1/episodes/*`（含 `/comments`）
  - GET `/p1/characters/*`
  - GET `/v0/subjects/*`
  - GET `/v0/episodes*`
  - POST `/v0/search/subjects`
- 转发到 `https://api.bgm.tv` 或 `https://next.bgm.tv`，设置 `User-Agent: JellyMaku/<version> (repo)`。
- 不透传客户端 Cookie/Authorization；不加私有凭证；只读白名单。
- 用户自行部署，填入 API Base；仓库不内置任何 URL/密钥。

## 3. 数据层

### 3.1 BangumiClient

- 两套 base：v0（api.bgm.tv）与 Next（next.bgm.tv）；可被 API Base 覆盖。
- User-Agent：`JellyMaku/<version> (https://github.com/tang-bai/JellyMaku)`。
- 超时 15s；重试 1 次；429/401/403 明确错误；1 req/s 保守限流。
- 缓存：JSON 文件，按路径+参数 hash；原子写；TTL（日历 12–24h、subject 7d、episodes 7d、comments 1–7d）。
- 连接测试：GET `/p1/calendar`；区分 DNS/TLS/超时/401/签名错误。

### 3.2 模型

- BangumiSubject：id、name、name_cn、date、images、rating、votes、metaTags、info、eps。
- BangumiEpisode：id、subject_id、sort、type、name、name_cn、airdate、duration。
- CalendarDay：weekday、subjects。
- SubjectComment：user、rate、comment、updatedAt。
- EpisodeComment：user、content、createdAt、replies。
- SearchResult：list/total。

### 3.3 映射存储

- `BangumiMappingStore`：key = serverId:itemId；value = subjectId、episodeId、confidence、source、manual、updatedAt。
- source：manual/tmdb/title/hash。
- 低置信度不自动加载评论；UI 提示“确认 Bangumi 条目”。
- 支持清除/重建映射；导入/导出可选。

### 3.4 映射算法

1. 手动 mapping。
2. Jellyfin BaseItemDto.ProviderIds（Tmdb/Tvdb/AniDb/Imdb）→ Bangumi subject infobox 外部链接交叉验证。
3. 标题+年份+集数：NFKC、去标点、大小写归一；name/name_cn/synonyms。
4. 人工确认。
5. 剧集：/v0/episodes?subject_id=...&type=0；按 sort/type 与 IndexNumber/ParentIndexNumber；SP/OP/ED 单独；禁止 offset=episode-1。

## 4. 番剧时间表

### 4.1 数据

- 当前季：GET /p1/calendar；按 weekday 分组。
- 非当前季：POST /v0/search/subjects，filter type=[2]、air_date 范围、分页；按放送日期分组。
- 排序：评分/热度/默认；过滤：在库/未入库/已看/弃番。
- 缓存 12–24h；离线显示上次缓存。

### 4.2 UI

- Fladder 导航“放送表”页；周选择器（7 天）。
- 卡片：封面、中日文名、评分、放送日、在库/已看徽标。
- 点击：Jellyfin 详情；未入库 → Bangumi 链接/手动绑定。
- 空态/错误/缓存提示。
- 与 Fladder 主题/自适应布局一致。

### 4.3 验收

- Mock/代理下 7 天展示；排序/过滤/跳转/缓存。
- 无网显示缓存/提示，不影响其他页面。
- Jellyfin 映射手动确认。

## 5. 图片识别

### 5.1 流程

1. 搜索页“以图搜番”；选择本地图片或 URL；预览。
2. 首次上传同意（trace.moe 第三方）。
3. POST /search?anilistInfo=2；串行；按图片 SHA-256 缓存。
4. 解析 result[]：similarity、episode、from/at、anilist.title/synonyms/episodes。
5. 匹配 Jellyfin：标题/synonyms 搜索 Series/Movie；展示候选；有集数时提示定位；用户选择跳转。
6. 匹配 Bangumi：仅当可达时标题搜索；展示候选；否则 AniList/trace.moe 链接。
7. 不自动绑定/不自动播放。

### 5.2 错误/隐私

- quota 100/天、concurrency 1：一次一个请求；提示配额。
- 图片上传第三方：明确同意；不自动截图；缓存本地。
- 识别不确定时显示多个候选 + 相似度。
- 不存储原图（除用户本地缓存）；不上传 Jellyfin 私有信息。

### 5.3 验收

- Mock/真实 trace.moe 选图 → 结果 → Jellyfin 候选/跳转。
- 配额/网络错误提示。
- 不自动上传；缓存命中。

## 6. Bangumi 评论

### 6.1 数据

- 主题：GET /p1/subjects/{id}/comments?limit=20&offset=...
- 分集：GET /p1/episodes/{id}/comments
- 缓存 1–7 天；分页；429/401 处理。
- 官方 v0 无评论；Next p1 非官方；网络不可达时隐藏/提示。

### 6.2 UI

- 详情页 Tab：评分、用户头像/昵称、日期、BBCode、分页。
- 播放器 Sheet：按集加载；回复展开；只读。
- BBCode v1：粗体/斜体/下划线/删除线/颜色/链接/引用/剧透/图片；安全过滤（HTML/JS/URL 协议）。
- 署名“评论来自 Bangumi”；不提供发送/点赞/举报。
- 图片懒加载/缓存；限制最大宽度。

### 6.3 映射

- Series/Movie → subject：标题+年份+ProviderIds/infobox；人工确认。
- Episode → Bangumi episode：/v0/episodes；按 sort/type；SP 单独。
- 映射失败：显示“未匹配 Bangumi”，不加载错误评论。

### 6.4 验收

- Mock/代理下主题评论+分集吐槽+回复+BBCode。
- 无网：入口隐藏/提示；不影响播放。
- 不冒充“开箱即用”；文档写明代理要求。

## 7. 测试

- 单测：client URL/限流/缓存/错误；日历分组；映射；BBCode 过滤；trace 解析。
- Widget：SchedulePage、ImageSearchPage、CommentsTab/Sheet、无网状态。
- Mock Bangumi：calendar/subject/episodes/comments/search。
- Mock trace.moe：成功/无结果/配额/超时。
- 本地 Jellyfin：映射/跳转。
- 真实联调（可选）：用户代理后 smoke；记录结果。
- 证据：artifacts/screenshots、logs、bangumi。

## 8. 风险

- 官方 API 不可达；Next p1 不稳定；镜像签名不可复用。
- 标题映射错误；SP/剧场版错位。
- trace.moe 配额/准确率/隐私。
- 评论内容合规/缓存/再分发。
- 代理部署门槛；用户可能无法提供。

## 9. 交付

- lib/bangumi/、页面/设置、Mock、Worker 模板、测试、截图。
- 文档更新 RESEARCH/KAZUMI/BANGUMI/TESTING/ROADMAP。
- 验收分“Mock/代理通过”和“无网降级”两种。
