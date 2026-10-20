
# JellyMaku

> 状态：**v0.1.0-beta.3** Windows Beta（弹幕迁移 danmu_api；analyze 0 issue；137 tests；2026-10-21）
> 目标基座：DonutWare/Fladder（Flutter/Dart，GPL-3.0）
> 当前仓库：main 已包含 Fladder + PR #735 + Stage A 代码；已推送 origin（最新提交见 git log）。

JellyMaku 是面向 Windows 10/11 的 Jellyfin 桌面播放器，基于 Fladder 二次开发，计划提供：

- danmu_api 弹幕（自动/手动匹配、Flutter 叠加层、样式/过滤/偏移；默认 https://danmu.api.tangbai.cc）
- Anime4K / FSRCNNX / ArtCNN GLSL 视频超分
- Jellyfin SyncPlay 一起看（复用 Fladder PR #735）
- Stage B：Bangumi 番剧时间表、以图搜番、Bangumi 评论（条件功能）

## 现在能做什么

- 运行 Windows 构建：`build/windows/x64/runner/Release/JellyMaku.exe`
- 使用便携包：`artifacts/JellyMaku-0.1.0-windows-x64-portable.zip`（本地生成，不入库）
- 在播放器底栏打开弹幕设置（danmu_api 地址/样式/手动匹配/本地导入）与超分菜单（Anime4K）
- 查看 Stage A 构建/测试证据：docs/jellymaku/STAGE_A_REPORT.md
- 查看 Windows 构建复现步骤：docs/jellymaku/BUILD_WINDOWS.md
- 阅读完整计划：docs/jellymaku/README.md
- 查看 agent 规则：AGENTS.md

## 还没做什么

- 最新 Fladder develop 尚未合并（基线仍是 PR #735 head）
- 真实 Jellyfin 12.2 登录/播放/字幕/seek/切集 E2E 尚未执行
- 播放器内真实弹幕加载/切集/暂停 E2E 尚未执行（API 已实测）；Windows 包已按新弹幕重建
- SyncPlay 双客户端真实联调尚未执行
- 超分画质/性能对比、安装器、中文 ARB 文案尚未完成
- Bangumi 时间表/图片识别/评论（Stage B）尚未开始

## 重要限制

- 弹幕默认使用公共 danmu_api（https://danmu.api.tangbai.cc）；搜索/match/评论接口已实测 200，但播放器内完整链路仍需真实 Jellyfin 媒体验证。自建服务若设置 TOKEN，请把 /{TOKEN} 写到 API 地址里。
- Bangumi 官方 API 在当前网络不可达；评论/搜索镜像要求签名，不能复用 Kazumi 私有凭证。评论功能必须由用户提供代理/自建 Worker，否则只能 Mock/离线验证。
- media_kit 的 Windows 渲染路径为 ANGLE/OpenGL，RTX VSR 不作为 v1 验收项；v1 使用 GLSL shader 超分。Anime4K 输出尚未做画质/性能验收。
- 所有下载物/测试文件放在本仓库目录；大文件不提交。

## 弹幕使用注意

- 已匹配但某一集没有弹幕：源站本身可能就没有（新番第一集常见）。换一集试试。
- 手动匹配搜不到：客户端会自动去掉 `(2026)`/`S01E01`/`第1集` 等尾部后缀重试；也可手动只输番名。
- 公共实例的 `/comment/{id}` 依赖进程内缓存，跨请求可能失效；客户端已用无状态的 `segmentcomment` 规避。
- renren 源弹幕稀少且时间轴可能偏移；追求体验建议选 B 站/巴哈等源（如有）。

## 许可

本项目计划以 GPL-3.0 分发，保留 Fladder、PR #735、Kazumi、Anime4K/default-shader-pack、danmu_api、Bangumi、trace.moe 等署名；详见 docs/jellymaku/LICENSING.md。

## 文档索引

docs/jellymaku/README.md 是完整索引；建议按 OVERVIEW → DECISIONS → PLAN → 对应模块阅读。
