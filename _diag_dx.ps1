$dxdiag = "$env:SystemRoot\System32\dxdiag.exe"
$out = "$env:TEMP\dxdiag_animeko.xml"
if (Test-Path $out) { Remove-Item $out }
& $dxdiag /whql:off /t $out | Out-Null
Start-Sleep -Seconds 3
if (Test-Path $out) {
    Write-Output "dxdiag dump saved: $out"
    $content = Get-Content $out -Raw
    Write-Output "=== DXDIAG_VERSION ==="
    if ($content -match '<DirectXVersion>([^<]+)') { Write-Output ("DirectXVersion: " + $matches[1]) }
    if ($content -match 'DxDiag Version: ([^\r\n<]+)') { Write-Output ("DxDiag: " + $matches[1]) }
    # Count display devices and feature levels
    Write-Output "=== DISPLAY DEVICES (feature levels) ==="
    $matches2 = [regex]::Matches($content, 'CardName: ([^\r\n<]+)')
    foreach ($m in $matches2) { Write-Output ("Card: " + $m.Groups[1].Value) }
    $fl = [regex]::Matches($content, 'DDIVersion: ([^\r\n<]+)')
    $idx = 0
    foreach ($m in $fl) { Write-Output ("  (Display $idx DDI: " + $m.Groups[1].Value + ")"); $idx++ }
    $drv = [regex]::Matches($content, 'DriverVersion: ([^\r\n<]+)')
    $idx2 = 0
    foreach ($m in $drv) { Write-Output ("  (Display $idx2 Driver: " + $m.Groups[1].Value + ")"); $idx2++ }
    Write-Output "=== FEATURE LEVELS (from each device section) ==="
    $sections = [regex]::Matches($content, 'Card name: ([^\r\n<]+).*?Feature Levels: ([^\r\n<]+)', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    foreach ($s in $sections) {
        Write-Output ("Device " + $s.Groups[1].Value + " -> FL: " + $s.Groups[2].Value)
    }
} else {
    Write-Output "dxdiag did not produce output"
}
