$txt = "$env:TEMP\dxdiag.txt"
if (Test-Path $txt) {
    $lines = Get-Content $txt
    Write-Output ("total: " + $lines.Count)
    $lines | Where-Object { $_ -match "DirectX Version|DDI Version|Feature Levels|Card name|Display Memory|Dedicated Memory|Driver Model|Operating System" }
} else {
    Write-Output "dxdiag.txt not found yet"
}
