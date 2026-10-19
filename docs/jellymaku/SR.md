
# 视频超分设计（GLSL shader）

> 状态：Draft。
> 目标：在 Fladder/media_kit 的 libmpv 上提供可切换的 Anime4K/FSRCNNX/ArtCNN 超分；RTX VSR 不作为 v1 验收。

## 1. 背景与限制

- media_kit 的 Windows 视频输出使用 ANGLE OpenGL 渲染上下文（media_kit_video/windows/video_output.cc），Flutter 通过 DXGI shared handle 显示。
- NativePlayer 提供 setProperty/command/observeProperty，可设置 glsl-shaders、vf、hwdec。
- Anime4K/FSRCNNX/ArtCNN 是 GLSL shader，可通过 glsl-shaders 加载，适合当前 OpenGL render API。
- RTX VSR 的 d3d11vpp 需要 D3D11 上下文/硬件帧；当前 ANGLE/OpenGL 路径不可靠，可能黑屏或无效。v1 不承诺。

## 2. shader 资产

- 来源：iwalton3/default-shader-pack v3.0.0（GPL-3.0）与 Anime4K（MIT）/FSRCNNX/ArtCNN 各自许可。
- 只取需要的文件：
  - Anime4K high：Clamp_Highlights、Restore/Upscale CNN、AutoDownscalePre 等。
  - Anime4K fast：fast 版本。
  - FSRCNNX：x2 shader。
  - ArtCNN：基础/Sharp/High。
- 放 assets/shaders/<profile>/；保留 LICENSE/来源；加入 THIRD_PARTY_NOTICES。

## 3. profile

| profile | 用途 | 说明 |
|---|---|---|
| off | 关闭 | 清空 glsl-shaders |
| anime4kHighA/B/C | 动画高质量 | A 模糊/压缩，B 模糊/振铃，C 锐利 |
| anime4kFastA | 动画高性能 | 低功耗 |
| artcnn | 通用 | 轻量 CNN |
| fsrcnnx | 真人/通用 | 细节增强 |
| rtxVsrExperimental | 实验 | 仅 spike；不作为验收 |

默认：off 或 anime4kHighA（产品决策待定；建议默认 off，设置页推荐）。切换即时生效；失败回退 off。

## 4. 应用方式

1. 首次使用：把 asset shader 复制到应用缓存目录（libmpv 需要真实文件路径）。
2. 清空：command(['change-list','glsl-shaders','clr',''])。
3. 追加：对每个 shader command(['change-list','glsl-shaders','append',path])；避免 Windows 路径分隔符问题。
4. 关闭：清空 + 重置相关 vf/hwdec（如有）。
5. 记录当前 profile/实际 shader 列表；observeProperty 诊断。
6. 切换失败：回退上一个/off，提示一次。

## 5. RTX VSR spike（可选）

- 尝试 setProperty hwdec=d3d11va、vf=d3d11vpp=scale=2:scaling-mode=nvidia。
- 检查 vf/hwdec-current/画面；黑屏/无效则移除/隐藏。
- 记录 artifacts/perf/rtx-vsr-result.json。
- 若未来必须支持：fork media_kit Windows 视频输出为 D3D11，或外部 mpv 模式；+3–5 天，高风险。

## 6. UI/设置

- 播放器设置“Video Enhancement”：profile 列表、说明、当前状态、关闭。
- 播放器控制条可放快捷入口（可选）。
- 显示“需要支持 GLSL 的 GPU/驱动”；不适用时提示。
- 设置持久化到 VideoPlayerSettingsModel（freezed/g）。

## 7. 性能/画质

- 1080p60 合成片：off/Anime4K/FSRCNNX 对比；截图 artifacts/screenshots/sr-*.png。
- 记录 glsl-shaders、hwdec-current、frame-drop-count（通过 observeProperty/调试日志）。
- 目标：热身后掉帧 <1%（Anime4K high）；若不达标，降低 profile/记录。
- 4K 源：避免叠加过多 shader；必要时自动降级。
- 显存/GPU 占用记录（如 nvidia-smi）。

## 8. 测试/验收

- 单测：profile→shader 列表映射；资产路径复制；命令序列（fake player）。
- 手动/截图：至少 3 个 profile 可切换、关闭恢复、持久化。
- 失败：缺失资产/权限/不支持 → 回退 off，不阻塞播放。
- RTX VSR：明确记录“可用/不可用/原因”，不写成已支持。

## 9. 许可

- default-shader-pack GPL-3.0；Anime4K MIT；FSRCNNX/ArtCNN 各自许可；保留 LICENSE/来源。
- 不把 shader 资产用于商业闭源分发；整体 GPL-3.0 兼容。
