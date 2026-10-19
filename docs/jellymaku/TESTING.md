
# 测试策略与验收

> 状态：Draft。以下测试尚未执行；所有“已通过”必须以后续实际命令/截图/日志为准。

## 1. 测试层级

| 层级 | 范围 | 工具/方式 |
|---|---|---|
| 单元 | DDP 签名/解析/匹配/缓存；Bangumi client/映射；BBCode；shader profile | Dart test / flutter test |
| Widget | 弹幕开关/设置/手动匹配；时间表；图片搜索；评论 Tab/Sheet；无网 | flutter test / widget test |
| Mock 集成 | Mock DDP、Mock Bangumi、Mock trace.moe | tool/ 下的 Dart HTTP server |
| 本地 Jellyfin | 登录/库/播放/字幕/弹幕/seek/切集/设置持久化 | Jellyfin 12.2 + 测试媒体 |
| SyncPlay | 双客户端矩阵 | JellyMaku + Jellyfin Web / 双实例 |
| 超分 | profile 切换/关闭/持久化/性能 | 截图 + mpv 属性/掉帧 |
| 打包 | 干净目录启动/登录/播放/弹幕/超分/SyncPlay | 安装器/便携 zip |

## 2. 环境

- Windows 10/11 x64；VS 2022 BuildTools；Developer Mode；Flutter 3.35.7。
- Jellyfin 12.2 + .NET 10；本地 127.0.0.1:8096。
- ffmpeg 9.0.1；测试媒体在 testdata/media。
- DDP：无凭证时 Mock/本地 XML；真实凭证可选。
- Bangumi：无网络路径时 Mock；真实联调需用户代理/Worker。
- trace.moe：Mock 或真实（quota 100/day，concurrency 1）。

## 3. 命令（计划）

~~~powershell
pwsh -File tools/bootstrap.ps1
pwsh -File tools/verify-assets.ps1
pwsh -File tools/setup-jellyfin.ps1
pwsh -File tools/run-dev.ps1
pwsh -File tools/test.ps1
pwsh -File tools/pack.ps1
~~~

Flutter 直接命令：

~~~powershell
.flutter\bin\flutter.bat pub get
.flutter\bin\flutter.bat gen-l10n
.flutter\bin\flutter.bat analyze
.flutter\bin\flutter.bat test
.flutter\bin\flutter.bat build windows --release
~~~

若中文路径导致问题，使用 subst J: 映射仓库根目录后再执行。

## 4. Mock

- tool/mock_ddp.dart：/api/v2/search/episodes、/api/v2/comment/{id}、/api/v2/match；记录签名头；支持 401/403/429/空评论/无匹配。
- tool/mock_bangumi.dart：/p1/calendar、/p1/subjects/{id}/comments、/p1/episodes/{id}/comments、/v0/subjects、/v0/episodes、/v0/search/subjects；支持 401/超时/空。
- tool/mock_trace.dart：/search；成功/无结果/配额/超时。
- fixtures 放 testdata/fixtures/；不含真实 token/用户数据。

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

- [ ] Flutter 工具链/构建可用；Fladder + PR #735 基线。
- [ ] 本地 Jellyfin 登录/播放/字幕/进度。
- [ ] 弹幕全场景 + 主字幕共存。
- [ ] shader 超分可切换/关闭/持久化；性能记录。
- [ ] SyncPlay 双客户端矩阵。
- [ ] Stage B：时间表/图片/评论 Mock 或代理通过；无网降级。
- [ ] 安装器/便携包干净运行。
- [ ] 无密钥/真实用户数据入库；许可/署名完整。
- [ ] 所有“已验证”有证据；未验证明确标注。

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
- 不做 DDP 大规模抓取/绕过配额。
- 不上传真实用户截图到 trace.moe 做批量测试。
- 不把未授权媒体/账号写入仓库。
