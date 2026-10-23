# Stage A 验收报告

> 项目：JellyMaku（Windows 10/11 x64）
> 版本：**v0.1.0-beta.5**（应用版本 `0.1.0+5`）
> 报告日期：2026-10-23
> 代码提交：`26ac04a4`；发布提交：`f9fb78ef`
> 结论：**Stage A 功能验收通过**；发布安装版完整功能 E2E 尚未执行，因此发布验收状态为“功能通过、安装验收待收尾”。本报告不把未执行项写成已通过。

## 1. 范围与结论

Stage A 的目标是交付一个可用的 Windows Jellyfin 桌面播放器，包含 Fladder 基座、danmu_api 弹幕、Anime4K GLSL 超分、Jellyfin SyncPlay、品牌与 Windows 打包。

| 验收域 | 结论 |
|---|---|
| Flutter 构建、静态分析、单元测试 | 通过 |
| Jellyfin 12.2 登录/媒体库/播放/暂停/seek | 通过（NAS 12.2） |
| 字幕切换、切集、弹幕叠加层 | 通过（用户手动复测） |
| danmu_api 弹幕 | 通过（自动/手动匹配、URL 拉取、合并去重、本地导入、叠加层） |
| Anime4K 超分 | 通过（四档；用户实机确认性能） |
| SyncPlay 一起看 | 通过（用户实机确认双客户端） |
| 播放信息面板 | 通过（用户实机确认） |
| 安装器/便携包构建与安装冒烟 | 通过 |
| 安装后完整功能 E2E | **未验证** |
| Stage B（Bangumi） | 不在本报告范围，尚未开始 |

**判定：Stage A 核心功能已验收；在完成安装版登录/播放/字幕/弹幕/超分/播放信息 E2E 之前，不建议把“发布安装验收”标记为完全关闭。**

## 2. 交付物

### 2.1 发布资产（v0.1.0-beta.5）

- Release：https://github.com/tang-bai/JellyMaku/releases/tag/v0.1.0-beta.5
- `JellyMaku-0.1.0-beta.5-windows-x64-setup.exe`
  - 大小：73,183,739 bytes
  - SHA256：`4084271BE1C56879CAD4D0504A408B618B83921DCCD5C37F169708EA4F1E2596`
- `JellyMaku-0.1.0-beta.5-windows-x64-portable.zip`
  - 大小：100,878,057 bytes
  - SHA256：`AFD688B195B8B07FF73A9E79DB274CAC085DE9CAA52DB0FE7D6B1D2ACF0443C6`
- 安装包包含 `LICENSE`、`README.md`、`AGENTS.md`、`THIRD_PARTY_NOTICES.md`。

### 2.2 源码状态

- 基座：Fladder develop `de7b5a2a23f16f5f3bb164ec0baedf50941e4808`。
- SyncPlay：Fladder PR #735 head `79e249ebf99ecc8dc8f0d5d43c3604ace45fbba9`，按 GPL-3.0 保留署名。
- 当前发布源码提交：`26ac04a4`；发布说明提交：`f9fb78ef`。
- 许可：项目整体 GPL-3.0；第三方组件/服务声明见 `THIRD_PARTY_NOTICES.md`。

## 3. 验证环境

| 项目 | 值 |
|---|---|
| 操作系统 | Windows 10 Pro 22H2（10.0.19045.6466），x64 |
| Flutter | 3.35.7 stable |
| Dart | 3.9.2（随 Flutter SDK） |
| 构建工具 | VS 2022 BuildTools 17.14；Windows SDK 10.0.26100 |
| 构建路径 | ASCII 路径（`L:\JellyMaku`），规避 Cargokit 中文路径编码问题 |
| Jellyfin | NAS `192.168.8.137:8096`，Jellyfin 12.2.0（ServerName「媒体库」） |
| 媒体库 | 电影 191 条、剧集 5380 条（验证时快照） |
| 弹幕服务 | danmu_api 公共实例 `https://danmu.api.tangbai.cc` |
| GPU/超分 | NVIDIA RTX 5070；Anime4K GLSL；RTX VSR 不在 v1 范围 |

## 4. 构建与自动化验证

| 检查项 | 结果 | 证据 |
|---|---|---|
| `dart analyze lib test` | 0 issue | 2026-10-23 运行记录 |
| `flutter test --no-pub` | **156 passed + 1 skipped** | 手动联网探针跳过；当前测试套件 |
| Windows release 构建 | 成功 | `flutter build windows --release --no-pub`，2026-10-23，约 114.9s |
| 应用启动冒烟 | 通过 | Release exe 启动，窗口标题 JellyMaku |
| 安装器编译 | 通过 | Inno Setup 6.7.3，beta.5 setup 已生成 |
| 安装/启动/卸载冒烟 | 通过 | 静默安装到 `artifacts/install-test-5`，启动/卸载成功；安装包含第三方声明 |
| 资产校验 | 通过 | `third_party/manifest.json` 8 项，`tools/verify-assets.ps1` 全部 OK |

## 5. 功能验收

### 5.1 Jellyfin 客户端与播放

- NAS Jellyfin 12.2 自动登录成功；`/Sessions` 显示 `Client=JellyMaku`、`DeviceName=Windows`、`User=test`。
- 打开《药屋少女的呢喃》S01E51 播放：位置 54s → 59s（5s 采样）。
- 空格暂停后位置冻结在 60s（3s 内不变）；恢复后推进到 62s。
- 右方向键 ×3 → 155s（每次约 30s，符合当前跳过设置）。
- 用户手动复测确认：**字幕切换、切集、弹幕叠加层**通过。

### 5.2 danmu_api 弹幕

- 默认公共实例；支持自建实例，TOKEN 只放在地址路径。
- 自动匹配优先 `POST /api/v2/match`，失败回退 `search/episodes`。
- 手动匹配：搜索番剧/内嵌分集并写入 `mapping.json`；可清除自动/手动映射。
- URL 型来源、renren/hanjutv 复合 ID 的 `segmentcomment`、本地 Bilibili XML/danmu_api JSON 导入均已接入。
- Flutter CustomPainter 叠加层：滚动/顶部/底部、字体/颜色/透明度/描边/显示区域/速度/偏移；暂停冻结显示时钟。
- 来源标签 `p[3]` 解析为 provider；不当作 uid；不提供发送弹幕。
- 5000 条基准：解析 52–55ms，首帧 15–17ms，后续帧约 1.0–1.1ms（Flutter test 环境，非播放器内 FPS）。
- 真实播放器内叠加层已由用户手动确认；混合来源的系统性回归/截图仍缺。

### 5.3 Anime4K 超分

- 档位：Off、Fast 2x、Balanced 2x、Strong 2x、4x。
- 通过 libmpv `glsl-shaders` 应用；加载失败仅记录日志并保留原输出，不阻塞播放。
- 四档截图已采集：`artifacts/screenshots/sr-off.png`、`sr-fast.png`、`sr-balanced.png`、`sr-strong.png`；历史对比图也在同目录。
- 用户实机确认性能通过；原始 FPS/掉帧/GPU 数据未归档。
- 已接入仅 Anime4K；FSRCNNX/ArtCNN 未接入；RTX VSR spike 失败并回退，不作为 v1 支持项。

### 5.4 SyncPlay 一起看

- PR #735 的 REST/WebSocket/时间同步/命令调度/组面板/队列生命周期代码已导入。
- 组面板中文化和侧栏「一起看」状态点已通过真实 UI 复测。
- 用户实机确认双客户端联调通过（2026-10-23）。
- 原始客户端组合、位置误差、WebSocket 日志和截图未归档；报告中不虚构误差数值。

### 5.5 播放信息面板

- 播放页 `SDR HD` 徽章可点击，打开每秒刷新的播放信息对话框。
- 实时区：状态、当前/视频/音频码率、下载速度、缓冲、丢帧、硬解、渲染帧率、加载耗时。
- 媒体区：视频/音频编码、分辨率、容器、源码率、文件大小、播放类型、播放器后端、转码原因/进度与 URL。
- libmpv 读取 `video-bitrate`/`audio-bitrate`/`cache-speed`/`demuxer-cache-duration`/`frame-drop-count`/`estimated-vf-fps`/`hwdec-current` 等属性；MDK 读取 MediaInfo；Native 后端降级为静态信息。
- 用户实机确认通过（2026-10-23）；原始 UI 截图和实时数值未归档。

### 5.6 品牌与打包

- Windows exe、窗口标题、关于页、更新检查均为 JellyMaku。
- beta.5 同时提供 Inno Setup 安装器和便携包。
- 安装器未签名，SmartScreen 可能提示。
- 安装目录完整功能 E2E 尚未执行。

## 6. 验收项对照

| 阶段项 | 状态 | 说明 |
|---|---|---|
| A0 仓库/工具链 | 通过 | Flutter/VS/SDK 可用；构建与启动冒烟通过 |
| A1/A2 弹幕 | 通过 | 自动/手动/URL/本地导入/叠加层；真实播放器内已手动确认 |
| A3 超分 | 通过（证据待归档） | 四档截图；用户确认性能；FPS/掉帧原始数据缺 |
| A4 SyncPlay | 通过（证据待归档） | 用户确认双客户端；原始日志/误差/截图缺 |
| A5 品牌/打包 | 部分通过 | beta.5 发布完成；安装版完整 E2E 未做 |
| A6 播放信息 | 通过（证据待归档） | 用户实机确认；原始截图/数值缺 |

## 7. 用户实机验收记录

| 日期 | 范围 | 结果 | 证据状态 |
|---|---|---|---|
| 2026-10-21 | 字幕切换、切集、弹幕叠加层 | 通过 | 用户手动确认；无独立截图归档 |
| 2026-10-23 | SyncPlay 双客户端 | 通过 | 用户确认；原始日志/位置误差/截图未归档 |
| 2026-10-23 | Anime4K 超分性能 | 通过 | 用户确认；FPS/掉帧原始数据未归档 |
| 2026-10-23 | 播放信息面板 | 通过 | 用户确认；UI 截图/实时数值未归档 |

## 8. 已知限制与残余风险

1. **安装版完整 E2E 未验证**：尚未在安装目录完成登录/播放/字幕/弹幕/超分/播放信息全链路；这是 Stage A 发布验收的唯一功能性缺口。
2. **用户确认项缺原始证据**：SyncPlay 误差/日志/截图、超分 FPS/掉帧、播放信息截图/数值尚未归档；不影响功能结论，影响可审计性。
3. **安装器未签名**：Windows SmartScreen 可能提示。
4. **公共 danmu_api 依赖**：公共实例的可用性、限流和源站策略不受本项目控制；失败时可用自建实例或本地文件。
5. **i18n 尾部债务**：`zh` 仍有 4 个深链键、`zh_Hant` 约有 200 个非 SyncPlay 键缺失。
6. **超分范围**：仅 Anime4K；FSRCNNX/ArtCNN 未接入；RTX VSR 不支持；4x 在 1440p/4K 的长期稳定性仍需观察。
7. **Stage B 未开始**：Bangumi 时间表、以图搜番、评论均不在本报告范围；官方网络不可达，评论需要代理/Worker 才能真实联调。

## 9. Stage A 判定

- **功能验收：通过。** Fladder 播放、danmu_api 弹幕、Anime4K 超分、SyncPlay、播放信息面板和 Windows 打包均已达到 Stage A 目标。
- **发布验收：条件通过。** 安装器/便携包已发布，但安装目录完整功能 E2E 尚未执行；该步骤完成后可关闭 Stage A。
- **不建议**在安装版 E2E 完成前把“安装包干净运行、全功能通过”写成已验证。

## 10. 复现与证据

~~~powershell
# ASCII 路径（例如 L:\JellyMaku）
$env:PUB_CACHE = "K:\.pub-cache"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:PATH = "K:\tools\nuget;" + $env:PATH
$env:CL = "/utf-8"

.\.flutter\bin\flutter.bat pub get
.\.flutter\bin\dart.bat analyze lib test
.\.flutter\bin\flutter.bat test --no-pub
.\.flutter\bin\flutter.bat build windows --release --no-pub
& .\tools\pack.ps1 -Version 0.1.0
~~~

- 测试/构建详细记录：[IMPLEMENTATION.md](IMPLEMENTATION.md)
- 测试策略与证据目录：[TESTING.md](TESTING.md)
- SyncPlay 测试矩阵：[PARTY.md](PARTY.md)
- 超分设计与截图：[SR.md](SR.md)
- 弹幕设计与实测：[DANMAKU.md](DANMAKU.md)
- Windows 构建：[BUILD_WINDOWS.md](BUILD_WINDOWS.md)

## 11. 修订记录

- 2026-10-23：重写为 v0.1.0-beta.5 的 Stage A 验收报告；纳入 NAS Jellyfin 12.2 E2E、弹幕、Anime4K、SyncPlay、播放信息面板和 beta.5 发布验证。
- 2026-10-19/20：旧版构建/弹幕历史报告，保留在 git 历史中；其中旧弹幕实现、旧凭证和旧测试已不适用于当前版本。
