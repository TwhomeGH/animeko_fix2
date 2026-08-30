$jar = 'C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.jetbrains.skiko\skiko-awt\0.144.6\c9bec39e3c517ed5591c71c7db0cbbe64b6be849\skiko-awt-0.144.6.jar'
$tmp = 'C:\Users\Co\animeko\_skikojar'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($jar, $tmp)
Write-Output 'extracted'
Get-ChildItem $tmp -Recurse -Filter 'SkikoProperties*' | Select-Object -ExpandProperty FullName
