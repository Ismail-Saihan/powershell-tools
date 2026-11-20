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
if ($content -notmatch "function Get-OpenVpnGuiPath") {
    throw "Test Failed: Get-OpenVpnGuiPath function missing"
}
if ($content -notmatch "EmbeddedIptspOvpn") {
    throw "Test Failed: EmbeddedIptspOvpn payload missing"
}

# Verify OpenVPNServiceInteractive service check exists (ENV-03)
if ($content -notmatch "OpenVPNServiceInteractive") {
    throw "Test Failed: OpenVPNServiceInteractive check missing in OpenVPN module"
}

# Verify OpenVPN download URLs do not use 404 source repository
if ($content -match "github\.com/OpenVPN/openvpn/releases/download") {
    throw "Test Failed: OpenVpnMsiUrl points to openvpn source repo instead of binary distribution (causes 404)"
}
if ($content -notmatch "swupdate\.openvpn\.(net|org)" -and $content -notmatch "build\.openvpn\.net") {
    throw "Test Failed: OpenVpn mirrors must include official OpenVPN community CDN"
}

# Verify CommonDesktopDirectory usage (ENV-01)
if ($content -notmatch "CommonDesktopDirectory") {
    throw "Test Failed: CommonDesktopDirectory not referenced for multi-user desktop shortcuts"
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

# Test deployment in an in-memory session where $PSScriptRoot is empty (e.g. irm | iex)
& {
    $testDir2 = Join-Path $env:TEMP "TestOpenVpnConfigMemory"
    if (Test-Path $testDir2) { Remove-Item $testDir2 -Recurse -Force }
    $local:PSScriptRoot = ""
    $deployed = Deploy-OpenVpnConfig -TargetDirectory $testDir2
    if (-not (Test-Path $deployed)) {
        throw "Test Failed: In-memory Deploy-OpenVpnConfig failed to deploy embedded profile"
    }
    Remove-Item $testDir2 -Recurse -Force
}

# Test Get-OpenVpnGuiPath execution
$null = Get-OpenVpnGuiPath

Write-Host "Task 3 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
