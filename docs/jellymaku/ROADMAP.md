
# 路线图与当前状态

> 更新：2026-10-20。所有状态以实际文件/命令为准；未执行的写“未开始”。

## 1. 当前状态

| 项目 | 状态 | 说明 |
|---|---|---|
| 文档集 + AGENTS.md | 完成；Stage A 报告/构建说明已补 | 见 STAGE_A_REPORT/BUILD_WINDOWS |
| 本地 git 仓库 | 完成 | main 已推送到 origin（e2b3ca7） |
| 旧 MPV Shim 实现 | 丢失 | 本地/远程均不可恢复；不再作为基座 |
| Fladder 源码 | 已导入 | PR #735 head 基线；最新 develop 待合并 |
| Flutter 工具链 | 完成 | 3.35.7；analyze 0 issue |
| 构建/单测 | 完成 | Windows release/启动冒烟（10-20）；118 tests（10-20） |
| 弹幕 | 核心功能已接入；真实联调未做 | DDP/自动+手动匹配/来源过滤/合并去重/本地导入/发送回显/缓存/叠加层/设置/DPAPI；真实联调未做 |
| 超分 | 核心已接入；未验收 | Anime4K Fast/Quality；画质/性能未测 |
| SyncPlay | 代码+单测；真实双端未做 | PR #735 head；见 PARTY |
| Bangumi 时间表/图片/评论 | 未开始 | 条件功能；见 BANGUMI/KAZUMI |
| 打包/品牌 | 便携包已出；安装器未做 | JellyMaku.exe/窗口/资源；zip 90.6MB |

## 2. 里程碑

| 里程碑 | 内容 | 目标 |
|---|---|---|
| M0 | 文档/AGENTS/资产约定 | 本次 |
| M1 | Fladder + PR #735 可构建、可登录/播放 | Stage A0 |
| M2 | 弹幕可用（Mock/本地导入 + 真实凭证可选） | Stage A1/A2 |
| M3 | shader 超分可切换、有性能证据 | Stage A3 |
| M4 | SyncPlay 双客户端通过 | Stage A4 |
| M5 | 安装器/便携包 + Stage A 验收 | Stage A5 |
| M6 | Bangumi 数据层/Mock/代理 | Stage B0 |
| M7 | 番剧时间表 | Stage B1 |
| M8 | 图片识别 | Stage B2 |
| M9 | Bangumi 评论（条件） | Stage B3 |

## 3. 当前阻塞

1. **已推送**：main 已推送到 origin（e2b3ca7）；后续变更需确认后再 push。
2. **基线不含最新 develop**：当前为 PR #735 head；Phase A0 仍需 merge/rebase 最新 develop 并解决冲突。
3. **真实 Jellyfin E2E 未做**：未下载/启动 Jellyfin 12.2；登录/播放/字幕/seek/切集未验证。
4. **DDP 凭证缺失**：真实弹幕联调需 AppId/AppSecret；当前只有本地 mock/单测。手动匹配/来源过滤已实现，但 p[3] 来源语义与真实响应仍需凭证确认。
5. **SyncPlay 真实双端未做**：单测通过；Jellyfin 12.2 WebSocket/时钟误差未验证。
6. **超分未验收**：无画质/性能截图；ANGLE/OpenGL 下 shader 可能被拒绝。
7. **Bangumi 网络**：官方不可达；评论/搜索镜像 401；需用户代理/自建 Worker。
8. **安装器/中文 ARB 未做**：当前 portable zip；弹幕设置文案硬编码英文。

## 4. 下一步（建议顺序）

1. 推送 main 到 origin，确认远程可构建。
2. 补最新 develop 合并，重新跑 analyze/test/build。
3. 下载/启动 Jellyfin 12.2 + .NET 10 + 测试媒体；做登录/播放/seek/切集/字幕 E2E。
4. 申请 DDP AppId/AppSecret；真实弹幕联调（含 p[3] 来源语义）；补本地导入/发送回显。
5. SyncPlay 双端联调；超分画质/性能验收；安装器/中文 ARB。
6. Stage B Bangumi 数据层/Mock；再决定真实评论联调。

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
