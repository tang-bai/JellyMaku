
# 上游策略：Fladder、PR #735、legacy

> 状态：Draft。
> 原则：固定上游 commit；小 patch；保留上游历史/许可；不向上游强推。

## 1. 固定的上游

| 上游 | 固定点 | 说明 |
|---|---|---|
| DonutWare/Fladder | develop de7b5a2a23f16f5f3bb164ec0baedf50941e4808（2026-10-18） | 基座 |
| Fladder PR #735 | head 79e249ebf99ecc8dc8f0d5d43c3604ace45fbba9 | SyncPlay；open |
| Jellyfin | 12.2 | 测试/兼容目标 |
| default-shader-pack | v3.0.0 | shader 资产 |
| Flutter | 3.35.7 | Fladder .fvmrc |

## 2. 分支/仓库策略

当前工作区无 .git，远程仓库为空；旧实现丢失。建议：

1. **新本地仓库**：`git init -b main`，提交文档；再导入 Fladder 历史。
2. **导入方式**（二选一）：
   - 方案 A（推荐）：以 Fladder commit 为根新建 `jellymaku` 分支；合并 PR #735；文档作为额外 commit。旧 MPV Shim 历史已不可恢复，不强求。
   - 方案 B：新仓库 main 先放文档；`git remote add fladder`，fetch，创建孤立分支/合并 unrelated histories；历史较复杂，但保留上游提交。
3. 不直接在上游 develop 上提交；不 force-push 上游；不向 DonutWare 提交未经讨论的大改。
4. PR #735：合并/移植时保留作者与提交信息；在 README/THIRD_PARTY_NOTICES 署名。
5. 后续升级：固定 commit；小范围 merge/rebase；每次升级跑 analyze/test/build + 弹幕/SyncPlay smoke。

## 3. 旧实现（legacy MPV Shim）

- 旧方案：jellyfin-mpv-shim + Python + libmpv + mpvtk；已有弹幕/RTX VSR/SyncPlay 的一些实现与文档。
- 状态：本地 .git/远程均不可恢复；不再维护。
- 处理：
  - 文档保留历史背景（README/ROADMAP）。
  - 若用户另有备份，先确认再决定是否归档到 `docs/archive/mpv-shim/`；不要静默覆盖。
  - 不把旧代码/旧结论直接搬进 Fladder 方案；需要重新验证。

## 4. 合并 PR #735 的步骤（计划）

~~~powershell
git remote add fladder https://github.com/DonutWare/Fladder.git
git fetch fladder develop
git fetch fladder refs/pull/735/head:pr-735
git switch -c jellymaku <fladder-commit>
git merge --no-ff pr-735
~~~

- 冲突热点：video_player_provider.dart、playback_model.dart、video_player_settings.dart、video_player_settings_provider.dart、home_screen.dart、ARB、pubspec、生成文件。
- 若冲突过大：从 pr-735 建分支 merge develop；或按 PR 文件清单移植。
- 验证：flutter analyze/test/build；Jellyfin 12.2 SyncPlay；Windows/libMPV。

## 5. 许可/署名

- Fladder GPL-3.0；PR #735 GPL-3.0；Kazumi GPL-3.0；保留 LICENSE/提交作者。
- 不复制 Kazumi 图标/字体/美术。
- 发布包含完整源码/许可/第三方声明。

## 6. 不向上游推送

- 本项目是用户仓库的衍生；不自动向上游开 PR/推送。
- 如希望贡献回 Fladder，先与用户确认并遵守其贡献指南/讨论。
