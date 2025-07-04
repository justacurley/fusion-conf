#!/usr/bin/env pwsh
# Simple test runner for HealthEntryClasses
# Usage: ./run-tests.ps1
(Get-Module Health*) ? (& { Remove-Module Health* -Force }) : $null
Write-Host "🧪 Running HealthEntry Classes Unit Tests..." -ForegroundColor Cyan
Write-Host ""

try {
    # Run tests with detailed output
    $result = Invoke-Pester "./HealthEntryClasses.Tests.ps1" -Output Detailed -PassThru
    
    Write-Host ""
    if ($result.FailedCount -eq 0) {
        Write-Host "✅ All tests passed! ($($result.PassedCount) passed)" -ForegroundColor Green
    } else {
        Write-Host "❌ Some tests failed! ($($result.FailedCount) failed, $($result.PassedCount) passed)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error running tests: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
