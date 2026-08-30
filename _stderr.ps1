$f = "C:\Users\Co\AppData\Local\cortexkit\aft\opencode\bash-tasks\eaf1a85feab25569\bash-c3693544786b2e22\io\stderr"
if (Test-Path $f) {
    $lines = Get-Content $f
    Write-Output ("stderr total: " + $lines.Count)
    $lines | Select-Object -Last 60
} else {
    Write-Output "no stderr file"
}
