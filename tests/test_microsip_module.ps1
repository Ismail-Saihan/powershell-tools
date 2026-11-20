# Unit Test for Task 4: MicroSIP VOIP Module & Config Writer
$ErrorActionPreference = "Stop"

Write-Host "Running Task 4 Tests..." -ForegroundColor Cyan

$ScriptPath = Join-Path $PSScriptRoot "..\remote-tools.ps1"
$content = Get-Content $ScriptPath -Raw

if ($content -notmatch "function Install-VoipModule") {
    throw "Test Failed: Install-VoipModule function missing"
}
if ($content -notmatch "function Set-MicroSipConfig") {
    throw "Test Failed: Set-MicroSipConfig function missing"
}

# Source script in test mode
. $ScriptPath -TestMode

$testIniDir = Join-Path $env:TEMP "TestMicroSip"
$testIniPath = Join-Path $testIniDir "MicroSIP.ini"
if (Test-Path $testIniDir) { Remove-Item $testIniDir -Recurse -Force }
$null = New-Item -ItemType Directory -Path $testIniDir -Force

# Call Set-MicroSipConfig with mock data
Set-MicroSipConfig -IniPath $testIniPath `
                   -Username "John Doe" `
                   -Extension "204" `
                   -Password "SecretPass123" `
                   -SipServer "182.163.126.250" `
                   -SipPort 5060

if (-not (Test-Path $testIniPath)) {
    throw "Test Failed: MicroSIP.ini was not created"
}

$iniContent = Get-Content $testIniPath -Raw
if ($iniContent -notmatch "user=204") { throw "Test Failed: user=204 missing" }
if ($iniContent -notmatch "authID=204") { throw "Test Failed: authID=204 missing" }
if ($iniContent -notmatch "password=SecretPass123") { throw "Test Failed: password missing" }
if ($iniContent -notmatch "server=182\.163\.126\.250:5060") { throw "Test Failed: server IP:port missing" }
if ($iniContent -notmatch "name=John Doe") { throw "Test Failed: name missing" }
if ($iniContent -notmatch "autoStart=1") { throw "Test Failed: autoStart missing" }

# Cleanup
Remove-Item $testIniDir -Recurse -Force

Write-Host "Task 4 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
