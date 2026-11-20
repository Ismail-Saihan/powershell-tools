# Unit Test for Task 6: Print Server Module
$ErrorActionPreference = "Stop"

Write-Host "Running Task 6 Tests..." -ForegroundColor Cyan

$ScriptPath = Join-Path $PSScriptRoot "..\remote-tools.ps1"
$content = Get-Content $ScriptPath -Raw

if ($content -notmatch "function Install-PrintServerModule") {
    throw "Test Failed: Install-PrintServerModule function missing"
}
if ($content -notmatch "function Add-PrintServerDefenderExclusions") {
    throw "Test Failed: Add-PrintServerDefenderExclusions function missing"
}
if ($content -notmatch "function Register-PrintServerStartup") {
    throw "Test Failed: Register-PrintServerStartup function missing"
}

# Source script in test mode
. $ScriptPath -TestMode

$testDir = Join-Path $env:TEMP "TestPrintServer"
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
$null = New-Item -ItemType Directory -Path $testDir -Force

$testExe = Join-Path $testDir "print_server.exe"
[System.IO.File]::WriteAllText($testExe, "Mock Print Server")

# Test startup registration logic with custom target
$startupLnk = Register-PrintServerStartup -TargetExe $testExe -TargetDir $testDir -TestOnly

$vbsPath = Join-Path $testDir "start_minimized.vbs"
if (-not (Test-Path $vbsPath)) {
    throw "Test Failed: Minimized VBScript runner was not created"
}

$vbsContent = Get-Content $vbsPath -Raw
if ($vbsContent -notmatch "print_server\.exe") {
    throw "Test Failed: VBScript runner does not reference print_server.exe"
}

# Cleanup
Remove-Item $testDir -Recurse -Force

Write-Host "Task 6 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
