Add-Type -AssemblyName System.Windows.Forms
try {
    $dxdiag = & dxdiag /t "$env:TEMP\dxdiag.txt" 2>$null
    Start-Sleep -Seconds 4
    $txt = "$env:TEMP\dxdiag.txt"
    if (Test-Path $txt) {
        Get-Content $txt | Select-Object -First 60
    }
} catch {
    Write-Output ("dxdiag error: " + $_.Exception.Message)
}
