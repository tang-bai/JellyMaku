
# 路线图与当前状态

> 更新：2026-10-19。所有状态以实际文件/命令为准；未执行的写“未开始”。

## 1. 当前状态

| 项目 | 状态 | 说明 |
|---|---|---|
| 文档集 + AGENTS.md | 完成（0c46705） | 计划文档；非实现 |
| 本地 git 仓库 | 完成 | main 已初始化；远程为空/未推送 |
| 旧 MPV Shim 实现 | 丢失 | 本地/远程均不可恢复；不再作为基座 |
| Fladder 源码 | 已导入 | PR #735 head 基线 e7ce1e97；最新 develop 待合并 |
| Flutter 工具链 | 未安装 | 需下载 3.35.7；VS BuildTools/Developer Mode 已具备 |
| 弹幕 | 未开始 | 设计见 DANMAKU |
| 超分 | 未开始 | 设计见 SR |
| SyncPlay | 代码已导入；未验证 | PR #735 head；见 PARTY |
| Bangumi 时间表/图片/评论 | 未开始 | 条件功能；见 BANGUMI/KAZUMI |
| 打包/品牌 | 未开始 | PLAN Stage A5 |

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

1. **尚未推送**：本地 main 已有导入；远程为空、origin 已配置。需确认是否/何时推送。
2. **基线不含最新 develop**：当前为 PR #735 head；Phase A0 需 merge/rebase 最新 develop 并解决冲突。
3. **PR #735 上游未合并**：代码已导入；仍需构建/测试验证 Jellyfin 12.2/Windows。
4. **Flutter SDK 未安装**：1.76GB；需 VS 构建验证。
5. **Bangumi 网络**：官方不可达；评论/搜索镜像 401；需用户代理/自建 Worker。
6. **DDP 凭证**：真实弹幕联调需 AppId/AppSecret；否则 Mock/本地 XML。
7. **RTX VSR 限制**：不作为 v1 验收；如需驱动级 VSR 另立项。

## 4. 下一步（建议顺序）

1. 安装 Flutter 3.35.7；确认 VS BuildTools/Developer Mode；必要时 subst J:。
2. 补最新 develop 合并；flutter pub get/analyze/test/build 基线。
3. 下载 Jellyfin/.NET/shader/Inno 到本目录；manifest。
4. Stage A1 弹幕；Stage A3 超分；Stage A4 SyncPlay；Stage A5 打包。
5. Stage B0 Bangumi 数据层/Mock；再决定是否做真实评论联调。

## 5. 决策待确认

- 是否现在配置 origin 并推送 main（远程仍为空）？
- 是否将 JellyMaku 作为显示名、保留 Fladder 内部包名/ID？
- 是否 Stage A 先交付、Stage B 后置？
- 是否必须 RTX VSR（否则 v1 只做 shader 超分）？
- 是否提供 Bangumi 代理/Worker（否则评论只 Mock）？

## 6. 完成定义

- 每个里程碑有可运行构建/截图/日志。
- 文档状态与实现一致；未验证项不标记完成。
- 不把旧实现/文档的未验证结论带入新项目。
