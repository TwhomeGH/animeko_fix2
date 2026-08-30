Write-Output "=== Gradle JDKs ==="
Get-ChildItem 'C:\Users\Co\.gradle\jdks' -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $o = New-Object PSObject
    $o | Add-Member -NotePropertyName Name -NotePropertyValue $_.Name
    $o | Add-Member -NotePropertyName SizeMB -NotePropertyValue ([math]::Round($size/1MB))
    $o
} | Sort-Object SizeMB -Descending | Format-Table -AutoSize

Write-Output ""
Write-Output "=== All installed JVMs in common locations ==="
$jvmRoots = @('C:\Program Files\Eclipse Adoptium','C:\Program Files\Java','C:\Program Files\Microsoft','C:\Program Files\JetBrains')
$found = @()
foreach ($root in $jvmRoots) {
    if (Test-Path $root) {
        $found += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
    }
}
$found

Write-Output ""
Write-Output "=== Gradle toolchain config in project ==="
Write-Output "jvm.toolchain.vendor=jetbrains"
Write-Output "jvm.toolchain.version=21 (from animeko/gradle.properties)"

Write-Output ""
Write-Output "=== Current JAVA_HOME ==="
Write-Output $env:JAVA_HOME
