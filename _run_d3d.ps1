$logPath = "C:\Users\Co\AppData\Roaming\Him188\Ani\data\logs\app.log"
Set-Content -Path $logPath -Value "" -Encoding utf8
$env:JAVA_TOOL_OPTIONS = "-Dskiko.renderApi=DIRECT3D"
Write-Output "JAVA_TOOL_OPTIONS set for launch"
$appExe = "C:\Users\Co\animeko\app\desktop\build\compose\binaries\main\app\Ani\Ani.exe"
$p = Start-Process -FilePath $appExe -PassThru
Write-Output ("Started PID=" + $p.Id)
