
# 上游策略：Fladder、PR #735、legacy

> 状态（2026-10-23）：Accepted；Fladder develop `de7b5a2a` 已合并，PR #735 head 已保留；本地 `main` 为 `26ac04a4`（领先 origin/main 1 个提交，未推送）。
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

当前 `main` 已包含 PR #735 head（Fladder + SyncPlay）并合并 Fladder develop `de7b5a2a`；origin 为 https://github.com/tang-bai/JellyMaku，本地 `main` 为 `26ac04a4`（origin/main 仍 `21891411`）。实际采用：

1. **main**：工作分支；v0.1.0 正式版已发布，工作区干净。
2. **导入基线**：PR #735 head + 上游 develop 合并；保留提交历史/作者。
3. **后续升级**：固定 commit；小范围 merge/rebase；每次升级跑 analyze/test/build + 弹幕/SyncPlay smoke。
4. 不直接在上游 develop 上提交；不 force-push 上游；不向 DonutWare 提交未经讨论的大改。
5. PR #735：保留作者与提交信息；在 README/THIRD_PARTY_NOTICES 署名。
6. `THIRD_PARTY_NOTICES.md` 已补；发布前随安装包核对 `LICENSING.md` 发布检查。

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
