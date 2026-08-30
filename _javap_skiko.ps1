$dir = 'C:\Users\Co\animeko\_skikojar'
Push-Location $dir
javap -p -c 'org\jetbrains\skiko\SkikoProperties.class' 2>&1 | Out-String | Write-Output
Pop-Location
