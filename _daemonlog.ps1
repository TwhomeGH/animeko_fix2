$logDir = "C:\Users\Co\.gradle\daemon\9.3.1"
if (Test-Path $logDir) {
    $logs = Get-ChildItem $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 2
    foreach ($l in $logs) {
        Write-Output ("LOG: " + $l.Name + " modified=" + $l.LastWriteTime)
        Get-Content $l.FullName -Tail 8
        Write-Output "-----"
    }
} else {
    Write-Output "no daemon log dir"
}
