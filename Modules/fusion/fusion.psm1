# fusion PowerShell Module
# Version: 2.0
# Author: Alex W. McCurley
# Email: alexwmccurley@gmail.com
# Dependencies: HealthEntryClasses module

# Import required classes for type validation
using module ../HealthEntryClasses/HealthEntryClasses.psm1

Write-Information "Loading fusion module v2.0..."

# Get the module root directory
$ModuleRoot = $PSScriptRoot

# Load all public functions
$PublicFunctions = @(Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue)

# Dot source all public functions
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Information "Loaded function: $($Function.BaseName)"
    }
    catch {
        Write-Error "Failed to load function $($Function.FullName): $($_.Exception.Message)"
    }
}

# Export all public functions
if ($PublicFunctions.Count -gt 0) {
    $FunctionNames = $PublicFunctions | ForEach-Object { $_.BaseName }
    Export-ModuleMember -Function $FunctionNames
    Write-Information "Exported $($FunctionNames.Count) public functions: $($FunctionNames -join ', ')"
}
else {
    Write-Warning "No public functions found to export from fusion module"
}

Write-Information "fusion module v2.0 loaded successfully"