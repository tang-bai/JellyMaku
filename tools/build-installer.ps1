param(
    [string]$Version = "0.1.0",
    [string]$BuildDir = "build\windows\x64\runner\Release"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path (Join-Path $BuildDir "JellyMaku.exe"))) {
    throw "Missing $BuildDir\JellyMaku.exe. Run: .flutter\bin\flutter.bat build windows --release --no-pub"
}

$iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $iscc) {
    foreach ($candidate in @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Join-Path $PSScriptRoot "..\tools\inno\ISCC.exe")
    )) {
        if (Test-Path $candidate) { $iscc = $candidate; break }
    }
}
if (-not $iscc) {
    throw "Inno Setup 6 (ISCC.exe) not found. Install from https://jrsoftware.org/isdl.php or extract portable to tools\inno."
}

& $iscc "/DMyAppVersion=$Version" (Join-Path $PSScriptRoot "..\installer\jellymaku.iss")
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }

$setup = Join-Path $PSScriptRoot "..\artifacts\installer\JellyMaku-$Version-windows-x64-setup.exe"
if (-not (Test-Path $setup)) { throw "Installer not produced: $setup" }
Write-Output ("Installer: " + (Resolve-Path $setup))
Write-Output ("Size: " + (Get-Item $setup).Length)
Write-Output ("SHA256: " + (Get-FileHash $setup -Algorithm SHA256).Hash)
