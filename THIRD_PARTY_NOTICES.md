# Third-Party Notices / 第三方声明

JellyMaku is a Windows Jellyfin desktop client based on Fladder. This project is
licensed under the GNU General Public License v3.0 (see `LICENSE`). The
following components and services are used or referenced.

JellyMaku 是基于 Fladder 的 Windows Jellyfin 桌面客户端，整体以 GPL-3.0 分发
（见 `LICENSE`）。以下组件/服务被使用或引用。

## Source and libraries

| Component | License | Usage |
|---|---|---|
| [DonutWare/Fladder](https://github.com/DonutWare/Fladder) | GPL-3.0 | Base application and UI; modified for JellyMaku |
| Fladder SyncPlay PR #735 | GPL-3.0 | SyncPlay implementation, adapted with attribution |
| [Flutter](https://flutter.dev) | BSD-3-Clause | UI framework |
| [media_kit](https://github.com/media-kit/media-kit) | MIT | Playback wrapper |
| [mpv / libmpv](https://mpv.io) | GPL-2.0-or-later (packaged build) | Playback engine |
| [Anime4K](https://github.com/bloc97/Anime4K) | MIT | GLSL super-resolution shaders; see `assets/shaders/ANIME4K_LICENSE.txt` |
| [ANGLE](https://github.com/alexmercerind/flutter-windows-ANGLE-OpenGL-ES) | BSD-3-Clause | OpenGL ES on Windows |
| [MDK SDK](https://sourceforge.net/projects/mdk-sdk/) | LGPL-2.1-or-later (see upstream) | Optional playback backend |
| [SQLite](https://sqlite.org) | Public domain | Local database |
| Microsoft.Windows.CppWinRT / WIL | MIT | Windows native dependencies |
| [Inno Setup](https://jrsoftware.org/isinfo.php) | Inno Setup license | Installer build tool (not bundled as source) |

## Services (called at runtime, not bundled)

| Service | Notes |
|---|---|
| [danmu_api](https://github.com/huangxd-/danmu_api) | Danmaku aggregation; default public instance `https://danmu.api.tangbai.cc`. Danmaku is free; unauthorized commercial use is prohibited. |
| [Jellyfin](https://jellyfin.org) | Media server; Jellyfin is not affiliated with this project. |
| [Bangumi](https://bgm.tv) | Metadata/comments (Stage B; not yet enabled). |
| [trace.moe](https://trace.moe) | Image search (Stage B; not yet enabled). |

## Attribution

- “JellyMaku is based on Fladder (https://github.com/DonutWare/Fladder), licensed under GPL-3.0.”
- “SyncPlay support adapted from Fladder PR #735 by irican-f and contributors.”
- “Danmaku data aggregated by danmu_api (https://github.com/huangxd-/danmu_api).”
- “Video super-resolution shaders from Anime4K; see included license.”

JellyMaku is not affiliated with Jellyfin, Bangumi, danmu_api, Fladder, or their
respective maintainers. All trademarks belong to their owners.
