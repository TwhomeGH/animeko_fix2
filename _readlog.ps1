Start-Sleep -Seconds 8
$log = "C:\Users\Co\AppData\Roaming\Him188\Ani\data\logs\app.log"
if (Test-Path $log) {
    $lines = Get-Content $log -Encoding utf8
    $keys = @("renderApi", "JCEF", "mediampv", "AniCefApp", "initializing", "Skiko", "redrawer", "D3D", "Player errored", "Unsupported")
    foreach ($k in $keys) {
        $m = $lines | Where-Object { $_ -match [regex]::Escape($k) }
        foreach ($line in $m) { Write-Output ("[" + $k + "] " + $line) }
    }
    Write-Output ("total_lines=" + $lines.Count)
} else {
    Write-Output "log not found"
}
