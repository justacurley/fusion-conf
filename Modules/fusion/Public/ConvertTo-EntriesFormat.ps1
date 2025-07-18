function ConvertTo-EntriesFormat {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )

    # Validate input type
    if ($Entry -isnot [PSCustomObject]) {
        throw 'Entry parameter must be a PSCustomObject'
    }

    # Convert to entries.json format
    Write-Host 'Converting entry to entries.json format...'

    # Create new HealthEntry instance
    $healthEntry = [HealthEntry]::new()

    # Set Date and Time
    $healthEntry.Date = if ($Entry.date) { $Entry.date } else { '' }
    $healthEntry.Time = if ($Entry.timestamp) { $Entry.timestamp } else { '' }

    # Process medications using MedicationTaken class
    $medProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'med_*' -and ($_.Value -eq $true -or $_.Value -eq 'true') }
    foreach ($medProp in $medProperties) {
        # Parse "med_dilaudid_4mg" format
        if ($medProp.Name -match '^med_(.+?)_(.+)$') {
            $medName = $matches[1]
            $dosage = $matches[2]

            # Additional validation for realistic medication patterns
            # Dosage should look like a medical dosage (contain numbers and units)
            if ($dosage -match '^\d+(\.\d+)?(mg|g|ml|mcg|iu|units?)$|^\d+(\.\d+)?$') {
                # Medication name should be alphabetic (possibly with numbers)
                if ($medName -match '^[a-zA-Z][a-zA-Z0-9]*$') {
                    try {
                        $medication = [MedicationTaken]::new($dosage, $medName)
                        $healthEntry.Medication += $medication
                        Write-Information "Added medication: $medName $dosage"
                    }
                    catch {
                        Write-Warning "Invalid medication: $medName $dosage - $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Information "Skipping invalid medication name format: $medName"
                }
            }
            else {
                Write-Information "Skipping invalid dosage format: $dosage"
            }
        }
    }

    # Process pain using PainLocation class with flexible location names
    # Handle boolean strings as well as boolean values
    $shouldProcessPain = ($Entry.add_pain -eq $true -or $Entry.add_pain -eq 'true') -or
    ($Entry.PSObject.Properties | Where-Object { $_.Name -like 'pain_location_*' })

    if ($shouldProcessPain) {
        $painProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'pain_location_*' }
        foreach ($painProp in $painProperties) {
            $id = $painProp.Name -replace 'pain_location_', ''
            $location = $painProp.Value
            $levelProp = "pain_level_$id"
            $noteProp = "pain_note_$id"

            if ($Entry.PSObject.Properties[$levelProp] -and $location) {
                try {
                    $level = [double]$Entry.PSObject.Properties[$levelProp].Value
                    $note = if ($Entry.PSObject.Properties[$noteProp]) { $Entry.PSObject.Properties[$noteProp].Value } else { '' }

                    # Use the new constructor signature: location, level, note
                    $pain = [PainLocation]::new($location, $level, $note)
                    $healthEntry.Pain += $pain
                    Write-Information "Added pain: $location level $level"
                }
                catch {
                    Write-Warning "Invalid pain entry: $location $level - $($_.Exception.Message)"
                }
            }
        }
    }

    # Process activities using Activity class
    # Handle boolean strings as well as boolean values
    $shouldProcessActivity = ($Entry.add_activity -eq $true -or $Entry.add_activity -eq 'true') -or
    ($Entry.PSObject.Properties | Where-Object { $_.Name -like 'activities_type_*' })

    if ($shouldProcessActivity) {
        $activityProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'activities_type_*' }
        Write-Information "Found $($activityProperties.Count) activity type properties"

        foreach ($activityProp in $activityProperties) {
            $id = $activityProp.Name -replace 'activities_type_', ''
            $activityType = $activityProp.Value
            $lengthProp = "activities_length_$id"
            $noteProp = "activities_note_$id"

            Write-Information "Processing activity ID $id, Type: $activityType"

            if ($Entry.PSObject.Properties[$lengthProp] -and $activityType) {
                try {
                    $duration = [int]$Entry.PSObject.Properties[$lengthProp].Value
                    $note = if ($Entry.PSObject.Properties[$noteProp]) { $Entry.PSObject.Properties[$noteProp].Value } else { '' }

                    $activity = [Activity]::new($activityType, $duration, $note)
                    $healthEntry.Activity += $activity
                    Write-Information "Added activity: $activityType duration $duration"
                }
                catch {
                    Write-Warning "Invalid activity entry: $activityType - $($_.Exception.Message)"
                }
            }
        }
    }

    # Process vitals using Vitals class
    if ($Entry.o2 -or $Entry.bpr) {
        try {
            $o2 = if ($Entry.o2) { [int]$Entry.o2 } else { 95 }
            $bpr = if ($Entry.bpr) { $Entry.bpr } else { '120/80' }

            $healthEntry.Vitals = [Vitals]::new($o2, $bpr)
            Write-Information "Added vitals: o2=$o2 bpr=$bpr"
        }
        catch {
            Write-Warning "Invalid vitals: o2=$($Entry.o2) bpr=$($Entry.bpr) - $($_.Exception.Message)"
        }
    }

    # Set notes
    if ($Entry.notes) {
        $healthEntry.Note = $Entry.notes
    }

    if ($Entry.mood) {
        try {
            $moodLevel = [int]$Entry.mood
            $moodNote = if ($Entry.mood_note) { $Entry.mood_note } else { '' }

            $healthEntry.Mood = [Mood]::new($moodLevel, $moodNote)
            Write-Information "Added mood: level $moodLevel"
        }
        catch {
            Write-Warning "Invalid mood entry: level=$($Entry.mood) note=$($Entry.mood_note) - $($_.Exception.Message)"
        }
    }
    # No need for strict validation - allow empty entries
    # The individual classes handle their own validation

    # Use the class's ToHashtable() method for consistent serialization
    $entryStructure = $healthEntry.ToHashtable()

    # Create the full structure for entries.json
    $fullEntry = @{
        $healthEntry.Date = @{
            $healthEntry.Time = $entryStructure
        }
    }

    # Add date-level fields like Sleep if present
    if ($Entry.sleep) {
        $fullEntry[$healthEntry.Date]['Sleep'] = $Entry.sleep
    }

    # Return the result
    return @{
        FullEntry      = $fullEntry
        EntryStructure = $entryStructure
        Date           = $healthEntry.Date
        Timestamp      = $healthEntry.Time
    }
}
