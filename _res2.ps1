$res = "C:\Users\Co\animeko\app\desktop\appResources"
Get-ChildItem $res -Directory | ForEach-Object { Write-Output ("DIR: " + $_.Name) }
# check windows dir
$win = Join-Path $res "windows-x64"
Write-Output ("windows-x64 exists: " + (Test-Path $win))
if (Test-Path $win) {
    Get-ChildItem $win -Recurse -File | Select-Object -First 40 | ForEach-Object { Write-Output ("  " + $_.FullName.Replace($res, "...")) }
}
Write-Output "done"
