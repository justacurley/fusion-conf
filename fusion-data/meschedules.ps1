$EntriesPath = "$PSScriptRoot\entries.json"
$Schedules = [PSCustomObject]@{
    StartDate = "0604"
    EndDate   = "0609"
    MedSchedule = [PSCustomObject]@{
        "0800" = [PSCustomObject]@{
            dilaudid = "4mg"
            tylenol   = "1g"
        }
        "1000" = [PSCustomObject]@{
            valium = "5mg"
        }
        "1200" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "1400" = [PSCustomObject]@{
            tylenol = "1g"
        }
        "1600" = [PSCustomObject]@{
            dilaudid = "4mg"
            valium  = "5mg"
            vitaminD = "500mg"
        }
        "2100" = [PSCustomObject]@{
            dilaudid = "4mg"
            tylenol   = "1g"
        }
        "2200" = [PSCustomObject]@{
            lexapro = "20mg"
            valium  = "5mg"
        }
    }
},[PSCustomObject]@{
    StartDate = "0610"
    EndDate   = "0623"
    MedSchedule = [PSCustomObject]@{
        "0800" = [PSCustomObject]@{
            dilaudid = "4mg"
            tylenol   = "1g"
        }
        "1000" = [PSCustomObject]@{
            valium = "5mg"
        }
        "1300" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "1400" = [PSCustomObject]@{
            tylenol = "1g"
        }
        "1800" = [PSCustomObject]@{
            dilaudid = "4mg"
            vitaminD = "500mg"
        }
        "2100" = [PSCustomObject]@{
            tylenol   = "1g"
        }
        "2200" = [PSCustomObject]@{
            lexapro = "20mg"
            dilaudid = "4mg"
            valium  = "5mg"
        }
    }
},[PSCustomObject]@{
    StartDate = "0624"
    EndDate   = "0701"
    MedSchedule = [PSCustomObject]@{
        "0800" = [PSCustomObject]@{
            tylenol   = "1g"
        }
        "0900" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "1400" = [PSCustomObject]@{
            dilaudid = "4mg"
            tylenol = "1g"
        }
        "2100" = [PSCustomObject]@{
            dilaudid = "4mg"
            tylenol   = "1g"
        }
        "2200" = [PSCustomObject]@{
            lexapro = "20mg"
            valium  = "5mg"
        }
    }
},[PSCustomObject]@{
    StartDate = "0520"
    EndDate   = "0531"
    MedSchedule = [PSCustomObject]@{
        "0000" = [PSCustomObject]@{
            dilaudid   = "4mg"
        }
        "0400" = [PSCustomObject]@{
            dilaudid   = "4mg"
        }
        "0800" = [PSCustomObject]@{
            tylenol   = "1g"
            dilaudid = "4mg"
        }
        "1000" = [PSCustomObject]@{
            valium = "5mg"
        }
        "1200" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "1400" = [PSCustomObject]@{
            tylenol = "1g"
        }
        "1600" = [PSCustomObject]@{
            valium = "5mg"
            dilaudid = "4mg"
        }
        "1800" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "2000" = [PSCustomObject]@{
            tylenol   = "1g"
        }
        "2200" = [PSCustomObject]@{
            lexapro = "20mg"
            dilaudid = "4mg"
            valium  = "5mg"
        }
    }
},[PSCustomObject]@{
    StartDate = "0601"
    EndDate   = "0603"
    MedSchedule = [PSCustomObject]@{
        "0000" = [PSCustomObject]@{
            dilaudid   = "4mg"
        }
        "0800" = [PSCustomObject]@{
            tylenol   = "1g"
            dilaudid = "4mg"
        }
        "1000" = [PSCustomObject]@{
            valium = "5mg"
        }
        "1200" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "1400" = [PSCustomObject]@{
            tylenol = "1g"
        }
        "1600" = [PSCustomObject]@{
            valium = "5mg"
            dilaudid = "4mg"
        }
        "1800" = [PSCustomObject]@{
            dilaudid = "4mg"
        }
        "2000" = [PSCustomObject]@{
            tylenol   = "1g"
        }
        "2200" = [PSCustomObject]@{
            lexapro = "20mg"
            dilaudid = "4mg"
            valium  = "5mg"
        }
    }
}

# Function to update entries.json with missing Medications based on schedules
function Update-EntriesWithMedications {
    param(
        [string]$EntriesPath = "$PSScriptRoot\entries.json",
        [array]$MedicationSchedules = $Schedules,
        [switch]$Debug
    )
    
    try {
        # Read the entries file
        $entries = Get-Content -Path $EntriesPath -Raw | ConvertFrom-Json
        $updatedCount = 0
        $createdTimestamps = 0
        $addedMedications = 0
        $totalEntries = 0
        $matchedSchedules = 0
        
        if ($Debug) {
            Write-Host "Debug: Found $($entries.PSObject.Properties.Name.Count) date entries" -ForegroundColor Magenta
        }
        
        # Process each date in entries
        foreach ($dateKey in $entries.PSObject.Properties.Name) {
            # Skip non-date entries (like max_pain_level)
            if ($dateKey -notmatch '^\d{4}$') { 
                if ($Debug) { Write-Host "Debug: Skipping non-date key: $dateKey" -ForegroundColor Yellow }
                continue 
            }
            
            if ($Debug) { Write-Host "Debug: Processing date: $dateKey" -ForegroundColor Cyan }
            
            $dateEntry = $entries.$dateKey
            
            # Find the applicable medication schedule for this date
            $applicableSchedule = $null
            foreach ($schedule in $MedicationSchedules) {
                if ($dateKey -ge $schedule.StartDate -and $dateKey -le $schedule.EndDate) {
                    $applicableSchedule = $schedule
                    $matchedSchedules++
                    if ($Debug) { Write-Host "  Debug: Found schedule for $dateKey ($($schedule.StartDate) to $($schedule.EndDate))" -ForegroundColor Green }
                    break
                }
            }
            
            if (-not $applicableSchedule) {
                if ($Debug) { Write-Host "  Debug: No medication schedule found for date: $dateKey" -ForegroundColor Red }
                continue
            }
            
            # Process each scheduled timestamp for this date
            foreach ($scheduledTime in $applicableSchedule.MedSchedule.PSObject.Properties.Name) {
                $scheduledMeds = $applicableSchedule.MedSchedule.$scheduledTime
                
                # Check if timestamp entry exists
                if (-not $dateEntry.PSObject.Properties[$scheduledTime]) {
                    # Create missing timestamp entry
                    if ($Debug) { Write-Host "    Debug: Creating missing timestamp entry: $scheduledTime" -ForegroundColor Magenta }
                    
                    # Create new timestamp entry with basic structure
                    $newTimestampEntry = [PSCustomObject]@{
                        bpr = ""
                        medication_taken = ""
                        Activities = [PSCustomObject]@{}
                        Pain = [PSCustomObject]@{}
                        note = ""
                        Medications = [PSCustomObject]@{}
                        o2 = ""
                    }
                    
                    # Add scheduled medications
                    foreach ($medProp in $scheduledMeds.PSObject.Properties) {
                        $newTimestampEntry.Medications | Add-Member -NotePropertyName $medProp.Name -NotePropertyValue $medProp.Value
                    }
                    
                    # Add to date entry
                    $dateEntry | Add-Member -NotePropertyName $scheduledTime -NotePropertyValue $newTimestampEntry
                    $createdTimestamps++
                    $updatedCount++
                    
                    Write-Host "Created timestamp $dateKey at $scheduledTime with medications: $($scheduledMeds.PSObject.Properties.Name -join ', ')" -ForegroundColor Green
                } else {
                    # Timestamp exists, check medications
                    $timestampEntry = $dateEntry.$scheduledTime
                    $totalEntries++
                    
                    if ($Debug) { Write-Host "    Debug: Processing existing timestamp: $scheduledTime" -ForegroundColor Cyan }
                    
                    # Ensure Medications object exists
                    if (-not $timestampEntry.PSObject.Properties['Medications']) {
                        $timestampEntry | Add-Member -NotePropertyName 'Medications' -NotePropertyValue ([PSCustomObject]@{})
                        if ($Debug) { Write-Host "      Debug: Created empty Medications object" -ForegroundColor Yellow }
                    }
                    
                    # Check each scheduled medication
                    $addedMedsThisEntry = @()
                    foreach ($medProp in $scheduledMeds.PSObject.Properties) {
                        $medName = $medProp.Name
                        $medDose = $medProp.Value
                        
                        # Check if this medication already exists
                        if (-not $timestampEntry.Medications.PSObject.Properties[$medName]) {
                            # Add missing medication
                            $timestampEntry.Medications | Add-Member -NotePropertyName $medName -NotePropertyValue $medDose
                            $addedMedsThisEntry += $medName
                            $addedMedications++
                            
                            if ($Debug) { Write-Host "      Debug: Added missing medication: $medName = $medDose" -ForegroundColor Green }
                        } else {
                            if ($Debug) { Write-Host "      Debug: Medication $medName already exists" -ForegroundColor Yellow }
                        }
                    }
                    
                    if ($addedMedsThisEntry.Count -gt 0) {
                        $updatedCount++
                        Write-Host "Added medications to $dateKey at $scheduledTime : $($addedMedsThisEntry -join ', ')" -ForegroundColor Green
                    }
                }
            }
        }
        
        # Save the updated entries back to file
        if ($updatedCount -gt 0) {
            $entries | ConvertTo-Json -Depth 10 | Set-Content -Path $EntriesPath -Encoding UTF8
        }
        
        Write-Host "Summary:" -ForegroundColor Green
        Write-Host "  Total existing timestamp entries processed: $totalEntries"
        Write-Host "  New timestamp entries created: $createdTimestamps"
        Write-Host "  Individual medications added: $addedMedications"
        Write-Host "  Total entries updated: $updatedCount"
        if ($updatedCount -gt 0) {
            Write-Host "  Updated file saved to: $EntriesPath"
        }
        
        return $entries
    }
    catch {
        Write-Error "Error updating entries with medications: $($_.Exception.Message)"
        return $null
    }
}

# Function to show medication schedule coverage
function Show-MedicationScheduleCoverage {
    param(
        [array]$MedicationSchedules = $Schedules
    )
    
    Write-Host "Medication Schedule Coverage:" -ForegroundColor Green
    foreach ($schedule in $MedicationSchedules) {
        Write-Host "  $($schedule.StartDate) to $($schedule.EndDate):" -ForegroundColor Yellow
        foreach ($time in $schedule.MedSchedule.PSObject.Properties.Name | Sort-Object) {
            $meds = $schedule.MedSchedule.$time
            $medList = ($meds.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }) -join ', '
            Write-Host "    $time - $medList" -ForegroundColor Cyan
        }
        Write-Host ""
    }
}

# Uncomment the lines below to run the functions
Show-MedicationScheduleCoverage
Update-EntriesWithMedications -Debug


