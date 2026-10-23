param(
    [Parameter(Mandatory = $true)]
    [string[]]$Files,
    [string]$CertificatePath,
    [string]$CertificatePassword,
    [string]$CertificateThumbprint,
    [string]$TimestampUrl = "http://timestamp.digicert.com"
)

$ErrorActionPreference = "Stop"

if (($CertificatePath -and $CertificateThumbprint) -or (-not $CertificatePath -and -not $CertificateThumbprint)) {
    throw "Provide exactly one of -CertificatePath or -CertificateThumbprint."
}

$signtool = (Get-Command signtool.exe -ErrorAction SilentlyContinue | Select-Object -First 1).Source
if (-not $signtool) {
    $kits = @()
    if (${env:ProgramFiles(x86)}) {
        $kits += (Join-Path (${env:ProgramFiles(x86)}) "Windows Kits\10\bin")
    }
    $kits += "C:\Program Files (x86)\Windows Kits\10\bin"
    $kits = $kits | Where-Object { Test-Path $_ }
    foreach ($kit in $kits) {
        $candidate = Get-ChildItem -LiteralPath $kit -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\' } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($candidate) { $signtool = $candidate.FullName; break }
    }
}
if (-not $signtool) { throw "signtool.exe not found. Install the Windows SDK signing tools." }

$signArgs = @("sign", "/fd", "SHA256")
if ($TimestampUrl) { $signArgs += @("/tr", $TimestampUrl, "/td", "SHA256") }
if ($CertificatePath) {
    if (-not (Test-Path -LiteralPath $CertificatePath)) { throw "Certificate not found: $CertificatePath" }
    $signArgs += @("/f", (Resolve-Path -LiteralPath $CertificatePath).Path)
    if ($CertificatePassword) { $signArgs += @("/p", $CertificatePassword) }
} else {
    $signArgs += @("/sha1", $CertificateThumbprint)
}

foreach ($item in $Files) {
    if (-not (Test-Path -LiteralPath $item)) { throw "File not found: $item" }
    $full = (Resolve-Path -LiteralPath $item).Path
    & $signtool @signArgs $full
    if ($LASTEXITCODE -ne 0) { throw "signtool sign failed for $full (exit $LASTEXITCODE)" }
    $signature = Get-AuthenticodeSignature -FilePath $full
    Write-Output ("Signed: " + $full)
    Write-Output ("SignTool: " + $signtool)
    Write-Output ("SignatureStatus: " + $signature.Status)
    Write-Output ("Signer: " + $signature.SignerCertificate.Subject)
}
