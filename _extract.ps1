$jar = 'C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.openani.mediamp\mediamp-mpv-desktop\0.3.2\2a71e03c54072c45f78eda0a110000ac5c008b22\mediamp-mpv-desktop-0.3.2.jar'
$tmp = 'C:\Users\Co\animeko\_mpvjar'
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($jar, $tmp)
Write-Output "extracted to $tmp"
Get-ChildItem $tmp -Recurse -Filter '*.class' | Where-Object { $_.Name -match 'MpvMediampPlayer|Surface|Handle' } | Select-Object -ExpandProperty FullName
