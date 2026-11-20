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
if ($content -notmatch "function Test-IsAdmin") {
    throw "Test Failed: Test-IsAdmin function missing"
}
if ($content -notmatch "function Invoke-DownloadWithProgress") {
    throw "Test Failed: Invoke-DownloadWithProgress function missing"
}
if ($content -notmatch "function Show-MainMenu") {
    throw "Test Failed: Show-MainMenu function missing"
}
if ($content -notmatch "function Get-ReleaseAssetUrl") {
    throw "Test Failed: Get-ReleaseAssetUrl function missing"
}

Write-Host "Task 2 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
