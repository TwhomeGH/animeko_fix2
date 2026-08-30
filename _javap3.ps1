$dir = 'C:\Users\Co\animeko\_mpvjar'
Push-Location $dir
$classes = @(
  'org\openani\mediamp\mpv\internal\MpvSurfaceRing.class',
  'org\openani\mediamp\mpv\internal\MpvSurfaceDrawResolver.class',
  'org\openani\mediamp\mpv\internal\OpenGLSurfaceDrawResolver.class'
)
foreach ($c in $classes) {
  Write-Output "==================== $c ===================="
  javap -p -c $c 2>&1 | Out-String | Write-Output
}
Pop-Location
