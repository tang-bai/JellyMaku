
# 一起看（Jellyfin SyncPlay）设计

> 状态：Draft。
> 决策：复用 Fladder PR #735，不重写 SyncPlay，不使用 Kazumi 的公共 SyncPlay 服务器。

## 1. 目标与前提

- 多人同步观看同一 Jellyfin 条目：播放/暂停/seek/切集/迟到加入/重连。
- 所有参与者登录同一台 Jellyfin 服务器、各自有账号。
- 不新增端口/中转/服务器；不修改 Jellyfin 服务端。
- 不支持应用内聊天/发送弹幕/访客无账号。

## 2. PR #735 提供的能力

- REST：/SyncPlay/List、New、Join、Leave、Pause、Unpause、Seek、Stop、Buffering、Ready、SetNewQueue、Queue、Ping、SetIgnoreWait 等。
- WebSocket：/socket?ApiKey=...&deviceId=...；处理 SyncPlayCommand、SyncPlayGroupUpdate、KeepAlive/ForceKeepAlive。
- 时间同步：/GetUtcTime 的 T2/T3 估算 offset/ping；命令按 When 调度。
- 命令调度/去重、缓冲等待、断线重连（显式退避 + jitter）、组面板/FAB/badge。
- 文档：docs/syncplay-implementation.md（1523 行）。
- Jellyfin 12 适配：WebSocket token 改用 ApiKey，处理旧 api_key 被禁用。

## 3. 集成点

- lib/providers/websocket/jellyfin_websocket.dart：连接/重连/消息分发。
- lib/providers/syncplay/*：controller/provider/message handler/command handler/time sync/buffering debouncer。
- lib/providers/video_player_provider.dart：播放状态回调、组内控制。
- lib/wrappers/media_control_wrapper.dart：pause/seek/play 转发。
- lib/screens/home_screen.dart + 组 sheet：入口/状态。
- Windows/libMPV：验证 onPlay/onPause/onSeek/onStop/getPositionTicks/isPlaying/isBuffering 回调。

## 4. 行为

- 组内：本地暂停/seek 通过 SyncPlay API 发送；服务器广播给所有成员（含自己）。
- 非组内：行为不变。
- 迟到加入：join 后等待服务器命令/组状态；必要时请求 host 重新 seek。
- 缓冲：发送 Buffering/Ready；组内等待。
- 断线：WebSocket 指数退避 + jitter；重连后重新加入/同步。
- 切集：SetNewQueue/SetPlaylistItem/NextItem；验证 libMPV 队列。
- 本地弹幕跟随 player position；SyncPlay seek/pause 自动驱动弹幕重算。

## 5. UI

- 顶栏/首页入口：创建组、组列表、加入、离开。
- 组面板：组名、成员、状态（Waiting/Playing/Paused）、当前条目。
- 播放器 badge/提示：已加入/等待/缓冲。
- 中文文案；错误提示（组不存在/已满/权限/网络）。
- 不新增聊天。

## 6. 测试矩阵

| 场景 | 预期 |
|---|---|
| 创建/加入 | 双方看到组和成员 |
| 播放/暂停 | 双方状态一致；误差 1–2s |
| seek | 双方位置一致 |
| 切集 | 双方切到同一条目 |
| 迟到加入 | 能加入并同步当前状态 |
| 断网/重连 | 自动重连；恢复组状态 |
| 缓冲 | 组内等待/恢复 |
| 离开/关闭 | 组状态更新；不影响他人 |
| Jellyfin 12.2 | WebSocket ApiKey/GetUtcTime 正常 |

测试方式：

- 首选：JellyMaku + Jellyfin Web（浏览器）双客户端。
- 次选：两个 JellyMaku 实例（增加 JELLYMAKU_DATA_DIR/--dataDir 测试隔离）。
- 记录：日志、截图、位置误差、组状态。

## 7. 已知限制（SyncPlay 2.0）

- 没有“新房间创建”的 WebSocket 通知；需刷新/重新拉列表。
- 创建/加入不返回完整房间信息；需再查询/等待命令。
- 不能重命名等。
- 服务器/网络延迟会影响同步；接受 1–2s 误差。
- 反向代理必须支持 WebSocket。

## 8. 风险

- PR #735 基于旧 develop，合并冲突。
- Windows/libMPV 回调与 PR 的假设不一致。
- Jellyfin 12.2 WebSocket/命令字段变化。
- 双实例测试环境困难。
- 处理：先合并/编译；用 Jellyfin Web 对照；必要时缩小到暂停/seek。

## 9. 验收

- 创建/加入/播放/暂停/seek/切集/迟到/重连通过。
- 无额外端口；文档写明同服务器/账号要求。
- 错误/断线可恢复；不阻塞本地播放。
- 代码/文档署名 PR #735 作者。
