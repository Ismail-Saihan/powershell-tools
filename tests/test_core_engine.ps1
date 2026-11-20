# Unit Test for Task 2: Core Engine & Helpers
$ErrorActionPreference = "Stop"

Write-Host "Running Task 2 Tests..." -ForegroundColor Cyan

# 1. Test dot-sourcing or parsing remote-tools.ps1
$ScriptPath = Join-Path $PSScriptRoot "..\remote-tools.ps1"
if (-not (Test-Path $ScriptPath)) {
    throw "Test Failed: remote-tools.ps1 does not exist!"
}

# Parse script syntax to ensure zero syntax errors
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)
if ($errors.Count -gt 0) {
    throw "Test Failed: Syntax errors detected in remote-tools.ps1: $($errors -join '; ')"
}

# 2. Test functions exist in remote-tools.ps1
$content = Get-Content $ScriptPath -Raw
$requiredCoreFunctions = @(
    "Test-IsAdmin",
    "Invoke-DownloadWithProgress",
    "Show-MainMenu",
    "Get-ReleaseAssetUrl",
    "Wait-UserPrompt",
    "Invoke-SelfElevation",
    "Test-NetworkPort"
)

foreach ($fn in $requiredCoreFunctions) {
    if ($content -notmatch "function $fn") {
        throw "Test Failed: $fn function missing"
    }
}

# Verify Invoke-SelfElevation uses PSCommandPath (EL-01)
if ($content -notmatch '\$PSCommandPath') {
    throw "Test Failed: Invoke-SelfElevation does not reference `$PSCommandPath (EL-01)"
}

# Source script in test mode
. $ScriptPath -TestMode

# 3. Test Invoke-DownloadWithProgress caching logic with mock file
$testCacheDir = Join-Path $env:TEMP "TestDownloadCache"
if (Test-Path $testCacheDir) { Remove-Item $testCacheDir -Recurse -Force }
$null = New-Item -ItemType Directory -Path $testCacheDir -Force
$testCachedFile = Join-Path $testCacheDir "cached_sample.txt"
[System.IO.File]::WriteAllText($testCachedFile, "Sample Cached Content")

# Calling with single URL via alias
$cachedResult = Invoke-DownloadWithProgress -Url "https://invalid.example.com/fake" -DestinationPath $testCachedFile -Description "Cached Check"
if (-not $cachedResult) {
    throw "Test Failed: Cached file should have returned true immediately without web request"
}

# Calling with array of URLs
$cachedResult2 = Invoke-DownloadWithProgress -Urls @("https://invalid.example.com/fake1", "https://invalid.example.com/fake2") -DestinationPath $testCachedFile -Description "Multi-URL Cached Check"
if (-not $cachedResult2) {
    throw "Test Failed: Multi-URL parameter should return true on cached file"
}

Remove-Item $testCacheDir -Recurse -Force

Write-Host "Task 2 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
