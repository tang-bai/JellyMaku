
# 实施检查清单与证据模板

> 状态（2026-10-23）：v0.1.0-beta.5 已发布；工作区干净。
> 当前 HEAD：analyze 0 issue；156 tests passed + 1 skipped；Windows release 于 2026-10-23 构建成功。
> 已验证：NAS Jellyfin 12.2 登录/播放/暂停/seek（自动），字幕切换/切集/弹幕叠加层（手动）。
> 未完成：SyncPlay 双客户端、超分 FPS/掉帧、安装版完整 E2E、播放信息面板真实播放验证、Stage B。
> 用途：让后续 agent 按清单推进，避免“文档写了但没做”。

## 1. Stage A 检查清单

### A0 仓库/工具链

- [x] 确认仓库策略（新建 main）。
- [x] 固定 Fladder commit de7b5a2；记录 PR #735 head。
- [x] 以 PR #735 head 导入 Fladder + SyncPlay，并 merge 文档。
- [x] 解决 README/.gitignore 冲突；main 已快进到导入提交。
- [x] 合并最新 develop `de7b5a2a`（分支 `merge/develop-20261021`；冲突：desktop_platform_wrapper/media_control_wrapper/pubspec.lock）。
- [x] Flutter 3.35.7 到 .flutter；PUB_CACHE 本地。
- [x] VS BuildTools/Windows SDK/Developer Mode 检查通过。
- [x] flutter analyze/test 通过（0 issue；当前工作区 156 tests + 1 skipped）。
- [x] flutter build windows --release 成功；启动冒烟通过。
- [x] 真实 Jellyfin 12.2（NAS `192.168.8.137:8096`）登录/播放测试片；未在本地启动 Jellyfin/.NET。
- [x] third_party/manifest.json 生成；`tools/verify-assets.ps1` 通过（8 items）。

### A1/A2 弹幕

- [x] lib/danmaku 核心；danmu_api 客户端/错误/URL 哈希缓存。
- [x] 自动匹配：`POST /api/v2/match` 优先，`search/episodes` 打分回退。
- [x] 手动匹配：搜索番剧→内嵌分集→应用，mapping.json 持久化，可清除（自动 mapping 也可清）。
- [x] 来源标签：`p[3]` 解析为 provider，不作为 uid；只保留本地导入开关。
- [x] danmu_api：默认 `https://danmu.api.tangbai.cc`、可自建（TOKEN 写在地址路径）、URL 拉弹幕、手动匹配用搜索内分集。
- [x] 合并重复弹幕：归一化（全角/空白/符号/重复字符）+5 秒窗口 +「xN」顶部白字。
- [x] 实时过滤：类型/来源开关无需重载；解析类设置 300ms 防抖重载。
- [x] 样式：颜色开关、描边（独立 stroke TextPainter）、显示区域/透明度/字号/速度/偏移。
- [x] 本地 XML/JSON 导入（Bilibili XML / danmu_api 兼容 JSON，`source=local`，优先于在线匹配）。
- [x] 发送弹幕入口已移除（danmu_api 只读；不提供本地回显）。
- [x] Flutter 叠加层；设置弹窗；播放器入口。
- [x] 单测/Mock（danmu_api HTTP mock/本地 HttpServer、解析/来源/合并、匹配请求、设置迁移）。
- [x] Jellyfin E2E：seek/pause 自动验证；字幕切换/切集/弹幕叠加层由用户手动验证通过（2026-10-21）。
- [x] 5000 条解析/布局基准：`parse` 52–55ms、首帧 15–17ms、平均 1.0–1.1ms/帧（`test/danmaku/danmaku_perf_test.dart`；Flutter test 环境，非播放器内 FPS）。

### A3 超分

- [x] shader 资产/许可；profile 模型（Anime4K Fast/Quality）。
- [x] glsl-shaders 应用；失败仅日志回退。
- [x] 播放器菜单/持久化（独立设置页未做）。
- [x] 至少 3 个 profile 截图（`artifacts/screenshots/sr-*.png`）。
- [ ] 性能记录（FPS/掉帧；目前只有 GPU 利用率粗测）。
- [x] RTX VSR 结论：spike 失败已回退（`backup/pre-rtx-vsr`），v1 不做。

### A4 SyncPlay

- [x] PR #735 代码导入；Windows release 构建包含 smtc_windows。
- [x] 中文文案/组面板完善（2026-10-22 补齐 `syncPlay*` 与 `leave`，真实 UI 复测通过）。
- [x] 侧栏「一起看」状态点与当前页面高亮互斥（2026-10-22 真实 UI 复测）。
- [ ] 双客户端矩阵；Jellyfin 12.2 WebSocket（单测已通过，真实联调未做）。
- [ ] 双端日志/截图/位置误差。

### A5 品牌/打包

- [x] JellyMaku 名称/exe/窗口/版本资源；窗口标题已改为 JellyMaku；关于页链接改为 JellyMaku。
- [x] 更新检查指向 `tang-bai/JellyMaku`（含 Windows zip 资产识别与 UA）。
- [x] i18n ARB en/zh；gen-l10n（弹幕设置/手动匹配/按钮提示已迁移，中文 UI 测试通过）。
- [x] portable zip；Anime4K/Fladder 许可保留；Inno 脚本 `installer/jellymaku.iss` + `tools/build-installer.ps1` 已加。
- [x] Inno 安装器实际编译；静默安装/启动/卸载冒烟通过（Inno 6.7.3 → tools/inno）。
- [ ] 干净目录完整功能验证；Stage A 真实 E2E 验收（安装/启动/卸载冒烟已完成，功能 E2E 未做）。

### A6 播放信息面板

- [x] `SDR HD` 徽章可点击，打开实时播放信息对话框；显示码率/下载速度/缓冲/丢帧/硬解/渲染帧率/加载耗时。
- [x] `PlaybackRuntimeStats` + libmpv/MDK/Native 后端分级读取；ARB 三语。
- [x] 单测/analyze/Windows release 构建通过（2026-10-23）。
- [ ] NAS Jellyfin 播放中点击徽章的 UI 截图与实时数值确认。

## 2. Stage B 检查清单

### B0 数据层

- [ ] BangumiClient（v0/Next p1）；可配置 Base/代理。
- [ ] User-Agent/限流/缓存/错误。
- [ ] MappingStore；MOCK。
- [ ] worker.js 模板；连接测试。
- [ ] 单测。

### B1 时间表

- [ ] 当前季/非当前季；分组/排序/缓存。
- [ ] SchedulePage；在库/已看/弃番；跳转。
- [ ] 映射/手动绑定。
- [ ] Mock/无网/截图。

### B2 图片识别

- [ ] 以图搜番入口/预览/同意。
- [ ] trace.moe 客户端/缓存/配额。
- [ ] Jellyfin 候选/跳转；Bangumi 条件映射。
- [ ] Mock/错误/隐私/截图。

### B3 评论

- [ ] 主题/分集评论；分页/缓存。
- [ ] 映射/SP；BBCode 子集；只读。
- [ ] 详情 Tab/播放器 Sheet。
- [ ] 无网降级；Mock/代理验收。

## 3. 证据模板

每个功能完成后追加：

~~~text
### <功能>
- 日期：
- commit：
- 命令：
- 结果：通过/失败/降级
- 截图：artifacts/screenshots/...
- 日志：artifacts/logs/...
- 性能：artifacts/perf/...
- 已知问题：
- 未验证项：
~~~

### 弹幕 v2（手动匹配/来源/合并/本地导入）

- 日期：2026-10-20
- commit：feat(danmaku): add source filters, manual match and duplicate merge；feat(danmaku): add local import and local echo（2026-10-20）
- 命令：
  - `.\.flutter\bin\flutter.bat test --no-pub` → 121 tests passed（迁移前历史记录；迁移后 137）
  - `.\.flutter\bin\dart.bat analyze lib test` → No issues found
- 结果：通过（单元/静态）；未做真实弹幕/Jellyfin E2E、未重新构建 Windows 包。
- 截图：artifacts/screenshots/danmaku-*（未生成）
- 性能：5000 条未压测
- 已知问题：p[3] 来源语义待真实凭证确认；自动匹配仍取第一条候选；本地 XML 用正则解析。
- 未验证项：真实凭证搜索/拉取、手动匹配落盘后的播放、来源开关在真实混合弹幕下的表现、本地文件在真实播放器中的时间轴。

### Windows release 重建（2026-10-20）

- 命令（ASCII 路径 `L:\JellyMaku`）：
  - `.flutter\bin\flutter.bat build windows --release --no-pub` → √ Built `build\windows\x64\runner\Release\JellyMaku.exe`（116.1s；多源回退后重建）
  - `tools\pack.ps1 -Version 0.1.0` → `artifacts\JellyMaku-0.1.0-windows-x64-portable.zip`（90,733,695 bytes，SHA256 `4F25765532DDE9002C1ECA207100CE5AFBF2BF98C00D81B33A04DA41522CDB13`）
  - 启动冒烟：portable exe 启动 8 秒未退出，随后手动结束。
- 证据：`data\app.so` 时间 2026-10-20 22:25；zip 22:26。
- 注意：`JellyMaku.exe` 本体未变（runner 未改），新 Dart 代码在 `data\app.so`；只替换 exe 不会更新界面。

### danmu_api 迁移（2026-10-20）

- 服务器：`https://danmu.api.tangbai.cc`（HTTPS 证书有效，PowerShell 200；旧文档的 hostname mismatch 已过时）。
- 实测：
  - `GET /api/v2/search/episodes?anime=孤独摇滚` → 200，9 条番剧、内嵌 episodes。
  - `POST /api/v2/match` body `{"fileName":"孤独摇滚！ S01E01"}` → `isMatched=true`；电影片名也能命中。
  - `GET /api/v2/comment?url=<bilibili 页面>&format=json` → 200，6,898 条；`p` 例 `2.69,1,16777215,[bilibili1]`。
  - Dart `DanmakuApiClient` live probe（临时测试，已删除）：`matchFile('孤独摇滚！ S01E01')` → episodeId 10022；`getComments(url)` → 6,899 条，中文正常；耗时约 9s。
  - `searchAnime('FX战士久留美')` → 3 个 renren 分集（url 为 `59377-431223` 等复合 ID）；`getComments(url: 59377-431845, provider: renren)` → 4 条；第 01 集 → 0 条（源站本身无弹幕）。
  - `GET /api/v2/comment/10004?format=json` → 404；`GET /api/v2/bangumi/4780191` → 404。
- 代码：
  - 删除旧弹幕客户端/签名/凭证与密钥存储；新增 `DanmakuApiClient`（match/search/comment）。
  - 自动匹配 `/match` 优先、`search/episodes` 回退；评论 `url + format=json`；id 路由仅兜底。
  - `p[3]` 解析为 `provider`；缓存 key `sha1(baseUrl|url)`；设置 `apiBase` 迁移并清理旧 secret。
  - 旧 mapping 无 url 时重搜；最多 5 个候选；协议相对 URL 补 `https:`。
  - 搜索标题自动去尾部年份/季集（如 `X (2026)` → `X`）重试；非 http 复合 ID 走 `segmentcomment`。
- 命令：
  - `.\\.flutter\\bin\\dart.bat analyze lib test` → No issues found。
  - `.\\.flutter\\bin\\flutter.bat test --no-pub` → 137 tests passed。
  - `.\\.flutter\\bin\\flutter.bat test --no-pub test\\danmaku` → 40 tests passed。
- 构建/打包（2026-10-20 23:38）：
  - ASCII 路径 `L:\\JellyMaku`：`flutter build windows --release --no-pub` → √ Built，107.5s；`data\\app.so` 23:38:02。
  - `tools\\pack.ps1 -Version 0.1.0` → `artifacts\\JellyMaku-0.1.0-windows-x64-portable.zip`，90,712,816 bytes，SHA256 `5FFC849F33D8E7216EE93AEC17192EBE7EEDAEEC8A47D97452FA891564B61237`。
  - 启动冒烟：Release exe 运行 8s 正常后手动结束。
- 未验证：播放器内真实加载/切集/暂停；真实 Jellyfin 媒体；真实混合来源弹幕表现。

### 弹幕 5000 条压测 / 超分截图（2026-10-21）

- 弹幕基准：`flutter test --no-pub test/danmaku/danmaku_perf_test.dart`
  - 5000 条：解析 52–55ms，首帧（轨道+文本布局）15–17ms，后续帧平均 1.0–1.1ms（120 帧）
  - 限制：Flutter test/Ahem 字体环境，非播放器内实际 FPS；真实播放叠加层仍建议人工观感确认
- 超分截图（NAS 12.2 播放《药屋少女的呢喃》，窗口截图）：
  - `artifacts/screenshots/sr-off.png`、`sr-fast.png`、`sr-balanced.png`、`sr-strong.png`
  - 历史对比：`sr-off-bright.png`、`sr-fast-bright.png`、`sr-quality-bright.png`、`sr-diff-off-quality.png`
- 性能粗测：GPU 总利用率约 23%，JellyMaku 进程约 4.3%（Strong）；**未采集 FPS/掉帧**，A3 性能项暂不勾选。

### v0.1.0-beta.5 发布（2026-10-23）

- Release: https://github.com/tang-bai/JellyMaku/releases/tag/v0.1.0-beta.5
- 资产:
  - `JellyMaku-0.1.0-beta.5-windows-x64-setup.exe` 73,183,739 bytes，SHA256 `4084271BE1C56879CAD4D0504A408B618B83921DCCD5C37F169708EA4F1E2596`
  - `JellyMaku-0.1.0-beta.5-windows-x64-portable.zip` 100,878,057 bytes，SHA256 `AFD688B195B8D07FF73A9E79DB274CAC085DE9CAA52DB0FE7D6B1D2ACF0443C6`
- 内容：播放信息面板、Seerr 未配置修复、缺图 404 占位、日志本地时区、SyncPlay 中文文案/侧栏高亮、`THIRD_PARTY_NOTICES.md`。
- 安装器验证：静默安装到 `artifacts/install-test-5` → 启动窗口标题 JellyMaku → 静默卸载成功；安装包含 `THIRD_PARTY_NOTICES.md`；未做安装后完整功能 E2E。
- 资产校验：`third_party/manifest.json` 8 项，`tools/verify-assets.ps1` 全部 OK。

### v0.1.0-beta.4 发布（2026-10-21）

- Release: https://github.com/tang-bai/JellyMaku/releases/tag/v0.1.0-beta.4
- 资产:
  - `JellyMaku-0.1.0-beta.4-windows-x64-setup.exe` 66,321,323 bytes，SHA256 `B31CB7BA225B4477E87CDAB6F41403408CC173AF831B5359664430DA9DF1A7E2`
  - `JellyMaku-0.1.0-beta.4-windows-x64-portable.zip` 90,884,125 bytes，SHA256 `9438CD22E95E3CB73746C8CF3EC803103918C4EB72B7AD1D698D2280764691AF`
- 安装器验证：静默安装到 `artifacts/install-test` → 启动窗口标题 JellyMaku → 静默卸载成功；未做安装后完整功能 E2E。
- 资产校验：`third_party/manifest.json` 8 项，`tools/verify-assets.ps1` 全部 OK。

### 本地 Jellyfin E2E（NAS，2026-10-21）

- 服务器：`http://192.168.8.137:8096`，Jellyfin **12.2.0**（ServerName「媒体库」）；测试账号 `test`（密码不入库）。
- 登录：`POST /Users/AuthenticateByName` 返回 200。注意 12.2 需要 `Authorization: MediaBrowser Client="...", Device="...", DeviceId="...", Token="..."`；沿用旧的 `X-Emby-Authorization` 会 400。
- 客户端：JellyMaku 自动登录成功；`/Sessions` 出现 `Client=JellyMaku`、`DeviceName=Windows`、`User=test`。
- 媒体库：电影 191 条、剧集 5380 条可见。
- 播放：打开《药屋少女的呢喃》S01E51「如果没有面包」：
  - 位置 54s → 59s（5s 采样）；
  - 空格暂停后位置冻结在 60s（3s 内不变）；再按空格恢复并推进到 62s；
  - 右方向键 ×3 → 155s（每次约 30s，符合用户 skipForward 设置）。
- 用户手动复测（2026-10-21，用户确认通过）：**字幕切换、切集、弹幕叠加层** 三项已在同一 NAS 环境手动验证通过。
- 自动化侧未覆盖：Flutter 自绘 UI 无法用 UIA 定位控件，字幕/切集/弹幕仍以手动结果为准。
- 限制：Flutter 自绘 UI 在 Windows 只暴露 `FLUTTERVIEW` 节点，UIA 无法按控件名定位；本次用坐标点击 + 窗口标题辅助，建议后续补 `integration_test` 或可访问性语义树。

### 上游 Fladder develop 合并（2026-10-21）

- 日期：2026-10-21
- 合并目标：`fladder/develop` = `de7b5a2a23f16f5f3bb164ec0baedf50941e4808`（上游最新，领先基线 18 个提交）
- 分支：`merge/develop-20261021`（基于 main `06da5e30`，本地；未推送）
- 冲突解决：
  - `lib/bootstrap/platform/desktop_platform_wrapper.dart`：保留本地“SMTC 在 bootstrap/runApp 前初始化”，只接收上游的 Windows URL 协议注册（`ensureWindowsProtocolRegistered`）。
  - `lib/wrappers/media_control_wrapper.dart`：采用上游 `!MultiWindowMediaSession.supported` 判据 + 保留本地 try/catch（SMTC 失败不得中断播放状态订阅）。
  - `pubspec.lock`：取上游后重新 `flutter pub get`（镜像），锁定新依赖（app_links 等）。
  - 附带：`multi_window_media_session.dart` 的 SMTC 构造加 try/catch，避免 Hub 初始化被 SMTC 异常打断。
- 命令（ASCII 路径 `L:\JellyMaku`）：
  - `.flutter\bin\flutter.bat pub get` → 成功（GitHub 需 `http.version=HTTP/1.1`；见 BUILD_WINDOWS）
  - `.flutter\bin\dart.bat analyze lib test` → No issues found!
  - `.flutter\bin\flutter.bat test --no-pub` → **137 tests passed**
  - `.flutter\bin\flutter.bat build windows --release --no-pub` → √ Built `build\windows\x64\runner\Release\JellyMaku.exe`（71.5s；app.so 2026-10-21 02:24）
  - 启动冒烟：Release exe 运行 8s 未退出（手动结束）
  - `tools\pack.ps1 -Version 0.1.0` → `artifacts\JellyMaku-0.1.0-windows-x64-portable.zip`，90,878,704 bytes，SHA256 `2E3850FCFC3DDD3BA42E234EB0C677016F605CBD4BBE20EF14ACCFF28D59944D`
- 结果：通过（静态/单测/构建）；**未做**真实 Jellyfin/播放器内弹幕/SyncPlay 双端 E2E。
- 已知问题：`dart run build_runner build` 会对全部生成文件产生纯格式化重排（dart_style 差异，170 个文件），本次已回退，仅保留上游自带的生成文件；后续如需再生成需单独评审。
- 未验证项：上游多窗口媒体会话、深链（app_links）、照片同步 UI 在真实 Jellyfin 下的行为；弹幕/超分/SyncPlay 与上游改动的交互。

### Seerr 未配置时的崩溃修复（2026-10-22）

- 现象：日志出现 `SEVERE | Flutter error: HttpException: Seerr server not configured`，栈为 `SeerrRequest.intercept` → `SeerrService.me` → `SeerrUser._fetchUser`。
- 原因：`SeerrUser.build()` 无条件请求 Seerr 的当前用户；未配置 Seerr 时 `SeerrRequest` 直接抛异常，该 Future 无人 await，最终进入 `PlatformDispatcher.onError` 记一条 SEVERE。打开监听 `seerrUserProvider` 的页面（如“设置 → 个人资料”）即可触发。
- 修复：
  - `lib/providers/seerr_api_provider.dart`：新增 `isSeerrConfigured()`（`FladderConfig.seerrBaseUrl` 或 `seerrCredentials.isConfigured`）。
  - `lib/providers/seerr_user_provider.dart`：`build()` 未配置直接返回 null、不发请求；`refreshUser()` 同样短路；`_fetchUser` 加 try/catch，失败只写 `dart:developer` 日志。
- 证据（2026-10-22）：`flutter analyze --no-pub` → No issues found（40.9s）；`flutter test --no-pub` → 144 tests passed（含新增 `test/providers/seerr/seerr_config_test.dart` 6 项）。
- 未验证：真实 Seerr 实例的“连接 → 拉取用户 → 发起请求”E2E；本次仅静态检查 + 单测。
### 缺图 404 不再写入崩溃日志（2026-10-22）

- 现象：`SEVERE | Flutter error: HttpException: Invalid statusCode: 404, uri = http://<服务器>/Items/<id>/Images/Primary?fillHeight=600&fillWidth=600&quality=90`。
- 定位：`flutter_cache_manager` 的 `HttpFileService` 对非 200 抛 `HttpExceptionWithStatus`；`FadeInImage`/`Image` 在没有 `imageErrorBuilder`/`errorBuilder` 时会把异常转给 `FlutterError.onError`，被 `CrashLogNotifier` 记为 SEVERE。实测该 URL 在 NAS 上返回 404（响应头 `age` 约 19 天，非偶发），即条目元数据里有 Primary 标签但服务器上没有图。
- 修复：
  - `lib/util/fladder_image.dart`：未传 `imageErrorBuilder` 时默认回退到 `placeHolder ?? SizedBox.shrink()`。
  - `lib/screens/shared/detail_scaffold.dart`：`getDominantColor` 取色失败返回 `null`；详情页头图 `FadeInImage` 加 `imageErrorBuilder`。
  - `lib/screens/video_player/components/video_progress_bar.dart`：章节缩略图缺失时显示空。
- 影响面：仅该条目封面/背景是否显示；缺图条目改为显示占位，不再刷崩溃日志。
- 证据（2026-10-22）：`flutter analyze --no-pub` → No issues found（48.5s）；`flutter test --no-pub` → 146 tests passed（新增 `test/util/image_fallbacks_test.dart` 2 项）。
### 日志时间跟随本机时区（2026-10-22）

- 需求：日志按电脑当前时间显示，格式 `MM.dd-HH:mm`（如 `10.22-18:28`）。
- 实现：
  - `lib/util/log_time.dart`：`formatLogTime()` 取 `toLocal()` 后输出 `MM.dd-HH:mm`。
  - `lib/models/error_log_model.dart`：崩溃日志页/复制文本（`content`/`clipBoard`）使用该格式；`toJson` 仍存 UTC 瞬时值，重载后按本机时区渲染。
  - `lib/providers/crash_log_provider.dart`：调试控制台 `logPrint` 同样使用该格式。
- 说明：早先版本曾固定 UTC+8 并带 `+08:00` 偏移，现按需求改回本机时区；如需排查跨时区问题，可再临时加偏移后缀。
- 证据（2026-10-22）：`flutter analyze --no-pub` → No issues found；`flutter test --no-pub` → 见本轮测试结果（`test/util/log_time_test.dart` 5 项）。

### 一起看导航按钮不再抢占当前页面高亮（2026-10-22）

- 现象：创建/加入 SyncPlay 组后，侧边栏「一起看」与当前页面（如「媒体库」）同时显示选中背景；切换到其他按钮后「一起看」仍保持高亮。
- 原因：`lib/widgets/navigation_scaffold/components/side_navigation_bar.dart` 把表示“已加入组”的 `isSyncPlayActive` 直接传给了 `NavigationButton.selected`，而该参数应只表示当前路由。
- 修复：
  - 「一起看」按钮固定 `selected: false`，不再参与页面选中态。
  - 已加入组时改为显示 8px 状态圆点（`_SyncPlayNavBadge`），颜色跟随 `SyncPlayGroupState`；离开组后圆点消失。
  - 页面高亮仍由 `currentIndex` 决定，保证同一时间只有一个导航项显示选中背景。
- 证据（2026-10-22）：`dart analyze lib test` → No issues found；`flutter test --no-pub` → 151 tests passed（1 skipped 手动联网探针）。
- 构建：`flutter build windows --release --no-pub` → `√ Built build\windows\x64\runner\Release\JellyMaku.exe`（2026-10-22 19:00，202.5s；设置 `SystemDrive=C:` 后 MSBuild `FileTracker` 恢复正常）。
- 真实 UI 点击复测（2026-10-22 18:52–18:56，Windows x64）：自动登录 NAS Jellyfin 12.2，UI 创建 `UITest1022` / `UITest1022B` 组；分别切到「媒体库」「已同步」后，侧边栏只有当前页面显示棕色选中 pill，「一起看」行无选中背景，仅右侧保留 8px 状态圆点；离开组后圆点消失。
- 截图证据：`artifacts/ui-test/with-group.png`（媒体库）、`with-group-synced.png`（已同步）、`without-group.png`（离开组后）。
- 复测方式说明：UI 复测使用 `flutter assemble` 生成的新 `app.so`（18:44，已确认含 `syncplay_active_badge`）复制到 Release 目录运行；随后 19:00 的完整 Windows release 构建成功，Release 目录中的 `app.so` 仍为该份 AOT 产物。
- 未验证：真实双客户端（JellyMaku + Jellyfin Web/第二实例）同步播放；本次只验证侧边栏高亮与组状态点。

### 一起看模块中文化（2026-10-22）

- 问题：`app_zh.arb` / `app_zh_Hant.arb` 缺少 SyncPlay 文案，生成代码回退到英文；UI 出现 `Create SyncPlay Group`、`Group Name`、`No active groups`、`Leave`、`Joined ...` 等英文。
- 修改：
  - `lib/l10n/app_zh.arb`：补齐 44 个 `syncPlay*` 文案 + 通用 `leave`（「离开」）。
  - `lib/l10n/app_zh_Hant.arb`：补齐 45 个 `syncPlay*` 文案 + 通用 `leave`（「離開」）。
  - 运行 `flutter gen-l10n` 重新生成中文 getter；未改动 SyncPlay 业务逻辑。
- 真实 UI 复测（2026-10-22 22:22–22:26，Windows x64，NAS Jellyfin 12.2）：
  - 创建组对话框显示「创建一起看群组」「群组名称」「电影之夜」「取消」「创建」；
  - 空列表显示「没有活跃的群组」「创建一个群组，和大家一起看」「创建群组」；
  - 创建/加入后提示「已加入“ZHTest1022”」，活动组面板显示「空闲」及中文引导；
  - 离开组提示「已离开一起看群组」。
- 证据：`flutter analyze lib test` → No issues found；`flutter test --no-pub` → 151 tests passed（1 skipped）；`flutter build windows --release --no-pub` → `√ Built ...`（124.0s）；截图 `artifacts/ui-test/localized-sheet.png`、`localized-create-dialog.png`。
- 说明：`zh` 仍有 4 个与深链相关的旧缺失键，`zh_Hant` 仍有 200 个非 SyncPlay 旧缺失键；本次只覆盖一起看模块。

### 播放信息面板：画质徽章入口 + 实时码率/加载速度（2026-10-23）

- 需求：播放页点击右下角 `SDR HD` 画质徽章，显示当前视频码率、视频加载/下载速度等详细信息。
- 实现：
  - `video_player_controls.dart`：`mediaInfoTag` 徽章改为可点击的 `InkWell`（带 Tooltip），与「直接播放」徽章共用 `showVideoPlaybackInformation`。
  - `video_playback_information.dart`：重写为每秒刷新的播放信息对话框；实时区显示状态、当前/视频/音频码率、下载速度、缓冲、丢帧、硬件解码、渲染帧率、加载耗时；媒体区显示视频/音频编码、分辨率、容器、源码率、文件大小、播放类型、播放器后端、转码原因/进度与 URL。
  - `PlaybackRuntimeStats` + `BasePlayer.playbackStats()`：libmpv 读取 `video-bitrate`/`audio-bitrate`/`cache-speed`/`demuxer-cache-duration`/`frame-drop-count`/`estimated-vf-fps`/`hwdec-current`/`video-codec`/`audio-codec`/`file-format`，并记录加载耗时；下载速度优先用 `demuxer-cache-state` 的 `total-bytes` 增量计算，`cache-speed` 为 0 时仍可显示实际读取速率；MDK 读取 MediaInfo；Native 后端优雅降级为静态信息。
  - `lib/util/byte_formatting.dart`：字节数/下载速率格式化；ARB 新增中/英/繁中文案。
- 证据（2026-10-23）：`dart analyze lib test` → No issues found；`flutter test --no-pub` → 156 tests passed（1 skipped）；`flutter build windows --release --no-pub` → `√ Built build\windows\x64\runner\Release\JellyMaku.exe`（114.9s）。
- 未验证：真实 NAS Jellyfin 播放中点击徽章的 UI 截图与实时数值；libmpv `cache-speed` 在真实 HTTP 直连流上的数值表现需实机确认（本地文件探测为 0，属预期）。

### 文档复核（2026-10-23）

- 命令：
  - `.flutter\bin\dart.bat analyze lib test` → No issues found
  - `.flutter\bin\flutter.bat test --no-pub` → 156 tests passed + 1 skipped（手动联网探针）
- 结果：通过（静态/单测）；本次未重新构建/打包，沿用 2026-10-23 的 Windows release 构建记录。
- 修改：同步 README/AGENTS/ROADMAP/IMPLEMENTATION/PLAN/DANMAKU/TESTING/BUILD_WINDOWS/ASSETS/ARCHITECTURE/UPSTREAM/DECISIONS/SR/PARTY 的状态与计数。
- 剩余：SyncPlay 双端、超分性能、安装版 E2E、播放信息面板实机、Stage A 报告重写、随安装包复核第三方声明。

## 4. 禁止事项

- 不把“文档计划”写成“已实现”。
- 不把 lint/analyze 通过当成功能通过。
- 不提交密钥/真实账号/版权媒体。
- 不使用 Kazumi 受限图标/字体/美术。
- 不做未授权的 Bangumi/danmu_api 批量抓取。
- 不在无代理情况下宣称 Bangumi 评论可用。

## 5. 当前进度

- 文档：状态页已按 2026-10-23 结果同步；STAGE_A_REPORT 仍为历史版本，待重写。
- 代码：Fladder + PR #735 head 已导入，develop `de7b5a2a` 已合并；弹幕/超分/SyncPlay/播放信息面板已接入；Bangumi Stage B 未开始。
- 构建：当前 HEAD Windows release 于 2026-10-23 构建成功；beta.5 发布资产为同一提交产物。
- 测试：当前 HEAD 156 tests passed + 1 skipped（2026-10-23）；analyze 0 issue。
- 发布：v0.1.0-beta.5 安装器/便携包已发布；安装器未签名，安装目录完整 E2E 未做。
- 未验证：SyncPlay 双端、超分 FPS/掉帧、安装版完整功能、播放信息面板实机数值。
