# Unit Test for Task 5: Printer Driver Module
$ErrorActionPreference = "Stop"

Write-Host "Running Task 5 Tests..." -ForegroundColor Cyan

$ScriptPath = Join-Path $PSScriptRoot "..\remote-tools.ps1"
$content = Get-Content $ScriptPath -Raw

if ($content -notmatch "function Show-PrinterDriverMenu") {
    throw "Test Failed: Show-PrinterDriverMenu function missing"
}
if ($content -notmatch "function Install-PrinterDriver") {
    throw "Test Failed: Install-PrinterDriver function missing"
}

# Source script in test mode
. $ScriptPath -TestMode

# Check driver definition table
if (-not $global:PrinterDrivers -or $global:PrinterDrivers.Count -lt 3) {
    throw "Test Failed: Printer driver definition table missing or incomplete"
}

$gprinter = $global:PrinterDrivers["1"]
if ($gprinter.Filename -ne "Gprinter Driver.exe") {
    throw "Test Failed: Gprinter filename mismatch ($($gprinter.Filename))"
}

$rongta = $global:PrinterDrivers["2"]
if ($rongta.Filename -ne "Rongta Driver.exe") {
    throw "Test Failed: Rongta filename mismatch ($($rongta.Filename))"
}

$dotmax = $global:PrinterDrivers["3"]
if ($dotmax.Filename -ne "Dotmax Printer Driver.exe") {
    throw "Test Failed: Dotmax filename mismatch ($($dotmax.Filename))"
}

Write-Host "Task 5 Tests: ALL CHECKS PASSED!" -ForegroundColor Green
