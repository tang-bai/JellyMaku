
# 旧方案归档说明（MPV Shim 基座）

> 状态：占位/历史说明。
> 日期：2026-10-19。

## 为什么是空的

旧 JellyMaku 方案基于 jellyfin/jellyfin-mpv-shim（Python + libmpv + mpvtk），曾包含弹幕、RTX VSR、SyncPlay、便携打包等实现与文档。

在本次切换到 Fladder 基座之前：

- 本地工作区的 `.git` 目录已不存在；
- 远程仓库 https://github.com/tang-bai/JellyMaku 为空（size 0）；
- 磁盘上的旧源码/旧文档也未保留。

因此无法把旧文档实际归档到这里，也没有可恢复的旧代码。本目录仅保留说明，避免后续误以为有可用归档。

## 处理原则

- 新项目以 `docs/jellymaku/` 的 Fladder 方案为准，不回搬旧实现。
- 如果用户另有旧代码/文档备份，先确认来源与版本，再放入本目录；不要静默覆盖。
- 旧方案中的结论（测试/截图/性能）不再视为已验证；如要复用，必须重新跑。

## 相关文档

- 新方案索引：../../jellymaku/README.md
- 上游策略：../../jellymaku/UPSTREAM.md
- 决策记录：../../jellymaku/DECISIONS.md
