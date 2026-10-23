
# Stage A 构建与验证报告（历史）

> 状态：**HISTORICAL / 不代表当前状态**。本报告记录 2026-10-19/20 的旧弹幕实现与当时构建，部分内容已删除或已被后续改动取代。
> 当前状态请看 [ROADMAP.md](ROADMAP.md)、[IMPLEMENTATION.md](IMPLEMENTATION.md)；Stage A 最终报告仍待重写。
> 日期：2026-10-19（历史）
> 当时结论：核心可构建/启动；真实 Jellyfin、在线弹幕、SyncPlay 双端未完成（这些项目后来已有部分更新）。

## 1. 环境

| 项目 | 值 |
|---|---|
| Flutter | 3.35.7 stable（Dart 3.9.2） |
| 构建路径 | `L:\JellyMaku`（ASCII subst，避免中文路径/Cargokit 编码问题） |
| MSVC | VS 2022 BuildTools 17.14，Windows SDK 10.0.26100 |
| 依赖 | media_kit/libmpv、FVP/MDK、ANGLE、sqlite3、NuGet 本地源 |
| 关键编译参数 | `CL=/utf-8`（规避 C4819 代码页 936 警告被当作错误） |

## 2. 构建产物

- Release：`build/windows/x64/runner/Release/JellyMaku.exe`
- 可执行文件版本资源：ProductName/FileDescription = JellyMaku；OriginalFilename = JellyMaku.exe。
- 冒烟：进程启动成功，窗口标题 `JellyMaku`，12 秒后正常关闭（`CloseMainWindow`）。
- 便携包：`artifacts/JellyMaku-0.1.0-windows-x64-portable.zip`
  - 大小：90,713,113 bytes（v0.1.0-beta.3 弹幕迁移 danmu_api）
  - SHA256：`A1B42E23C12254EA47C003088FB40D49B258D716B9F0DBB39E44D7671DC3FE2A`
  - 结构：`JellyMaku/JellyMaku.exe` + DLL + `data/` + README/LICENSE/AGENTS。

## 3. 验证结果

| 项目 | 结果 | 证据 |
|---|---|---|
| `dart analyze lib test` | 通过，0 issue | `artifacts/logs/analyze-clean.txt` |
| `flutter test --no-pub` | 137 tests（1 个手动联网探针跳过） | 本次发布前运行输出 |
| `flutter build windows --release --no-pub` | 成功 | `artifacts/logs` / 上述 exe |
| 应用启动冒烟 | 窗口标题 JellyMaku；正常关闭 | 本报告第 2 节 |
| 旧密钥存储往返 | 通过（Windows，历史） | 旧测试已删除 |
| 旧弹幕客户端签名/搜索/评论 | 通过（本地 HTTP mock，历史） | 旧测试已删除 |
| 弹幕解析/过滤/偏移 | 通过 | `test/danmaku/danmaku_test.dart` |
| SyncPlay 协议/队列/生命周期 | 通过（现有 PR #735 单测） | `test/providers/syncplay/*` |

## 4. 已接入功能

### 在线弹幕（旧实现）

- 旧弹幕客户端：应用身份头签名，搜索集数、拉取评论。
- `lib/danmaku/matcher.dart`：按剧名 + 集数自动匹配；手动映射数据层已预留（UI 未完成）。
- `lib/danmaku/comment_parser.dart`：模式/颜色/偏移/屏蔽词/屏蔽用户/去重/采样。
- `lib/danmaku/cache.dart`：评论与映射缓存（7 天默认）。
- `lib/screens/video_player/components/danmaku_overlay.dart`：Flutter `CustomPainter` 叠加层，滚动/顶部/底部，跟随播放/暂停/倍速/seek。
- 播放器控制栏入口 + 设置弹窗：开关、字号、透明度、速度、显示区域、偏移、简繁转换、显示模式。
- 旧版本使用系统密钥存储保存凭据；现已移除。
- 未完成：手动匹配 UI、本地 XML/JSON 导入、弹幕发送/点赞。

### GLSL 超分

- 内置 Anime4K `Clamp_Highlights`、`Restore_CNN_M`、`Upscale_CNN_x2_M`（MIT，见 `assets/shaders/ANIME4K_LICENSE.txt`）。
- `VideoEnhancementProfile.off/anime4kFast/anime4kQuality`，通过 libmpv `glsl-shaders` 应用。
- 播放器控制栏菜单切换；设置持久化；shader 加载失败仅记录日志，不阻断播放。
- 未完成：真实视频画质/性能对比、FSRCNNX/ArtCNN、RTX VSR。

### SyncPlay

- PR #735 的 WebSocket/REST、时间同步、命令调度、组 UI、队列/生命周期测试已导入。
- 现有 94 项 SyncPlay/WebSocket 相关测试通过；Windows 构建包含 `smtc_windows.dll`。
- 未完成：Jellyfin 12.2 上双客户端真实联调、中文文案完善、误差/截图记录。

### 品牌/打包

- Windows 可执行名、窗口标题、版本资源改为 JellyMaku。
- 当时仅生成 portable zip；安装器后来已在 beta.4 补齐。
- 当时更新检查仍可能指向 Fladder 上游；后来已在 beta.4 改为 JellyMaku。

## 5. 重要限制（历史，部分已被后续更新）

1. **当时未合并最新 Fladder develop**：基线是 PR #735 head（`79e249e`）；已于 2026-10-21 合并 `de7b5a2a`。
2. **当时未做真实 Jellyfin E2E**：后来已在 NAS Jellyfin 12.2 完成登录/播放/暂停/seek 自动验证及字幕/切集/叠加层手动验证。
3. **当时未做真实旧弹幕联调**：旧版本需要应用凭证；旧行为仅由本地 mock 测试覆盖，后来旧实现已被 danmu_api 取代。
4. **当时未做 SyncPlay 双端联调**：只有单测；Jellyfin 12.2 WebSocket/时钟误差仍未真实验证。
5. **当时超分未做画质/性能验收**：后来已补四档截图，FPS/掉帧仍未验收。
6. **当时弹幕设置文案未走 ARB**：后来已迁移到 ARB。
7. **当时 main 已推送 origin（e2b3ca7）**；后来 origin/main 已更新到 `21891411`，本地另有未推送提交。

## 6. 复现提示

- 中文路径会导致 Cargokit 生成的 pubspec 编码错误；构建时使用 ASCII 路径（如 `subst L: <repo-parent>` 后从 `L:\JellyMaku` 构建）。
- media_kit/ANGLE/FVP/sqlite3 默认从 GitHub/SourceForge/sqlite.org 下载；本环境已预置到 `third_party/` 并修补本地 pub cache，否则需代理。
- NuGet 使用本地 feed（`third_party/nuget`）与本地 `nuget.exe`；否则 `local_auth_windows`/`permission_handler_windows` 会卡在 nuget.org。
- 详细构建步骤见 `docs/jellymaku/BUILD_WINDOWS.md`。

## 7. 播放进度/SMTC 修复（2026-10-19 22:50）

现象：视频画面正常，但进度条停在 00:00、总时长 -00:00，并显示持续加载。

根因（来自 `%LOCALAPPDATA%\JellyMaku contributors\JellyMaku\crash_logs.json`）：

1. `MediaControlsWrapper.setup` 先调用 `_initPlayer()`，再调用 `_subscribePlayerState()`。
2. `_initPlayer()` 构造 `SMTCWindows` 时，SMTC 的 Rust 桥未初始化（启动时 `SMTCWindows.initialize()` 在 post-frame callback 中，存在竞态）。
3. 异常导致 `_subscribePlayerState()` 没有执行，`mediaPlaybackProvider` 永远收不到 position/duration/buffering 更新；画面仍由播放器输出。
4. 额外发现 `smtc_windows 1.1.0` 的 codegen 是 `flutter_rust_bridge 2.11.1`，而依赖解析到了 2.13.0，版本检查必然失败。

修复：

- 在 `bootstrapApplication` 中、`runApp` 之前初始化 SMTC，并捕获失败。
- `MediaControlsWrapper.setup` 改为先 `_subscribePlayerState()`，再 `_initPlayer()`。
- `_subscribePlayer` 对 SMTC 构造/监听做 try/catch；SMTC 不可用时只记录日志，不影响播放状态。
- `pubspec.yaml` pin `flutter_rust_bridge: 2.11.1`。

验证：`dart analyze lib` 0 issue；100 tests passed；Windows release 构建成功；启动后 crash_logs 无新增 SMTC 错误。真实视频的进度条仍需用户在已登录的 Jellyfin 环境复测。


## 8. 弹幕行列跳动修复（2026-10-19 23:00）

现象：视频播放时，滚动/顶部/底部弹幕所在行会跳动，尤其是在旧弹幕离开屏幕、新弹幕进入时。

根因：`DanmakuPainter.paint` 每帧只对“当前可见”的评论重新分配轨道：

- `scrollEnds` 每帧从 -1 开始，只记录当前活动评论占用的轨道；
- `topRow`/`bottomRow` 每帧从 0 递增。

因此一条评论的 lane 会随其他评论进出活动窗口而变化，表现为整行跳变。

修复：

- 在绘制前按完整时间轴为每条评论预分配轨道/行；
- 滚动、顶部、底部分别维护占用结束时间；
- 优先选择已空闲的轨道，轨道不足时选择最早结束的轨道；
- 绘制阶段只读取预分配的 `scrollLanes[i]`、`topRows[i]`、`bottomRows[i]`。

验证：`dart analyze lib` 0 issue；100 tests passed；Windows release 构建成功。真实视频弹幕仍需用户复测。
