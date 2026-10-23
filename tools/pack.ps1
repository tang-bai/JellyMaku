
param(
    [string]$BuildDir = "build\windows\x64\runner\Release",
    [string]$Version = "0.1.0",
    [string]$OutDir = "artifacts",
    [string]$CertificatePath,
    [string]$CertificatePassword,
    [string]$CertificateThumbprint,
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

$exe = Join-Path $BuildDir "JellyMaku.exe"
if (-not (Test-Path $exe)) {
    throw "Missing $exe. Run: .flutter\bin\flutter.bat build windows --release"
}

$stageRoot = Join-Path $OutDir "portable"
$stage = Join-Path $stageRoot "JellyMaku"
if (Test-Path $stageRoot) { Remove-Item -Recurse -Force $stageRoot }
New-Item -ItemType Directory -Force -Path $stage | Out-Null

Copy-Item (Join-Path $BuildDir "*") $stage -Recurse -Force
foreach ($file in @("README.md", "LICENSE", "AGENTS.md", "THIRD_PARTY_NOTICES.md")) {
    if (Test-Path $file) { Copy-Item $file $stage -Force }
}

if ($CertificatePath -or $CertificateThumbprint) {
    $signParams = @{ Files = @((Join-Path $stage "JellyMaku.exe")); TimestampUrl = $TimestampUrl }
    if ($CertificatePath) { $signParams.CertificatePath = $CertificatePath }
    if ($CertificatePassword) { $signParams.CertificatePassword = $CertificatePassword }
    if ($CertificateThumbprint) { $signParams.CertificateThumbprint = $CertificateThumbprint }
    & (Join-Path $PSScriptRoot "sign-release.ps1") @signParams
} else {
    Write-Output "Signing skipped: no certificate/thumbprint supplied."
}

$zip = Join-Path $OutDir "JellyMaku-$Version-windows-x64-portable.zip"
if (Test-Path $zip) { Remove-Item -Force $zip }
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal

$hash = (Get-FileHash $zip -Algorithm SHA256).Hash
Write-Output ("Packaged: " + $zip)
Write-Output ("Size: " + (Get-Item $zip).Length)
Write-Output ("SHA256: " + $hash)
