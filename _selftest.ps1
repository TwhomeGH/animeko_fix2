$f = "C:\Users\Co\AppData\Local\cortexkit\aft\opencode\bash-tasks\eaf1a85feab25569\bash-ffc947dc5eb595e8\io\stdout"
$lines = Get-Content $f
# find the last [selftest] start line index
$idx = -1
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match "\[selftest\] start") { $idx = $i; break }
}
Write-Output ("last selftest start at line: " + $idx + " of " + $lines.Count)
if ($idx -ge 0) {
    $end = [Math]::Min($lines.Count - 1, $idx + 120)
    for ($j = [Math]::Max(0, $idx - 5); $j -le $end; $j++) {
        Write-Output ("L" + $j + ": " + $lines[$j])
    }
}
