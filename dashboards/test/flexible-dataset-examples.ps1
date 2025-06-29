# Example: Building Custom Combined Datasets with the Flexible GetFusion Module

# Import the GetFusion module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

# Set the path to your entries.json file
$EntriesPath = "/home/data/fusion-data/entries/entries.json"

Write-Host "=== Building Custom Combined Datasets ===" -ForegroundColor Green

try {
    # Load the base data
    $entries = Get-EntriesData -entriesPath $EntriesPath
    $dates = Get-DatesList -entries $entries

    Write-Host "`n1. Example: Building a Pain & Sleep Dataset" -ForegroundColor Yellow
    
    $painSleepData = @()
    foreach ($date in $dates) {
        $dateEntry = $entries.$date
        
        # Only process dates that have max_pain_level
        if ($dateEntry.PSObject.Properties['max_pain_level']) {
            $baseObject = [PSCustomObject]@{
                Date = Convert-DateToDisplay -date $date
                MaxPain = [double]$dateEntry.max_pain_level
            }
            
            # Add sleep data if available
            if ($dateEntry.PSObject.Properties['Sleep']) {
                $sleepHours = Get-SleepHours -sleepValue $dateEntry.Sleep
                $baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data $sleepHours
            }
            
            # Add average back pain
            $avgBackPain = Get-AverageBackPain -dateEntry $dateEntry
            if ($avgBackPain) {
                $baseObject = Set-CombinedData -combinedData $baseObject -name "BackPain" -data $avgBackPain
            }
            
            $painSleepData += $baseObject
        }
    }
    
    # Sort the data
    $painSleepData = Sort-HealthDataByDate -healthData $painSleepData
    
    Write-Host "Pain & Sleep Dataset: $($painSleepData.Count) entries"
    $painSleepData | Select-Object -First 5 | Format-Table -AutoSize

    Write-Host "`n2. Example: Building a Medication Tracking Dataset" -ForegroundColor Yellow
    
    $medicationTrackingData = @()
    $allMedications = Get-MedicationData -entries $entries
    
    # Group medications by date and create summary
    $medicationsByDate = $allMedications | Group-Object Date
    foreach ($dateGroup in $medicationsByDate) {
        $medicationSummary = [PSCustomObject]@{
            Date = $dateGroup.Name
            MedicationCount = $dateGroup.Count
            MedicationList = ($dateGroup.Group.Medication -join ", ")
        }
        
        # Add pain data for correlation if available
        $dateKey = $dateGroup.Name -replace "/", ""
        if ($dateKey.Length -eq 3) { $dateKey = "0" + $dateKey }  # Pad single digit months
        
        if ($entries.PSObject.Properties[$dateKey]) {
            $dateEntry = $entries.$dateKey
            if ($dateEntry.PSObject.Properties['max_pain_level']) {
                $medicationSummary = Set-CombinedData -combinedData $medicationSummary -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
            }
        }
        
        $medicationTrackingData += $medicationSummary
    }
    
    $medicationTrackingData = Sort-HealthDataByDate -healthData $medicationTrackingData
    
    Write-Host "Medication Tracking Dataset: $($medicationTrackingData.Count) entries"
    $medicationTrackingData | Select-Object -First 5 | Format-Table -AutoSize

    Write-Host "`n3. Example: Building a Comprehensive Daily Summary Dataset" -ForegroundColor Yellow
    
    $dailySummaryData = @()
    foreach ($date in $dates) {
        $dateEntry = $entries.$date
        
        $dailySummary = [PSCustomObject]@{
            Date = Convert-DateToDisplay -date $date
        }
        
        # Add pain data
        if ($dateEntry.PSObject.Properties['max_pain_level']) {
            $dailySummary = Set-CombinedData -combinedData $dailySummary -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
        }
        
        # Add sleep data
        if ($dateEntry.PSObject.Properties['Sleep']) {
            $sleepHours = Get-SleepHours -sleepValue $dateEntry.Sleep
            $dailySummary = Set-CombinedData -combinedData $dailySummary -name "Sleep" -data $sleepHours
        }
        
        # Add medication count for the day
        $dayMedications = Get-DateMedicationData -date $date -dateEntry $dateEntry
        $dailySummary = Set-CombinedData -combinedData $dailySummary -name "MedicationCount" -data $dayMedications.Count
        
        # Add activity count for the day
        $dayActivities = Get-DateActivityData -date $date -dateEntry $dateEntry
        $dailySummary = Set-CombinedData -combinedData $dailySummary -name "ActivityCount" -data $dayActivities.Count
        
        # Add vitals count for the day
        $dayVitals = Get-DateVitalsData -date $date -dateEntry $dateEntry
        $dailySummary = Set-CombinedData -combinedData $dailySummary -name "VitalsCount" -data $dayVitals.Count
        
        $dailySummaryData += $dailySummary
    }
    
    $dailySummaryData = Sort-HealthDataByDate -healthData $dailySummaryData
    
    Write-Host "Daily Summary Dataset: $($dailySummaryData.Count) entries"
    $dailySummaryData | Select-Object -First 5 | Format-Table -AutoSize

    Write-Host "`n4. Example: Activity & Pain Correlation Dataset" -ForegroundColor Yellow
    
    $activityPainData = @()
    $allActivities = Get-ActivityData -entries $entries
    
    # Group activities by date
    $activitiesByDate = $allActivities | Group-Object Date
    foreach ($dateGroup in $activitiesByDate) {
        $activitySummary = [PSCustomObject]@{
            Date = $dateGroup.Name
            ActivityCount = $dateGroup.Count
            Activities = ($dateGroup.Group.Activity -join "; ")
        }
        
        # Add pain correlation data
        $dateKey = $dateGroup.Name -replace "/", ""
        if ($dateKey.Length -eq 3) { $dateKey = "0" + $dateKey }
        
        if ($entries.PSObject.Properties[$dateKey]) {
            $dateEntry = $entries.$dateKey
            if ($dateEntry.PSObject.Properties['max_pain_level']) {
                $activitySummary = Set-CombinedData -combinedData $activitySummary -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
            }
            
            $avgBackPain = Get-AverageBackPain -dateEntry $dateEntry
            if ($avgBackPain) {
                $activitySummary = Set-CombinedData -combinedData $activitySummary -name "AvgBackPain" -data $avgBackPain
            }
        }
        
        $activityPainData += $activitySummary
    }
    
    $activityPainData = Sort-HealthDataByDate -healthData $activityPainData
    
    Write-Host "Activity & Pain Correlation Dataset: $($activityPainData.Count) entries"
    $activityPainData | Select-Object -First 5 | Format-Table -AutoSize

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Flexible Module Benefits ===" -ForegroundColor Green
Write-Host "✅ No opinionated default datasets - build exactly what you need"
Write-Host "✅ Composable functions - mix and match data types"
Write-Host "✅ Set-CombinedData allows dynamic property addition"
Write-Host "✅ Sort-HealthDataByDate works with any dataset containing Date property"
Write-Host "✅ Specific data extractors for targeted analysis"
Write-Host "✅ Both all-data and single-date functions available"

Write-Host "`n=== Pattern for Custom Datasets ===" -ForegroundColor Green
Write-Host @"
# 1. Load base data
`$entries = Get-EntriesData -entriesPath `$path
`$dates = Get-DatesList -entries `$entries

# 2. Build your custom dataset
`$customData = @()
foreach (`$date in `$dates) {
    `$baseObject = [PSCustomObject]@{ Date = Convert-DateToDisplay -date `$date }
    
    # Add whatever data you need
    `$baseObject = Set-CombinedData -combinedData `$baseObject -name "SomeData" -data `$someValue
    `$baseObject = Set-CombinedData -combinedData `$baseObject -name "OtherData" -data `$otherValue
    
    `$customData += `$baseObject
}

# 3. Sort if needed
`$customData = Sort-HealthDataByDate -healthData `$customData
"@
