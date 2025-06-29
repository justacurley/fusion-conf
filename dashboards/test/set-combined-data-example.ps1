# Example demonstrating the Set-CombinedData function for dynamic health data composition

# Import the GetFusion module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

# Set the path to your entries.json file
$EntriesPath = "/home/data/fusion-data/entries/entries.json"

Write-Host "=== Set-CombinedData Function Usage Example ===" -ForegroundColor Green

try {
    # Load the base data
    $entries = Get-EntriesData -entriesPath $EntriesPath
    $dates = Get-DatesList -entries $entries

    Write-Host "`n1. Building comprehensive health data with Set-CombinedData:" -ForegroundColor Yellow
    
    # Process first few dates to demonstrate
    $comprehensiveData = @()
    foreach ($date in $dates | Select-Object -First 3) {
        $dateEntry = $entries.$date
        
        # Start with base health metrics
        $healthMetrics = Get-DateHealthMetrics -date $date -dateEntry $dateEntry
        
        if ($healthMetrics) {
            # Add medications data
            $medicationData = Get-MedicationData -date $date -dateEntry $dateEntry
            $healthMetrics = Set-CombinedData -combinedData $healthMetrics -name "Medications" -data $medicationData
            
            # Add activities data
            $activityData = Get-ActivityData -date $date -dateEntry $dateEntry
            $healthMetrics = Set-CombinedData -combinedData $healthMetrics -name "Activities" -data $activityData
            
            # Add vitals data
            $vitalsData = Get-VitalsData -date $date -dateEntry $dateEntry
            $healthMetrics = Set-CombinedData -combinedData $healthMetrics -name "Vitals" -data $vitalsData
            
            $comprehensiveData += $healthMetrics
            
            # Show what we built
            Write-Host "Date: $($healthMetrics.Date)"
            Write-Host "  MaxPain: $($healthMetrics.MaxPain)"
            Write-Host "  BackPain: $($healthMetrics.BackPain)"
            Write-Host "  Sleep: $($healthMetrics.Sleep)"
            Write-Host "  Medications: $($healthMetrics.Medications.Count) entries"
            Write-Host "  Activities: $($healthMetrics.Activities.Count) entries"
            Write-Host "  Vitals: $($healthMetrics.Vitals.Count) entries"
            Write-Host ""
        }
    }

    Write-Host "`n2. Alternative approach - building custom objects from scratch:" -ForegroundColor Yellow
    
    # You could also start with a base object and build it up
    $customHealthData = @()
    foreach ($date in $dates | Select-Object -First 2) {
        $dateEntry = $entries.$date
        
        # Start with a minimal base object
        $baseObject = [PSCustomObject]@{
            Date = Convert-DateToDisplay -date $date
        }
        
        # Add whatever data you need
        if ($dateEntry.PSObject.Properties['max_pain_level']) {
            $baseObject = Set-CombinedData -combinedData $baseObject -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
        }
        
        $medicationData = Get-MedicationData -date $date -dateEntry $dateEntry
        if ($medicationData.Count -gt 0) {
            $baseObject = Set-CombinedData -combinedData $baseObject -name "Medications" -data $medicationData
        }
        
        $customHealthData += $baseObject
        
        Write-Host "Custom object for $($baseObject.Date):"
        $baseObject | Format-List
    }

    Write-Host "`n3. Benefits of Set-CombinedData approach:" -ForegroundColor Yellow
    Write-Host "  ✅ Dynamic: Add any type of data to health objects"
    Write-Host "  ✅ Flexible: Different objects can have different properties"
    Write-Host "  ✅ Composable: Build complex objects step by step"
    Write-Host "  ✅ Extensible: Add new data types without changing core functions"
    Write-Host "  ✅ Conditional: Only add data when it exists"

    Write-Host "`n4. Use cases:" -ForegroundColor Yellow
    Write-Host "  • Dashboard-specific data: Each dashboard can add its own required data"
    Write-Host "  • Conditional data: Add optional fields only when available"
    Write-Host "  • Custom aggregations: Add computed fields like medication counts"
    Write-Host "  • Multi-source data: Combine data from different parts of entries.json"
    Write-Host "  • Report generation: Build comprehensive objects for detailed reports"

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Pattern for Using Set-CombinedData ===" -ForegroundColor Green
Write-Host @"
# 1. Start with base health metrics or create a minimal object
`$healthData = Get-DateHealthMetrics -date `$date -dateEntry `$dateEntry

# 2. Add additional data as needed
`$healthData = Set-CombinedData -combinedData `$healthData -name "Medications" -data `$medicationArray
`$healthData = Set-CombinedData -combinedData `$healthData -name "Activities" -data `$activityArray
`$healthData = Set-CombinedData -combinedData `$healthData -name "CustomMetric" -data `$computedValue

# 3. Result: Flexible, comprehensive health data object
"@
