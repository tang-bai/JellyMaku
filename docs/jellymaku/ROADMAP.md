
# 路线图与当前状态

> 更新：2026-10-21。所有状态以实际文件/命令为准；未执行的写“未开始”。

## 1. 当前状态

| 项目 | 状态 | 说明 |
|---|---|---|
| 文档集 + AGENTS.md | 完成；Stage A 报告/构建说明已补 | 见 STAGE_A_REPORT/BUILD_WINDOWS |
| 本地 git 仓库 | 完成 | main 已推送 origin（v0.1.0-beta.4 发布） |
| 旧 MPV Shim 实现 | 丢失 | 本地/远程均不可恢复；不再作为基座 |
| Fladder 源码 | 已导入 + 已合并 develop | PR #735 head + Fladder develop `de7b5a2a`（2026-10-21 合并；见 IMPLEMENTATION） |
| Flutter 工具链 | 完成 | 3.35.7；analyze 0 issue |
| 构建/单测 | 完成 | Windows release（10-21，品牌/ARB/按钮顺序后）；138 tests；analyze 0 |
| 弹幕 | 已接入并完成 E2E | danmu_api 自动/手动匹配、URL 拉取、合并去重、本地导入、叠加层；NAS 播放器内 seek/pause 自动验证，字幕/切集/弹幕由用户手动确认；5000 条基准 52–55ms 解析、约 1ms/帧 |
| 超分 | 核心已接入；部分验收 | Anime4K Fast/Balanced/Strong/4x；截图已采，性能仅 GPU 粗测，缺 FPS/掉帧 |
| SyncPlay | 代码+单测；真实双端未做 | PR #735 head；见 PARTY |
| Bangumi 时间表/图片/评论 | 未开始 | 条件功能；见 BANGUMI/KAZUMI |
| 打包/品牌 | 完成 | 安装器 + 便携包已发布到 GitHub v0.1.0-beta.4；品牌/更新检查/关于页/窗口标题完成 |

## 2. 里程碑

| 里程碑 | 内容 | 目标 |
|---|---|---|
| M0 | 文档/AGENTS/资产约定 | 本次 |
| M1 | Fladder + PR #735 可构建、可登录/播放 | Stage A0 |
| M2 | 弹幕可用（danmu_api/本地导入 + 播放器内 E2E） | Stage A1/A2 |
| M3 | shader 超分可切换、有性能证据 | Stage A3 |
| M4 | SyncPlay 双客户端通过 | Stage A4 |
| M5 | 安装器/便携包 + Stage A 验收 | Stage A5 |
| M6 | Bangumi 数据层/Mock/代理 | Stage B0 |
| M7 | 番剧时间表 | Stage B1 |
| M8 | 图片识别 | Stage B2 |
| M9 | Bangumi 评论（条件） | Stage B3 |

## 3. 当前阻塞

1. **SyncPlay 真实双端未做**：单测通过；Jellyfin 12.2 WebSocket/时钟误差未验证；中文组面板未完善。
2. **超分性能未验收**：截图已有，缺 FPS/掉帧记录（仅 GPU 利用率粗测）。
3. **安装后完整功能未验证**：安装器/启动/卸载冒烟通过，但未在安装目录做登录/播放/弹幕 E2E。
4. **Stage A 报告过期**：STAGE_A_REPORT.md 仍是旧弹幕实现的历史版本，验收前需重写。
5. **Bangumi 网络（Stage B）**：官方不可达；评论/搜索镜像 401；需用户代理/自建 Worker。

## 4. 下一步（建议顺序）

1. **SyncPlay 双端联调**：JellyMaku + Jellyfin Web / 双实例，验证播放/暂停/seek/切集/重连，记录误差与截图。
2. **超分性能验收**：用 PresentMon/CapFrameX 采各档 FPS/掉帧，补进 A3 证据。
3. **安装目录完整 E2E**：在安装版上做登录/播放/字幕/弹幕验收。
4. **Stage A 收尾**：重写 `STAGE_A_REPORT.md`，确认许可/署名完整，准备 Stage A 验收。
5. **Stage B**：Bangumi 数据层/Mock；再决定真实评论代理方案。

## 5. 决策待确认

- 后续 develop 合并/修复是否直接推送 main？
- 是否将 JellyMaku 作为显示名、保留 Fladder 内部包名/ID？
- 是否 Stage A 先交付、Stage B 后置？
- 是否必须 RTX VSR（否则 v1 只做 shader 超分）？
- 是否提供 Bangumi 代理/Worker（否则评论只 Mock）？

## 6. 完成定义

- 每个里程碑有可运行构建/截图/日志。
- 文档状态与实现一致；未验证项不标记完成。
- 不把旧实现/文档的未验证结论带入新项目。
