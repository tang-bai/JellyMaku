# Changelog

## v0.1.0-beta.5 — 2026-10-23

### 新增

- 播放信息面板：点击播放页 `SDR HD` 徽章打开实时信息，显示码率、下载速度、缓冲、丢帧、硬解、渲染帧率、加载耗时等；libmpv/MDK/Native 后端分级支持。

### 修复

- Seerr 未配置时不再发起当前用户请求并写入 SEVERE 崩溃日志。
- 缺图 404 使用占位图，不再反复写入崩溃日志。
- 日志时间跟随本机时区（`MM.dd-HH:mm`）。
- SyncPlay 侧栏状态点不再抢占当前页面高亮。
- 补齐一起看模块简体/繁中文案。
- 新增 `THIRD_PARTY_NOTICES.md`，补齐发布合规声明与许可证检查。

### 验证与已知缺口

- 当前工作区：analyze 0 issue；156 tests passed + 1 skipped；Windows release 构建成功（2026-10-23）。
- 仍未验证：SyncPlay 真实双端、超分 FPS/掉帧、安装版完整 E2E、播放信息面板实机数值、Stage B。

## v0.1.0-beta.4 — 2026-10-21

### Stage A 收尾

- 合并 Fladder develop `de7b5a2a`，修复 SMTC/多窗口/深链冲突。
- NAS Jellyfin 12.2 E2E：登录/播放/暂停/seek 自动验证；字幕切换、切集、弹幕叠加层手动确认。
- 播放器：弹幕按钮移到播放按钮左侧，顺序为 弹幕→上一集→-30s→播放→+30s→下一集→超分。
- 弹幕按钮/超分提示改为 ARB 本地化；弹幕设置与手动匹配对话框中英双语。
- 品牌：窗口标题、更新检查、关于页链接改为 JellyMaku；关于页补充 Fladder 上游说明；移除赞助区块。
- 打包：新增 Inno Setup 安装器 `JellyMaku-0.1.0-beta.4-windows-x64-setup.exe` 与便携包。
- 资产校验：新增 `third_party/manifest.json` 与 `tools/verify-assets.ps1`。

### 已知限制

- SyncPlay 双客户端尚未真实联调。
- 超分只完成截图与 GPU 粗测，缺 FPS/掉帧记录。
- 安装器未签名，SmartScreen 可能提示。
- Bangumi Stage B 未开始。

## v0.1.0-beta.3 — 2026-10-21

### 弹幕

- 弹幕数据源改为 danmu_api，默认 `https://danmu.api.tangbai.cc`，可在设置里改为自建实例。
- 移除旧弹幕服务的应用凭证、签名和密钥存储；旧设置自动迁移，旧密钥清理。
- 自动匹配优先 `POST /api/v2/match`，评论按分集 URL 拉取；缓存 key 改为服务器 + URL 哈希，避免 episodeId 跨服务器串数据。
- 移除简繁转换开关（danmu_api 由服务端 `DANMU_SIMPLIFIED_TRADITIONAL` 控制）。
- 修正 `p[3]` 来源标签解析；来源标签不再被当作 uid 屏蔽。

## v0.1.0-beta.2 — 2026-10-20

### 改进

- 侧栏“搜索”展开为整行图标 + 文字，收起时仍为紧凑图标。
- “一起看”改为与控制台/媒体库一致的导航项样式。
- 侧栏展开/折叠加入 250ms 过渡动画，主内容区域同步平滑让位。
- “一起看”改为全局侧栏项，在搜索页、媒体库等页面不再被隐藏。
- 搜索按钮文字在过渡期间保持单行省略，不再换行。

### 说明

- 功能与 beta.1 一致；本版聚焦侧栏布局、样式和过渡动画。

## v0.1.0-beta.1 — 2026-10-20

首个 Windows x64 Beta。

### 新增

- 基于 Fladder + SyncPlay PR #735 的 Windows 桌面客户端。
- 弹幕：自动匹配、滚动/顶部/底部、简繁转换、字体/透明度/速度/显示区域/时间偏移。
- 弹幕设置界面完整简体中文化。
- Anime4K 超分档位：Fast 2x、Balanced 2x、Strong 2x、4x；中文菜单说明。
- 播放器体验修复：点击画面暂停、暂停时弹幕冻结、恢复播放不拉扯、弹幕匀速与轨道/文本布局缓存。

### 安装

1. 解压 `JellyMaku-v0.1.0-beta.1-windows-x64-portable.zip`。
2. 运行 `JellyMaku.exe`。
3. 添加 Jellyfin 服务器；在播放器底栏的弹幕设置中配置弹幕源。

### 已知限制

- 首个 Beta，仅提供 Windows x64 便携包。
- 真实 Jellyfin 12.2 E2E、真实弹幕凭证、SyncPlay 双客户端未完成完整验收。
- 手动匹配弹幕、本地 XML 弹幕、安装器/自动更新尚未完成。
- RTX VSR 不支持（media_kit ANGLE/OpenGL 限制）。
- Anime4K 4x 为两次 2x 推理，GPU 开销较高；掉帧时请使用 Balanced/Strong。

### 校验

- 大小：90,684,544 bytes
- SHA256：`296537FAC6D225D466AC950136608F5D239BB4C3480BD7E32667FFAA4250DF9A`

源码与许可证见仓库；JellyMaku 以 GPL-3.0 发布。
