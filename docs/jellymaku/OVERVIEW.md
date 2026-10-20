
# JellyMaku 概览

## 1. 是什么

JellyMaku 是面向 Windows 10/11 的 Jellyfin 桌面播放器，基于 **DonutWare/Fladder** 二次开发。它保留 Fladder 的现代 Flutter UI、Jellyfin 客户端能力、下载/同步、Trickplay、媒体段跳过，并新增：

- danmu_api 弹幕（自动/手动匹配、Flutter 叠加层、样式/过滤/偏移；默认 https://danmu.api.tangbai.cc）。
- 视频超分（Anime4K / FSRCNNX / ArtCNN 等 GLSL shader）。
- 一起看（Jellyfin SyncPlay，复用社区 PR #735）。
- 番剧时间表、以图搜番、Bangumi 评论（Stage B，条件功能）。

它不是 Jellyfin 官方客户端；不隶属于 Jellyfin 或 Bangumi 项目。

## 2. 目标用户

- 有自建 Jellyfin 服务器、主要在 Windows 桌面看番/看电影的用户。
- 希望自动匹配弹幕（danmu_api 聚合多站来源），并能在播放器里开关/调样式。
- 有独立显卡、希望用 Anime4K/FSRCNNX 实时提升画质的用户。
- 想和朋友在同一 Jellyfin 服务器上同步观看的用户。
- 有 Bangumi 使用习惯、希望看到放送表/评论/以图搜番的用户（Stage B）。

## 3. 功能范围

### Stage A（必须交付）

| 功能 | 实现方式 | 依赖 |
|---|---|---|
| Jellyfin 登录/库/详情/播放 | 复用 Fladder | Jellyfin 服务器 |
| 直连/转码/离线 | 复用 Fladder | - |
| 弹幕 | danmu_api 客户端 + Flutter CustomPainter | 网络（默认公共实例，可自建）或本地 XML/JSON |
| 弹幕设置 | 字体/字号/透明度/速度/区域/偏移/过滤/手动匹配/API 地址 | - |
| 超分 | libmpv glsl-shaders | 支持 GLSL 的 GPU/驱动 |
| 一起看 | Jellyfin SyncPlay（PR #735） | 同一服务器、各自账号 |
| 品牌/安装器/便携包 | Flutter build + Inno Setup | Windows 工具链 |

### Stage B（增值，条件功能）

| 功能 | 实现方式 | 依赖/限制 |
|---|---|---|
| 番剧时间表 | Bangumi `/p1/calendar` + 搜索补季 | Bangumi 可达；官方当前网络不可达 |
| 以图搜番 | trace.moe + Jellyfin/Bangumi 匹配 | trace.moe 配额；图片上传需同意 |
| Bangumi 评论 | Next `/p1/.../comments`，只读 | 官方 v0 无评论；必须经代理/自建镜像 |
| 详情/播放器评论入口 | Riverpod + Flutter 页面 | 同上，网络不可达时优雅降级 |

## 4. 明确不做（v1）

- 不写自绘播放器/同步服务器/弹幕渲染引擎之外的底层。
- 不做应用内聊天、发送弹幕、Bangumi 发帖/点赞/举报。
- 不做房主中转、端口映射、cloudflared；SyncPlay 走 Jellyfin 服务器。
- 不做移动端/Web/TV 专项、HDR/杜比视界专项。
- 不做 RTX VSR 驱动级超分（v1 只做 GLSL shader）。
- 不保证所有番剧自动匹配正确；低置信度必须人工确认。
- 不复制 Kazumi 的图标、字体、美术资源；只参考/移植 GPL 代码。

## 5. 关键原则

1. **先能播，再增强**：弹幕/超分/同步失败都不能阻塞播放。
2. **条件功能**：Bangumi 模块在不可达时隐藏/提示，不影响核心。
3. **可验证**：每个功能有单测、Mock 或截图/日志；不虚报。
4. **本地资产**：所有下载/测试文件在仓库目录，manifest 可校验。
5. **合规**：GPL-3.0、danmu_api/Bangumi 署名、trace.moe 隐私、不内置密钥。

## 6. 成功标准

- Stage A：本地 Jellyfin 登录/播放；弹幕可用；shader 超分可切换；SyncPlay 双客户端通过；便携包/安装器干净运行。
- Stage B：有 Bangumi 网络路径时时间表/评论/图片识别可用；无路径时功能明确不可用且不影响 Stage A。
- 所有验收以实际命令/截图/日志为准（见 TESTING.md）。
