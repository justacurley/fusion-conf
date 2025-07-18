function New-SampleHealthEntries {
    <#
    .SYNOPSIS
    Generates sample health entries using the unified schema v2.0 format

    .DESCRIPTION
    Creates sample health entries using the new unified schema v2.0 with composite keys (yyMMddHHmm),
    multiple entry types, and structured data sections. Provides fine-grained control over data generation
    for testing purposes.

    .PARAMETER Count
    Number of sample entries to generate (default: 5)

    .PARAMETER UserEmail
    User email for the sample entries (default: "sample.user@example.com")

    .PARAMETER EntryTypes
    Array of entry types to include. If not specified, random types will be selected.
    Valid values: "mood", "vitals", "medications", "activities", "pain", "weight", "sleep"

    .PARAMETER MoodCount
    Number of mood entries to generate (overrides random selection)

    .PARAMETER VitalsCount
    Number of vitals entries to generate (overrides random selection)

    .PARAMETER MedicationCount
    Number of medication entries to generate (overrides random selection)

    .PARAMETER ActivityCount
    Number of activity entries to generate (overrides random selection)

    .PARAMETER PainCount
    Number of pain entries to generate (overrides random selection)

    .PARAMETER WeightCount
    Number of weight entries to generate (overrides random selection)

    .PARAMETER SleepCount
    Number of sleep entries to generate (overrides random selection)

    .PARAMETER DateRange
    Number of days in the past to generate entries for (default: 30)

    .PARAMETER MinEntriesPerDay
    Minimum number of entries per day (default: 1)

    .PARAMETER MaxEntriesPerDay
    Maximum number of entries per day (default: 4)

    .PARAMETER OutputFormat
    Output format: "Array" returns array of entries, "Hashtable" returns hashtable keyed by entry_id (default: "Array")

    .EXAMPLE
    $samples = New-SampleHealthEntries -Count 10

    .EXAMPLE
    $samples = New-SampleHealthEntries -Count 3 -UserEmail "test@domain.com"

    .EXAMPLE
    $samples = New-SampleHealthEntries -PainCount 5 -MoodCount 3 -VitalsCount 2

    .EXAMPLE
    $samples = New-SampleHealthEntries -EntryTypes @("pain", "medications") -Count 10

    .EXAMPLE
    $samples = New-SampleHealthEntries -Count 20 -DateRange 7 -OutputFormat "Hashtable"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Count = 5,

        [Parameter(Mandatory = $false)]
        [string]$UserEmail = "sample.user@example.com",

        [Parameter(Mandatory = $false)]
        [ValidateSet("mood", "vitals", "medications", "activities", "pain", "weight", "sleep")]
        [string[]]$EntryTypes,

        [Parameter(Mandatory = $false)]
        [int]$MoodCount,

        [Parameter(Mandatory = $false)]
        [int]$VitalsCount,

        [Parameter(Mandatory = $false)]
        [int]$MedicationCount,

        [Parameter(Mandatory = $false)]
        [int]$ActivityCount,

        [Parameter(Mandatory = $false)]
        [int]$PainCount,

        [Parameter(Mandatory = $false)]
        [int]$WeightCount,

        [Parameter(Mandatory = $false)]
        [int]$SleepCount,

        [Parameter(Mandatory = $false)]
        [int]$DateRange = 30,

        [Parameter(Mandatory = $false)]
        [int]$MinEntriesPerDay = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxEntriesPerDay = 4,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Array", "Hashtable")]
        [string]$OutputFormat = "Hashtable"
    )

    try {
        # Handle zero count case
        if ($Count -eq 0) {
            Write-Information "Count is 0, returning empty result"
            if ($OutputFormat -eq "Array") {
                return @()
            } else {
                return @{}
            }
        }

        $entries = @{}
        $entryTypes = @("mood", "pain", "vitals", "medications", "activities", "sleep", "weight")
        $painLocations = @("back", "neck", "shoulder", "hip", "knee", "head", "chest", "abdomen")
        $activities = @("Walking", "Stretching", "Exercise", "Physical Therapy", "Swimming", "Yoga", "Running")
        $medications = @("tylenol", "dilaudid", "lexapro", "vitaminD", "oxycodone", "valium")
        $moodNotes = @("Feeling good today", "A bit tired", "Energetic morning", "Relaxed evening", "Productive day", "Need more rest")

        # If specific type counts are provided, use them to override Count
        $typeCountsProvided = $false
        $totalTypeCount = 0
        $typeCounts = @{}

        if ($PSBoundParameters.ContainsKey('MoodCount')) { $typeCounts['mood'] = $MoodCount; $totalTypeCount += $MoodCount; $typeCountsProvided = $true }
        if ($PSBoundParameters.ContainsKey('VitalsCount')) { $typeCounts['vitals'] = $VitalsCount; $totalTypeCount += $VitalsCount; $typeCountsProvided = $true }
        if ($PSBoundParameters.ContainsKey('MedicationCount')) { $typeCounts['medications'] = $MedicationCount; $totalTypeCount += $MedicationCount; $typeCountsProvided = $true }
        if ($PSBoundParameters.ContainsKey('ActivityCount')) { $typeCounts['activities'] = $ActivityCount; $totalTypeCount += $ActivityCount; $typeCountsProvided = $true }
        if ($PSBoundParameters.ContainsKey('PainCount')) { $typeCounts['pain'] = $PainCount; $totalTypeCount += $PainCount; $typeCountsProvided = $true }
        if ($PSBoundParameters.ContainsKey('WeightCount')) { $typeCounts['weight'] = $WeightCount; $totalTypeCount += $WeightCount; $typeCountsProvided = $true }
        if ($PSBoundParameters.ContainsKey('SleepCount')) { $typeCounts['sleep'] = $SleepCount; $totalTypeCount += $SleepCount; $typeCountsProvided = $true }

        # Use specific type counts if provided, otherwise use Count parameter
        $actualCount = if ($typeCountsProvided) { $totalTypeCount } else { $Count }

        for ($i = 0; $i -lt $actualCount; $i++) {
            # Generate random date/time within specified date range
            $baseDate = (Get-Date).AddDays(-$DateRange)
            $randomDate = $baseDate.AddDays((Get-Random -Minimum 0 -Maximum $DateRange))
            $randomHour = Get-Random -Minimum 6 -Maximum 22
            $randomMinute = Get-Random -Minimum 0 -Maximum 59

            # Create composite key (yyMMddHHmm)
            $compositeKey = "{0:yy}{0:MM}{0:dd}{1:D2}{2:D2}" -f $randomDate, $randomHour, $randomMinute

            # Ensure unique keys
            while ($entries.ContainsKey($compositeKey)) {
                $randomMinute = ($randomMinute + 1) % 60
                if ($randomMinute -eq 0) { $randomHour = ($randomHour + 1) % 24 }
                $compositeKey = "{0:yy}{0:MM}{0:dd}{1:D2}{2:D2}" -f $randomDate, $randomHour, $randomMinute
            }

            # Determine entry types for this entry
            $selectedTypes = @()

            if ($typeCountsProvided) {
                # Use specific type counts - assign one type per entry in order
                $currentIndex = 0
                foreach ($type in $typeCounts.Keys) {
                    if ($i -ge $currentIndex -and $i -lt ($currentIndex + $typeCounts[$type])) {
                        $selectedTypes = @($type)
                        break
                    }
                    $currentIndex += $typeCounts[$type]
                }
            } elseif ($EntryTypes) {
                # Use specified EntryTypes
                $typeCount = Get-Random -Minimum 1 -Maximum ([math]::Min($EntryTypes.Count, 4) + 1)
                $selectedTypes = $EntryTypes | Get-Random -Count $typeCount
            } else {
                # Select random entry types (1-3 types per entry)
                $typeCount = Get-Random -Minimum 1 -Maximum 4
                $selectedTypes = $entryTypes | Get-Random -Count $typeCount
            }

            # Ensure entry_types is always an array
            $selectedTypes = [string[]]@($selectedTypes)

            # Build data section based on selected types
            $data = @{}

            foreach ($type in $selectedTypes) {
                switch ($type) {
                    "mood" {
                        $data.mood = @{
                            mood_level = Get-Random -Minimum 1 -Maximum 5  # Schema v2.0: 1-5 scale
                            mood_note = $moodNotes | Get-Random
                        }
                    }
                    "pain" {
                        # Generate 1-3 pain locations for this entry
                        $painCount = Get-Random -Minimum 1 -Maximum 4
                        $selectedPainLocations = $painLocations | Get-Random -Count $painCount
                        $data.pain = @()
                        foreach ($location in $selectedPainLocations) {
                            $data.pain += @{
                                location = $location
                                severity = [math]::Round((Get-Random -Minimum 0.0 -Maximum 10.0), 1)  # Schema v2.0: 0-10 scale with decimals
                                note = "Sample pain entry for $location"
                            }
                        }
                    }
                    "vitals" {
                        $systolic = Get-Random -Minimum 110 -Maximum 140
                        $diastolic = Get-Random -Minimum 70 -Maximum 90
                        $data.vitals = @{
                            blood_pressure = "$systolic/$diastolic"
                            heart_rate = Get-Random -Minimum 60 -Maximum 100
                            oxygen_saturation = Get-Random -Minimum 95 -Maximum 100
                            temperature = [math]::Round((Get-Random -Minimum 97.0 -Maximum 99.5), 1)
                        }
                    }
                    "medications" {
                        # Generate 1-3 medications for this entry
                        $medicationCount = Get-Random -Minimum 1 -Maximum 4
                        $selectedMedications = $medications | Get-Random -Count $medicationCount
                        $dosages = @("500mg", "1g", "2mg", "4mg", "5mg", "10mg", "20mg")
                        $data.medications = @()
                        foreach ($med in $selectedMedications) {
                            $data.medications += @{
                                name = $med  # Schema v2.0: 'name' not 'medication_name'
                                dosage = $dosages | Get-Random
                            }
                        }
                    }
                    "activities" {
                        # Generate 1-3 activities for this entry
                        $activityCount = Get-Random -Minimum 1 -Maximum 4
                        $selectedActivities = $activities | Get-Random -Count $activityCount
                        $data.activities = @()
                        foreach ($activity in $selectedActivities) {
                            $data.activities += @{
                                name = $activity  # Schema v2.0: 'name' not 'activity_name'
                                duration_minutes = Get-Random -Minimum 5 -Maximum 120
                                note = "Sample activity: $activity"
                            }
                        }
                    }
                    "weight" {
                        $weightLbs = [math]::Round((Get-Random -Minimum 120.0 -Maximum 250.0), 1)
                        $weightKg = [math]::Round($weightLbs * 0.453592, 1)  # Convert lbs to kg
                        $data.weight = @{
                            weight_lbs = $weightLbs
                            weight_kg = $weightKg
                        }
                    }
                    "sleep" {
                        $data.sleep = @{
                            sleep_hours = [math]::Round((Get-Random -Minimum 4.0 -Maximum 10.0), 1)
                            # Schema v2.0: Only 'sleep_hours' field, no quality or note
                        }
                    }
                }
            }

            # Create the entry (100% schema v2.0 compatible)
            $entry = @{
                entry_id = $compositeKey
                user_email = $UserEmail
                date = "{0:yyyy-MM-dd}" -f $randomDate
                time = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute
                entry_types = $selectedTypes
                data = $data
                notes = if ((Get-Random -Minimum 1 -Maximum 4) -eq 1) { "Sample general note for entry" } else { "" }
            }

            $entries[$compositeKey] = $entry
        }

        Write-Information "Generated $actualCount sample health entries using unified schema v2.0"

        # Return in requested format
        if ($OutputFormat -eq "Array") {
            return $entries.Values
        } else {
            return $entries
        }

    }
    catch {
        Write-Error "Error generating sample health entries: $($_.Exception.Message)"
        throw
    }
}
