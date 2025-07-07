# Updated example demonstrating the simplified data extraction functions

# Import the GetFusion module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

# Set the path to your entries.json file
$EntriesPath = "/home/data/fusion-data/entries/entries.json"

Write-Host "=== Updated Data Extraction Functions Example ===" -ForegroundColor Green

try {
    # Load the entries data once
    $entries = Get-EntriesData -entriesPath $EntriesPath

    Write-Host "`n1. Simplified data extraction - no loops needed in dashboard code:" -ForegroundColor Yellow
    
    # Get all medications across all dates with a single function call
    $allMedications = Get-MedicationData -entries $entries
    Write-Host "Total medication entries: $($allMedications.Count)"
    
    # Get all activities across all dates
    $allActivities = Get-ActivityData -entries $entries
    Write-Host "Total activity entries: $($allActivities.Count)"
    
    # Get all vitals across all dates
    $allVitals = Get-VitalsData -entries $entries
    Write-Host "Total vitals entries: $($allVitals.Count)"

    Write-Host "`n2. Sample medication data with context:" -ForegroundColor Yellow
    $allMedications | Select-Object -First 5 | Format-Table -AutoSize

    Write-Host "`n3. Sample activity data with context:" -ForegroundColor Yellow
    $allActivities | Select-Object -First 5 | Format-Table -AutoSize

    Write-Host "`n4. Sample vitals data with context:" -ForegroundColor Yellow
    $allVitals | Select-Object -First 5 | Format-Table -AutoSize

    Write-Host "`n5. Dashboard usage is now much simpler:" -ForegroundColor Yellow
    Write-Host @"
# OLD WAY (complex):
`$entries = Get-EntriesData -entriesPath `$path
`$dates = Get-DatesList -entries `$entries
`$allMedications = @()
foreach (`$date in `$dates) {
    `$dateEntry = `$entries.`$date
    `$medications = Get-DateMedicationData -date `$date -dateEntry `$dateEntry
    `$allMedications += `$medications
}

# NEW WAY (simple):
`$entries = Get-EntriesData -entriesPath `$path
`$allMedications = Get-MedicationData -entries `$entries
"@

    Write-Host "`n6. Data analysis examples:" -ForegroundColor Yellow
    
    # Medication frequency by date
    if ($allMedications.Count -gt 0) {
        $medicationsByDate = $allMedications | Group-Object Date | Sort-Object Name
        Write-Host "Medication entries by date:"
        foreach ($group in $medicationsByDate | Select-Object -First 5) {
            Write-Host "  $($group.Name): $($group.Count) medications"
        }
    }
    
    # Activity frequency by date
    if ($allActivities.Count -gt 0) {
        $activitiesByDate = $allActivities | Group-Object Date | Sort-Object Name
        Write-Host "`nActivity entries by date:"
        foreach ($group in $activitiesByDate | Select-Object -First 5) {
            Write-Host "  $($group.Name): $($group.Count) activities"
        }
    }

    Write-Host "`n7. Single-date functions still available for specific needs:" -ForegroundColor Yellow
    $dates = Get-DatesList -entries $entries
    if ($dates.Count -gt 0) {
        $firstDate = $dates[0]
        $dateEntry = $entries.$firstDate
        
        $dateMedications = Get-DateMedicationData -date $firstDate -dateEntry $dateEntry
        $dateActivities = Get-DateActivityData -date $firstDate -dateEntry $dateEntry
        $dateVitals = Get-DateVitalsData -date $firstDate -dateEntry $dateEntry
        
        Write-Host "Data for $(Convert-DateToDisplay -date $firstDate):"
        Write-Host "  Medications: $($dateMedications.Count)"
        Write-Host "  Activities: $($dateActivities.Count)"
        Write-Host "  Vitals: $($dateVitals.Count)"
    }

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Benefits of Updated Functions ===" -ForegroundColor Green
Write-Host "✅ Simplified dashboard code - no manual looping needed"
Write-Host "✅ Consistent data format with Date and Timestamp context"
Write-Host "✅ Better performance - optimized looping in module"
Write-Host "✅ Easier data analysis - all data in one collection"
Write-Host "✅ Flexible - both all-data and single-date functions available"

Write-Host "`n=== Function Summary ===" -ForegroundColor Green
Write-Host "All-Data Functions (take entries):"
Write-Host "  - Get-MedicationData: All medications across all dates"
Write-Host "  - Get-ActivityData: All activities across all dates"
Write-Host "  - Get-VitalsData: All vitals across all dates"
Write-Host ""
Write-Host "Single-Date Functions (take date + dateEntry):"
Write-Host "  - Get-DateMedicationData: Medications for one date"
Write-Host "  - Get-DateActivityData: Activities for one date"
Write-Host "  - Get-DateVitalsData: Vitals for one date"
