$proc = Get-Process -Id 18416 -ErrorAction SilentlyContinue
if ($proc) { Stop-Process -Id 18416 -Force; Write-Output "stopped 18416" } else { Write-Output "18416 not running" }
Get-ChildItem "C:\Users\Co\animeko\app\desktop\build\compose\binaries\main\app\Ani" -Recurse -Filter "mediampv.dll" -ErrorAction SilentlyContinue | ForEach-Object { Write-Output ("dll at: " + $_.FullName) }
