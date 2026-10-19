
# 架构决策记录（ADR）

> 状态：Proposed/Accepted 混合；未标注 Accepted 的需在实施前复核。
> 规则：推翻决策时新增 ADR，不直接改写历史。

## ADR-001：以 Fladder 为基座

- 状态：**Accepted**（用户指定）。
- 背景：从零实现 Windows Jellyfin 客户端 + 播放器 + SyncPlay + 弹幕/超分成本高；Fladder 已有成熟 UI/Jellyfin/media_kit。
- 决策：固定 Fladder develop commit de7b5a2；派生 jellymaku 分支；保留旧 MPV Shim 方案为历史。
- 后果：获得完整客户端；需承担 Flutter/媒体栈复杂度；上游活跃需固定/合并。
- 备选：jellyfin-desktop（Qt/C++）、mpv.net（无 Jellyfin）、自研（不选）。

## ADR-002：复用 Fladder PR #735 实现 Jellyfin SyncPlay

- 状态：Proposed（PR head 代码已导入；待构建/验证）。
- 背景：PR 已实现 WebSocket、时间同步、命令调度、UI、文档；重写成本高。
- 决策：以 PR #735 为起点，合并到 Fladder develop；适配 Windows/libMPV；补测试/中文。
- 后果：减少开发；PR 未合并/可能冲突；需署名与维护。
- 备选：自研 SyncPlay（不选）；Kazumi 公共 SyncPlay（不兼容 Jellyfin）。

## ADR-003：弹幕使用 Flutter 自绘叠加层

- 状态：Proposed。
- 背景：media_kit 的 libass/字幕层与 external ASS secondary-sid 复杂。
- 决策：DDP 解析 + CustomPainter 叠加；只绘制活跃评论。
- 后果：实时样式/开关；不能点击/高级 ASS；截图需外部。
- 备选：libmpv secondary-sid（后续可选）。

## ADR-004：超分使用 GLSL shader，RTX VSR 不纳入 v1

- 状态：Proposed。
- 背景：media_kit Windows 使用 ANGLE/OpenGL；d3d11vpp/RTX VSR 不可靠。
- 决策：Anime4K/FSRCNNX/ArtCNN 通过 glsl-shaders；默认 off/推荐；RTX VSR 仅 spike。
- 后果：可用且跨 GPU；无驱动级 VSR；需 shader 许可。
- 备选：fork media_kit D3D11/外部 mpv（+3–5 天，高风险）。

## ADR-005：Bangumi 模块作为 Stage B 条件功能

- 状态：Proposed。
- 背景：官方 Bangumi 当前网络不可达；评论仅 Next p1；镜像签名不可复用。
- 决策：Bangumi client 支持官方/代理/Worker；时间表/图片/评论独立开关；无网降级；不承诺开箱即用。
- 后果：核心不受阻；评论需用户网络条件；部分功能只能 Mock 验证。
- 备选：不实现评论（更保守）；只做时间表/图片本地匹配。

## ADR-006：以图搜番先匹配 Jellyfin，再考虑 Bangumi

- 状态：Proposed。
- 背景：trace.moe 返回 AniList，无 Bangumi ID；Bangumi 映射需搜索+人工。
- 决策：识别结果优先搜索本地 Jellyfin；Bangumi 可达时提供候选；不自动绑定。
- 后果：即使没有 Bangumi 网络也能用；映射准确率依赖人工。

## ADR-007：品牌/分支策略

- 状态：Proposed。
- 背景：本地 main 已初始化；PR #735 head 基线已导入；远程为空；旧实现已丢失。
- 决策：main 作为工作分支；显示名 JellyMaku；Dart 包名/内部 ID 尽量保持 Fladder；更新检查不指回 Fladder；后续补最新 develop。
- 后果：已有可查看源码；尚未构建；旧实现不可恢复；需文档说明。
- 备选：完全重命名包名/ID（成本高，暂不选）。

## ADR-008：不使用 Kazumi 作为基座

- 状态：**Accepted**（分析结论）。
- 背景：Kazumi 无 Jellyfin 集成，公共 SyncPlay 不兼容；但有可复用模块。
- 决策：Fladder 基座 + 移植 Kazumi 的时间表/图片/评论/弹幕/超分经验。
- 后果：保留 Jellyfin 能力；需跨架构移植；需 GPL 署名。

## ADR-009：所有下载/测试资产本地化

- 状态：**Accepted**（用户要求）。
- 决策：Flutter/Jellyfin/.NET/shader/Inno/测试媒体放仓库目录；大文件 gitignore；manifest 校验。
- 后果：可复现；仓库体积大但不入库；需下载脚本。
- 备选：系统级安装（不选）。
