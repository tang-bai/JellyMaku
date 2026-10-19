
# Windows 构建说明（Stage A）

> 本文件记录本次实际通过的构建路径，不等同于“任意干净机器一键成功”。当前环境的依赖已预置在 `third_party/` / `.pub-cache/`，大文件不入库。

## 1. 前置

- Windows 10/11 x64，VS 2022 BuildTools（C++/CMake/Windows SDK），Developer Mode 开启。
- Flutter 3.35.7 解压到 `.flutter/`；Dart 3.9.2 随 SDK。
- Git、`tar.exe`（Windows 自带 bsdtar）、7z 解压能力。
- 建议把仓库映射到 ASCII 路径再构建；中文路径会让 Cargokit 生成的 `pubspec.yaml` 使用系统代码页，Dart 无法解析。

~~~powershell
subst L: "F:\DeepSeek Harness项目"   # 仓库父目录
cd L:\JellyMaku
~~~

## 2. 预置原生依赖

| 依赖 | 文件/位置 | 说明 |
|---|---|---|
| libmpv | `third_party/mpv/mpv-dev-x86_64-20260531-git-13a3e3a.7z` | MD5 69141eef346f9c82640274e6a0f36e7a；复制到 `build/windows/x64/` |
| ANGLE | `third_party/angle/ANGLE.7z` | MD5 e866f13e8d552348058afaafe869b1ed；解压到 `build/windows/x64/ANGLE/` |
| MDK SDK | `third_party/mdk/mdk-sdk-windows-x64.7z` | 解压到 FVP 包目录的 `mdk-sdk/` |
| SQLite | `third_party/sqlite/sqlite-autoconf-3520000.tar.gz` | 需把 `sqlite3_flutter_libs` 的 Windows CMake `URL` 改为本地路径 |
| NuGet | `tools/nuget/nuget.exe`、`third_party/nuget/*.nupkg` | 本地 feed；否则 `local_auth_windows` 会卡 nuget.org |

NuGet 需要：
`Microsoft.Windows.ImplementationLibrary 1.0.220201.1`、
`Microsoft.Windows.CppWinRT 2.0.220418.1`、
`Microsoft.Windows.CppWinRT 2.0.210806.1`。

`build/windows/x64/NuGet.Config`：

~~~xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="local" value="K:\third_party\nuget" />
  </packageSources>
</configuration>
~~~

## 3. 构建

~~~powershell
$env:PUB_CACHE = "K:\.pub-cache"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PATH = "K:\tools\nuget;" + $env:PATH
$env:CL = "/utf-8"
$env:FLUTTER_SUPPRESS_ANALYTICS = "true"

& "K:\.flutter\bin\flutter.bat" pub get
& "K:\.flutter\bin\flutter.bat" build windows --release --no-pub
~~~

- `CL=/utf-8` 必须：`connectivity_plus` 的源文件含非 ASCII 字符，MSVC 默认代码页 936 会报 C4819，而项目把警告当错误。
- Cargokit 会为 `smtc_windows` 构建 Rust；首次会自动安装 Rust 工具链。
- 若插件注册器过期（例如 `screen_brightness_windows` 从 2.1.0 升到 2.1.2），删除 `windows/flutter/generated_plugin_registrant.cc/.h`，重新 `flutter pub get` 生成 C-API 版本。

## 4. 产物与打包

~~~powershell
& .\tools\pack.ps1 -Version 0.1.0
~~~

输出：`artifacts/JellyMaku-0.1.0-windows-x64-portable.zip`。

## 5. 常见失败

| 现象 | 处理 |
|---|---|
| libmpv/ANGLE 0 字节、MD5 失败 | 手动下载后放到 `build/windows/x64/`，保留 `third_party` 副本 |
| `package:build_tool` 无法解析 | 在 cargokit 的 `cargokit_build/tool` 下用 `PUB_HOSTED_URL` 镜像执行 `dart pub get` |
| CMake 卡 nuget/sqlite/sourceforge | 使用本地 NuGet feed、本地 SQLite tar、预置 MDK |
| 项目路径正好是盘符根（如 `K:`） | Flutter 生成 `PROJECT_DIR=K:;...` 导致 cwd 错误；改从 `L:\JellyMaku` 构建 |
| `flutter_assemble` exit 255 | 先看 `flutter build -v` 日志；本次是盘符根路径问题 |
| C4819 被当作错误 | 设置 `CL=/utf-8` |
| screen brightness 注册失败 | 删除并重新生成 plugin registrant |
| SMTC codegen/runtime 版本不匹配 | 保持 `flutter_rust_bridge: 2.11.1`（smtc_windows 1.1.0 的生成版本） |
| 视频播放但进度条 00:00/一直加载 | 检查 SMTC 初始化竞态；SMTC 异常不得跳过 player state 订阅 |
