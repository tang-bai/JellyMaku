# 路线图与当前状态

> 更新：2026-10-23。状态以实际文件/命令/证据为准；未执行的写“未开始/未验证”。
> 基线：本地 `main` 为 `26ac04a4`（领先 origin/main `21891411` 1 个提交，未推送）；文档/声明仍有工作区改动。

## 1. 当前状态

| 项目 | 状态 | 说明 |
|---|---|---|
| 文档集 + AGENTS.md | 基本同步；最终报告待补 | 状态页已按 2026-10-23 结果更新；STAGE_A_REPORT 仍为历史版本 |
| 本地 git 仓库 | 本地提交领先 origin 1 | `26ac04a4` 已提交、未推送；文档/声明仍有工作区改动 |
| 旧 MPV Shim 实现 | 丢失 | 本地/远程均不可恢复；不再作为基座 |
| Fladder 源码 | 已导入 + 已合并 develop | PR #735 head + Fladder develop `de7b5a2a`（2026-10-21） |
| Flutter 工具链 | 完成 | 3.35.7；analyze 0 issue |
| 构建/单测 | 当前 HEAD 通过 | 2026-10-23：156 tests passed + 1 skipped；Windows release 构建成功；beta.5 发布包即当前 HEAD |
| 弹幕 | 已接入；真实播放器内 E2E 已手动确认 | danmu_api 自动/手动匹配、URL 拉取、合并去重、本地导入、叠加层；NAS 12.2 seek/pause 自动验证，字幕/切集/叠加层手动确认 |
| 超分 | 核心已接入；性能未验收 | Anime4K Fast/Balanced/Strong/4x；截图已采；缺 FPS/掉帧记录 |
| SyncPlay | 代码/单测/UI 中文化通过；真实双端未做 | PR #735 head；中文组面板、侧栏状态点已验证；双客户端同步未联调 |
| 播放信息面板 | 已实现并构建；真实播放未验证 | 2026-10-23 新增；码率/下载速度/缓冲/硬解/帧率；需 NAS 实机截图与数值确认 |
| 打包/品牌 | 完成 | beta.5（2026-10-23）安装器 + 便携包已发布；安装器未签名；安装目录完整 E2E 未做 |
| Bangumi 时间表/图片/评论 | 未开始 | 条件功能；见 BANGUMI/KAZUMI |

## 2. 里程碑

| 里程碑 | 内容 | 目标 |
|---|---|---|
| M0 | 文档/AGENTS/资产约定 | 完成 |
| M1 | Fladder + PR #735 可构建、可登录/播放 | Stage A0，完成 |
| M2 | 弹幕可用（danmu_api/本地导入 + 播放器内 E2E） | Stage A1/A2，基本完成 |
| M3 | shader 超分可切换、有性能证据 | Stage A3，性能待补 |
| M4 | SyncPlay 双客户端通过 | Stage A4，未完成 |
| M5 | 安装器/便携包 + Stage A 验收 | Stage A5，发布完成、验收未完成 |
| M6 | Bangumi 数据层/Mock/代理 | Stage B0，未开始 |
| M7 | 番剧时间表 | Stage B1，未开始 |
| M8 | 图片识别 | Stage B2，未开始 |
| M9 | Bangumi 评论（条件） | Stage B3，未开始 |

## 3. 当前阻塞 / 验收缺口

1. **SyncPlay 真实双端未做**：Jellyfin 12.2 WebSocket/时钟误差未验证；需 JellyMaku + Jellyfin Web/第二实例，覆盖播放/暂停/seek/切集/迟到/重连。
2. **超分性能未验收**：截图已有，缺 FPS/掉帧记录（仅 GPU 利用率粗测）。
3. **安装后完整功能未验证**：安装器/启动/卸载冒烟通过，但未在安装目录做登录/播放/字幕/弹幕/超分/SyncPlay E2E；安装器未签名。
4. **播放信息面板未实机验证**：2026-10-23 构建/单测通过，但未在 NAS 播放中点击徽章确认 UI 与实时数值。
5. **Stage A 报告过期**：STAGE_A_REPORT.md 仍是 2026-10-19/20 历史版本，验收前需重写当前结论。
6. **i18n 仍有历史缺口**：`zh` 4 个深链键、`zh_Hant` 约 200 个非 SyncPlay 键缺失；不影响当前 Stage A 验收，但属于收尾债务。
7. **Bangumi 网络（Stage B）**：官方不可达；评论/搜索镜像 401；需用户代理/自建 Worker。

## 4. 下一步（建议顺序）

1. **SyncPlay 双端联调**：JellyMaku + Jellyfin Web / 双实例，验证播放/暂停/seek/切集/重连，记录误差与截图。
2. **超分性能验收**：用 PresentMon/CapFrameX 采各档 FPS/掉帧，补进 A3 证据。
3. **安装目录完整 E2E**：在安装版上做登录/播放/字幕/弹幕/超分验收。
4. **播放信息面板实机复测**：NAS 播放中点击 `SDR HD`，截图并确认码率/速度/缓冲/硬解/帧率。
5. **beta.5 发布收尾**：构建/打包/安装冒烟，复核 `THIRD_PARTY_NOTICES.md` 与 `LICENSING.md`。
6. **Stage A 收尾**：重写 `STAGE_A_REPORT.md`，准备 Stage A 验收。
7. **Stage B**：Bangumi 数据层/Mock；再决定真实评论代理方案。

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

## 7. 近期变更

- 2026-10-23：文档复核——同步 README/AGENTS 状态；重新运行 analyze（0 issue）与 tests（156 passed + 1 skipped）；整理剩余验收项。
- 2026-10-23：播放信息面板——`SDR HD` 徽章可点击，打开实时播放信息（视频/音频码率、下载速度、缓冲、丢帧、硬解、渲染帧率、加载耗时）；MPV/MDK/Native 后端分级支持。真实播放 UI/数值待补。
- 2026-10-22：Seerr 未配置崩溃修复、缺图 404 降级、日志本机时区、SyncPlay 侧栏高亮修复、一起看模块中文化。
