
# 许可、署名与内容合规

> 状态（2026-10-23）：Draft；发布前需许可证复核。本文不是法律意见。`THIRD_PARTY_NOTICES.md` 已补齐（待随本次改动提交），发布检查清单已按当前仓库内容勾选。

## 1. 本项目许可

- 本项目基于 Fladder（GPL-3.0）二次开发，整体按 **GPL-3.0** 分发。
- 必须提供完整对应源码（含修改），保留 LICENSE/NOTICE，不添加额外限制。
- 不分发闭源衍生版本；不把 GPL 代码与不兼容许可静态链接。

## 2. 第三方组件

| 组件 | 许可 | 使用方式 | 义务 |
|---|---|---|---|
| DonutWare/Fladder | GPL-3.0 | 基座/修改 | 源码、许可、署名、修改说明 |
| Fladder PR #735 | GPL-3.0 | SyncPlay 实现 | 保留作者署名/提交说明 |
| Predidit/Kazumi | GPL-3.0 | 参考/移植时间表/图片/评论/弹幕逻辑 | 源码、许可、署名；不复制受限资产 |
| Jellyfin Server/Web | GPL-2.0 | 互操作/测试 | 不作为本项目代码分发；署名 |
| media_kit | MIT | 播放 | 保留许可 |
| libmpv/mpv | GPL-2.0-or-later（打包构建） | 播放内核 | 源码/许可；遵守 GPL |
| Flutter | BSD-3-Clause | UI 框架 | 保留许可 |
| Anime4K | MIT | shader | 保留许可/来源 |
| default-shader-pack | GPL-3.0 | shader 集合 | 源码/许可 |
| FSRCNNX/ArtCNN | 各自许可（以仓库为准） | shader | 保留许可/来源 |
| danmu_api（huangxd-/danmu_api） | 项目许可/部署者条款 | 弹幕聚合 API（仅 HTTP 调用，不打包其代码） | 署名、免费、禁止未授权商用、缓存/限流 |
| Bangumi | 服务条款/用户内容 | 元数据/评论 | User-Agent、缓存/限流、署名、不二次分发/商用 |
| trace.moe | 服务条款 | 图片识别 | 署名、隐私、配额、不批量 |
| Inno Setup | 自由使用 | 安装器 | 保留许可 |

## 3. 不得复制的内容

- Kazumi 的 **图标、Mi Sans 字体、美术/截图**：有单独版权/授权限制，不是 GPL 自由资产；不得复制/再分发。
- Fladder 的图标/品牌：如改用 JellyMaku 品牌，保留 Fladder 署名；不使用其商标误导官方关系。
- 未授权的番剧封面/截图/视频：测试只用合成媒体/公开测试片；截图仅开发记录。

## 4. 署名文本（建议）

- “JellyMaku is based on Fladder (https://github.com/DonutWare/Fladder), licensed under GPL-3.0.”
- “SyncPlay support adapted from Fladder PR #735 by irican-f and contributors.”
- “Danmaku data aggregated by danmu_api (https://github.com/huangxd-/danmu_api), default instance https://danmu.api.tangbai.cc.”
- “Anime metadata/comments from Bangumi (https://bgm.tv/).”
- “Image recognition by trace.moe (https://trace.moe).”
- “Video super-resolution shaders from Anime4K/default-shader-pack; see licenses.”
- “Not affiliated with Jellyfin, Bangumi, danmu_api, or Fladder.”

## 5. danmu_api 合规

- UI/README 标注 danmu_api 项目与默认实例；自建实例由部署者负责其服务条款。
- 弹幕功能免费，不设付费墙/增值收费。
- 不批量抓取、不下载数据库、不绕过配额。
- 自建 TOKEN 只放在 API 地址路径里；不硬编码/不入库/不日志。
- 缓存有限；按需请求；遵守 429/Retry-After。
- 弹幕来源由 danmu_api 服务端聚合；客户端不二次分发源站数据。

## 6. Bangumi 合规

- 设置清晰 User-Agent（项目名/版本/仓库）。
- 保守 1 req/s；缓存；不批量抓取。
- 评论只读展示，不二次分发/商用；标注来源。
- 不绕过登录/权限；不抓取受限内容。
- Next p1 非官方接口；若服务方变更/禁止，应停用并降级。

## 7. trace.moe 合规

- 仅用户主动上传；首次明确同意。
- 不自动上传播放画面/批量截图。
- 缓存结果；遵守 quota/concurrency。
- 不把图片用于训练/再分发。

## 8. 隐私

- 不收集遥测；不内置分析 SDK。
- 日志不记录 token/图片内容/用户密码。
- danmu_api 请求不含 Jellyfin token/服务器地址。
- Bangumi 请求不含 Jellyfin token；仅公开元数据/评论。
- 本地缓存可清除；卸载/清缓存说明。

## 9. 发布检查

- [x] LICENSE、`THIRD_PARTY_NOTICES.md`、源代码链接（https://github.com/tang-bai/JellyMaku）。
- [x] 第三方许可/署名齐全（见 `THIRD_PARTY_NOTICES.md`）。
- [x] 无受限图标/字体/美术（沿用 Fladder 上游资源，未复制 Kazumi 资产）。
- [x] 无密钥/真实用户数据/版权媒体。
- [x] danmu_api/Bangumi/trace.moe 署名与限制说明。
- [x] 非官方声明。
