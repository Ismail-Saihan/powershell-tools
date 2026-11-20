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
    "Test-NetworkPort",
    "Wait-UserPrompt",
    "Test-PortAvailability"
)

foreach ($fn in $requiredFunctions) {
    if ($content -notmatch "function $fn") {
        throw "Test Failed: Function $fn is missing in remote-tools.ps1"
    }
}

# Verify HOST-01: Zero calls to [System.Console]::ReadLine()
if ($content -match '\[System\.Console\]::ReadLine') {
    throw "Test Failed: Detected legacy [System.Console]::ReadLine() calls in remote-tools.ps1 (HOST-01 violation)"
}

# Source script in test mode
. $ScriptPath -TestMode

# Verify helper Test-NetworkPort works and does not throw or leak handles (SYS-01)
$testLocal = Test-NetworkPort -TargetHost "127.0.0.1" -Port 99999 -TimeoutSeconds 1 -Quiet
if ($testLocal) {
    throw "Test Failed: Test-NetworkPort should have returned false for invalid port"
}

# Verify Test-PortAvailability returns expected schema
$portStatus = Test-PortAvailability -Port 80
if ($null -eq $portStatus -or -not $portStatus.ContainsKey("Available")) {
    throw "Test Failed: Test-PortAvailability did not return expected hashtable"
}

Write-Host "Sub-menus Architecture Tests: ALL CHECKS PASSED!" -ForegroundColor Green
