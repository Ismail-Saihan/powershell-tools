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
if ($content -notmatch "function Get-MicroSipExePath") {
    throw "Test Failed: Get-MicroSipExePath function missing"
}

# Source script in test mode
. $ScriptPath -TestMode

$testIniDir = Join-Path $env:TEMP "TestMicroSip"
$testIniPath = Join-Path $testIniDir "MicroSIP.ini"
if (Test-Path $testIniDir) { Remove-Item $testIniDir -Recurse -Force }
$null = New-Item -ItemType Directory -Path $testIniDir -Force

# Test 1: Call Set-MicroSipConfig to create initial configuration from scratch
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

# Test 2: Verify UTF-8 without BOM (VOIP-02)
$bytes = [System.IO.File]::ReadAllBytes($testIniPath)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    throw "Test Failed: MicroSIP.ini was written with UTF-8 BOM, which corrupts Win32 parsing!"
}

# Test 3: Existing INI preservation (VOIP-01) - Add custom contacts and audio devices, then update [Account1]
$preExistingIni = @"
[Settings]
autoStart=1
micId=USB Headset Microphone
speakerId=Realtek High Definition
ringVolume=85

[Contacts]
101=Reception Desk
102=Billing Department

[Account1]
user=100
"@
[System.IO.File]::WriteAllText($testIniPath, $preExistingIni, [System.Text.UTF8Encoding]::new($false))

# Update credentials with whitespace (testing VOIP-03 trimming)
Set-MicroSipConfig -IniPath $testIniPath `
                   -Username "  Jane Smith  " `
                   -Extension "  305  " `
                   -Password "  NewSecurePass456  " `
                   -SipServer "  182.163.126.250  " `
                   -SipPort 5060

$updatedContent = Get-Content $testIniPath -Raw
# Verify preserved sections
if ($updatedContent -notmatch "micId=USB Headset Microphone") { throw "Test Failed: Preserved micId missing" }
if ($updatedContent -notmatch "ringVolume=85") { throw "Test Failed: Preserved ringVolume missing" }
if ($updatedContent -notmatch "101=Reception Desk") { throw "Test Failed: Preserved [Contacts] section missing" }
if ($updatedContent -notmatch "102=Billing Department") { throw "Test Failed: Preserved contact entry 102 missing" }

# Verify updated and trimmed Account1
if ($updatedContent -notmatch "user=305") { throw "Test Failed: Updated user=305 missing or untrimmed" }
if ($updatedContent -notmatch "authID=305") { throw "Test Failed: Updated authID=305 missing" }
if ($updatedContent -notmatch "name=Jane Smith") { throw "Test Failed: Updated name missing or untrimmed" }
if ($updatedContent -notmatch "password=NewSecurePass456") { throw "Test Failed: Updated password missing or untrimmed" }

# Test 4: Get-MicroSipExePath
$null = Get-MicroSipExePath

# Cleanup
Remove-Item $testIniDir -Recurse -Force

Write-Host "Task 4 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
