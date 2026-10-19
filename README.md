
# JellyMaku

> 状态：文档先行 / 源码尚未导入（2026-10-19）
> 目标基座：DonutWare/Fladder（Flutter/Dart，GPL-3.0）
> 当前仓库：本地 .git 缺失，远程仓库为空；旧 MPV Shim 实现不可恢复。

JellyMaku 是面向 Windows 10/11 的 Jellyfin 桌面播放器，基于 Fladder 二次开发，计划提供：

- 弹弹play 弹幕（自动/手动匹配、Flutter 叠加层、样式/过滤/偏移）
- Anime4K / FSRCNNX / ArtCNN GLSL 视频超分
- Jellyfin SyncPlay 一起看（复用 Fladder PR #735）
- Stage B：Bangumi 番剧时间表、以图搜番、Bangumi 评论（条件功能）

## 现在能做什么

- 阅读完整计划：docs/jellymaku/README.md
- 查看 agent 规则：AGENTS.md
- 查看 Kazumi 三项能力分析：docs/jellymaku/KAZUMI.md
- 查看 Bangumi 网络限制：docs/jellymaku/BANGUMI.md
- 查看下载/测试资产约定：docs/jellymaku/ASSETS.md

## 还没做什么

- Fladder 源码尚未导入
- Flutter 工具链尚未安装
- 弹幕/超分/SyncPlay/Bangumi 均未实现
- 没有可运行构建、测试、截图或安装包

## 重要限制

- Bangumi 官方 API 在当前网络不可达；评论/搜索镜像要求签名，不能复用 Kazumi 私有凭证。评论功能必须由用户提供代理/自建 Worker，否则只能 Mock/离线验证。
- media_kit 的 Windows 渲染路径为 ANGLE/OpenGL，RTX VSR 不作为 v1 验收项；v1 使用 GLSL shader 超分。
- 所有下载物/测试文件放在本仓库目录；大文件不提交。

## 许可

本项目计划以 GPL-3.0 分发，保留 Fladder、PR #735、Kazumi、Anime4K/default-shader-pack、DanDanPlay、Bangumi、trace.moe 等署名；详见 docs/jellymaku/LICENSING.md。

## 文档索引

docs/jellymaku/README.md 是完整索引；建议按 OVERVIEW → DECISIONS → PLAN → 对应模块阅读。
