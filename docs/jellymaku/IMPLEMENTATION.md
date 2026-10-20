
# 实施检查清单与证据模板

> 状态：Stage A 核心已构建/验证：Flutter 3.35.7、analyze 0、137 tests（2026-10-21，Fladder develop 合并后）；Windows release 于 2026-10-21 重新构建；portable zip 最近一次为 2026-10-20。
> 弹幕在 2026-10-20 迁移到 danmu_api：默认公共实例、`/api/v2/match` 自动匹配、URL 拉取、来源标签解析、URL 哈希缓存、移除旧凭证/签名/密钥存储。
> 真实 Jellyfin/SyncPlay E2E 仍未完成；播放器内真实弹幕加载/切集未验证。
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
- [x] flutter analyze/test 通过（0 issue；137 tests）。
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
- [ ] 双客户端矩阵；Jellyfin 12.2 WebSocket（单测已通过，真实联调未做）。
- [ ] 中文文案/组面板完善。
- [ ] 日志/截图/误差。

### A5 品牌/打包

- [x] JellyMaku 名称/exe/窗口/版本资源；窗口标题已改为 JellyMaku；关于页链接改为 JellyMaku。
- [x] 更新检查指向 `tang-bai/JellyMaku`（含 Windows zip 资产识别与 UA）。
- [x] i18n ARB en/zh；gen-l10n（弹幕设置/手动匹配/按钮提示已迁移，中文 UI 测试通过）。
- [x] portable zip；Anime4K/Fladder 许可保留；Inno 脚本 `installer/jellymaku.iss` + `tools/build-installer.ps1` 已加。
- [x] Inno 安装器实际编译；静默安装/启动/卸载冒烟通过（Inno 6.7.3 → tools/inno）。
- [ ] 干净目录完整功能验证；Stage A 真实 E2E 验收。

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

## 4. 禁止事项

- 不把“文档计划”写成“已实现”。
- 不把 lint/analyze 通过当成功能通过。
- 不提交密钥/真实账号/版权媒体。
- 不使用 Kazumi 受限图标/字体/美术。
- 不做未授权的 Bangumi/danmu_api 批量抓取。
- 不在无代理情况下宣称 Bangumi 评论可用。

## 5. 当前进度

- 文档：完成；本次更新 DANMAKU/IMPLEMENTATION/ROADMAP/AGENTS/README/CHANGELOG。
- 代码：Fladder + PR #735 head 已导入；弹幕已迁移到 danmu_api（自动+手动匹配/URL 拉取/合并/本地导入/叠加层）、超分（Anime4K）已接入；Bangumi Stage B 未开始。
- 构建：Windows release 于 2026-10-20 23:38 重新构建/冒烟通过；portable zip 已按新代码重打（90,712,816 bytes，SHA256 `5FFC849F33D8E7216EE93AEC17192EBE7EEDAEEC8A47D97452FA891564B61237`）。
- 测试：137 tests passed（2026-10-20）；`dart analyze lib test` → No issues found。
- 发布：portable zip 已出；安装器/中文 ARB 未做。
- 未验证：播放器内真实弹幕加载/切集、真实 Jellyfin 播放、SyncPlay 双端、超分画质/性能。
