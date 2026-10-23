
# AGENTS.md

> 适用范围：本仓库根目录及其子目录。所有 agent/贡献者在改代码前先读本文与 docs/jellymaku/README.md。
> 状态：**v0.1.0** Windows 正式版已发布（2026-10-23）；Flutter 3.35.7；analyze 0 issue；**157 tests passed + 1 skipped**（2026-10-23）。RTX VSR spike 失败已回退；Anime4K Fast/Balanced/Strong/4x 已接入；danmu_api 默认 https://danmu.api.tangbai.cc，无需凭证；支持自建/本地导入。
> 日期：2026-10-23。

## 0. 当前仓库状态（必须先理解）

- 本地 `main` 已同步 origin https://github.com/tang-bai/JellyMaku 的 `main`；v0.1.0 正式版已发布；收尾更新已提交。
- `main` 已包含 Fladder 源码 + SyncPlay PR #735（head 79e249e）+ Stage A 弹幕/超分/品牌代码，并于 2026-10-21 合并 Fladder develop `de7b5a2a`。
- v0.1.0 的安装器/便携包已发布（2026-10-23）；安装器未签名；`tools/sign-release.ps1` 已支持 PFX/证书指纹，待受信任证书。
- v0.1.0 在 beta.5 基础上补齐 i18n、签名支持与安装版字幕补测，并包含播放信息面板/Seerr/缺图/日志时间修复。
- 2026-10-23 收尾：`zh`/`zh_Hant` ARB 键 1188/1188；安装版字幕补测通过；157 tests passed + 1 skipped；签名脚本已就绪，受信任证书未提供。
- 旧的 JellyMaku（基于 jellyfin-mpv-shim）实现、旧文档、旧 git 历史已丢失，无法恢复；不要尝试从远程恢复。
- Flutter 3.35.7 已安装到 .flutter；**analyze 0 issue、157 tests passed + 1 skipped；Windows release 于 2026-10-23 从当前源码构建通过**（v0.1.0 发布包即当前源码）。
- 已验证：NAS Jellyfin 12.2 登录/播放/暂停/seek（自动）以及字幕切换/切集/弹幕叠加层（手动 + 安装版字幕补测）；用户实机确认 SyncPlay 双客户端、超分性能、播放信息面板通过（2026-10-23）；播放信息截图/实时数值已采集。
- 未验证：SyncPlay/超分原始 FPS/误差/截图未归档。
- 因此：
  - 不要把“计划”当成“已实现”；
  - 不要把单测/构建通过当成真实 E2E 通过；
  - 不要在没有用户确认的情况下 push/force-push/改写历史。

## 1. 项目使命

构建 Windows 10/11 的 Jellyfin 桌面播放器 JellyMaku，基于 **DonutWare/Fladder**（Flutter/Dart，GPL-3.0），新增：

1. danmu_api 弹幕（自动/手动匹配、Flutter 叠加层、样式/过滤/偏移）。
2. GLSL shader 视频超分（Anime4K/FSRCNNX/ArtCNN）。
3. Jellyfin SyncPlay 一起看（复用 Fladder PR #735）。
4. Stage B：Bangumi 番剧时间表、以图搜番、Bangumi 评论（条件功能）。

## 2. 不可协商的决策

- **基座**：Fladder 固定 commit `de7b5a2a23f16f5f3bb164ec0baedf50941e4808`。
- **SyncPlay**：复用 PR #735 head `79e249ebf99ecc8dc8f0d5d43c3604ace45fbba9`；不要重写，不要用 Kazumi 的公共 SyncPlay。
- **弹幕**：Flutter CustomPainter 叠加层；不要改成自绘播放器/ASS secondary 为主方案。
- **超分**：GLSL shader；RTX VSR 不作为 v1 验收项（media_kit ANGLE/OpenGL 限制）。
- **Bangumi**：Stage B 条件功能；官方当前网络不可达，评论必须经用户代理/自建 Worker 才能真实联调。
- **不使用 Kazumi 作为基座**；只参考/移植 GPL 代码，不复制其图标/字体/美术。
- **所有下载物/测试资产**放本仓库目录；大文件 gitignore；manifest 校验。
- **GPL-3.0**：保留源码/许可/署名；不引入不兼容许可。

## 3. 计划中的仓库布局

~~~text
docs/jellymaku/          计划/调研/架构/测试/许可
docs/archive/mpv-shim/   旧方案占位说明（不可恢复）
lib/danmaku/             danmu_api/解析/匹配/缓存/叠加层
lib/bangumi/             Bangumi 数据层/映射/缓存
lib/video/               超分
lib/providers/            Riverpod providers
lib/screens/             播放器/设置/时间表/图片/评论
assets/shaders/          Anime4K/FSRCNNX/ArtCNN
tool/                    mock_bangumi/mock_trace
tools/                   bootstrap/setup/test/pack/worker
test/                    单测/widget
third_party/             Jellyfin/.NET/shader pack 等下载物（gitignore）
testdata/                媒体/fixtures/本地 Jellyfin（gitignore）
artifacts/               截图/日志/性能/安装包（gitignore）
~~~

## 4. 标准工作流

1. **读文档**：docs/jellymaku/README.md → OVERVIEW → DECISIONS → 对应模块文档。
2. **确认状态**：检查当前分支/文件/工具链；不要假设旧代码存在。
3. **计划**：小步；先写失败测试/验收标准；明确不做什么。
4. **实现**：最小 patch；复用 Fladder 结构；不重写播放器/同步协议。
5. **验证**：analyze/test/build/手动 E2E；记录命令/输出/截图。
6. **证据**：更新 docs/jellymaku/IMPLEMENTATION.md、ROADMAP.md；未验证项明确标注。
7. **提交**：逻辑 commit；不提交密钥/大文件；推送前用户确认。

## 5. 命令（已实际使用）

~~~powershell
# 从 ASCII 路径构建（如 subst L: <repo-parent>; cd L:\JellyMaku）
$env:PUB_CACHE = "K:\.pub-cache"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:PATH = "K:\tools\nuget;" + $env:PATH
$env:CL = "/utf-8"

.flutter\bin\flutter.bat pub get
dart analyze lib test
.flutter\bin\flutter.bat test --no-pub
.flutter\bin\flutter.bat build windows --release --no-pub
& .\tools\pack.ps1 -Version 0.1.0
~~~

- 完整依赖预置与失败处理见 docs/jellymaku/BUILD_WINDOWS.md。
- 中文/空格路径会导致 Cargokit pubspec 编码错误；必须用 ASCII 路径构建。

- 不要在没有工具链/依赖时伪造“构建成功”。

## 6. 编码约定

- Dart/Flutter；Riverpod；freezed/json_serializable；build_runner 生成文件。
- 新 UI 文案走 ARB（app_en.arb/app_zh.arb），gen-l10n；不要硬编码中文到 widget（错误日志/调试除外）。
- 网络/缓存/解析逻辑与 Widget 分离，便于单测。
- 不使用 `dart:io` 破坏 Web/移动构建；必要时条件导入/`kIsWeb` 守卫。
- 不修改 Fladder 核心状态机；小 hook/组合优先。
- 不引入重量级新依赖，除非文档说明理由/许可/构建影响。
- 代码注释解释“为什么”，不解释显而易见的“做什么”。

## 7. 测试与证据

- 单元测试优先：danmu_api 客户端/解析/匹配/缓存/布局；Bangumi client/映射/BBCode；shader profile。
- Widget 测试：设置/弹窗/无网状态。
- Mock：danmu_api 用 http MockClient/本地 HttpServer；Bangumi/trace.moe fixtures 在 testdata/fixtures。
- Jellyfin 12.2 E2E 使用 NAS（本地未安装服务端）；SyncPlay 用 Jellyfin Web/双实例。
- 每个“已通过”附命令/输出/截图路径；没有证据就写“未验证”。
- 不把 lint/analyze 通过等同于功能通过。

## 8. 安全/合规

- 不提交自建 danmu_api TOKEN、Jellyfin token、Bangumi token、真实用户数据、版权媒体。
- danmu_api TOKEN 只放在 API 地址里，不写日志；日志脱敏。
- danmu_api 请求不带 Jellyfin token/服务器地址。
- Bangumi User-Agent 明确；1 req/s；缓存；不批量抓取。
- trace.moe 仅用户主动上传；首次同意；串行/缓存。
- 不逆向/复用 Kazumi 镜像签名凭证。
- 不复制 Kazumi 图标/Mi Sans/美术；不冒充 Jellyfin/Bangumi/Fladder 官方。
- 弹幕功能免费；禁止未授权商用。

## 9. 功能状态（截至 2026-10-23）

| 功能 | 状态 |
|---|---|
| 文档/AGENTS | 状态页已同步；Stage A 报告已重写（2026-10-23） |
| Fladder 源码导入 | 完成（PR #735 head + develop `de7b5a2a` 合并） |
| Flutter/构建 | 当前 HEAD analyze 0、157 tests + 1 skipped、Windows release 构建成功；v0.1.0 发布包即当前源码 |
| SyncPlay | 用户实机确认双客户端通过；原始日志/误差/截图待归档 |
| 弹幕 | danmu_api/自动+手动匹配/URL 拉取/合并/本地导入/缓存/叠加层已接入；NAS 播放器内叠加层手动确认 |
| 超分 | Anime4K Fast/Balanced/Strong/4x 已接入；用户确认性能通过；原始 FPS/掉帧待归档 |
| 播放信息 | 用户实机确认 + 安装版 E2E 通过；实时码率/速度/缓冲/硬解/帧率；截图/数值已采集 |
| 品牌/打包 | v0.1.0 安装器 + 便携包已发布；安装版主链路 E2E + 字幕补测通过 |
| Bangumi 时间表/图片/评论 | 未开始 |
| 推送 GitHub | `main` 已同步 origin（v0.1.0） |

## 10. 已知陷阱

1. **Bangumi 官方不可达**：api.bgm.tv/next.bgm.tv 超时；api.kazumi.fyi 评论/搜索 401；不要在无代理时宣称评论可用。
2. **trace.moe 配额**：100/天、并发 1；不要批量/自动上传。
3. **RTX VSR**：2026-10-20 spike 失败：已加载后切换无变化（0.07/255）；先选 RTX 再重启加载会卡死。media_kit ANGLE/OpenGL 无法直接承载 d3d11vpp；不要把它写成已支持。回退备份：分支 `backup/pre-rtx-vsr`、标签 `backup/pre-rtx-vsr-2026-10-20`。
4. **PR #735 冲突**：基于旧 develop；2026-10-21 已合并 develop（冲突集中在 desktop_platform_wrapper/media_control_wrapper/pubspec.lock），详见 IMPLEMENTATION。
5. **中文路径**：Cargokit 生成的 pubspec 会用系统代码页，Dart 无法解析；用 ASCII 路径 + `/utf-8`。
6. **已推送**：`main` 已同步 origin（v0.1.0 发布）。RTX 实验分支 `experiment/rtx-vsr` 仅本地保留。后续 push/force-push 仍需用户确认。
7. **旧实现丢失**：不要从远程“恢复”旧 MPV Shim 代码（当时远程为空，现仅有新实现历史）。
8. **许可**：Kazumi 代码 GPL-3.0 可用，但资产不可复制；Anime4K MIT 已附许可。
9. **原生依赖下载**：libmpv/ANGLE/MDK/SQLite/NuGet 可能卡在 GitHub/SourceForge/sqlite.org/nuget.org；用 third_party 预置与本地 feed。
10. **插件注册器过期**：升级 screen_brightness_windows 后必须删除并重新生成 generated_plugin_registrant.cc/.h。
11. **SMTC 初始化竞态**：SMTC 必须在 runApp 前初始化；`_subscribePlayerState` 必须先于可选 SMTC 设置，SMTC 异常不得中断进度订阅。`smtc_windows 1.1.0` 需配 `flutter_rust_bridge 2.11.1`，否则 codegen/runtime 版本检查会失败。
12. **弹幕轨道必须稳定**：轨道分配要基于完整时间轴，不能每帧只对活动评论重排；否则评论进出窗口时行列会跳动。
13. **桌面点击暂停不能重复切换**：不要同时监听 `onHorizontalDragDown` 和 `onTap` 调用 `playOrPause`/`userPlayOrPause`；一次点击会切换两次，表现为点中间不暂停。
14. **弹幕要用独立显示时钟**：暂停/缓冲时冻结显示时间；恢复播放从冻结值继续，不要直接跳回 provider 的 raw position（会产生回拉）。不要逐帧做漂移校正（会让速度忽快忽慢）；provider 位置只用于大 seek 对齐。
15. **弹幕渲染要缓存**：轨道分配与带颜色的 TextPainter 必须缓存；每帧重排全部评论/重新 layout 文本会造成帧时间不稳，看起来像弹幕在跳动。
16. **danmu_api 来源字段语义（已实测）**：`p[3]` 是 `[bilibili1]` 这类来源标签，不是用户 id；解析时存 `provider`，`uid` 置空，`blockUsers` 不得把来源标签当用户。当前不做按站过滤 UI，来源由服务端聚合策略决定。
17. **弹幕设置分两类**：时间偏移/屏蔽词/合并/条数会改变解析结果，必须防抖重载（300ms）；字号/颜色/描边/类型与本地开关只影响绘制，直接重绘，不要触发网络或解析。
18. **本地导入的边界**：`localFile` 优先于在线 API 与手动映射，且不需要任何凭证；不提供发送弹幕（danmu_api 只读）。
19. **danmu_api 的坑（2026-10-20 实测）**：自动匹配优先 `POST /api/v2/match`（body `{"fileName":"标题 S01E01"}`）；搜索用 `search/episodes`（内嵌 episodes），不要用 `/bangumi/{id}`（404）；`标题 (2026)` 这类带空格年份的查询会 0 结果，客户端会去尾部年份/季集重试；URL 型来源用 `comment?url=<分集页面>&format=json`；非 http 的复合 ID（renren/hanjutv，如 `59377-431845`）必须用 `POST /api/v2/segmentcomment` body `{"type":"renren","url":"59377-431845","segment_start":0,"segment_end":86400000}`，公共 EdgeOne 实例的 `/comment/{id}` 依赖进程内搜索缓存，跨请求会 404；episodeId 不跨服务器稳定，缓存 key 用 `sha1(baseUrl|url)`；自建 TOKEN 放在 `/{TOKEN}` 路径；HTTPS 证书当前公共实例正常；`chConvert` 不受支持（服务端 `DANMU_SIMPLIFIED_TRADITIONAL`）。

20. **代码签名**：PFX/密码/私钥不得入库；`tools/sign-release.ps1` 支持 PFX/证书指纹；没有受信任证书时输出 `Signing skipped`，不要伪造签名。

## 11. 文档索引

- docs/jellymaku/README.md
- OVERVIEW / RESEARCH / ARCHITECTURE / PLAN / KAZUMI / BANGUMI / DANMAKU / SR / PARTY / TESTING / ASSETS / LICENSING / DECISIONS / ROADMAP / IMPLEMENTATION / STAGE_A_REPORT / BUILD_WINDOWS / UPSTREAM
- docs/upstream/FLADDER_README.md（上游 README 存档）
- docs/archive/mpv-shim/README.md

## 12. 阻塞时怎么做

- 网络/凭证/代理缺失：明确报告，提供 Mock/降级方案；不要伪造成功。
- 工具链缺失：记录错误/版本，给出安装命令；不要跳过构建验收。
- 需求冲突：新增 ADR/提问；不要静默选择。
- 用户未确认仓库/推送策略：只做本地文档/代码，不 init/push/force。
