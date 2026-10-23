
# 测试策略与验收

> 状态（2026-10-23）：当前 HEAD analyze 0、156 tests passed + 1 skipped；Windows release 于 2026-10-23 构建成功；beta.5 安装器/便携包已发布。
> 已验证：NAS Jellyfin 12.2 登录/播放/暂停/seek（自动），字幕切换/切集/弹幕叠加层（手动）。
> 未验证：SyncPlay 双端、超分 FPS/掉帧、安装版完整 E2E、播放信息面板实机。
>
> 已执行证据见 [IMPLEMENTATION.md](IMPLEMENTATION.md) 与 artifacts/logs/（本地，不入库）。

## 1. 测试层级

| 层级 | 范围 | 工具/方式 |
|---|---|---|
| 单元 | danmu_api 客户端/解析/匹配/缓存；Bangumi client/映射；BBCode；shader profile | Dart test / flutter test |
| Widget | 弹幕开关/设置/手动匹配；时间表；图片搜索；评论 Tab/Sheet；无网 | flutter test / widget test |
| Mock 集成 | danmu_api（MockClient/本地 HttpServer）、Mock Bangumi、Mock trace.moe | Dart HttpServer / MockClient |
| Jellyfin 12.2（NAS） | 登录/库/播放/字幕/弹幕/seek/切集/设置持久化 | Jellyfin 12.2 + NAS 媒体库 |
| SyncPlay | 双客户端矩阵 | JellyMaku + Jellyfin Web / 双实例 |
| 超分 | profile 切换/关闭/持久化/性能 | 截图 + mpv 属性/掉帧 |
| 打包 | 干净目录启动/登录/播放/弹幕/超分/SyncPlay | 安装器/便携 zip |

## 2. 环境

- Windows 10/11 x64；VS 2022 BuildTools；Developer Mode；Flutter 3.35.7（已安装）。
- Jellyfin 12.2（NAS `192.168.8.137:8096`，ServerName「媒体库」）；本地未安装 Jellyfin/.NET。
- 测试媒体使用 NAS 媒体库；本地 `testdata/media` 未生成（合成片计划未执行）。
- danmu_api：默认公共实例可直接请求；离线/限流时用本地 XML 或缓存。自建 TOKEN 写在地址路径。
- Bangumi：无网络路径时 Mock；真实联调需用户代理/Worker。
- trace.moe：Mock 或真实（quota 100/day，concurrency 1）。

## 3. 已执行命令

~~~powershell
# 从 ASCII 路径运行（中文路径会导致 Cargokit 编码失败）
$env:PUB_CACHE = "K:\.pub-cache"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:PATH = "K:\tools\nuget;" + $env:PATH
$env:CL = "/utf-8"

.flutter\bin\flutter.bat pub get
dart analyze lib test                 # 0 issue
.flutter\bin\flutter.bat test --no-pub   # 156 passed + 1 skipped
.flutter\bin\flutter.bat build windows --release --no-pub
& .\tools\pack.ps1 -Version 0.1.0
~~~

结果（2026-10-23）：analyze 0 issue；156 tests passed + 1 skipped；Windows release 构建成功；beta.5 发布资产见 IMPLEMENTATION.md。

已存在脚本：`tools/pack.ps1`、`tools/verify-assets.ps1`、`tools/build-installer.ps1`。尚未实现：`bootstrap.ps1`、`setup-jellyfin.ps1`、`run-dev.ps1`、`test.ps1`。

在空环境/agent 进程中运行 Flutter 前，先按 [BUILD_WINDOWS.md](BUILD_WINDOWS.md) §1.1 设置 `ProgramFiles(x86)`、`USERPROFILE`、`APPDATA` 等变量；否则 `flutter test` 可能因 Flutter tool 的环境检查崩溃。

## 4. Mock

- danmu_api mock：`test/danmaku/danmaku_api_client_test.dart` 使用本地 HttpServer/MockClient，覆盖 match/search/comment/segmentcomment/错误。
- Bangumi/trace.moe mock：尚未开始；原计划的 `tool/mock_bangumi.dart`、`tool/mock_trace.dart` 未创建。

## 5. 必测场景

### 弹幕

- 签名固定向量；Path 不含 query；时间戳偏差。
- p 字段/模式/颜色/文本清洗/过滤/去重/偏移/上限/简繁。
- 匹配：手动/TMDB/标题/无匹配候选。
- 缓存：设置变化失效、chconvert 分桶、失败缓存。
- 5000 条解析/布局性能。
- 播放：主字幕共存、seek/pause/切集、开关/样式/偏移。
- 错误：无凭证/401/403/429/超时/空评论/无匹配不阻塞。

### 超分

- profile→shader 列表/路径复制/命令序列。
- 至少 3 个 profile 切换/关闭/持久化。
- 失败回退；截图；掉帧记录。
- RTX VSR 结论记录。

### SyncPlay

- 创建/加入/播放/暂停/seek/切集/迟到/重连/缓冲。
- 位置误差 1–2s；无额外端口；Jellyfin 12.2 WebSocket ApiKey。

### Bangumi

- 日历分组/排序/过滤/映射/跳转/缓存/无网。
- 图片识别解析/Jellyfin 候选/配额/隐私/缓存。
- 评论分页/BBCode/回复/映射/无网降级。
- 网络：官方不可达/401/超时；代理/Mock 可预测。

## 6. 验收清单

- [x] Flutter 工具链/构建可用；Fladder + PR #735 基线。
- [x] 本地 Jellyfin 登录/播放/字幕/进度（NAS 12.2）。
- [x] 弹幕叠加层/暂停/seek/切集已手动确认；混合来源系统性回归待补。
- [ ] shader 超分可切换/关闭/持久化；性能记录（截图已有，FPS/掉帧缺）。
- [ ] SyncPlay 双客户端矩阵。
- [ ] Stage B：时间表/图片/评论 Mock 或代理通过；无网降级。
- [ ] 安装器/便携包干净运行（安装/卸载冒烟已有，完整功能 E2E 缺）。
- [ ] 无密钥/真实用户数据入库；许可/署名完整（THIRD_PARTY_NOTICES 待补）。
- [x] 所有“已验证”有证据；未验证明确标注。

## 7. 证据目录

- artifacts/screenshots/：播放器/弹幕/超分/时间表/图片/评论/设置。
- artifacts/logs/：运行日志、Mock 请求、错误。
- artifacts/perf/：掉帧/性能 JSON。
- artifacts/build/：便携包/安装器。
- docs/jellymaku/IMPLEMENTATION.md：命令/结果/缺口。

## 8. 基线失败策略

- 先记录 Fladder + PR #735 的 analyze/test/build 基线。
- 与现有功能无关的环境失败（路径/字体/驱动）记录原因，不阻塞新功能；但 Stage A 验收必须有可运行构建。
- 不把“lint 通过”当作“功能通过”。

## 9. 不做的测试

- 不做真实 Bangumi 生产压力/批量抓取。
- 不做 danmu_api 大规模抓取/绕过配额。
- 不上传真实用户截图到 trace.moe 做批量测试。
- 不把未授权媒体/账号写入仓库。
