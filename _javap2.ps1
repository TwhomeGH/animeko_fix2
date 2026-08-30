$dir = 'C:\Users\Co\animeko\_mpvjar'
Push-Location $dir
$classes = @(
  'org\openani\mediamp\mpv\internal\MpvSurfaceRingKt.class',
  'org\openani\mediamp\mpv\internal\WindowsOpenGLSurfaceBackend.class',
  'org\openani\mediamp\mpv\internal\OpenGLSurfaceRingBackend.class'
)
foreach ($c in $classes) {
  Write-Output "==================== $c ===================="
  javap -p -c $c 2>&1 | Out-String | Write-Output
}
Pop-Location
