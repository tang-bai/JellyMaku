
# Stage A 构建与验证报告

> 日期：2026-10-19
> 结论：Stage A 核心已可构建、可启动；弹幕/超分/SyncPlay 代码已接入。真实 Jellyfin、DDP、SyncPlay 双端联调尚未完成。

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
  - 大小：90,686,578 bytes（点击暂停修复后重打包）
  - SHA256：`D9F91881373E23505001A9E2FC2DF1A53DE90836AD4FE7A6EBD7CDE505CDD395`
  - 结构：`JellyMaku/JellyMaku.exe` + DLL + `data/` + README/LICENSE/AGENTS。

## 3. 验证结果

| 项目 | 结果 | 证据 |
|---|---|---|
| `dart analyze lib test` | 通过，0 issue | `artifacts/logs/analyze-clean.txt` |
| `flutter test --no-pub` | 103 passed | `artifacts/logs/test-anime4k-profiles.txt` |
| `flutter build windows --release --no-pub` | 成功 | `artifacts/logs` / 上述 exe |
| 应用启动冒烟 | 窗口标题 JellyMaku；正常关闭 | 本报告第 2 节 |
| DPAPI 密钥往返 | 通过（Windows） | `test/danmaku/secret_store_test.dart` |
| DDP 客户端签名/搜索/评论 | 通过（本地 HTTP mock） | `test/danmaku/ddp_client_test.dart` |
| 弹幕解析/过滤/偏移 | 通过 | `test/danmaku/danmaku_test.dart` |
| SyncPlay 协议/队列/生命周期 | 通过（现有 PR #735 单测） | `test/providers/syncplay/*` |

## 4. 已接入功能

### 弹弹play 弹幕

- `lib/danmaku/ddp_client.dart`：`X-AppId/X-Timestamp/X-Signature` 签名，搜索集数、拉取评论。
- `lib/danmaku/matcher.dart`：按剧名 + 集数自动匹配；手动映射数据层已预留（UI 未完成）。
- `lib/danmaku/comment_parser.dart`：模式/颜色/偏移/屏蔽词/屏蔽用户/去重/采样。
- `lib/danmaku/cache.dart`：评论与映射缓存（7 天默认）。
- `lib/screens/video_player/components/danmaku_overlay.dart`：Flutter `CustomPainter` 叠加层，滚动/顶部/底部，跟随播放/暂停/倍速/seek。
- 播放器控制栏入口 + 设置弹窗：开关、AppId/AppSecret、字号、透明度、速度、显示区域、偏移、简繁转换、显示模式。
- AppSecret 在 Windows 通过 DPAPI（CryptProtectData）保存；非 Windows 回退 SharedPreferences（Web stub）。
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
- portable zip 已生成；安装器（Inno Setup）未做。
- 更新检查仍可能指向 Fladder 上游；Stage A 未改。

## 5. 重要限制

1. **未合并最新 Fladder develop**：基线仍是 PR #735 head（`79e249e`）。
2. **未做真实 Jellyfin E2E**：未下载/启动 Jellyfin 12.2；登录、播放、字幕、seek、切集未在真实服务器验证。
3. **未做真实 DDP 联调**：没有 AppId/AppSecret；DDP 行为仅由本地 mock 测试覆盖。
4. **未做 SyncPlay 双端联调**：只有单测；Jellyfin 12.2 WebSocket/时钟误差未验证。
5. **超分未做画质/性能验收**：未截图、未测掉帧；ANGLE/OpenGL 下部分 shader 可能被 libmpv 拒绝。
6. **弹幕设置文案未走 ARB**：当前为英文硬编码；中文 i18n 待补。
7. **已推送 GitHub**：main 已推送 origin（e2b3ca7）；后续变更需重新推送。

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
