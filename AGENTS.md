
# AGENTS.md

> 适用范围：本仓库根目录及其子目录。所有 agent/贡献者在改代码前先读本文与 docs/jellymaku/README.md。
> 状态：Stage A 核心已构建（Windows release 可启动；analyze 0 issue；100 tests passed）；已推送 GitHub（e2b3ca7）。
> 日期：2026-10-19。

## 0. 当前仓库状态（必须先理解）

- 本地 git 已初始化，main 为工作分支；origin https://github.com/tang-bai/JellyMaku 已推送（e2b3ca7）。
- main 已包含 Fladder 源码 + SyncPlay PR #735（PR head 79e249e）+ Stage A 弹幕/超分/品牌代码 + 项目文档/AGENTS。
- 旧的 JellyMaku（基于 jellyfin-mpv-shim）实现、旧文档、旧 git 历史已丢失，无法恢复；不要尝试从远程恢复。
- Flutter 3.35.7 已安装到 .flutter；**analyze 0 issue、100 tests passed、Windows release 构建成功、启动冒烟通过**。
- 基线说明：为尽快拿到可运行起点，main 以 PR #735 head 为基线（包含 Fladder + SyncPlay），**尚未合并最新 develop**；Phase A0 仍需补这次合并。
- 未验证：真实 Jellyfin 12.2 E2E、真实 DDP 凭证、SyncPlay 双客户端、超分画质/性能。
- 因此：
  - 不要把“计划”当成“已实现”；
  - 不要把单测/构建通过当成真实 E2E 通过；
  - 不要在没有用户确认的情况下 push/force-push/改写历史。

## 1. 项目使命

构建 Windows 10/11 的 Jellyfin 桌面播放器 JellyMaku，基于 **DonutWare/Fladder**（Flutter/Dart，GPL-3.0），新增：

1. 弹弹play 弹幕（自动/手动匹配、Flutter 叠加层、样式/过滤/偏移）。
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
lib/danmaku/             DDP/解析/匹配/缓存/叠加层
lib/bangumi/             Bangumi 数据层/映射/缓存
lib/video/               超分
lib/providers/            Riverpod providers
lib/screens/             播放器/设置/时间表/图片/评论
assets/shaders/          Anime4K/FSRCNNX/ArtCNN
tool/                    mock_ddp/mock_bangumi/mock_trace
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

- 单元测试优先：DDP 签名/解析/匹配/缓存/布局；Bangumi client/映射/BBCode；shader profile。
- Widget 测试：设置/弹窗/无网状态。
- Mock：tool/mock_ddp.dart、mock_bangumi.dart、mock_trace.dart；fixtures 在 testdata/fixtures。
- 本地 Jellyfin 12.2 E2E；SyncPlay 用 Jellyfin Web/双实例。
- 每个“已通过”附命令/输出/截图路径；没有证据就写“未验证”。
- 不把 lint/analyze 通过等同于功能通过。

## 8. 安全/合规

- 不提交 DDP AppSecret、Jellyfin token、Bangumi token、真实用户数据、版权媒体。
- AppSecret 在 Windows 用 DPAPI；日志脱敏。
- DDP 请求不带 Jellyfin token/服务器地址。
- Bangumi User-Agent 明确；1 req/s；缓存；不批量抓取。
- trace.moe 仅用户主动上传；首次同意；串行/缓存。
- 不逆向/复用 Kazumi 镜像签名凭证。
- 不复制 Kazumi 图标/Mi Sans/美术；不冒充 Jellyfin/Bangumi/Fladder 官方。
- 弹幕功能免费；禁止未授权商用。

## 9. 功能状态（截至文档落盘）

| 功能 | 状态 |
|---|---|
| 文档/AGENTS | 完成；Stage A 报告/BUILD_WINDOWS 已补 |
| Fladder 源码导入 | 完成（PR #735 head 基线） |
| Flutter/构建 | 完成：analyze 0、100 tests、Windows release 成功、启动冒烟 |
| SyncPlay | 代码已导入；单测通过；真实双端未联调 |
| 弹幕 | DDP 客户端/自动匹配/缓存/叠加层/设置/DPAPI 已接入；手动匹配/本地 XML/真实联调未完成 |
| 超分 | Anime4K 资产+profile+glsl-shaders+菜单已接入；画质/性能未验收 |
| 品牌/打包 | JellyMaku exe/窗口/资源；portable zip；安装器/中文 ARB 未完成 |
| Bangumi 时间表/图片/评论 | 未开始 |
| 推送 GitHub | 完成（e2b3ca7） |

## 10. 已知陷阱

1. **Bangumi 官方不可达**：api.bgm.tv/next.bgm.tv 超时；api.kazumi.fyi 评论/搜索 401；不要在无代理时宣称评论可用。
2. **trace.moe 配额**：100/天、并发 1；不要批量/自动上传。
3. **RTX VSR**：media_kit ANGLE/OpenGL 下不可靠；不要把它写成已支持。
4. **PR #735 冲突**：基于旧 develop；合并需解决 settings/player/ARB 冲突。
5. **中文路径**：Cargokit 生成的 pubspec 会用系统代码页，Dart 无法解析；用 ASCII 路径 + `/utf-8`。
6. **已推送**：main 已推送 origin e2b3ca7；后续 push/force-push 仍需用户确认。
7. **旧实现丢失**：不要从远程“恢复”旧 MPV Shim 代码（远程为空）。
8. **许可**：Kazumi 代码 GPL-3.0 可用，但资产不可复制；Anime4K MIT 已附许可。
9. **原生依赖下载**：libmpv/ANGLE/MDK/SQLite/NuGet 可能卡在 GitHub/SourceForge/sqlite.org/nuget.org；用 third_party 预置与本地 feed。
10. **插件注册器过期**：升级 screen_brightness_windows 后必须删除并重新生成 generated_plugin_registrant.cc/.h。
11. **SMTC 初始化竞态**：SMTC 必须在 runApp 前初始化；`_subscribePlayerState` 必须先于可选 SMTC 设置，SMTC 异常不得中断进度订阅。`smtc_windows 1.1.0` 需配 `flutter_rust_bridge 2.11.1`，否则 codegen/runtime 版本检查会失败。

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
