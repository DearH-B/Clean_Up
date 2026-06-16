param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$failures = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

$gradlePath = Join-Path $ProjectRoot "android\app\build.gradle.kts"
$manifestPath = Join-Path $ProjectRoot "android\app\src\main\AndroidManifest.xml"
$keyPropertiesPath = Join-Path $ProjectRoot "android\key.properties"

$gradle = Get-Content -Raw -Encoding UTF8 $gradlePath
$manifest = Get-Content -Raw -Encoding UTF8 $manifestPath

if ($gradle -match 'applicationId\s*=\s*"com\.cleanup\.clean_up"') {
    $failures.Add("applicationId still uses the placeholder com.cleanup.clean_up.")
}

if ($manifest -match 'android:label="clean_up"') {
    $failures.Add("Android app label still uses the placeholder clean_up.")
}

if (-not (Test-Path -LiteralPath $keyPropertiesPath)) {
    $failures.Add("android/key.properties is missing. Configure the upload key.")
} else {
    $properties = @{}
    foreach ($line in Get-Content -Encoding UTF8 $keyPropertiesPath) {
        if ($line -match '^\s*([^#=]+?)\s*=\s*(.+?)\s*$') {
            $properties[$matches[1]] = $matches[2]
        }
    }
    foreach ($name in "storePassword", "keyPassword", "keyAlias", "storeFile") {
        if (-not $properties.ContainsKey($name) -or
            [string]::IsNullOrWhiteSpace($properties[$name]) -or
            $properties[$name] -match "replace-with") {
            $failures.Add("android/key.properties has no production value for $name.")
        }
    }
    if ($properties.ContainsKey("storeFile")) {
        $storeFile = Join-Path (Join-Path $ProjectRoot "android\app") $properties["storeFile"]
        if (-not (Test-Path -LiteralPath $storeFile)) {
            $failures.Add("Upload keystore file was not found: $storeFile")
        }
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "docs\RELEASE_READINESS_CURRENT.md"))) {
    $warnings.Add("The current release readiness report is missing.")
}

Write-Host "Android release preflight"
if ($warnings.Count -gt 0) {
    foreach ($warning in $warnings) {
        Write-Host "[WARN] $warning" -ForegroundColor Yellow
    }
}
if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[BLOCKED] $failure" -ForegroundColor Red
    }
    exit 2
}

Write-Host "[PASS] Package name, app label, and upload signing are configured." -ForegroundColor Green
