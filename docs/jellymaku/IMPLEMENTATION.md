
# 实施检查清单与证据模板

> 状态：未开始。所有 checkbox 默认未完成；完成后附命令/截图/日志。
> 用途：让后续 agent 按清单推进，避免“文档写了但没做”。

## 1. Stage A 检查清单

### A0 仓库/工具链

- [ ] 确认仓库策略（git init/恢复/分支）。
- [ ] 固定 Fladder commit de7b5a2；记录 PR #735 head。
- [ ] 创建 jellymaku 分支；导入 Fladder；合并 PR #735。
- [ ] 解决冲突；flutter pub get/analyze/test 通过。
- [ ] Flutter 3.35.7 到 .flutter；PUB_CACHE 本地。
- [ ] VS BuildTools/Windows SDK/Developer Mode 检查通过。
- [ ] flutter build windows --release 成功。
- [ ] 本地 Jellyfin 12.2 + .NET 10 启动；登录/播放测试片。
- [ ] third_party/manifest.json 生成；verify-assets 通过。

### A1/A2 弹幕

- [ ] lib/danmaku 核心；DDP 签名/错误/缓存。
- [ ] 匹配/手动映射/本地 XML。
- [ ] Flutter 叠加层；设置页；播放器入口。
- [ ] 单测/Widget/Mock；5000 条性能。
- [ ] 本地 Jellyfin E2E：主字幕共存/seek/pause/切集。
- [ ] 截图/日志。

### A3 超分

- [ ] shader 资产/许可；profile 模型。
- [ ] glsl-shaders 应用；失败回退。
- [ ] 设置页/持久化。
- [ ] 至少 3 个 profile 截图；性能记录。
- [ ] RTX VSR spike 结论（可选）。

### A4 SyncPlay

- [ ] PR #735 合并/适配；Windows/libMPV 回调。
- [ ] 双客户端矩阵；Jellyfin 12.2 WebSocket。
- [ ] 中文文案/组面板。
- [ ] 日志/截图/误差。

### A5 品牌/打包

- [ ] JellyMaku 名称/exe/窗口/安装器/关于页。
- [ ] 更新检查不指回 Fladder。
- [ ] i18n ARB en/zh；gen-l10n。
- [ ] Inno Setup/portable zip；许可/第三方声明。
- [ ] 干净目录验证；Stage A 验收。

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

- 文档：本次落盘。
- 代码：未导入/未实现。
- 构建：未执行。
- 测试：未执行。
- 发布：未执行。
