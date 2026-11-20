# Comprehensive Test Runner for Remote User PowerShell Tools Suite
$ErrorActionPreference = "Stop"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "       RUNNING FULL TEST SUITE - REMOTE POWERSHELL TOOLS          " -ForegroundColor White
Write-Host "==================================================================" -ForegroundColor Cyan

$testFiles = @(
    "test_core_engine.ps1",
    "test_openvpn_module.ps1",
    "test_microsip_module.ps1",
    "test_printer_module.ps1",
    "test_printserver_module.ps1",
    "test_publish_release.ps1",
    "test_submenus.ps1"
)

$passed = 0
$failed = 0

foreach ($test in $testFiles) {
    $fullPath = Join-Path $PSScriptRoot $test
    Write-Host "`n>>> Running: $test ..." -ForegroundColor Yellow
    try {
        & powershell -ExecutionPolicy Bypass -File $fullPath
        if ($LASTEXITCODE -ne 0) {
            throw "Script exited with code $LASTEXITCODE"
        }
        $passed++
    } catch {
        Write-Error "Test $test FAILED: $($_.Exception.Message)"
        $failed++
    }
}

# AST Syntax Check on all ps1 files
Write-Host "`n>>> Running PowerShell AST syntax analysis across all scripts..." -ForegroundColor Yellow
$allScripts = Get-ChildItem -Path (Join-Path $PSScriptRoot "..") -Filter "*.ps1" -Recurse
foreach ($script in $allScripts) {
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$errors)
    if ($errors.Count -gt 0) {
        Write-Error "Syntax error in $($script.Name): $($errors -join '; ')"
        $failed++
    } else {
        Write-Host "  [SYNTAX OK] $($script.Name)" -ForegroundColor Green
    }
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
if ($failed -eq 0) {
    Write-Host " ALL TESTS PASSED! ($passed suites passed, 0 failures)" -ForegroundColor Green
} else {
    Write-Error "TEST RUN FAILED! ($passed passed, $failed failures)"
    exit 1
}
Write-Host "==================================================================" -ForegroundColor Cyan
