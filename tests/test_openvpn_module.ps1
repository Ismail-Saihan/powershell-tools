# Unit Test for Task 3: OpenVPN Client & Profile Deployment
$ErrorActionPreference = "Stop"

Write-Host "Running Task 3 Tests..." -ForegroundColor Cyan

$ScriptPath = Join-Path $PSScriptRoot "..\remote-tools.ps1"
$content = Get-Content $ScriptPath -Raw

if ($content -notmatch "function Install-OpenVPNModule") {
    throw "Test Failed: Install-OpenVPNModule function missing"
}
if ($content -notmatch "function Deploy-OpenVpnConfig") {
    throw "Test Failed: Deploy-OpenVpnConfig function missing"
}
if ($content -notmatch "EmbeddedIptspOvpn") {
    throw "Test Failed: EmbeddedIptspOvpn payload missing"
}

# Test profile deployment logic
. $ScriptPath -TestMode

$testDir = Join-Path $env:TEMP "TestOpenVpnConfig"
if (Test-Path $testDir) { Remove-Item $testDir -Recurse -Force }

Deploy-OpenVpnConfig -TargetDirectory $testDir

$targetFile = Join-Path $testDir "IPTSP VPN.ovpn"
if (-not (Test-Path $targetFile)) {
    throw "Test Failed: IPTSP VPN.ovpn was not created in target directory"
}

$fileContent = Get-Content $targetFile -Raw
if ($fileContent -notmatch "remote 182.163.126.253 1194 udp4") {
    throw "Test Failed: Deployed profile does not match expected server configuration"
}

# Cleanup
Remove-Item $testDir -Recurse -Force

Write-Host "Task 3 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
