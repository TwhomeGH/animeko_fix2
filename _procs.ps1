$procs = Get-Process java -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    Write-Output ("java PID=" + $p.Id + " WS=" + [math]::Round($p.WorkingSet64/1MB) + "MB CPU=" + [math]::Round($p.CPU) + "s")
}
# any MpvVerify/Ani window
$win = Get-Process | Where-Object { $_.MainWindowTitle -match "MpvVerify|Ani" -and $_.MainWindowTitle -ne "" }
foreach ($w in $win) { Write-Output ("win=" + $w.ProcessName + " title=" + $w.MainWindowTitle + " pid=" + $w.Id) }
Write-Output "done"
