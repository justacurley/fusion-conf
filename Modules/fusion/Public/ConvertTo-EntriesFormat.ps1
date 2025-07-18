function ConvertTo-EntriesFormat {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry,

        [Parameter(Mandatory = $false)]
        [string]$UserEmail = "user@example.com"
    )

    # Validate input type
    if ($Entry -isnot [PSCustomObject]) {
        throw 'Entry parameter must be a PSCustomObject'
    }

    # Convert to new unified schema v2.0 format
    Write-Host 'Converting entry to unified schema v2.0 format...'

    # Parse dates and create entry_id (yyMMddHHmm format)
    $rawDate = if ($Entry.date) { $Entry.date } else { '' }
    $rawTime = if ($Entry.timestamp) { $Entry.timestamp } else { '' }

    if (-not $rawDate -or -not $rawTime) {
        throw 'Date and timestamp are required for schema v2.0'
    }

    # Convert MMDD to YYYY-MM-DD and HHMM to HH:mm
    $year = [datetime]::Now.Year
    $month = $rawDate.Substring(0, 2)
    $day = $rawDate.Substring(2, 2)
    $hour = $rawTime.Substring(0, 2)
    $minute = $rawTime.Substring(2, 2)

    $isoDate = "$year-$month-$day"
    $isoTime = "$hour`:$minute"
    $entryId = $([datetime]::ParseExact($isoDate, "yyyy-MM-dd", $null).ToString("yyMMdd")) + $rawTime

    # Initialize the new schema structure
    $schemaEntry = @{
        entry_id = $entryId
        user_email = $UserEmail
        date = $isoDate
        time = $isoTime
        entry_types = @()
        data = @{}
        notes = if ($Entry.notes) { $Entry.notes } else { "" }
    }

    # Process medications
    $medProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'med_*' -and ($_.Value -eq $true -or $_.Value -eq 'true') }
    if ($medProperties.Count -gt 0) {
        $schemaEntry.entry_types += "medications"
        $schemaEntry.data.medications = @()

        foreach ($medProp in $medProperties) {
            if ($medProp.Name -match '^med_(.+?)_(.+)$') {
                $medName = $matches[1]
                $dosage = $matches[2]

                # Validate dosage format and medication name
                if ($dosage -match '^\d+(\.\d+)?(mg|g|ml|mcg|iu|units?)$|^\d+(\.\d+)?$' -and $medName -match '^[a-zA-Z][a-zA-Z0-9]*$') {
                    $schemaEntry.data.medications += @{
                        name = $medName
                        dosage = $dosage
                    }
                    Write-Information "Added medication: $medName $dosage"
                }
            }
        }
    }

    # Process pain using new schema format
    $shouldProcessPain = ($Entry.add_pain -eq $true -or $Entry.add_pain -eq 'true') -or
        ($Entry.PSObject.Properties | Where-Object { $_.Name -like 'pain_location_*' })

    if ($shouldProcessPain) {
        $painProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'pain_location_*' }
        if ($painProperties.Count -gt 0) {
            $schemaEntry.entry_types += "pain"
            $schemaEntry.data.pain = @()

            foreach ($painProp in $painProperties) {
                $id = $painProp.Name -replace 'pain_location_', ''
                $location = $painProp.Value
                $levelProp = "pain_level_$id"
                $noteProp = "pain_note_$id"

                if ($Entry.PSObject.Properties[$levelProp] -and $location) {
                    try {
                        $level = [double]$Entry.PSObject.Properties[$levelProp].Value
                        $note = if ($Entry.PSObject.Properties[$noteProp]) { $Entry.PSObject.Properties[$noteProp].Value } else { "" }

                        # Validate pain level is within medical range (0-10)
                        if ($level -ge 0.0 -and $level -le 10.0) {
                            $schemaEntry.data.pain += @{
                                location = $location
                                severity = $level
                                note = $note
                            }
                            Write-Information "Added pain: $location level $level"
                        }
                    } catch {
                        throw "Invalid pain level value: '$($Entry.PSObject.Properties[$levelProp].Value)' for location '$location'"
                    }
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
        if ($activityProperties.Count -gt 0) {
            $schemaEntry.entry_types += "activities"
            $schemaEntry.data.activities = @()

            foreach ($activityProp in $activityProperties) {
                $id = $activityProp.Name -replace 'activities_type_', ''
                $activityType = $activityProp.Value
                $lengthProp = "activities_length_$id"
                $noteProp = "activities_note_$id"

                if ($Entry.PSObject.Properties[$lengthProp] -and $activityType) {
                    try {
                        $duration = [int]$Entry.PSObject.Properties[$lengthProp].Value
                        $note = if ($Entry.PSObject.Properties[$noteProp]) { $Entry.PSObject.Properties[$noteProp].Value } else { "" }

                        # Validate duration is reasonable (1-480 minutes as per schema)
                        if ($duration -ge 1 -and $duration -le 480) {
                            $schemaEntry.data.activities += @{
                                name = $activityType
                                duration_minutes = $duration
                                note = $note
                            }
                            Write-Information "Added activity: $activityType duration $duration minutes"
                        }
                    } catch {
                        throw "Invalid activity duration value: '$($Entry.PSObject.Properties[$lengthProp].Value)' for activity '$activityType'"
                    }
                }
            }
        }
    }

    # Process vitals using Vitals class
    if ($Entry.o2 -or $Entry.bpr) {
        $schemaEntry.entry_types += "vitals"
        $schemaEntry.data.vitals = @{
            oxygen_saturation = if ($Entry.o2) { [int]$Entry.o2 } else { 95 }
            blood_pressure = if ($Entry.bpr) { $Entry.bpr } else { "120/80" }
            heart_rate = if ($Entry.heart_rate) { [int]$Entry.heart_rate } else { 72 }
            temperature = if ($Entry.temperature) { [double]$Entry.temperature } else { 98.6 }
        }
        Write-Information "Added vitals: o2=$($schemaEntry.data.vitals.oxygen_saturation) bpr=$($schemaEntry.data.vitals.blood_pressure)"
    }

    # Set notes
    if ($Entry.notes) {
        $schemaEntry.notes = $Entry.notes
    }

    # Process mood
    if ($Entry.mood) {
        $moodLevel = [int]$Entry.mood
        $moodNote = if ($Entry.mood_note) { $Entry.mood_note } else { "" }

        # Validate mood level is in range (1-5 as per schema)
        if ($moodLevel -ge 1 -and $moodLevel -le 5) {
            $schemaEntry.entry_types += "mood"
            $schemaEntry.data.mood = @{
                mood_level = $moodLevel
                mood_note = $moodNote
            }
            Write-Information "Added mood: level $moodLevel"
        }
    }

    # Process sleep
    if ($Entry.sleep) {
        # Parse sleep hours from various formats (e.g., "8 hours", "7.5", "8:30")
        $sleepHours = 0.0
        if ($Entry.sleep -match '(\d+\.?\d*)') {
            $sleepHours = [double]$matches[1]
        }

        if ($sleepHours -ge 0.0 -and $sleepHours -le 24.0) {
            $schemaEntry.entry_types += "sleep"
            $schemaEntry.data.sleep = @{
                sleep_hours = $sleepHours
            }
            Write-Information "Added sleep: $sleepHours hours"
        }
    }

    # Return the new schema format
    return @{
        SchemaEntry = $schemaEntry
        Date = $rawDate
        Timestamp = $rawTime
        EntryId = $entryId
    }
}
