$jarRoot = "C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.openani.mediamp"
if (Test-Path $jarRoot) {
    Get-ChildItem $jarRoot -Recurse -Filter "*.jar" | Where-Object { $_.Name -match "runtime" } |
        ForEach-Object { Write-Output ("jar: " + $_.FullName + " (" + $_.Length + " bytes)") }
}
# also look for mediampv elsewhere on common paths
$candidates = @(
    "C:\Users\Co\.gradle\caches",
    "C:\Users\Co\mediamp\mediamp-mpv\build"
)
foreach ($c in $candidates) {
    if (Test-Path $c) {
        Get-ChildItem $c -Recurse -Filter "mediampv.dll" -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Output ("dll: " + $_.FullName) }
    }
}
Write-Output "done"
