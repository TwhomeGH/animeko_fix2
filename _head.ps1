$f = "C:\Users\Co\AppData\Local\cortexkit\aft\opencode\bash-tasks\eaf1a85feab25569\bash-c3693544786b2e22\io\stderr"
$lines = Get-Content $f
# print first 40 lines (exception head) and any 'Caused by'
Write-Output "=====HEAD 45====="
$lines | Select-Object -First 45
Write-Output "=====CAUSED BY / Unsupported / Skiko====="
$lines | Where-Object { $_ -match "Caused by|Unsupported|Skiko|redrawer|mpv|D3D|Direct3D|Exception" }
