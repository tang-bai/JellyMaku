
# 实施检查清单与证据模板

> 状态：Stage A 核心已构建/验证：Flutter 3.35.7、analyze 0、117 tests（2026-10-20）；Windows release + 启动冒烟、portable zip 于 2026-10-20 重新构建。
> 弹幕在 2026-10-20 增加了 Kazumi 对齐能力：手动匹配三步 UI、来源过滤、合并去重、实时类型/来源开关、描边/颜色开关。
> 真实 Jellyfin/DDP/SyncPlay E2E 仍未完成；弹幕未做真实凭证联调。
> 用途：让后续 agent 按清单推进，避免“文档写了但没做”。

## 1. Stage A 检查清单

### A0 仓库/工具链

- [x] 确认仓库策略（新建 main）。
- [x] 固定 Fladder commit de7b5a2；记录 PR #735 head。
- [x] 以 PR #735 head 导入 Fladder + SyncPlay，并 merge 文档。
- [x] 解决 README/.gitignore 冲突；main 已快进到导入提交。
- [ ] 补最新 develop 合并（仍为 PR #735 head）。
- [x] Flutter 3.35.7 到 .flutter；PUB_CACHE 本地。
- [x] VS BuildTools/Windows SDK/Developer Mode 检查通过。
- [x] flutter analyze/test 通过（0 issue；117 tests）。
- [x] flutter build windows --release 成功；启动冒烟通过。
- [ ] 本地 Jellyfin 12.2 + .NET 10 启动；登录/播放测试片。
- [ ] third_party/manifest.json 生成；verify-assets 通过。

### A1/A2 弹幕

- [x] lib/danmaku 核心；DDP 签名/错误/缓存。
- [x] 自动匹配（标题+集号→search/episodes 第一条候选）。
- [x] 手动匹配：三步对话框（搜索番剧→分集→应用），mapping.json 持久化，可清除。
- [x] 来源过滤：p[3] → BiliBili/Gamer/弹弹play 自有，绘制层实时开关。
- [x] 合并重复弹幕：归一化（全角/空白/符号/重复字符）+5 秒窗口 +「xN」顶部白字。
- [x] 实时过滤：类型/来源开关无需重载；解析类设置 300ms 防抖重载。
- [x] 样式：颜色开关、描边（独立 stroke TextPainter）、显示区域/透明度/字号/速度/偏移。
- [x] 本地 XML/JSON 导入（Bilibili XML / DDP JSON，`source=local`，优先于在线匹配）。
- [x] 发送弹幕入口已移除（DDP 无发送 API；不提供本地回显）。
- [x] Flutter 叠加层；设置弹窗；播放器入口。
- [x] 单测/Mock（DDP HTTP mock、解析/来源/合并、手动匹配请求、DPAPI）。
- [ ] 本地 Jellyfin E2E：主字幕共存/seek/pause/切集。
- [ ] 截图/性能日志（5000 条未压测）。

### A3 超分

- [x] shader 资产/许可；profile 模型（Anime4K Fast/Quality）。
- [x] glsl-shaders 应用；失败仅日志回退。
- [x] 播放器菜单/持久化（独立设置页未做）。
- [ ] 至少 3 个 profile 截图；性能记录。
- [ ] RTX VSR spike 结论（可选，不作 v1）。

### A4 SyncPlay

- [x] PR #735 代码导入；Windows release 构建包含 smtc_windows。
- [ ] 双客户端矩阵；Jellyfin 12.2 WebSocket（单测已通过，真实联调未做）。
- [ ] 中文文案/组面板完善。
- [ ] 日志/截图/误差。

### A5 品牌/打包

- [x] JellyMaku 名称/exe/窗口/版本资源（关于页/安装器未做）。
- [ ] 更新检查不指回 Fladder。
- [ ] i18n ARB en/zh；gen-l10n（弹幕设置仍硬编码英文）。
- [x] portable zip；Anime4K/Fladder 许可保留（Inno 安装器未做）。
- [ ] 干净目录完整功能验证；Stage A 真实 E2E 验收。

## 2. Stage B 检查清单

### B0 数据层

- [ ] BangumiClient（v0/Next p1）；可配置 Base/代理。
- [ ] User-Agent/限流/缓存/错误。
- [ ] MappingStore；MOCK。
- [ ] worker.js 模板；连接测试。
- [ ] 单测。

### B1 时间表

- [ ] 当前季/非当前季；分组/排序/缓存。
- [ ] SchedulePage；在库/已看/弃番；跳转。
- [ ] 映射/手动绑定。
- [ ] Mock/无网/截图。

### B2 图片识别

- [ ] 以图搜番入口/预览/同意。
- [ ] trace.moe 客户端/缓存/配额。
- [ ] Jellyfin 候选/跳转；Bangumi 条件映射。
- [ ] Mock/错误/隐私/截图。

### B3 评论

- [ ] 主题/分集评论；分页/缓存。
- [ ] 映射/SP；BBCode 子集；只读。
- [ ] 详情 Tab/播放器 Sheet。
- [ ] 无网降级；Mock/代理验收。

## 3. 证据模板

每个功能完成后追加：

~~~text
### <功能>
- 日期：
- commit：
- 命令：
- 结果：通过/失败/降级
- 截图：artifacts/screenshots/...
- 日志：artifacts/logs/...
- 性能：artifacts/perf/...
- 已知问题：
- 未验证项：
~~~

### 弹幕 v2（手动匹配/来源/合并/本地导入）

- 日期：2026-10-20
- commit：feat(danmaku): add source filters, manual match and duplicate merge；feat(danmaku): add local import and local echo（2026-10-20）
- 命令：
  - `.\.flutter\bin\flutter.bat test --no-pub` → 117 tests passed
  - `.\.flutter\bin\dart.bat analyze lib test` → No issues found
- 结果：通过（单元/静态）；未做真实 DDP/Jellyfin E2E、未重新构建 Windows 包。
- 截图：artifacts/screenshots/danmaku-*（未生成）
- 性能：5000 条未压测
- 已知问题：p[3] 来源语义待真实凭证确认；自动匹配仍取第一条候选；本地 XML 用正则解析。
- 未验证项：真实凭证搜索/拉取、手动匹配落盘后的播放、来源开关在真实混合弹幕下的表现、本地文件在真实播放器中的时间轴。

### Windows release 重建（2026-10-20）

- 命令（ASCII 路径 `L:\JellyMaku`）：
  - `.flutter\bin\flutter.bat build windows --release --no-pub` → √ Built `build\windows\x64\runner\Release\JellyMaku.exe`（111.5s；移除发送入口、折叠 AppId 后重建）
  - `tools\pack.ps1 -Version 0.1.0` → `artifacts\JellyMaku-0.1.0-windows-x64-portable.zip`（90,722,301 bytes，SHA256 `7DA17389816C212A164E7F2EF400CDA8054FD568B84BED0B270A4B663B907E55`）
  - 启动冒烟：portable exe 启动 8 秒未退出，随后手动结束。
- 证据：`data\app.so` 时间 2026-10-20 20:16；zip 20:17。
- 注意：`JellyMaku.exe` 本体未变（runner 未改），新 Dart 代码在 `data\app.so`；只替换 exe 不会更新界面。

## 4. 禁止事项

- 不把“文档计划”写成“已实现”。
- 不把 lint/analyze 通过当成功能通过。
- 不提交密钥/真实账号/版权媒体。
- 不使用 Kazumi 受限图标/字体/美术。
- 不做未授权的 Bangumi/DDP 批量抓取。
- 不在无代理情况下宣称 Bangumi 评论可用。

## 5. 当前进度

- 文档：完成；本次更新 DANMAKU/IMPLEMENTATION/ROADMAP/AGENTS。
- 代码：Fladder + PR #735 head 已导入；弹幕（自动+手动匹配/来源/合并/本地导入/叠加层）、超分（Anime4K）已接入；Bangumi Stage B 未开始。
- 构建：Windows release 重新构建成功、启动冒烟通过（2026-10-20）；portable zip 已重打。
- 测试：117 tests passed（2026-10-20）；`dart analyze lib test` → No issues found。
- 发布：portable zip 已出；安装器/中文 ARB 未做。
- 未验证：真实 DDP 凭证、真实 Jellyfin 播放、SyncPlay 双端、超分画质/性能、弹幕 p[3] 来源语义。
