# GetFusion PowerShell Module
# Contains reusable functions for processing health data from unified entries schema v2.0

# Global variable to track distinct data values found during processing
$global:DistinctDataValues = @{}

# Global variable to cache the dates list for performance optimization
$global:DatesList = $null

# Import all Public functions
$PublicFunctions = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
    }
    catch {
        Write-Error "Failed to import function $($Function.FullName): $_"
    }
}

# Export all Public functions (formerly private functions are now public)
Export-ModuleMember -Function @(
    'Get-SleepChartData',
    'Get-AverageBackPain',
    'Get-TotalActivityDuration',
    'Convert-DateToDisplay',
    'Get-EntriesData',
    'Get-DatesList',
    'Sort-HealthDataByDate',
    'Set-CombinedData',
    'Get-DateMedicationData',
    'Get-DateActivityData',
    'Get-DateVitalsData',
    'Get-HealthMetrics',
    'Clear-CachedData',
    'Get-PSUCachedEntries',
    'Find-DuplicateEntries',
    'Compare-EntryData',
    'Compare-Medications',
    'Compare-PainData',
    'Compare-Activities',
    'Compare-Vitals',
    'Compare-NoteText'
)
