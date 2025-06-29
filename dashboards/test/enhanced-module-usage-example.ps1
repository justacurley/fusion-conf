# Enhanced example script showing the new modular GetFusion functions

# Import the GetFusion module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

# Set the path to your entries.json file
$EntriesPath = "/home/data/fusion-data/entries/entries.json"

Write-Host "=== Enhanced GetFusion Module Usage Example ===" -ForegroundColor Green

try {
    # Example 1: Using the main Get-HealthData function (same as before)
    Write-Host "`n1. Getting comprehensive health data (main function):" -ForegroundColor Yellow
    $healthData = Get-HealthData -entriesPath $EntriesPath
    Write-Host "Found $($healthData.Count) days of data"
    $healthData | Select-Object -First 3 | Format-Table -AutoSize

    # Example 2: Using the new modular functions step by step
    Write-Host "`n2. Using modular functions step by step:" -ForegroundColor Yellow
    
    # Load entries data
    $entries = Get-EntriesData -entriesPath $EntriesPath
    Write-Host "Loaded entries data with $($entries.PSObject.Properties.Count) dates"
    
    # Get sorted dates list
    $dates = Get-DatesList -entries $entries
    Write-Host "Date range: $($dates[0]) to $($dates[-1])"
    
    # Process individual dates
    Write-Host "`nProcessing individual dates:"
    $customHealthData = @()
    foreach ($date in $dates | Select-Object -First 5) {  # Just first 5 for demo
        $dateEntry = $entries.$date
        $metrics = Get-DateHealthMetrics -date $date -dateEntry $dateEntry
        
        if ($metrics) {
            $customHealthData += $metrics
            Write-Host "  $($metrics.Date): Pain=$($metrics.MaxPain), BackPain=$($metrics.BackPain), Sleep=$($metrics.Sleep)"
        }
    }
    
    # Sort the data
    $sortedData = Sort-HealthDataByDate -healthData $customHealthData
    Write-Host "Sorted $($sortedData.Count) health records"

    # Example 3: Building custom data extractors (example template)
    Write-Host "`n3. Template for custom data extraction functions:" -ForegroundColor Yellow
    Write-Host @"
# Example: Custom function to extract medication data
function Get-MedicationMetrics {
    param([string]`$date, `$dateEntry)
    
    `$medications = @()
    foreach (`$timestamp in `$dateEntry.PSObject.Properties.Name) {
        if (`$timestamp -match '^\d{4}$') {
            `$entry = `$dateEntry.`$timestamp
            if (`$entry.PSObject.Properties['Medications']) {
                `$medications += `$entry.Medications
            }
        }
    }
    
    return `$medications
}

# Example: Custom function to extract activity data
function Get-ActivityMetrics {
    param([string]`$date, `$dateEntry)
    
    `$activities = @()
    foreach (`$timestamp in `$dateEntry.PSObject.Properties.Name) {
        if (`$timestamp -match '^\d{4}$') {
            `$entry = `$dateEntry.`$timestamp
            if (`$entry.PSObject.Properties['Activities']) {
                `$activities += `$entry.Activities
            }
        }
    }
    
    return `$activities
}
"@

    Write-Host "`n4. Available modular functions:" -ForegroundColor Yellow
    Write-Host "Core Functions:"
    Write-Host "  - Get-HealthData: Main function (unchanged interface)"
    Write-Host "  - Get-SleepHours: Parse sleep data"
    Write-Host "  - Get-AverageBackPain: Calculate back pain averages"
    Write-Host "  - Convert-DateToDisplay: Date format conversion"
    Write-Host ""
    Write-Host "New Modular Functions:"
    Write-Host "  - Get-EntriesData: Load and parse entries.json"
    Write-Host "  - Get-DatesList: Get sorted list of dates"
    Write-Host "  - Get-DateHealthMetrics: Process single date entry"
    Write-Host "  - Sort-HealthDataByDate: Sort health data chronologically"
    
    Write-Host "`n5. Benefits of the refactored approach:" -ForegroundColor Yellow
    Write-Host "  ✅ Modular: Each function has a single responsibility"
    Write-Host "  ✅ Reusable: Use individual functions for custom data extraction"
    Write-Host "  ✅ Testable: Easy to test each function independently"
    Write-Host "  ✅ Extensible: Add new data extractors following the same pattern"
    Write-Host "  ✅ Maintainable: Changes to one part don't affect others"

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "You can now easily add new data extraction functions by:"
Write-Host "1. Creating functions like Get-MedicationMetrics, Get-ActivityMetrics, etc."
Write-Host "2. Using Get-EntriesData and Get-DatesList to get the base data"
Write-Host "3. Processing individual dates with your custom logic"
Write-Host "4. Using Sort-HealthDataByDate to sort results if needed"
