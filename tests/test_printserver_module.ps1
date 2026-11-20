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
if ($content -notmatch "function Stop-PrintServerGracefully") {
    throw "Test Failed: Stop-PrintServerGracefully function missing"
}
if ($content -notmatch "function Test-PortAvailability") {
    throw "Test Failed: Test-PortAvailability function missing"
}

# Source script in test mode
. $ScriptPath -TestMode

$testDir = Join-Path $env:TEMP "TestPrintServer"
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }
$null = New-Item -ItemType Directory -Path $testDir -Force

$testExe = Join-Path $testDir "print_server.exe"
[System.IO.File]::WriteAllText($testExe, "Mock Print Server")

# 1. Test startup registration logic with direct .lnk shortcut (WindowStyle = 7, no VBScript)
$startupLnk = Register-PrintServerStartup -TargetExe $testExe -TargetDir $testDir -TestOnly
if (-not (Test-Path $startupLnk)) {
    throw "Test Failed: Direct startup .lnk shortcut was not created: $startupLnk"
}

$vbsPath = Join-Path $testDir "start_minimized.vbs"
if (Test-Path $vbsPath) {
    throw "Test Failed: VBScript launcher was created (ASR rule violation)"
}

$wshShell = New-Object -ComObject WScript.Shell
$sc = $wshShell.CreateShortcut($startupLnk)
$canonicalActual = (Get-Item $sc.TargetPath).FullName
$canonicalExpected = (Get-Item $testExe).FullName
if ($canonicalActual -ne $canonicalExpected) {
    throw "Test Failed: Shortcut TargetPath mismatch ($canonicalActual vs $canonicalExpected)"
}
if ($sc.WindowStyle -ne 7) {
    throw "Test Failed: Shortcut WindowStyle is not 7 (minimized)"
}

# 2. Test Stop-PrintServerGracefully
$stopped = Stop-PrintServerGracefully -TimeoutSeconds 1
if (-not $stopped) {
    throw "Test Failed: Stop-PrintServerGracefully did not return true"
}

# 3. Test Test-PortAvailability on high unused port
$portStatus = Test-PortAvailability -Port 59876
if ($null -eq $portStatus -or -not $portStatus.ContainsKey("Available")) {
    throw "Test Failed: Test-PortAvailability did not return expected hashtable"
}
if (-not $portStatus.Available) {
    throw "Test Failed: High test port 59876 should be available"
}

# Cleanup
Remove-Item $testDir -Recurse -Force

Write-Host "Task 6 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
