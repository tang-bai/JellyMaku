
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

## 1.1 非交互/空环境下的必备变量（2026-10-21 实测）

在无用户桌面环境（或从 CI/agent 启动、`process.env` 为空）时，Flutter 构建会误报“找不到 Visual Studio”或 MSBuild `FileTracker` 抛 `MSB4018`。必须显式提供：

```powershell
$env:ProgramData = "C:\ProgramData"                 # vswhere 依赖；缺失会得到空 VS 列表
$env:ALLUSERSPROFILE = "C:\ProgramData"
$env:ProgramFiles = "C:\Program Files"
${env:ProgramFiles(x86)} = "C:\Program Files (x86)"
$env:CommonProgramFiles = "C:\Program Files\Common Files"
${env:CommonProgramFiles(x86)} = "C:\Program Files (x86)\Common Files"
$env:CommonProgramW6432 = "C:\Program Files\Common Files"
$env:USERPROFILE = "C:\Users\<user>"
$env:APPDATA = "$env:USERPROFILE\AppData\Roaming"
$env:LOCALAPPDATA = "$env:USERPROFILE\AppData\Local"
$env:TEMP = "$env:LOCALAPPDATA\Temp"
$env:TMP = "$env:TEMP"
$env:SystemDrive = "C:"
$env:Path = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0;E:\Program Files\Git\cmd;" + $env:Path
```

- GitHub 走 git 协议可能被 reset：给 pub / git 用 `http.version=HTTP/1.1`
  （`$env:GIT_CONFIG_COUNT=1; $env:GIT_CONFIG_KEY_0="http.version"; $env:GIT_CONFIG_VALUE_0="HTTP/1.1"`）。
- `dart format` 需要 PowerShell 在 PATH；本仓库按 120 列排版，默认 80 列格式化会产生大面积无关 diff，不要全库重排。

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

### 4.1 Inno 安装器

- 脚本：`installer/jellymaku.iss`；构建：`tools/build-installer.ps1 -Version 0.1.0`
- 依赖 Inno Setup 6（`ISCC.exe`）；会依次查找 PATH、`C:\Program Files (x86)\Inno Setup 6`、`C:\Program Files\Inno Setup 6`、`tools/inno\ISCC.exe`
- 输出：`artifacts/installer/JellyMaku-<version>-windows-x64-setup.exe`
- 本机 Inno Setup 6.7.3 位于 `tools\inno\app\ISCC.exe`；v0.1.0 安装器已实际编译、静默安装/启动/卸载冒烟通过（2026-10-23）。安装版主链路 E2E 已完成；安装器未签名。

### 4.2 Authenticode 签名（可选）

签名工具：Windows SDK 的 `signtool.exe`（自动在 PATH 与 Windows Kits 中查找）。

~~~powershell
# PFX 证书
& .\tools\build-installer.ps1 -Version 0.1.0 -CertificatePath C:\secure\jellymaku.pfx -CertificatePassword "***"
& .\tools\pack.ps1 -Version 0.1.0 -CertificatePath C:\secure\jellymaku.pfx -CertificatePassword "***"

# 或使用证书指纹（证书需安装在 CurrentUser\My）
& .\tools\build-installer.ps1 -Version 0.1.0 -CertificateThumbprint <THUMBPRINT>
& .\tools\pack.ps1 -Version 0.1.0 -CertificateThumbprint <THUMBPRINT>

# 单独签名已有文件
& .\tools\sign-release.ps1 -Files .\artifacts\installer\JellyMaku-0.1.0-windows-x64-setup.exe -CertificatePath C:\secure\jellymaku.pfx -CertificatePassword "***"
~~~

- 使用 SHA-256 与 DigiCert RFC3161 时间戳；可通过 `-TimestampUrl` 覆盖。
- PFX、密码、私钥不得提交仓库；CI 用 Secret 注入。
- 没有证书时脚本会明确输出 `Signing skipped`，不会伪造签名。
- 当前 v0.1.0 发布包未签名；需要受信任代码签名证书（OV/EV）才能消除 SmartScreen 警告。

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
