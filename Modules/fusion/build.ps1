#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build and test script for the Fusion PowerShell module.

.DESCRIPTION
    This script provides common development tasks for the Fusion module:
    - Running tests
    - Running tests with code coverage analysis
    - Generating HTML coverage reports
    - Validating module manifest
    - Installing/importing the module
    - Generating documentation

.PARAMETER Task
    The task to perform: Test, TestWithCoverage, CoverageReport, Validate, Install, Import, or All

.EXAMPLE
    ./build.ps1 -Task Test
    ./build.ps1 -Task TestWithCoverage
    ./build.ps1 -Task CoverageReport
    ./build.ps1 -Task All
#>

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Test", "TestWithCoverage", "CoverageReport", "Validate", "Install", "Import", "All")]
    [string]$Task = "All"
)

$ModulePath = $PSScriptRoot
$ModuleName = "fusion"
$ManifestPath = Join-Path $ModulePath "$ModuleName.psd1"
$TestPath = Join-Path $ModulePath "tests/$ModuleName.Tests.ps1"

function Write-TaskHeader {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Test-Module {
    param([switch]$WithCoverage)
    
    if ($WithCoverage) {
        Write-TaskHeader "Running Pester Tests with Code Coverage"
    } else {
        Write-TaskHeader "Running Pester Tests"
    }
    
    if (-not (Test-Path $TestPath)) {
        Write-Error "Test file not found: $TestPath"
        return $false
    }
    
    try {
        if ($WithCoverage) {
            # Configure code coverage for the main module file
            $coverageFiles = @(
                Join-Path $ModulePath "$ModuleName.psm1"
            )
            
            $pesterConfig = New-PesterConfiguration
            $pesterConfig.Run.Path = $TestPath
            $pesterConfig.Run.PassThru = $true
            $pesterConfig.Output.Verbosity = 'Detailed'
            $pesterConfig.CodeCoverage.Enabled = $true
            $pesterConfig.CodeCoverage.Path = $coverageFiles
            $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
            $pesterConfig.CodeCoverage.OutputPath = Join-Path $ModulePath 'coverage.xml'
            
            $result = Invoke-Pester -Configuration $pesterConfig
            
            # Display code coverage results
            if ($result.CodeCoverage) {
                $coverage = $result.CodeCoverage
                
                # Use the correct property names for Pester 5.x
                $totalCommands = $coverage.CommandsAnalyzedCount
                $coveredCommands = $coverage.CommandsExecutedCount
                $coveredPercent = $coverage.CoveragePercent
                
                if ($totalCommands -and $totalCommands -gt 0) {
                    Write-Host "📊 Code Coverage: $([math]::Round($coveredPercent, 2))% ($coveredCommands/$totalCommands commands)" -ForegroundColor Cyan
                    
                    if ($coveredPercent -ge 90) {
                        Write-Host "🎯 Excellent coverage!" -ForegroundColor Green
                    } elseif ($coveredPercent -ge 80) {
                        Write-Host "👍 Good coverage!" -ForegroundColor Yellow
                    } elseif ($coveredPercent -ge 60) {
                        Write-Host "✅ Decent coverage!" -ForegroundColor Cyan
                    } else {
                        Write-Host "⚠️  Consider adding more tests" -ForegroundColor Red
                    }
                } else {
                    Write-Host "📊 No code coverage data available" -ForegroundColor Yellow
                }
                
                # Show missed commands if any
                $missedCommands = $coverage.CommandsMissed
                if ($missedCommands -and $missedCommands.Count -gt 0) {
                    Write-Host "`n🔍 Top missed commands:" -ForegroundColor Yellow
                    $missedCommands | Select-Object -First 5 | ForEach-Object {
                        Write-Host "   Line $($_.Line): $($_.Command)" -ForegroundColor Gray
                    }
                    if ($missedCommands.Count -gt 5) {
                        Write-Host "   ... and $($missedCommands.Count - 5) more (see coverage.xml for details)" -ForegroundColor Gray
                    }
                }
            }
        } else {
            # Simple test run without coverage
            $result = Invoke-Pester $TestPath -PassThru -Output Detailed
        }
        
        if ($result.FailedCount -eq 0) {
            Write-Host "✅ All tests passed! ($($result.PassedCount) tests)" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ $($result.FailedCount) tests failed!" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Error "Failed to run tests: $_"
        return $false
    }
}

function Test-Manifest {
    Write-TaskHeader "Validating Module Manifest"
    
    try {
        $manifest = Test-ModuleManifest -Path $ManifestPath -Verbose:$false
        Write-Host "✅ Module manifest is valid" -ForegroundColor Green
        Write-Host "   Version: $($manifest.Version)" -ForegroundColor Gray
        Write-Host "   Author: $($manifest.Author)" -ForegroundColor Gray
        Write-Host "   Functions: $($manifest.ExportedFunctions.Count)" -ForegroundColor Gray
        return $true
    } catch {
        Write-Error "❌ Module manifest validation failed: $_"
        return $false
    }
}

function Install-ModuleLocal {
    Write-TaskHeader "Installing Module Locally"
    
    $userModulesPath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "PowerShell/Modules/$ModuleName"
    
    try {
        if (Test-Path $userModulesPath) {
            Remove-Item $userModulesPath -Recurse -Force
            Write-Host "Removed existing module installation" -ForegroundColor Yellow
        }
        
        New-Item -Path $userModulesPath -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$ModulePath/*" -Destination $userModulesPath -Recurse -Force
        
        Write-Host "✅ Module installed to: $userModulesPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "❌ Failed to install module: $_"
        return $false
    }
}

function Import-ModuleLocal {
    Write-TaskHeader "Importing Module"
    
    try {
        Import-Module $ManifestPath -Force
        Write-Host "✅ Module imported successfully" -ForegroundColor Green
        
        $commands = Get-Command -Module $ModuleName
        Write-Host "   Available commands: $($commands.Count)" -ForegroundColor Gray
        $commands | ForEach-Object { Write-Host "     - $($_.Name)" -ForegroundColor Gray }
        return $true
    } catch {
        Write-Error "❌ Failed to import module: $_"
        return $false
    }
}

function New-CoverageReport {
    Write-TaskHeader "Generating HTML Coverage Report"
    
    $coverageXml = Join-Path $ModulePath 'coverage.xml'
    $reportPath = Join-Path $ModulePath 'coverage-report'
    
    if (-not (Test-Path $coverageXml)) {
        Write-Warning "No coverage.xml found. Run tests with coverage first."
        Write-Host "Try: ./build.ps1 -Task TestWithCoverage" -ForegroundColor Yellow
        return $false
    }
    
    try {
        # Check if ReportGenerator is available
        if (-not (Get-Command reportgenerator -ErrorAction SilentlyContinue)) {
            Write-Host "Installing ReportGenerator tool..." -ForegroundColor Yellow
            dotnet tool install --global dotnet-reportgenerator-globaltool
        }
        
        # Generate HTML report
        if (Test-Path $reportPath) {
            Remove-Item $reportPath -Recurse -Force
        }
        
        & reportgenerator "-reports:$coverageXml" "-targetdir:$reportPath" "-reporttypes:Html;Badges"
        
        $indexPath = Join-Path $reportPath 'index.html'
        if (Test-Path $indexPath) {
            Write-Host "✅ Coverage report generated: $indexPath" -ForegroundColor Green
            Write-Host "🌐 Open in browser: file://$indexPath" -ForegroundColor Cyan
            return $true
        } else {
            Write-Error "Failed to generate coverage report"
            return $false
        }
    } catch {
        Write-Warning "ReportGenerator not available. Install with:"
        Write-Host "dotnet tool install --global dotnet-reportgenerator-globaltool" -ForegroundColor Yellow
        
        # Alternative: Generate simple HTML report manually
        Write-Host "Generating basic coverage summary..." -ForegroundColor Yellow
        $summaryPath = Join-Path $ModulePath 'coverage-summary.html'
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Fusion Module - Code Coverage Summary</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; }
        .coverage { font-size: 24px; font-weight: bold; color: #2e8b57; }
        .note { margin-top: 20px; padding: 10px; background: #fff3cd; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Fusion Module - Code Coverage</h1>
        <div class="coverage">Coverage report available in coverage.xml (JaCoCo format)</div>
    </div>
    <div class="note">
        <strong>Note:</strong> For detailed HTML reports, install ReportGenerator:<br>
        <code>dotnet tool install --global dotnet-reportgenerator-globaltool</code>
    </div>
    <p><strong>Coverage file:</strong> <code>$coverageXml</code></p>
    <p><strong>Generated:</strong> $(Get-Date)</p>
</body>
</html>
"@
        $htmlContent | Out-File $summaryPath -Encoding UTF8
        Write-Host "✅ Basic summary generated: $summaryPath" -ForegroundColor Green
        return $true
    }
}

# Main execution
Write-Host "Fusion PowerShell Module Build Script" -ForegroundColor Magenta
Write-Host "Module Path: $ModulePath" -ForegroundColor Gray

$success = $true

switch ($Task) {
    "Test" { $success = Test-Module }
    "TestWithCoverage" { $success = Test-Module -WithCoverage }
    "Validate" { $success = Test-Manifest }
    "Install" { $success = Install-ModuleLocal }
    "Import" { $success = Import-ModuleLocal }
    "CoverageReport" { $success = New-CoverageReport }
    "All" {
        $success = Test-Manifest
        if ($success) { $success = Test-Module -WithCoverage }
        if ($success) { $success = Import-ModuleLocal }
        if ($success) { $success = New-CoverageReport }
    }
}

if ($success) {
    Write-Host "`n🎉 Task '$Task' completed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n💥 Task '$Task' failed!" -ForegroundColor Red
    exit 1
}
