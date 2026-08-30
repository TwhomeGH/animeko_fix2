$ErrorActionPreference = "Stop"
Write-Output ("start PSScriptRoot=[" + $PSScriptRoot + "]")
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
Write-Output ("scriptDir=[" + $scriptDir + "]")
$dir = $scriptDir
while ($dir -and -not (Test-Path (Join-Path $dir "gradlew.bat"))) {
    $parent = Split-Path -Parent $dir
    if ($parent -eq $dir) { break }
    $dir = $parent
}
$repo = $dir
Write-Output ("repo=[" + $repo + "]")
$gradlew = Join-Path $repo "gradlew.bat"
Write-Output ("gradlew=[" + $gradlew + "]")
