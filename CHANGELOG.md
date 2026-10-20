# Changelog

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
- 弹弹play 弹幕：自动匹配、滚动/顶部/底部、简繁转换、字体/透明度/速度/显示区域/时间偏移。
- 弹幕设置界面完整简体中文化。
- Anime4K 超分档位：Fast 2x、Balanced 2x、Strong 2x、4x；中文菜单说明。
- 播放器体验修复：点击画面暂停、暂停时弹幕冻结、恢复播放不拉扯、弹幕匀速与轨道/文本布局缓存。

### 安装

1. 解压 `JellyMaku-v0.1.0-beta.1-windows-x64-portable.zip`。
2. 运行 `JellyMaku.exe`。
3. 添加 Jellyfin 服务器；在播放器底栏的弹幕设置中填写弹弹play AppId/AppSecret。

### 已知限制

- 首个 Beta，仅提供 Windows x64 便携包。
- 真实 Jellyfin 12.2 E2E、真实弹弹play凭证、SyncPlay 双客户端未完成完整验收。
- 手动匹配弹幕、本地 XML 弹幕、安装器/自动更新尚未完成。
- RTX VSR 不支持（media_kit ANGLE/OpenGL 限制）。
- Anime4K 4x 为两次 2x 推理，GPU 开销较高；掉帧时请使用 Balanced/Strong。

### 校验

- 大小：90,684,544 bytes
- SHA256：`296537FAC6D225D466AC950136608F5D239BB4C3480BD7E32667FFAA4250DF9A`

源码与许可证见仓库；JellyMaku 以 GPL-3.0 发布。
