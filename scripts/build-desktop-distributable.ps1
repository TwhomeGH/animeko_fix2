# build-desktop-distributable.ps1
# One-click packaging of the animeko desktop app on Windows into a runnable
# directory (portable: Ani.exe + runtime + jcef).
#
# Output: app/desktop/build/compose/binaries/main/app/
#
# Usage:
#   powershell -File scripts/build-desktop-distributable.ps1
#   powershell -File scripts/build-desktop-distributable.ps1 -ApiServer http://localhost:4394
#   powershell -File scripts/build-desktop-distributable.ps1 -Jbr "C:\path\to\jbr" -ApiServer http://localhost:4394
#
# Params:
#   -ApiServer   Local backend API address for debugging (passed as -Pani.api.server)
#   -Jbr         Path to JetBrains Runtime 21 (with JCEF); auto-detected when omitted
#   -Release     Use createReleaseDistributable (slimmer, no jcef.config debug aid)
#   -GradleArgs  Extra args forwarded to gradlew (array, e.g. @("-Xmx2g"))

param(
    [string]$ApiServer = "",
    [string]$Jbr = "",
    [switch]$Release = $false,
    [string[]]$GradleArgs = @()
)

$ErrorActionPreference = "Stop"

# Locate repo root: walk up from the script dir until gradlew.bat is found.
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$dir = $scriptDir
while ($dir -and -not (Test-Path (Join-Path $dir "gradlew.bat"))) {
    $parent = Split-Path -Parent $dir
    if ($parent -eq $dir) { break }
    $dir = $parent
}
$repo = $dir
$gradlew = Join-Path $repo "gradlew.bat"

if (-not $repo -or -not (Test-Path $gradlew)) {
    Write-Error "gradlew.bat not found while walking up from $scriptDir"
}

Write-Output "Repository: $repo"

# ---- Resolve JBR (must contain JCEF) ----
$resolvedJbr = ""
if ($Jbr) {
    $resolvedJbr = $Jbr
} elseif ($env:ANI_COMPOSE_JAVA_HOME) {
    $resolvedJbr = $env:ANI_COMPOSE_JAVA_HOME
} else {
    # Read org.gradle.java.home from gradle.properties ('\\' means '\' in properties)
    $gp = Join-Path $repo "gradle.properties"
    if (Test-Path $gp) {
        $line = Select-String -Path $gp -Pattern '^\s*org\.gradle\.java\.home=(.+)$' | Select-Object -First 1
        if ($line) {
            $resolvedJbr = $line.Matches[0].Groups[1].Value -replace '\\\\', '\'
        }
    }
    if (-not $resolvedJbr -or -not (Test-Path (Join-Path $resolvedJbr "bin\java.exe"))) {
        # Auto-detect a JBR under ~/.gradle/jdks that ships jcef.jmod
        $jdks = Join-Path $env:USERPROFILE ".gradle\jdks"
        if (Test-Path $jdks) {
            $found = Get-ChildItem $jdks -Directory | Where-Object {
                (Test-Path (Join-Path $_.FullName "bin\java.exe")) -and
                (Test-Path (Join-Path $_.FullName "jmods\jcef.jmod"))
            } | Select-Object -First 1
            if ($found) { $resolvedJbr = $found.FullName }
        }
    }
}

if (-not $resolvedJbr -or -not (Test-Path (Join-Path $resolvedJbr "bin\java.exe"))) {
    Write-Error "No JBR (JetBrains Runtime with JCEF) found. Pass -Jbr or set ANI_COMPOSE_JAVA_HOME."
}
if (-not (Test-Path (Join-Path $resolvedJbr "jmods\jcef.jmod"))) {
    Write-Error "The given JDK has no JCEF (missing jmods/jcef.jmod). animeko desktop requires JetBrains Runtime 21 with JCEF."
}

Write-Output "ANI_COMPOSE_JAVA_HOME=$resolvedJbr"
$env:ANI_COMPOSE_JAVA_HOME = $resolvedJbr

# ---- Assemble gradle command ----
$task = if ($Release) { "createReleaseDistributable" } else { "createDistributable" }
$args = @(":app:desktop:$task", "--console=plain")
if ($ApiServer) {
    Write-Output "ani.api.server=$ApiServer"
    $args += "-Pani.api.server=$ApiServer"
}

# ---- Run ----
Write-Output "Running: gradlew $($args -join ' ')"
$code = & cmd /c "`"$gradlew`" $($args -join ' ') 2>&1"
$exit = $LASTEXITCODE
if ($exit -ne 0) {
    Write-Output "Packaging FAILED (exit $exit), full output:"
    $code | ForEach-Object { Write-Output $_ }
    exit 1
}

Write-Output "Packaging done -> app/desktop/build/compose/binaries/main/app/"
