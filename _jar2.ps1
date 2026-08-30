Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar = "C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.openani.mediamp\mediamp-ffmpeg-runtime-windows-x64\0.3.2\720873d20cc004daeb0178d41150aa3db413e160\mediamp-ffmpeg-runtime-windows-x64-0.3.2.jar"
$z = [System.IO.Compression.ZipFile]::OpenRead($jar)
Write-Output ("FFMPEG COUNT=" + $z.Entries.Count)
$z.Entries | ForEach-Object { Write-Output $_.FullName } | Select-Object -First 20
$z.Dispose()
