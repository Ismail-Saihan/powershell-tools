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

# Test 1: Call Set-MicroSipConfig matching the user's exact screenshot configuration
Set-MicroSipConfig -IniPath $testIniPath `
                   -Extension "1054" `
                   -FullName "Ismail Hossain Saihan[IT]" `
                   -DisplayName "Ismail-IT" `
                   -Password "SecretPass123" `
                   -SipServer "182.163.126.250" `
                   -SipPort 5060

if (-not (Test-Path $testIniPath)) {
    throw "Test Failed: MicroSIP.ini was not created"
}

$iniContent = Get-Content $testIniPath -Raw
if ($iniContent -notmatch "label=1054- Ismail Hossain Saihan\[IT\]") { throw "Test Failed: label=1054- Ismail Hossain Saihan[IT] missing" }
if ($iniContent -notmatch "user=1054") { throw "Test Failed: user=1054 missing" }
if ($iniContent -notmatch "username=1054") { throw "Test Failed: username=1054 missing" }
if ($iniContent -notmatch "authID=1054") { throw "Test Failed: authID=1054 missing" }
if ($iniContent -notmatch "domain=182\.163\.126\.250") { throw "Test Failed: domain missing" }
if ($iniContent -notmatch "server=182\.163\.126\.250:5060") { throw "Test Failed: server IP:port missing" }
if ($iniContent -notmatch "proxy=182\.163\.126\.250:5060") { throw "Test Failed: proxy IP:port missing" }
if ($iniContent -notmatch "password=SecretPass123") { throw "Test Failed: password missing" }
if ($iniContent -notmatch "displayName=Ismail-IT") { throw "Test Failed: displayName=Ismail-IT missing" }
if ($iniContent -notmatch "name=Ismail-IT") { throw "Test Failed: name=Ismail-IT missing" }
if ($iniContent -notmatch "publish=1") { throw "Test Failed: publish=1 missing" }
if ($iniContent -notmatch "keepAlive=15") { throw "Test Failed: keepAlive=15 missing" }
if ($iniContent -notmatch "regInterval=300") { throw "Test Failed: regInterval=300 missing" }
if ($iniContent -notmatch "transport=0") { throw "Test Failed: transport=0 missing" }
if ($iniContent -notmatch "srtp=0") { throw "Test Failed: srtp=0 missing" }
if ($iniContent -notmatch "accountId=1") { throw "Test Failed: accountId=1 missing in Settings" }
if ($iniContent -notmatch "autoStart=1") { throw "Test Failed: autoStart missing" }
if ($iniContent -notmatch "autoRecording=1") { throw "Test Failed: autoRecording=1 missing" }
if ($iniContent -notmatch "updatesInterval=never") { throw "Test Failed: updatesInterval=never missing" }
if ($iniContent -notmatch "recordingFormat=mp3") { throw "Test Failed: recordingFormat=mp3 missing" }
if ($iniContent -notmatch "recordingButton=1") { throw "Test Failed: recordingButton=1 missing" }

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
                   -FullName "  Jane Smith  " `
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
if ($updatedContent -notmatch "label=305- Jane Smith") { throw "Test Failed: Updated label missing or untrimmed" }
if ($updatedContent -notmatch "user=305") { throw "Test Failed: Updated user=305 missing or untrimmed" }
if ($updatedContent -notmatch "username=305") { throw "Test Failed: Updated username=305 missing or untrimmed" }
if ($updatedContent -notmatch "authID=305") { throw "Test Failed: Updated authID=305 missing" }
if ($updatedContent -notmatch "displayName=Jane Smith") { throw "Test Failed: Updated displayName missing or untrimmed" }
if ($updatedContent -notmatch "name=Jane Smith") { throw "Test Failed: Updated name missing or untrimmed" }
if ($updatedContent -notmatch "password=NewSecurePass456") { throw "Test Failed: Updated password missing or untrimmed" }
if ($updatedContent -notmatch "accountId=1") { throw "Test Failed: accountId=1 missing in updated Settings" }

# Verify call recording and updates interval enforced on existing INI
if ($updatedContent -notmatch "autoRecording=1") { throw "Test Failed: autoRecording=1 missing in updated INI" }
if ($updatedContent -notmatch "updatesInterval=never") { throw "Test Failed: updatesInterval=never missing in updated INI" }

# Test 4: Get-MicroSipExePath
$null = Get-MicroSipExePath

# Cleanup
Remove-Item $testIniDir -Recurse -Force

Write-Host "Task 4 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
