
# 下载物与测试资产

> 用户要求：测试文件和需要下载的文件都放在本仓库目录。大文件 gitignore，脚本/manifest 入库。
> 状态：Draft。以下为计划路径；尚未下载。

## 1. 目录约定

~~~text
.flutter/                       Flutter 3.35.7 SDK（本地）
.pub-cache/                     Dart/Flutter 依赖缓存
.pip-cache/                     （如用到 Python 工具）
tools/downloads/                原始压缩包缓存
tools/bin/                      7zr 等小工具
tools/inno/                     Inno Setup
third_party/jellyfin/           Jellyfin 12.2 服务端
third_party/dotnet/             .NET 10 runtime
third_party/shader-pack/        default-shader-pack v3.0.0 原始文件
third_party/upstream/           Fladder 固定源码/补丁（可选）
testdata/media/                 测试视频
testdata/fixtures/              DDP/Bangumi/trace.moe JSON
testdata/jellyfin/              本地 Jellyfin 数据/配置
testdata/runtime/               应用测试配置/日志
artifacts/screenshots/          截图
artifacts/logs/                 日志
artifacts/perf/                 性能 JSON
artifacts/build/                便携包/安装器
~~~

## 2. 固定版本与来源

| 资产 | 版本/来源 | 目标 | 说明 |
|---|---|---|---|
| Flutter SDK | 3.35.7 stable（Fladder .fvmrc） | .flutter/ | 约 1.76GB zip；PUB_CACHE 本地 |
| Fladder | develop de7b5a2a23f16f5f3bb164ec0baedf50941e4808 | 源码根 | 固定 commit；PR #735 合并 |
| SyncPlay PR | head 79e249ebf99ecc8dc8f0d5d43c3604ace45fbba9 | 源码 | open；合并/适配 |
| Jellyfin | 12.2 amd64 zip | third_party/jellyfin/ | 需要 .NET 10 |
| .NET runtime | 10.0 win-x64 | third_party/dotnet/ | Jellyfin 运行 |
| shader pack | default-shader-pack v3.0.0 | third_party/shader-pack/、assets/shaders/ | 选中 shader 入源码 |
| Inno Setup | 6.x | tools/inno/ | 安装器 |
| 7zr | 7-zip.org/a/7zr.exe | tools/bin/ | 解压 7z（如需要） |
| 测试视频 | ffmpeg 生成 + 可选 BBB | testdata/media/ | 1080p60/480p/720p/多音轨 |
| Mock DDP | tool/mock_ddp.dart | 源码 | 测试 |
| Mock Bangumi | tool/mock_bangumi.dart | 源码 | 测试 |
| Mock trace.moe | tool/mock_trace.dart | 源码 | 测试 |

## 3. 下载 URL 参考

- Flutter：https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.35.7-stable.zip
- Jellyfin：https://repo.jellyfin.org/files/server/windows/stable/v12.2/amd64/jellyfin_12.2-amd64.zip
- .NET 10：https://aka.ms/dotnet/10.0/dotnet-runtime-win-x64.zip
- shader pack：https://github.com/iwalton3/default-shader-pack/releases/tag/v3.0.0
- Inno Setup：https://jrsoftware.org/isdl.php
- Fladder：https://github.com/DonutWare/Fladder
- PR #735：https://github.com/DonutWare/Fladder/pull/735

URL 可能变化；bootstrap 脚本需校验状态码/SHA256，并写 manifest。

## 4. Flutter/构建

- 设置 PUB_CACHE=<repo>/.pub-cache；flutter config --no-analytics；flutter precache --windows。
- flutter pub get / gen-l10n / analyze / test / build windows --release。
- Flutter 3.35.7 需要 VS 2022 BuildTools + Windows SDK；本机已安装；Developer Mode 已启用。
- 仓库路径含中文/空格：tools/run-dev.ps1 可 subst J: 到仓库根；构建后保持文件在本目录。
- Inno Setup 未安装：下载/静默安装到 tools/inno；失败则交付 portable zip。

## 5. 本地 Jellyfin

- 解压 Jellyfin 12.2；.NET 10 解压到 third_party/dotnet；设置 DOTNET_ROOT/PATH。
- 数据目录：testdata/jellyfin/{data,config,cache,log}；端口 127.0.0.1:8096。
- 首次启动通过 Startup API 创建管理员；再创建测试用户 2（SyncPlay）。
- 添加电影/剧集库，指向 testdata/media；禁用外网元数据/图片抓取，使用本地 NFO/文件名。
- 测试账号/密码写入 testdata/runtime（gitignore），不写入文档。
- ffmpeg/ffprobe 使用系统安装；Jellyfin 扫描/直连测试。

## 6. 测试媒体

- synthetic-1080p60-60s.mp4：testsrc2 + sine；H.264/AAC。
- bbb-480p/720p/1080p-10s.mp4：可选公开测试片。
- multitrack.mkv：2 音轨 + SRT/ASS；验证主字幕/弹幕共存。
- 4K 可选：synthetic-2160p 短片；注意 RTX VSR 不验收。
- 封面/backdrop 小图；NFO 元数据（标题/年份/集号/TMDB 可选）。
- 生成命令写入 tools/bootstrap.ps1 或 tools/make-media.ps1。

## 7. manifest 与校验

- tools/bootstrap.ps1 下载后计算 SHA256，写 third_party/manifest.json：
  - name、version、url、sha256、size、target、extracted。
- tools/verify-assets.ps1 检查存在/哈希/架构/关键文件（pack-next.json、jellyfin.dll、flutter.bat）。
- 失败不静默跳过；记录错误并重试/提示。

## 8. gitignore

- .flutter/、.pub-cache/、.pip-cache/、build/、tools/downloads/、tools/inno/、third_party/、testdata/、artifacts/、*.log、mpv-2.dll 等。
- 仓库只保留脚本、fixtures（小）、shader 源文件（按许可）、文档、截图（小）。
- 不提交 Jellyfin 数据、账号、DDP/Bangumi 密钥、真实媒体。

## 9. 磁盘/网络

- 预计：Flutter 1.8GB + pub 1GB + Jellyfin/.NET 300MB + 测试媒体 200MB + artifacts 300MB。
- 当前 F: 盘剩余约 284GB。
- 下载失败：重试/镜像；记录到 TESTING/ROADMAP；不静默跳过。
