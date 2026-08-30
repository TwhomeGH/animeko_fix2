$d = Get-PSDrive C
Write-Output ("C Used GB: " + [math]::Round($d.Used/1GB,1))
Write-Output ("C Free GB: " + [math]::Round($d.Free/1GB,2))
Write-Output "--- jdks remaining ---"
Get-ChildItem 'C:\Users\Co\.gradle\jdks' -Directory | ForEach-Object { $_.Name }
