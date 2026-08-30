$roots = @(
    "C:\Users\Co\animeko\app\desktop\build",
    "C:\Users\Co\animeko\app\desktop\test-sandbox",
    "C:\Users\Co\.gradle\caches\modules-2\files-2.1\org.openani.mediamp"
)
foreach ($r in $roots) {
    if (Test-Path $r) {
        Get-ChildItem $r -Recurse -Filter "mediampv.dll" -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Output ("found: " + $_.FullName) }
    }
}
Write-Output "done"
