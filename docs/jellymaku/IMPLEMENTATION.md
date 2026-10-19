
# 实施检查清单与证据模板

> 状态：Stage A 核心已构建/验证（2026-10-19）：Flutter 3.35.7、analyze 0、100 tests、Windows release + 启动冒烟、portable zip。真实 Jellyfin/DDP/SyncPlay E2E 仍未完成。
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
- [x] flutter analyze/test 通过（0 issue；100 tests）。
- [x] flutter build windows --release 成功；启动冒烟通过。
- [ ] 本地 Jellyfin 12.2 + .NET 10 启动；登录/播放测试片。
- [ ] third_party/manifest.json 生成；verify-assets 通过。

### A1/A2 弹幕

- [x] lib/danmaku 核心；DDP 签名/错误/缓存。
- [ ] 匹配/手动映射/本地 XML（自动匹配/映射数据层已做；手动 UI/local XML 未做）。
- [x] Flutter 叠加层；设置弹窗；播放器入口。
- [x] 单测/Mock（DDP HTTP mock、解析、DPAPI）。
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

## 4. 禁止事项

- 不把“文档计划”写成“已实现”。
- 不把 lint/analyze 通过当成功能通过。
- 不提交密钥/真实账号/版权媒体。
- 不使用 Kazumi 受限图标/字体/美术。
- 不做未授权的 Bangumi/DDP 批量抓取。
- 不在无代理情况下宣称 Bangumi 评论可用。

## 5. 当前进度

- 文档：完成（0c46705）。
- 代码：Fladder + PR #735 head 已导入（e7ce1e97）；弹幕/超分/Bangumi 未实现。
- 构建：未执行（Flutter 未安装）。
- 测试：未执行。
- 发布：未执行。
