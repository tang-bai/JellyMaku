
# JellyMaku

> 状态：**v0.1.0-beta.1** 首个 Windows Beta（analyze 0 issue；103 tests passed；2026-10-20）
> 目标基座：DonutWare/Fladder（Flutter/Dart，GPL-3.0）
> 当前仓库：main 已包含 Fladder + PR #735 + Stage A 代码；已推送 origin（最新提交见 git log）。

JellyMaku 是面向 Windows 10/11 的 Jellyfin 桌面播放器，基于 Fladder 二次开发，计划提供：

- 弹弹play 弹幕（自动/手动匹配、Flutter 叠加层、样式/过滤/偏移）
- Anime4K / FSRCNNX / ArtCNN GLSL 视频超分
- Jellyfin SyncPlay 一起看（复用 Fladder PR #735）
- Stage B：Bangumi 番剧时间表、以图搜番、Bangumi 评论（条件功能）

## 现在能做什么

- 运行 Windows 构建：`build/windows/x64/runner/Release/JellyMaku.exe`
- 使用便携包：`artifacts/JellyMaku-0.1.0-windows-x64-portable.zip`（本地生成，不入库）
- 在播放器底栏打开弹幕设置（弹弹play AppId/AppSecret）与超分菜单（Anime4K）
- 查看 Stage A 构建/测试证据：docs/jellymaku/STAGE_A_REPORT.md
- 查看 Windows 构建复现步骤：docs/jellymaku/BUILD_WINDOWS.md
- 阅读完整计划：docs/jellymaku/README.md
- 查看 agent 规则：AGENTS.md

## 还没做什么

- 最新 Fladder develop 尚未合并（基线仍是 PR #735 head）
- 真实 Jellyfin 12.2 登录/播放/字幕/seek/切集 E2E 尚未执行
- 真实 DDP AppId/AppSecret 联调、手动匹配/本地 XML 尚未完成
- SyncPlay 双客户端真实联调尚未执行
- 超分画质/性能对比、安装器、中文 ARB 文案尚未完成
- Bangumi 时间表/图片识别/评论（Stage B）尚未开始

## 重要限制

- 当前环境无法直连 DDP 真实服务（无 AppId/AppSecret）；弹幕行为由本地 mock/单测覆盖，真实联调需用户凭证。
- Bangumi 官方 API 在当前网络不可达；评论/搜索镜像要求签名，不能复用 Kazumi 私有凭证。评论功能必须由用户提供代理/自建 Worker，否则只能 Mock/离线验证。
- media_kit 的 Windows 渲染路径为 ANGLE/OpenGL，RTX VSR 不作为 v1 验收项；v1 使用 GLSL shader 超分。Anime4K 输出尚未做画质/性能验收。
- 所有下载物/测试文件放在本仓库目录；大文件不提交。

## 许可

本项目计划以 GPL-3.0 分发，保留 Fladder、PR #735、Kazumi、Anime4K/default-shader-pack、DanDanPlay、Bangumi、trace.moe 等署名；详见 docs/jellymaku/LICENSING.md。

## 文档索引

docs/jellymaku/README.md 是完整索引；建议按 OVERVIEW → DECISIONS → PLAN → 对应模块阅读。
