param(
    [string]$Version = "0.1.0",
    [string]$BuildDir = "build\windows\x64\runner\Release",
    [string]$CertificatePath,
    [string]$CertificatePassword,
    [string]$CertificateThumbprint,
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

$buildExe = Join-Path $BuildDir "JellyMaku.exe"
if (-not (Test-Path $buildExe)) {
    throw "Missing $buildExe. Run: .flutter\bin\flutter.bat build windows --release --no-pub"
}

$signParams = @{}
$useSigning = [bool]($CertificatePath -or $CertificateThumbprint)
if ($useSigning) {
    $signParams = @{ Files = @($buildExe); TimestampUrl = $TimestampUrl }
    if ($CertificatePath) { $signParams.CertificatePath = $CertificatePath }
    if ($CertificatePassword) { $signParams.CertificatePassword = $CertificatePassword }
    if ($CertificateThumbprint) { $signParams.CertificateThumbprint = $CertificateThumbprint }
    & (Join-Path $PSScriptRoot "sign-release.ps1") @signParams
} else {
    Write-Output "Signing skipped: no certificate/thumbprint supplied."
}

$iscc = (Get-Command ISCC.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $iscc) {
    foreach ($candidate in @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Join-Path $PSScriptRoot "..\tools\inno\ISCC.exe"),
        (Join-Path $PSScriptRoot "..\tools\inno\app\ISCC.exe")
    )) {
        if (Test-Path $candidate) { $iscc = $candidate; break }
    }
}
if (-not $iscc) {
    throw "Inno Setup 6 (ISCC.exe) not found. Install from https://jrsoftware.org/isdl.php or extract portable to tools\inno."
}

$installerScript = Join-Path $PSScriptRoot "..\installer\jellymaku.iss"
& $iscc "/DMyAppVersion=$Version" $installerScript
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }

$setup = Join-Path $PSScriptRoot "..\artifacts\installer\JellyMaku-$Version-windows-x64-setup.exe"
if (-not (Test-Path $setup)) { throw "Installer not produced: $setup" }
if ($useSigning) {
    $signParams.Files = @($setup)
    & (Join-Path $PSScriptRoot "sign-release.ps1") @signParams
}
Write-Output ("Installer: " + (Resolve-Path $setup))
Write-Output ("Size: " + (Get-Item $setup).Length)
Write-Output ("SHA256: " + (Get-FileHash $setup -Algorithm SHA256).Hash)
