param(
    [string]$Manifest = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
if ([string]::IsNullOrWhiteSpace($Manifest)) {
    $Manifest = Join-Path $repoRoot "third_party\manifest.json"
}
if (-not (Test-Path $Manifest)) {
    throw "Manifest not found: $Manifest"
}

$manifestObject = Get-Content $Manifest -Raw | ConvertFrom-Json
$failures = New-Object System.Collections.Generic.List[string]
$rows = New-Object System.Collections.Generic.List[object]

foreach ($item in $manifestObject.items) {
    $path = Join-Path $repoRoot ($item.target -replace '/', '\')
    $status = "OK"
    $actualSize = $null
    $actualHash = $null

    if (-not (Test-Path $path)) {
        $status = "MISSING"
        $failures.Add("$($item.name) $($item.version): missing $($item.target)")
    } else {
        $file = Get-Item $path
        $actualSize = $file.Length
        if ($actualSize -ne [int64]$item.size) {
            $status = "SIZE"
            $failures.Add("$($item.name) $($item.version): size $actualSize != $($item.size)")
        }
        $actualHash = (Get-FileHash $path -Algorithm SHA256).Hash
        if ($actualHash -ne $item.sha256) {
            $status = "SHA256"
            $failures.Add("$($item.name) $($item.version): sha256 mismatch")
        }
    }

    foreach ($check in @($item.checks)) {
        if ([string]::IsNullOrWhiteSpace($check)) { continue }
        $checkPath = Join-Path $repoRoot ($check -replace '/', '\')
        if (-not (Test-Path $checkPath)) {
            $status = "CHECK"
            $failures.Add("$($item.name) $($item.version): missing $check")
        }
    }

    $rows.Add([pscustomobject]@{
        Name = $item.name
        Version = $item.version
        Status = $status
        Size = $actualSize
        Target = $item.target
    })
}

$rows | Format-Table -AutoSize
if ($failures.Count -gt 0) {
    Write-Output ""
    Write-Output "FAILED ($($failures.Count)):"
    $failures | ForEach-Object { Write-Output (" - " + $_) }
    exit 1
}
Write-Output ""
Write-Output "All assets verified ($($manifestObject.items.Count) items)."
