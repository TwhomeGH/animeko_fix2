$appDir = "C:\Users\Co\animeko\app\desktop\build\compose\binaries\main\app\Ani\app"
Write-Output ("appDir exists: " + (Test-Path $appDir))
if (Test-Path $appDir) {
    $dlls = Get-ChildItem $appDir -Filter "*.dll" -ErrorAction SilentlyContinue
    Write-Output ("dll count in app dir: " + $dlls.Count)
    $dlls | Select-Object -First 10 | ForEach-Object { Write-Output ("  " + $_.Name) }
}
# also check the whole Ani tree for any native dlls
$aniRoot = "C:\Users\Co\animeko\app\desktop\build\compose\binaries\main\app\Ani"
$allDlls = Get-ChildItem $aniRoot -Recurse -Filter "*.dll" -ErrorAction SilentlyContinue
Write-Output ("all dlls under Ani: " + $allDlls.Count)
$allDlls | ForEach-Object { Write-Output ("  " + $_.FullName.Replace($aniRoot, "...")) }
