$f = "C:\Users\Co\AppData\Local\cortexkit\aft\opencode\bash-tasks\eaf1a85feab25569\bash-c3693544786b2e22\io\stdout"
if (Test-Path $f) {
    $lines = Get-Content $f
    Write-Output ("total: " + $lines.Count)
    $hits = $lines | Where-Object { $_ -match "selftest|verify\]|Ready|mediampv|event_loop|mpv/cplayer|error|Error|Failed|BUILD" }
    foreach ($h in $hits) { Write-Output $h }
    Write-Output "=====TAIL30====="
    $lines | Select-Object -Last 30
} else {
    Write-Output "no stdout yet"
}
