$dir = 'C:\Users\Co\animeko\_mpvjar'
Push-Location $dir
$cls = 'org\openani\mediamp\mpv\compose\MpvMediampPlayerSurface_desktopKt.class'
javap -p -c $cls 2>&1 | Out-String | Write-Output
Pop-Location
