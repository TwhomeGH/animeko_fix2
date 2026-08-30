Write-Output ("PSScriptRoot=[" + $PSScriptRoot + "]")
Write-Output ("MyInvocation.MyCommand.Path=[" + $MyInvocation.MyCommand.Path + "]")
$repo = Split-Path -Parent $PSScriptRoot
Write-Output ("repo=[" + $repo + "]")
$gradlew = Join-Path $repo "gradlew.bat"
Write-Output ("gradlew=[" + $gradlew + "]")
