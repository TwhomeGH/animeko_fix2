$res = "C:\Users\Co\animeko\app\desktop\appResources"
Write-Output ("appResources exists: " + (Test-Path $res))
if (Test-Path $res) {
    Get-ChildItem $res -Recurse -File | ForEach-Object { Write-Output ("  " + $_.FullName.Replace($res, "...")) } | Select-Object -First 60
}
