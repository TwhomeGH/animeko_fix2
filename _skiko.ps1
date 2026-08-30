$skiko = Get-ChildItem 'C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.jetbrains.skiko' -Recurse -Filter 'skiko-jvm*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $skiko) { Write-Output 'no skiko-jvm jar found'; exit }
Write-Output ("jar: " + $skiko.FullName)
$tmp = 'C:\Users\Co\animeko\_skikojar'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($skiko.FullName, $tmp)
Write-Output 'extracted'
Get-ChildItem $tmp -Recurse -Filter 'SkikoProperties*.class' | Select-Object -ExpandProperty FullName
