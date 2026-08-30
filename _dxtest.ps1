# DirectX version from registry
$dx = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\DirectX" -ErrorAction SilentlyContinue
Write-Output ("DirectX Version: " + $dx.Version)
# OS version / build
$os = Get-CimInstance Win32_OperatingSystem
Write-Output ("OS: " + $os.Caption + " Build " + $os.BuildNumber)
# Video controllers
$gpu = Get-CimInstance Win32_VideoController
foreach ($g in $gpu) {
    Write-Output ("GPU: " + $g.Name + " | DriverVer=" + $g.DriverVersion + " | Status=" + $g.Status)
}
# Driver model via registry might not show DLL version
