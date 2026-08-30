Add-Type -AssemblyName System.IO.Compression.FileSystem
$jar = "C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.openani.mediamp\mediamp-mpv-runtime-windows-x64\0.3.2\4e21b62d588855f01a373f99caf3f018ef69eb53\mediamp-mpv-runtime-windows-x64-0.3.2.jar"
$z = [System.IO.Compression.ZipFile]::OpenRead($jar)
Write-Output ("COUNT=" + $z.Entries.Count)
$z.Entries | ForEach-Object { Write-Output $_.FullName } | Select-Object -First 80
$z.Dispose()
