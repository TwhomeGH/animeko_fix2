$base = 'C:\Users\Co\.gradle\caches'
Write-Output "=== Top-level dirs under caches ==="
Get-ChildItem $base -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $o = New-Object PSObject
    $o | Add-Member -NotePropertyName Name -NotePropertyValue $_.Name
    $o | Add-Member -NotePropertyName SizeMB -NotePropertyValue ([math]::Round($size/1MB))
    $o
} | Sort-Object SizeMB -Descending | Format-Table -AutoSize
