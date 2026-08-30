Write-Output "=== System RAM ==="
$os = Get-CimInstance Win32_OperatingSystem
Write-Output ("Total GB: " + [math]::Round($os.TotalVisibleMemorySize/1MB,1))
Write-Output ("Free  GB: " + [math]::Round($os.FreePhysicalMemory/1MB,1))
Write-Output ""
Write-Output "=== PageFile ==="
Get-CimInstance Win32_PageFileUsage | Select-Object Name,AllocatedBaseSize,CurrentUsage,PeakUsage | Format-Table -AutoSize
Write-Output ""
Write-Output "=== System .sys files on C: ==="
Get-Item 'C:\pagefile.sys','C:\hiberfil.sys','C:\swapfile.sys' -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $o = New-Object PSObject
    $o | Add-Member -NotePropertyName Name -NotePropertyValue $_.Name
    $o | Add-Member -NotePropertyName SizeGB -NotePropertyValue ([math]::Round($_.Length/1GB,2))
    $o
} | Format-Table -AutoSize
Write-Output ""
Write-Output "=== Gradle subdir sizes (MB) ==="
Get-ChildItem 'C:\Users\Co\.gradle' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $o = New-Object PSObject
    $o | Add-Member -NotePropertyName Name -NotePropertyValue $_.Name
    $o | Add-Member -NotePropertyName SizeMB -NotePropertyValue ([math]::Round($size/1MB))
    $o
} | Sort-Object SizeMB -Descending | Format-Table -AutoSize
