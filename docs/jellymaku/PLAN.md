
# 实施总计划（Stage A / Stage B）

> 状态：Stage A 核心已构建/验证（Windows release + 137 tests + 启动冒烟）；弹幕已迁移到 danmu_api（手动匹配/本地导入）；真实 E2E/最新 develop/安装器未完成。
> 日期：2026-10-19。
> 基座：DonutWare/Fladder develop de7b5a2a23f16f5f3bb164ec0baedf50941e4808 + PR #735。
> 原则：先交付可用的 Jellyfin 播放器，再叠加 Bangumi；每阶段有可运行产物与证据。
> 当前基线：main 已推送 origin（PR #735 head + Stage A 代码/文档，e2b3ca7）；最新 develop 未合并。

## 0. 交付概要

| 阶段 | 目标 | 预计工期 |
|---|---|---|
| Stage A | Fladder 导入 + 弹幕 + shader 超分 + Jellyfin SyncPlay + 品牌/打包 | 8–11 个工作日 |
| Stage B | Bangumi 时间表 + 图片识别 + 评论（条件功能） | 5–6.5 个工作日 |
| 合计 | - | 13–17.5 个工作日 |

若用户要求 RTX VSR 驱动级超分，额外 3–5 天，且风险显著；若要求 ECH/DoH 加速，额外 2–4 天。

## 1. 前提与假设

- Windows 10/11 x64 为主要平台；Flutter/VS 工具链可用。
- Fladder 固定 commit 可构建；PR #735 可合并/适配。
- SyncPlay 参与者使用同一 Jellyfin 服务器、各自有账号。
- danmu_api 默认公共实例可直接联调；离线/限流时用本地 XML 或缓存。
- Bangumi 真实联调需要用户代理/自建镜像；无则 Mock/条件功能。
- 接受 GPL-3.0 与 Fladder/Kazumi/PR #735 署名。
- 不把密钥、真实用户数据、版权媒体写入仓库。

## 2. Stage A：核心播放器

### Phase A0：仓库与工具链（1–1.5 天）

任务：

1. 仓库/基线策略：
   - 本地 main 已初始化；已导入 PR #735 head（Fladder + SyncPlay）与文档。
   - 记录 Fladder 基座 commit 与 PR #735 head；保存 upstream README 存档。
2. 补最新 develop 合并：
   - fetch fladder develop；把最新 develop 合入 main/jellymaku。
   - 解决冲突（video_player_provider、playback_model、settings、ARB、pubspec、生成文件）。
   - PR #735 已在基线中；如冲突过大，保留 PR head 基线并记录待办。
3. 工具链：
   - Flutter 3.35.7 下载到 .flutter；PUB_CACHE 到 .pub-cache。
   - VS 2022 BuildTools/Windows SDK/Developer Mode 检查。
   - 中文路径必要时 subst J:。
   - Inno Setup 到 tools/inno。
4. 资源：
   - Jellyfin 12.2 + .NET 10 + 测试媒体；全部在本目录。
   - 写 third_party/manifest.json。
5. 基线：
   - flutter analyze/test；flutter build windows --release；启动并登录本地 Jellyfin。

Gate：

- Fladder + PR #735 可编译、可登录、可播放。
- 工具链可重复；文档/资产位置明确。
- 基线失败清单记录到 artifacts/logs/baseline。

### Phase A1：弹幕核心（2–2.5 天）

任务：

1. lib/danmaku/：models、danmaku_api_client、comment_parser、matcher、cache、provider。
2. danmu_api match/search/comment、错误/限流/缓存；手动映射；本地 XML/JSON。
3. Flutter DanmakuOverlay：Ticker、活跃评论二分、lane、滚动/顶部/底部、样式。
4. 设置模型/provider；API 地址；无凭证。
5. 单元测试：match/search/comment、解析、匹配、缓存 key、布局、5000 条性能。

Gate：

- 29 个等效测试全绿（新实现重新计数）。
- Mock danmu_api 端到端加载；无匹配/401/403/429/超时降级。
- 5000 条解析 <200ms 或记录实际。

### Phase A2：弹幕 UI/手动匹配/本地导入（1.5–2 天）

任务：

1. 设置页：凭证、开关、样式、过滤、简繁、缓存、本地文件、测试连接。
2. 播放器入口：开关/Match/Reload/Settings；状态提示。
3. 手动匹配对话框；mapping 持久化；清除映射。
4. 本地导入（file_picker）；BBCode 无关。
5. 截图/视觉：弹幕开/关、顶部/底部、设置、手动匹配。

Gate：

- 全部弹幕设置可在 UI 完成。
- 主字幕/音轨/超分不受影响。
- 无凭证可用本地文件演示。

### Phase A3：超分（1–1.5 天）

任务：

1. assets/shaders：Anime4K high/fast、FSRCNNX、ArtCNN；许可证。
2. VideoEnhancementProfile + 设置页；
3. LibMPV.setVideoEnhancement：复制资产到缓存、change-list glsl-shaders、关闭清空、失败回退。
4. RTX VSR spike（可选）：记录结果，不作为验收。
5. 性能/截图：1080p60、关闭/Anime4K/FSRCNNX；记录 glsl-shaders/vf/掉帧。

Gate：

- 至少 3 个 profile 可切换/关闭/持久化。
- 画面/性能有证据。
- RTX VSR 结论明确。

### Phase A4：一起看（1–1.5 天）

任务：

1. 合并 PR #735 的 SyncPlayController/WebSocket/TimeSync/MessageHandler/CommandHandler/UI。
2. Windows/libMPV 回调适配；组内 pause/seek 走 SyncPlay。
3. Jellyfin 12.2 实测：创建/加入/播放/暂停/seek/切集/迟到/重连。
4. 中文文案；组面板/FAB；已知限制文档。

Gate：

- 双客户端矩阵通过；无额外端口。
- WebSocket/ApiKey 在 12.2 上可用。
- 位置误差 1–2s 内。

### Phase A5：品牌/打包/测试/文档（1.5–2 天）

任务：

1. 品牌：JellyMaku 显示名/exe/窗口标题/安装器/关于页；更新检查不回 Fladder。
2. i18n：ARB en/zh；gen-l10n。
3. 打包：flutter build windows --release；Inno Setup；便携 zip；许可/第三方声明。
4. 干净目录验证；截图/日志。
5. 文档更新；提交/推送策略（用户确认）。

Gate：

- 安装器/便携包干净运行。
- Stage A 验收清单全绿。
- 推送成功或报告认证失败。

## 3. Stage B：Bangumi 模块

### Phase B0：Bangumi 数据层与网络（1–1.5 天）

任务：

1. lib/bangumi/：client、models、mapping_store、cache、connectivity。
2. 可配置 API Base/HTTP 代理；User-Agent；1 req/s；缓存。
3. tools/bangumi-proxy/worker.js 自建代理模板。
4. Mock Bangumi + fixtures。
5. 测试：URL/限流/缓存/错误/映射。

Gate：

- 官方/代理/Mock 三种模式可切换。
- 无网/401/超时行为明确。
- Mock 全绿。

### Phase B1：番剧时间表（1–1.5 天）

任务：

1. `/p1/calendar` 当前季；非当前季搜索补全；分组/排序/缓存。
2. Fladder SchedulePage；周选择；卡片；在库/已看/弃番；跳转。
3. 映射：标题+年份+集数；人工绑定；未入库。
4. 测试/截图。

Gate：

- 当前季 7 天展示；过滤/跳转/缓存；无网提示。

### Phase B2：图片识别（1–1.5 天）

任务：

1. 搜索页以图搜番；文件/URL；预览；上传同意。
2. trace.moe 串行/缓存/quota 错误。
3. 解析 AniList 标题/synonyms/episode；Jellyfin 本地搜索/候选/跳转。
4. Bangumi 搜索仅可达时；否则 AniList 链接。
5. 测试/截图。

Gate：

- 选图 → 识别 → Jellyfin 跳转；不自动上传；配额/隐私提示。

### Phase B3：Bangumi 评论（1.5–2 天）

任务：

1. 主题/分集评论 API；分页/缓存/限流；官方 v0 无评论的说明。
2. 映射：subject/episode；SP/剧场版；人工确认。
3. 详情 Tab + 播放器 Sheet；BBCode 子集；只读；署名。
4. 网络不可达降级；Mock/代理验收。
5. 测试/截图。

Gate：

- Mock/代理下评论可读；无网优雅降级。
- 不提供发送/点赞；不冒充可用。

## 4. 验收清单（总）

- [ ] 源码/文档/资产位置清楚；无密钥入库。
- [ ] Fladder + PR #735 可构建；Jellyfin 登录/播放。
- [ ] 弹幕：自动/手动/本地；样式/过滤/偏移；主字幕共存。
- [ ] 超分：shader profile 可切换；有性能/截图；RTX VSR 结论明确。
- [ ] SyncPlay：双客户端矩阵；无额外端口。
- [ ] 打包：安装器/便携包干净运行。
- [ ] Stage B：时间表/图片/评论在 Mock/代理下通过；无网降级。
- [ ] 许可/署名/隐私/配额说明完整。
- [ ] 所有“已验证”都有证据；未验证项明确标注。

## 5. 风险与回退

| 风险 | 处理 |
|---|---|
| PR #735 冲突/过时 | 以 PR head 分支 merge develop；或按文件移植；保留署名 |
| Flutter/VS 构建失败 | 固定版本；subst；检查 Windows SDK；记录错误 |
| media_kit shader 不生效 | 先用 mpv 属性诊断；回退 off；不承诺 RTX VSR |
| Bangumi 不可达 | 用户代理/Worker；Mock；条件功能 |
| danmu_api 不可达 | 使用缓存/本地 XML；提示错误；不影响播放 |
| 映射错误 | 人工确认；低置信度不绑定 |
| 安装器工具缺失 | 先交付 portable zip；保留 pack 脚本 |

## 6. 交付物

- Stage A：源码分支、便携 zip、安装器、截图/日志、Stage A 实现记录。
- Stage B：Bangumi 模块、Mock/代理说明、时间表/图片/评论截图、条件验收记录。
- 文档：本目录 16+ 文档持续更新。
- Git：本地提交；推送需用户确认/凭证。
