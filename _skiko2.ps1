$ww = Get-ChildItem 'C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.jetbrains.skiko' -Recurse -Filter '*.jar' -ErrorAction SilentlyContinue
Write-Output ("skiko jars found: " + (@($ww).Count))
$ww | ForEach-Object { Write-Output $_.FullName }
