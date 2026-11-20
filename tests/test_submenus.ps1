# Unit Test for Sub-menus Architecture
$ErrorActionPreference = "Stop"

Write-Host "Running Sub-menus Architecture Tests..." -ForegroundColor Cyan

$ScriptPath = Join-Path $PSScriptRoot "..\remote-tools.ps1"
$content = Get-Content $ScriptPath -Raw

# Check all submenu functions exist
$requiredFunctions = @(
    "Show-OpenVpnMenu",
    "Show-VoipMenu",
    "Show-PrinterDriverMenu",
    "Show-PrintServerMenu",
    "Test-NetworkPort"
)

foreach ($fn in $requiredFunctions) {
    if ($content -notmatch "function $fn") {
        throw "Test Failed: Function $fn is missing in remote-tools.ps1"
    }
}

# Source script in test mode
. $ScriptPath -TestMode

# Verify helper Test-NetworkPort works
$testLocal = Test-NetworkPort -TargetHost "127.0.0.1" -Port 99999 -TimeoutSeconds 1 -Quiet
if ($testLocal) {
    throw "Test Failed: Test-NetworkPort should have returned false for invalid port"
}

Write-Host "Sub-menus Architecture Tests: ALL CHECKS PASSED!" -ForegroundColor Green
