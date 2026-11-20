# Unit Test for Task 7: Release Publisher Script
$ErrorActionPreference = "Stop"

Write-Host "Running Task 7 Tests..." -ForegroundColor Cyan

$PublishScript = Join-Path $PSScriptRoot "..\publish-release.ps1"
if (-not (Test-Path $PublishScript)) {
    throw "Test Failed: publish-release.ps1 does not exist"
}

# Verify syntax
$errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($PublishScript, [ref]$null, [ref]$errors)
if ($errors.Count -gt 0) {
    throw "Test Failed: Syntax errors detected in publish-release.ps1: $($errors -join '; ')"
}

# Test execution with -DryRun
$dryRunOutput = & powershell -ExecutionPolicy Bypass -File $PublishScript -GitHubUser "testuser" -GitHubRepo "testrepo" -Tag "v1.0.0" -DryRun
$outputStr = $dryRunOutput -join "`n"

if ($outputStr -notmatch "DryRun Mode Active") {
    throw "Test Failed: DryRun mode did not engage properly"
}
if ($outputStr -notmatch "Gprinter Driver\.exe") {
    throw "Test Failed: Gprinter Driver was not listed in asset inventory"
}
if ($outputStr -notmatch "print_server\.exe") {
    throw "Test Failed: print_server.exe was not listed in asset inventory"
}

Write-Host "Task 7 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
