
# 弹幕设计（danmu_api + Flutter 叠加层）

> 状态（2026-10-23）：2026-10-20 已迁移到 [danmu_api](https://github.com/huangxd-/danmu_api)，默认公共实例 `https://danmu.api.tangbai.cc`。
> 已实现：自动/手动匹配、URL 拉取、多来源聚合解析、缓存、本地 XML/JSON 导入、Flutter 叠加层、设置。当前工作区 `dart analyze` 0 issue；157 tests passed + 1 skipped。
> 已验证：NAS Jellyfin 12.2 播放器内叠加层手动确认；seek/pause 自动验证，字幕/切集手动验证。
> 未完成：真实混合来源弹幕的系统性回归/截图；不提供发送弹幕（danmu_api 只读）。

## 1. 为什么用 Flutter 叠加层

- media_kit 的 Windows 渲染路径使用 libass/隐藏 Flutter 字幕层；external ASS + secondary-sid 需要操作 track-list，兼容性和调试成本高。
- Flutter 叠加层可实时改样式/开关，不重新加载；与 Fladder UI 一致。
- 只绘制活跃评论（通常 <100 条），性能可控。
- 代价：不能点击弹幕、不能高级 ASS 特效、mpv 截图不含弹幕（需外部截屏）。

## 2. danmu_api

### 2.1 地址与认证

- 默认：`https://danmu.api.tangbai.cc`。
- 设置 →「高级：弹幕 API 地址」可改为自建 danmu_api。
- 自建服务若设置 `TOKEN`，把 `/{TOKEN}` 放在地址路径里（如 `http://192.168.1.10:9321/87654321`）；客户端不单独保存 token 字段。
- 客户端不发送旧应用凭证，也没有旧签名；只带 `Accept` / `User-Agent`。
- 旧设置里的旧 API 地址会自动迁移到默认公共实例；旧的密钥存储会在加载时删除。

### 2.2 端点（已实测）

| 用途 | 端点 | 说明 |
|---|---|---|
| 自动匹配 | `POST /api/v2/match`，body `{"fileName":"标题 S01E01"}` | `matches[]` 含 episodeId/animeTitle/episodeTitle/shift/url；`isMatched=false` 时回退搜索 |
| 搜索 + 分集 | `GET /api/v2/search/episodes?anime=...&episode=...` | `animes[].episodes[]` 内嵌分集与原始 url；手动匹配直接用 |
| 拉弹幕（主路径） | `GET /api/v2/comment?url=<原始页面>&format=json` | 返回 `comments[{cid,p,m,t}]`；必须显式 `format=json` |
| 拉弹幕（非 URL 源） | `POST /api/v2/segmentcomment?format=json` | renren/hanjutv 的 `url` 是 `59377-431845` 这类复合 ID；body `{type,url,segment_start,segment_end}`，无状态、不依赖搜索缓存 |
| 拉弹幕（兜底） | `GET /api/v2/comment/{episodeId}?format=json` | 依赖服务端进程内搜索缓存；公共 EdgeOne 实例跨请求常 404，只作最后尝试 |
| 连接测试 | `GET /api/v2/search/episodes?anime=test` | 设置里的「测试连接」 |
| 不可用 | `GET /api/v2/bangumi/{animeId}` | 实测 404；手动匹配必须用搜索内嵌分集 |

### 2.3 实测记录（2026-10-20）

- `search/episodes?anime=孤独摇滚` → 200，9 条番剧、每条内嵌 episodes。
- `POST /match` body `{"fileName":"孤独摇滚！ S01E01"}` → `isMatched=true`；电影 `孤独摇滚（上）` 也能命中。
- `comment?url=...&format=json` → 200，6,898 条；`p` 固定 4 段，如 `2.69,1,16777215,[bilibili1]`。
- Dart 客户端 live probe（临时测试，已删除）：match → episodeId 10022；comments → 6,899 条，中文正常，约 9s。
- `searchAnime('FX战士久留美')` → 3 个 renren 分集，url 为 `59377-431223` 等复合 ID（不是 http）。
- `segmentcomment`（type=renren）：第 02 集 `59377-431845` → 4 条；第 01 集 `59377-431223` → 0 条（源站确实没有弹幕）。
- `comment/10004` → 404 `{"count":0,"comments":[]}`；`comment?episodeId=...` → 400 `Missing commentId or url parameter`。公共 EdgeOne 实例每次请求可能落到新实例，`comment/{id}` 依赖的搜索缓存会丢失。
- `bangumi/4780191` → 404 `Anime not found`。
- HTTPS 证书当前有效（PowerShell 200）；不需要退回 http。

### 2.4 错误与超时

- 客户端超时 30s（评论响应可能 700KB/近 7k 条）。
- 401/403：错误信息追加“自建服务若设置 TOKEN，请把 /{TOKEN} 加到地址末尾”。
- 400/404（评论 URL/id）：视为空结果，交给上层重搜候选；其他状态/网络错误抛 `DanmakuException`。
- 429/Retry-After 保留在异常字段；当前不自动重试。
- 无缓存且请求失败 → 状态 `error`，不阻塞播放。

## 3. 匹配

优先级：

1. 本地文件（`localFile`，source=local，不请求网络）。
2. mapping.json（手动或上次自动匹配的结果；读取存储的 `source`）。
3. `POST /api/v2/match`：剧集 fileName 为 `系列名 S01E02`，电影用片名。
4. `search/episodes` + 轻量打分：B 站/巴哈优先，优酷/爱奇艺等降权，标题包含、集号正则加分；电影不惩罚“电影/剧场版”。
5. 无匹配 → `noMatch`，提示手动匹配。

`/match` 404（旧自建版本）或网络错误时静默回退 `search/episodes`；两者都没结果才报错/无匹配。

手动匹配流程：

1. 设置弹窗 →「手动匹配…」，预填系列名/标题。
2. `search/episodes?anime=<关键词>` → 选择番剧（结果已带分集）。若原标题带 `(2026)`、`S01E01`、`第1集` 等后缀，客户端会自动去掉尾部年份/季集后重试。
3. 选择分集 → 写 mapping（episodeId/titles/shift/source=manual/url）→ reload(force)。
4. 「清除匹配」删除 mapping（自动/手动均可），回到自动匹配。

### 3.1 本地导入

- 设置弹窗选择 `.xml`（Bilibili）或 `.json`（danmu_api 兼容），路径存 `localFile`。
- 本地文件优先于在线匹配；清除文件后恢复在线/手动映射。
- Bilibili XML：`<d p="time,mode,fontsize,color,...">text</d>`——color 是第 4 段，与在线 `time,mode,color,[来源]` 不同，解析器分开处理。
- JSON：`{"comments":[{"p","m"}]}`、裸数组，或缓存里的 `{"danmakus":[...]}`。
- 解析后统一 `source=local`、`provider=''`；由「本地导入」开关控制显示；不写评论/mapping 缓存。
- 限制：一个条目一个文件；不做目录扫描/文件名自动匹配；XML 用正则解析，不引入 XML 依赖。

MediaInfo：`itemId/name/seriesName/episode/season/isMovie/duration/tmdbId`。当前匹配只用标题/季/集/电影标记。

## 4. 评论解析

- `p`：`时间,模式,颜色,[来源]`；`m` 为文本。
- **来源标签**：实测 `p[3]` 是 `[bilibili1]` 这类来源标签，不是用户 id。解析后存 `provider`，`uid` 置空（只有非标签值才当 uid）。因此「屏蔽用户」不会误伤整个来源。
- 本地文件：`source=local`、`provider=''`，uid 保留文件里的用户字段。
- 模式：1/2/3 滚动、4 底部、5 顶部。
- 颜色：十进制 RGB；透明度由设置。
- 文本：去控制字符、限制 200 字、屏蔽词过滤。
- 偏移：`offsetSeconds + match.shift`；负数丢弃。
- 简繁转换：danmu_api 不支持 `chConvert` 查询参数，由服务端环境变量 `DANMU_SIMPLIFIED_TRADITIONAL` 控制；客户端已移除该设置。
- 去重：
  - 始终精确去重（原始 `p[3]` + 绝对时间 + 文本）。
  - 可选「合并重复弹幕」：全角转半角、去空白/符号、连续重复字符压缩到 3 个，5 秒窗口内相同文本合并为「文本 xN」顶部白字。
- 条数：`maxComments` 均匀采样。

**实时过滤**：顶/底/滚动与本地导入开关不参与解析，而在绘制时用 `isDanmakuVisible` 判断；播放中切换立即生效。时间偏移/屏蔽词/合并/条数变化触发 300ms 防抖重载。

## 5. Flutter 叠加层

- `DanmakuController`：评论列表、样式、状态、generation。
- `DanmakuOverlay`：ConsumerStatefulWidget + Ticker；读取 `mediaPlaybackProvider` 的 position/playing/rate。
- `DanmakuPainter`：CustomPainter；TextPainter 缓存（含描边副本）；RepaintBoundary；IgnorePointer。
- 插入 VideoPlayer Stack：视频之上、控制条之下。
- 独立显示时钟：暂停/缓冲冻结；恢复从冻结值继续；provider 位置只用于大 seek 对齐；不逐帧校正。
- 轨道分配基于完整时间轴并缓存；隐藏评论不占轨道；轨道满时复用最早结束的轨道。
- 倍速：显示时钟按 rate 前进；顶部/底部固定 4.5s，滚动按 `speedSeconds`。
- 样式：字号/字体/透明度/显示区域/滚动时长/颜色开关/描边；合并结果统一白色顶部。

## 6. UI/设置

- 播放器底栏「Danmaku」→ 设置弹窗。
- 状态行：`danmu_api · 状态：…`；显示当前匹配标题与自动/手动/本地。
- 「高级：弹幕 API 地址」：地址输入 + 测试连接；默认公共实例；token 路径写进地址。
- 字体/字号/透明度/速度/区域/偏移/描边/颜色。
- 顶/底/滚动开关；本地导入开关。
- 合并重复弹幕；自动匹配/最大条数/缓存天数（部分字段暂无 UI）。
- 手动匹配… / 重新加载 / 清除匹配。
- 本地 XML/JSON：选择文件… / 清除本地文件。
- 已移除：旧应用凭证、简繁转换下拉、密钥存储。

## 7. 生命周期/并发

- 每次播放 generation；旧请求完成丢弃。
- 切集/停止取消状态、清理。
- 设置变更：地址变化防抖重载；解析类防抖重载；样式类直接重绘。
- 手动匹配：写 mapping → 清空 state → 强制 load。

## 8. 隐私/合规

- UI/README 标注 danmu_api 项目与默认实例。
- 不发送 Jellyfin token/服务器地址给弹幕 API。
- 自建 danmu_api TOKEN 只在地址里，不写日志；旧凭据不再保存。
- 缓存有限、按需请求；不批量抓取；失败不空转。
- 弹幕功能免费；禁止未授权商用。

## 9. 测试/验收

- `dart analyze lib test`：0 issue。
- `flutter test --no-pub`：157 tests passed + 1 skipped（2026-10-23，当前工作区）。
- 弹幕相关：
  - 客户端：match POST、search 查询、comment URL+format、segmentcomment 非 URL 源、UTF-8、URL 规范化、400 回退 id、404 空结果、401 TOKEN 提示、isMatched=false。
  - 解析：来源标签/旧式 uid、模式/颜色/偏移/屏蔽/去重/合并/可见性。
  - 匹配：mapping 优先、match 优先、search 回退、autoMatch=false、电影 fileName、错误传播。
  - 设置迁移：默认地址、旧地址迁移、旧键忽略。
  - 缓存 key：同 URL 稳定、跨服务器/URL 区分。
  - Widget：设置弹窗高级区、手动匹配首屏。
- 真实 API 冒烟：search/episodes、match、comment?url 均 200；6,898 条弹幕。
- 真实播放器内：NAS Jellyfin 12.2 已完成 seek/pause 自动验证与字幕/切集/叠加层手动验证；未做混合来源的系统性回归和截图。

## 10. 已知限制

- 自动匹配依赖 Jellyfin 标题；英文/日文标题在 danmu_api 未配置标题映射时可能失败，请用手动匹配。
- danmu_api 是聚合器：BiliBili/巴哈/爱优腾等来源由服务端决定；若部署包含 `[dandan]` 源，客户端仍会显示（当前不做来源过滤）。
- `/comment/{id}` 与 `/bangumi/{id}` 不可靠，代码不再依赖；旧 mapping 没有 url 时会按标题+集号重搜。
- 非 http 的复合 ID（renren/hanjutv）走 `segmentcomment`；若源站本身没有弹幕（如 renren 第 01 集），会显示“该分集在 renren 源暂无可用弹幕”。
- 手动匹配一次只保存一个分集；切集后需要重新匹配或依赖自动匹配。
- 本地导入一次一个文件，不做目录扫描。
- 不还原 ASS 特效；截图默认不含弹幕层。
- 公共实例可用性/限流由服务方决定；失败时显示错误，不影响播放。

### 排障速查

| 现象 | 大概率原因 | 处理 |
|---|---|---|
| 已匹配但 0 条弹幕 | 该集在源站真的没有弹幕 | 换一集；或换源/手动匹配 |
| 手动匹配搜不到 | 标题带 `(2026)`/`S01E01`/`第1集` 后缀 | 客户端会自动去掉后缀重试；也可手动删后缀再搜 |
| `comment/{id}` 404 | 公共 EdgeOne 实例每次请求可能落到新实例，搜索缓存丢失 | 客户端已用 `segmentcomment` 规避；自建实例建议用 Vercel/Netlify/Docker |
| 匹配到了 renren 但时间轴不对 | renren 源弹幕极少且时间轴可能偏移 | 手动匹配时选 B 站/巴哈等其它源，或调时间偏移 |

## 11. 与 Kazumi 对照

| 能力 | Kazumi | JellyMaku |
|---|---|---|
| 拉取 | /comment/{episodeId}，withRelated+chConvert | danmu_api /comment?url + format=json |
| 自动匹配 | 搜索+打分 | /match 优先，search 回退 |
| 来源过滤 | 假定 p[3] 是来源标签 | p[3] 存 provider，当前不做按站开关 |
| 手动匹配 | 三步搜索 | 搜索+内嵌分集+保存 mapping |
| 去重合并 | 归一化 + 5s 窗口 + xN | 相同，默认关闭 |
| 本地导入 | 无 | Bilibili XML / danmu_api JSON，source=local |
| 发送 | 本地回显 / SyncPlay 聊天 | 不提供 |
| 渲染 | canvas_danmaku | 自绘 CustomPainter + 独立显示时钟 |

## 12. 迁移记录（2026-10-20）

- 删除：旧弹幕客户端、签名、应用凭证、密钥存储、`withRelated/chConvert` 参数、`/bangumi/{id}` 调用。
- 新增：`DanmakuApiClient`（match/search/comment）、URL 哈希缓存 key、`source=online`、`provider` 字段、地址迁移。
- 默认地址：`https://danmu.api.tangbai.cc`；可自建覆盖。
