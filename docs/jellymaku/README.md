# JellyMaku 项目文档

> 状态（2026-10-23）：v0.1.0-beta.5 已发布；本次文档验收状态更新未提交。Flutter 3.35.7；`dart analyze lib test` 0 issue；`flutter test --no-pub` 156 passed + 1 skipped；Windows release 于 2026-10-23 构建成功。
> 已验证：NAS Jellyfin 12.2 登录/播放/暂停/seek（自动）以及字幕切换/切集/弹幕叠加层（手动）；用户实机确认 SyncPlay 双客户端、超分性能通过（2026-10-23）。
> 未完成：安装版完整 E2E、Stage B；用户确认项缺原始 FPS/误差/截图归档。功能状态以 [ROADMAP.md](ROADMAP.md)、[IMPLEMENTATION.md](IMPLEMENTATION.md) 和 [STAGE_A_REPORT.md](STAGE_A_REPORT.md) 为准。
> 基座：DonutWare/Fladder（Flutter/Dart，GPL-3.0）+ SyncPlay PR #735。

## 0. 当前仓库状态（务必先读）

- 本地 `main` 已包含 Fladder + SyncPlay PR #735（head 79e249e），并已合并 Fladder develop `de7b5a2a`（2026-10-21）。
- 本地 `main` 已同步 origin；v0.1.0-beta.5 已发布；本次文档验收状态更新未提交。
- v0.1.0-beta.5 的 Windows x64 安装器与便携包已发布；安装器未签名。
- 弹幕默认走 danmu_api 公共实例（https://danmu.api.tangbai.cc），支持自建；不提供发送弹幕。
- 真实 Jellyfin 12.2 使用 NAS（`192.168.8.137:8096`）验证；没有在本地启动 Jellyfin/.NET。
- 旧 MPV Shim 实现/旧文档/旧 git 历史已丢失，不可恢复；新方案不再以它为基座。
- 下一步：安装版完整 E2E → 原始性能/联调证据归档 → Stage B。

## 1. 文档索引

| 文档 | 内容 |
|---|---|
| [OVERVIEW.md](OVERVIEW.md) | 产品定位、目标用户、范围、非目标、Stage A/B |
| [RESEARCH.md](RESEARCH.md) | 开源项目与 API 调研、实测事实、选型依据 |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Flutter/Riverpod/media_kit 架构、模块、数据流、文件布局 |
| [PLAN.md](PLAN.md) | 总实施计划、阶段门、工期、交付物 |
| [KAZUMI.md](KAZUMI.md) | Kazumi 的番剧时间表、图片识别、Bangumi 评论专项分析 |
| [BANGUMI.md](BANGUMI.md) | Bangumi 时间表/图片识别/评论的详细设计与网络方案 |
| [DANMAKU.md](DANMAKU.md) | danmu_api 弹幕客户端、匹配、渲染、设置、缓存、合规 |
| [SR.md](SR.md) | Anime4K/FSRCNNX/ArtCNN shader 超分；RTX VSR 限制 |
| [PARTY.md](PARTY.md) | Jellyfin SyncPlay（复用 PR #735）设计与测试矩阵 |
| [TESTING.md](TESTING.md) | 测试策略、Mock、验收清单、证据目录 |
| [ASSETS.md](ASSETS.md) | 下载物、测试媒体、工具链、manifest、目录约定 |
| [LICENSING.md](LICENSING.md) | GPL/第三方许可、署名、内容合规 |
| [DECISIONS.md](DECISIONS.md) | ADR：基座、SyncPlay、弹幕、超分、Bangumi、分支 |
| [ROADMAP.md](ROADMAP.md) | 状态表、里程碑、当前阻塞与下一步 |
| [IMPLEMENTATION.md](IMPLEMENTATION.md) | 实施检查清单与证据模板 |
| [STAGE_A_REPORT.md](STAGE_A_REPORT.md) | v0.1.0-beta.5 的 Stage A 验收报告（2026-10-23） |
| [BUILD_WINDOWS.md](BUILD_WINDOWS.md) | Windows 原生依赖、构建命令、已知失败与处理 |
| [UPSTREAM.md](UPSTREAM.md) | Fladder/PR #735 固定与合并策略；legacy 说明 |

归档目录：[docs/archive/mpv-shim/](../archive/mpv-shim/README.md)。

## 2. 推荐阅读顺序

1. 新 agent/新贡献者：AGENTS.md → 本文 → OVERVIEW → DECISIONS → PLAN。
2. 做播放器/弹幕：ARCHITECTURE → DANMAKU → SR → PARTY → TESTING。
3. 做 Bangumi 模块：RESEARCH → KAZUMI → BANGUMI → TESTING。
4. 做打包/发布：ASSETS → LICENSING → UPSTREAM → PLAN。

## 3. 术语

- **Fladder**：DonutWare 的跨平台 Jellyfin 前端，Flutter/Dart，GPL-3.0。
- **PR #735**：Fladder 社区提交的 Jellyfin SyncPlay 支持，当前 open，未合并。
- **Stage A**：核心播放器阶段：Fladder 导入、弹幕、shader 超分、Jellyfin SyncPlay、打包。
- **Stage B**：Bangumi 增值阶段：番剧时间表、图片识别、Bangumi 评论。
- **danmu_api**：可自建的弹幕聚合 API（https://github.com/huangxd-/danmu_api），默认公共实例 https://danmu.api.tangbai.cc。
- **Next p1**：Bangumi 新前端接口（next.bgm.tv/p1），非官方 OpenAPI；评论功能依赖。
- **trace.moe**：以图搜番服务，返回 AniList 结果。
- **RTX VSR**：NVIDIA 驱动级视频超分；在 media_kit 的 ANGLE/OpenGL 渲染路径下不作为 v1 验收项。

## 4. 阶段与边界

| 阶段 | 目标 | 状态（2026-10-23） |
|---|---|---|
| Stage A | 可用 Jellyfin 播放器 + 弹幕 + shader 超分 + SyncPlay + 打包 | 功能验收通过；发布安装版 E2E 与原始证据归档待收尾 |
| Stage B | Bangumi 时间表 + 图片识别 + 评论（条件功能） | 未开始，依赖 Bangumi 网络 |

Stage B 不应阻塞 Stage A；两阶段可独立验收。

## 5. 文档维护规则

- 任何“已完成/已通过/已验证”必须有命令输出、截图、日志或性能 JSON；否则写“计划/待验证”。
- 架构决策变更时新增 ADR，不直接改写历史结论。
- 外部 API/网络状态变化（尤其 Bangumi、danmu_api）需更新 RESEARCH/ROADMAP。
- 不把密钥、Token、真实用户数据、版权媒体写入文档或仓库。
- 所有下载物与测试文件放在本仓库目录内，路径见 ASSETS.md。
