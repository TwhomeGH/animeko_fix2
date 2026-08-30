$f = "C:\Users\Co\AppData\Local\cortexkit\aft\opencode\bash-tasks\eaf1a85feab25569\bash-ffc947dc5eb595e8\io\stdout"
if (Test-Path $f) {
    $lines = Get-Content $f
    Write-Output ("total lines: " + $lines.Count)
    # find selftest and error lines
    $hits = $lines | Where-Object { $_ -match "selftest|redrawer|Caused by|Exception|Unsupported|Skiko|D3D|Failed to load|mediampv" }
    foreach ($h in $hits) { Write-Output $h }
    Write-Output "=====TAIL====="
    $lines | Select-Object -Last 40
}
