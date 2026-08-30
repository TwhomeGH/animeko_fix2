$f = "C:\Users\Co\animeko\seek-verify.mp4"
if (Test-Path $f) {
    $s = (Get-Item $f).Length
    Write-Output ("exists size=" + $s)
} else {
    Write-Output "missing"
}
