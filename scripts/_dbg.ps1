Write-Output ("PSScriptRoot=[" + $PSScriptRoot + "]")
Write-Output ("MyInvocation.MyCommand.Path=[" + $MyInvocation.MyCommand.Path + "]")
Write-Output ("MyInvocation.MyCommand.Definition=[" + $MyInvocation.MyCommand.Definition + "]")
Write-Output ("location=" + (Get-Location).Path)
