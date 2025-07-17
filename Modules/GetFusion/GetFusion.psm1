# GetFusion PowerShell Module
# Contains reusable functions for processing health data from unified entries schema v2.0

# Global variable to track distinct data values found during processing
$global:DistinctDataValues = @{}

# Global variable to cache the dates list for performance optimization
$global:DatesList = $null

# Function to parse sleep data from various formats
function Get-SleepHours {
    param([string]$sleepValue)

    if ([string]::IsNullOrEmpty($sleepValue)) {
        return $null
    }

    # Parse "HH:MM" format like "7:39", "9:10", "6:03"
    if ($sleepValue -match '^(\d+):(\d+)$') {
        $hours = [int]$matches[1]
        $minutes = [int]$matches[2]
        return [math]::Round($hours + ($minutes / 60.0), 2)
    }
    # Handle decimal format like "7.5"
    elseif ($sleepValue -match '^(\d+(?:\.\d+)?)$') {
        return [double]$matches[1]
    }

    return $null
}

# Function to calculate average back pain for unified entries schema v2.0
function Get-AverageBackPain {
    param($entries)

    $backPainLevels = @()

    # Process unified schema v2.0 (array of entries)
    foreach ($entry in $entries) {
        if ($entry.entry_types -contains "pain" -and $entry.data.pain) {
            if ($entry.data.pain.location -eq "back") {
                $backPainLevels += [double]$entry.data.pain.severity
            }
        }
    }

    # Calculate average back pain (null if no back pain data)
    if ($backPainLevels.Count -gt 0) {
        return [math]::Round(($backPainLevels | Measure-Object -Average).Average, 1)
    }

    return $null
}

# Function to calculate total activity duration for a date (unified schema v2.0)
function Get-TotalActivityDuration {
    param([string]$date, $entries)

    $activityEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "activity" }

    if ($activityEntries) {
        $totalDuration = ($activityEntries | ForEach-Object { $_.data.activity.duration_minutes } | Measure-Object -Sum).Sum
        return $totalDuration
    }

    return $null
}

# Function to convert date format (unified schema uses YYYY-MM-DD, convert to MM/DD for display)
function Convert-DateToDisplay {
    param([string]$date)

    # Unified schema uses YYYY-MM-DD format, convert to MM/DD for display
    if ($date -match '^(\d{4})-(\d{2})-(\d{2})$') {
        return "$($matches[2])/$($matches[3])"
    }

    return $date
}

# Function to load and parse entries.json file (unified schema v2.0)
function Get-EntriesData {
    param([string]$entriesPath)

    $entries = Get-Content -Path $entriesPath | ConvertFrom-Json

    # Validate this is unified schema v2.0 format
    if (-not ($entries -is [Array] -and $entries.Count -gt 0 -and $entries[0].PSObject.Properties['entry_id'])) {
        throw "Invalid entries format. Expected unified schema v2.0 with entry_id fields."
    }

    Write-Information "Loaded $($entries.Count) entries from unified schema v2.0"
    return $entries
}

# Function to get sorted list of dates from entries (unified schema v2.0)
function Get-DatesList {
    param($entries)

    # Return cached dates if available
    if ($null -ne $global:DatesList) {
        return $global:DatesList
    }

    # Extract and sort unique dates from unified schema v2.0
    $dates = $entries | ForEach-Object { $_.date } | Sort-Object -Unique
    $global:DatesList = $dates
    return $global:DatesList
}

# Function to add additional data to a combined data object
function Set-CombinedData {
    param(
        [PSCustomObject]$combinedData,
        [string]$name,
        $data
    )

    # Add the new property to the existing object
    $combinedData | Add-Member -MemberType NoteProperty -Name $name -Value $data -Force

    return $combinedData
}

# Function to extract medication data (unified schema v2.0)
function Get-DateMedicationData {
    param([string]$date, $entries)

    # Initialize Medications array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Medications')) {
        $global:DistinctDataValues['Medications'] = @()
    }

    $medications = @()

    # Get all medication entries for the specified date
    $dateEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "medication" }

    foreach ($entry in $dateEntries) {
        if ($entry.data.medication) {
            $medicationName = $entry.data.medication.medication_name
            $dosage = $entry.data.medication.dosage

            # Track unique medications in global variable
            if ($global:DistinctDataValues['Medications'] -notcontains $medicationName) {
                $global:DistinctDataValues['Medications'] += $medicationName
            }

            $medicationWithContext = [PSCustomObject]@{
                Date       = $entry.date
                Timestamp  = $entry.time
                EntryId    = $entry.entry_id
                Medication = $medicationName
                Dose       = $dosage
                Notes      = $entry.notes
            }
            $medications += $medicationWithContext
        }
    }

    return $medications
}

# Function to extract activity data (unified schema v2.0)
function Get-DateActivityData {
    param([string]$date, $entries)

    # Initialize Activities array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Activities')) {
        $global:DistinctDataValues['Activities'] = @()
    }

    $activities = @()

    # Get all activity entries for the specified date
    $dateEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "activity" }

    foreach ($entry in $dateEntries) {
        if ($entry.data.activity) {
            $activityName = $entry.data.activity.activity_name

            # Track unique activities in global variable
            if ($global:DistinctDataValues['Activities'] -notcontains $activityName) {
                $global:DistinctDataValues['Activities'] += $activityName
            }

            $activityWithContext = [PSCustomObject]@{
                Date      = $entry.date
                Timestamp = $entry.time
                EntryId   = $entry.entry_id
                Activity  = $activityName
                Note      = $entry.data.activity.note
                Duration  = $entry.data.activity.duration_minutes
                Notes     = $entry.notes
            }
            $activities += $activityWithContext
        }
    }

    return $activities
}

# Function to extract vitals data (unified schema v2.0)
function Get-DateVitalsData {
    param([string]$date, $entries)

    $vitals = @()

    # Get all vitals entries for the specified date
    $dateEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "vitals" }

    foreach ($entry in $dateEntries) {
        if ($entry.data.vitals) {
            $vitalsData = $entry.data.vitals

            # Blood pressure
            if ($vitalsData.blood_pressure) {
                $bprWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Blood Pressure'
                    Vital     = $vitalsData.blood_pressure
                    Notes     = $entry.notes
                }
                $vitals += $bprWithContext
            }

            # Oxygen saturation
            if ($vitalsData.oxygen_saturation) {
                $o2WithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Oxygen Saturation'
                    Vital     = "$($vitalsData.oxygen_saturation)%"
                    Notes     = $entry.notes
                }
                $vitals += $o2WithContext
            }

            # Heart rate
            if ($vitalsData.heart_rate) {
                $hrWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Heart Rate'
                    Vital     = "$($vitalsData.heart_rate) bpm"
                    Notes     = $entry.notes
                }
                $vitals += $hrWithContext
            }

            # Temperature
            if ($vitalsData.temperature) {
                $tempWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Temperature'
                    Vital     = "$($vitalsData.temperature)°F"
                    Notes     = $entry.notes
                }
                $vitals += $tempWithContext
            }
        }
    }

    return $vitals
}

# Function to extract health metrics for unified schema v2.0
function Get-HealthMetrics {
    param(
        # Array of entries from unified schema v2.0
        [Parameter(Mandatory)]
        [Array]$Entries,
        [Parameter(Mandatory)]
        [ValidateSet('MaxPain', 'BackPain', 'Sleep', 'Medications', 'Activities', 'Vitals', 'ActivityDuration', 'Pain', 'Weight', 'Mood')]
        [string[]]$DataPoints
    )

    # Get cached dates if available, otherwise call Get-DatesList
    $dates = if ($null -ne $global:DatesList) { $global:DatesList } else { Get-DatesList -entries $Entries }

    # Initialize result hashtable
    $results = @{}

    # Initialize arrays for each requested data point
    if ($DataPoints -contains 'Medications') { $results['Medications'] = @() }
    if ($DataPoints -contains 'Activities') { $results['Activities'] = @() }
    if ($DataPoints -contains 'Vitals') { $results['Vitals'] = @() }
    if ($DataPoints -contains 'Pain') { $results['Pain'] = @() }
    if ($DataPoints -contains 'Weight') { $results['Weight'] = @() }
    if ($DataPoints -contains 'Mood') { $results['Mood'] = @() }
    if ($DataPoints -contains 'MaxPain' -or $DataPoints -contains 'BackPain' -or $DataPoints -contains 'Sleep' -or $DataPoints -contains 'ActivityDuration') {
        $results['CombinedHealthData'] = @()
    }

    foreach ($date in $dates) {
        # Handle combined health data (MaxPain, BackPain, Sleep, ActivityDuration)
        if ($DataPoints -contains 'MaxPain' -or $DataPoints -contains 'BackPain' -or $DataPoints -contains 'Sleep' -or $DataPoints -contains 'ActivityDuration') {
            $baseObject = [PSCustomObject]@{
                Date = $date
            }

            # Get entries for this date
            $dateEntries = $Entries | Where-Object { $_.date -eq $date }

            if ($DataPoints -contains 'MaxPain') {
                # Find max pain severity for the day
                $painEntries = $dateEntries | Where-Object { $_.entry_types -contains "pain" }
                if ($painEntries) {
                    $maxPain = ($painEntries | ForEach-Object { $_.data.pain.severity } | Measure-Object -Maximum).Maximum
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'MaxPain' -data $maxPain
                }
            }

            if ($DataPoints -contains 'BackPain') {
                $avgBackPain = Get-AverageBackPain -entries $dateEntries
                if ($null -ne $avgBackPain) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'BackPain' -data $avgBackPain
                }
            }

            if ($DataPoints -contains 'Sleep') {
                # Find sleep entries for the day
                $sleepEntries = $dateEntries | Where-Object { $_.entry_types -contains "sleep" }
                if ($sleepEntries) {
                    $totalSleep = ($sleepEntries | ForEach-Object { $_.data.sleep.sleep_hours } | Measure-Object -Sum).Sum
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'Sleep' -data $totalSleep
                }
            }

            if ($DataPoints -contains 'ActivityDuration') {
                # Calculate total activity duration for the day
                $activityEntries = $dateEntries | Where-Object { $_.entry_types -contains "activity" }
                if ($activityEntries) {
                    $totalDuration = ($activityEntries | ForEach-Object { $_.data.activity.duration_minutes } | Measure-Object -Sum).Sum
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'ActivityDuration' -data $totalDuration
                }
            }

            $results['CombinedHealthData'] += $baseObject
        }

        # Handle individual data types
        if ($DataPoints -contains 'Medications') {
            $medications = Get-DateMedicationData -date $date -entries $Entries
            $results['Medications'] += $medications
        }

        if ($DataPoints -contains 'Activities') {
            $activities = Get-DateActivityData -date $date -entries $Entries
            $results['Activities'] += $activities
        }

        if ($DataPoints -contains 'Vitals') {
            $vitals = Get-DateVitalsData -date $date -entries $Entries
            $results['Vitals'] += $vitals
        }

        if ($DataPoints -contains 'Pain') {
            $painEntries = $Entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "pain" }
            foreach ($entry in $painEntries) {
                if ($entry.data.pain) {
                    $painWithContext = [PSCustomObject]@{
                        Date      = $entry.date
                        Timestamp = $entry.time
                        EntryId   = $entry.entry_id
                        Location  = $entry.data.pain.location
                        Severity  = $entry.data.pain.severity
                        Note      = $entry.data.pain.note
                        Notes     = $entry.notes
                    }
                    $results['Pain'] += $painWithContext
                }
            }
        }

        if ($DataPoints -contains 'Weight') {
            $weightEntries = $Entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "weight" }
            foreach ($entry in $weightEntries) {
                if ($entry.data.weight) {
                    $weightWithContext = [PSCustomObject]@{
                        Date      = $entry.date
                        Timestamp = $entry.time
                        EntryId   = $entry.entry_id
                        WeightLbs = $entry.data.weight.weight_lbs
                        WeightKg  = $entry.data.weight.weight_kg
                        Notes     = $entry.notes
                    }
                    $results['Weight'] += $weightWithContext
                }
            }
        }

        if ($DataPoints -contains 'Mood') {
            $moodEntries = $Entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "mood" }
            foreach ($entry in $moodEntries) {
                if ($entry.data.mood) {
                    $moodWithContext = [PSCustomObject]@{
                        Date      = $entry.date
                        Timestamp = $entry.time
                        EntryId   = $entry.entry_id
                        MoodLevel = $entry.data.mood.mood_level
                        MoodNote  = $entry.data.mood.mood_note
                        Notes     = $entry.notes
                    }
                    $results['Mood'] += $moodWithContext
                }
            }
        }
    }

    return $results
}

# Function to sort health data by date
function Sort-HealthDataByDate {
    param($healthData)

    # For unified schema v2.0, detect date format and sort accordingly
    if ($healthData.Count -gt 0) {
        $sampleDate = $healthData[0].Date
        if ($sampleDate -match '^\d{4}-\d{2}-\d{2}$') {
            # YYYY-MM-DD format
            return $healthData | Sort-Object { [datetime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) }
        } elseif ($sampleDate -match '^\d{2}/\d{2}$') {
            # MM/dd format
            return $healthData | Sort-Object { [datetime]::ParseExact($_.Date, 'MM/dd', $null) }
        }
    }

    # Fallback to string sort if date format is unrecognized
    return $healthData | Sort-Object Date
}

# Function to clear cached data (useful when entries data changes)
function Clear-CachedData {
    $global:DatesList = $null
    $global:DistinctDataValues = @{}
}

# Function to get cached entries from PowerShell Universal
function Get-PSUCachedEntries {
    $Entries = (Get-PSUCache -Key 'entriesData' -OutVariable TempEntry) ? $TempEntry : (& {
            Write-Information 'Could not find entriesData cache'
            $EntriesPath = '/home/data/fusion-data/entries/entries.json'
            Get-EntriesData -entriesPath $EntriesPath
            Set-PSUCache -Key 'entriesData' -Value $Entries -Expiration (New-TimeSpan -Days 1) | Out-Null
            $Entries
        })
    $TempEntry ? (Remove-Variable -Name TempEntry -ErrorAction Ignore) : $null
    return $Entries
}

# Function to find duplicate entries based on similarity analysis (unified schema v2.0)
function Find-DuplicateEntries {
    param(
        [Parameter(Mandatory)]
        [Array]$Entries,
        [Parameter(Mandatory)]
        [int]$SimilarityThreshold = 80,
        [bool]$IncludeNotes = $true,
        [bool]$IncludeVitals = $true
    )

    $duplicates = @()
    $processedPairs = @{}

    # Group entries by date for efficiency
    $entriesByDate = $Entries | Group-Object -Property date

    foreach ($dateGroup in $entriesByDate) {
        $dateEntries = $dateGroup.Group

        # Compare each entry with every other entry for the same date
        for ($i = 0; $i -lt $dateEntries.Count; $i++) {
            for ($j = $i + 1; $j -lt $dateEntries.Count; $j++) {
                $entry1 = $dateEntries[$i]
                $entry2 = $dateEntries[$j]

                # Create a unique key for this pair to avoid duplicate comparisons
                $pairKey = "$($entry1.entry_id)-$($entry2.entry_id)"
                $reversePairKey = "$($entry2.entry_id)-$($entry1.entry_id)"

                if ($processedPairs.ContainsKey($pairKey) -or $processedPairs.ContainsKey($reversePairKey)) {
                    continue
                }

                $processedPairs[$pairKey] = $true

                # Compare the entries
                $comparison = Compare-EntryData -Entry1 $entry1 -Entry2 $entry2 -IncludeNotes $IncludeNotes -IncludeVitals $IncludeVitals

                if ($comparison.Score -ge $SimilarityThreshold) {
                    $duplicate = [PSCustomObject]@{
                        Date = $entry1.date
                        SimilarityScore = $comparison.Score
                        Entry1 = [PSCustomObject]@{
                            EntryId = $entry1.entry_id
                            Timestamp = $entry1.time
                            EntryTypes = $entry1.entry_types -join ', '
                            Notes = $entry1.notes
                        }
                        Entry2 = [PSCustomObject]@{
                            EntryId = $entry2.entry_id
                            Timestamp = $entry2.time
                            EntryTypes = $entry2.entry_types -join ', '
                            Notes = $entry2.notes
                        }
                        Reason = $comparison.Reason
                    }
                    $duplicates += $duplicate
                }
            }
        }
    }

    return $duplicates
}

# Function to compare two entries and return similarity score (unified schema v2.0)
function Compare-EntryData {
    param(
        [Parameter(Mandatory)]
        $Entry1,
        [Parameter(Mandatory)]
        $Entry2,
        [bool]$IncludeNotes = $true,
        [bool]$IncludeVitals = $true
    )

    $totalWeight = 0
    $matchingWeight = 0
    $reasons = @()

    # Compare entry types (20% weight)
    $entryTypesWeight = 20
    $totalWeight += $entryTypesWeight
    $commonTypes = $Entry1.entry_types | Where-Object { $Entry2.entry_types -contains $_ }
    $allTypes = ($Entry1.entry_types + $Entry2.entry_types) | Sort-Object -Unique
    if ($allTypes.Count -gt 0) {
        $typesSimilarity = $commonTypes.Count / $allTypes.Count
        $matchingWeight += $typesSimilarity * $entryTypesWeight
        if ($typesSimilarity -eq 1.0) { $reasons += "Entry types match exactly" }
        elseif ($typesSimilarity -gt 0.5) { $reasons += "Entry types partially match" }
    }

    # Compare each data type that exists in both entries
    foreach ($entryType in $commonTypes) {
        switch ($entryType) {
            "medication" {
                if ($Entry1.data.medication -and $Entry2.data.medication) {
                    $medWeight = 15
                    $totalWeight += $medWeight
                    $medSimilarity = Compare-Medications -Med1 $Entry1.data.medication -Med2 $Entry2.data.medication
                    $matchingWeight += $medSimilarity * $medWeight
                    if ($medSimilarity -eq 1.0) { $reasons += "Medications match exactly" }
                }
            }
            "pain" {
                if ($Entry1.data.pain -and $Entry2.data.pain) {
                    $painWeight = 15
                    $totalWeight += $painWeight
                    $painSimilarity = Compare-PainData -Pain1 $Entry1.data.pain -Pain2 $Entry2.data.pain
                    $matchingWeight += $painSimilarity * $painWeight
                    if ($painSimilarity -eq 1.0) { $reasons += "Pain data matches exactly" }
                }
            }
            "activity" {
                if ($Entry1.data.activity -and $Entry2.data.activity) {
                    $actWeight = 15
                    $totalWeight += $actWeight
                    $actSimilarity = Compare-Activities -Act1 $Entry1.data.activity -Act2 $Entry2.data.activity
                    $matchingWeight += $actSimilarity * $actWeight
                    if ($actSimilarity -eq 1.0) { $reasons += "Activities match exactly" }
                }
            }
            "vitals" {
                if ($IncludeVitals -and $Entry1.data.vitals -and $Entry2.data.vitals) {
                    $vitalsWeight = 15
                    $totalWeight += $vitalsWeight
                    $vitalsSimilarity = Compare-Vitals -Entry1 $Entry1 -Entry2 $Entry2
                    $matchingWeight += $vitalsSimilarity * $vitalsWeight
                    if ($vitalsSimilarity -eq 1.0) { $reasons += "Vitals match exactly" }
                }
            }
            "mood" {
                if ($Entry1.data.mood -and $Entry2.data.mood) {
                    $moodWeight = 10
                    $totalWeight += $moodWeight
                    $moodSimilarity = if ($Entry1.data.mood.mood_level -eq $Entry2.data.mood.mood_level) { 1.0 } else { 0.0 }
                    $matchingWeight += $moodSimilarity * $moodWeight
                    if ($moodSimilarity -eq 1.0) { $reasons += "Mood levels match exactly" }
                }
            }
        }
    }

    # Compare notes if requested (15% weight)
    if ($IncludeNotes) {
        $notesWeight = 15
        $totalWeight += $notesWeight
        $notesSimilarity = Compare-NoteText -Note1 $Entry1.notes -Note2 $Entry2.notes
        $matchingWeight += $notesSimilarity * $notesWeight
        if ($notesSimilarity -eq 1.0) { $reasons += "Notes match exactly" }
    }

    # Calculate final similarity score
    $similarityScore = if ($totalWeight -gt 0) {
        [math]::Round(($matchingWeight / $totalWeight) * 100, 1)
    } else {
        0
    }

    return [PSCustomObject]@{
        Score = $similarityScore
        Reason = if ($reasons.Count -gt 0) { $reasons -join "; " } else { "No significant matches found" }
    }
}

# Function to compare medication data (unified schema v2.0)
function Compare-Medications {
    param($Med1, $Med2)

    if (-not $Med1 -and -not $Med2) { return 1.0 }
    if (-not $Med1 -or -not $Med2) { return 0.0 }

    # Compare medication name and dosage
    if ($Med1.medication_name -eq $Med2.medication_name) {
        if ($Med1.dosage -eq $Med2.dosage) {
            return 1.0  # Perfect match
        } else {
            return 0.5  # Same medication, different dose
        }
    }

    return 0.0  # Different medications
}

# Function to compare pain data (unified schema v2.0)
function Compare-PainData {
    param($Pain1, $Pain2)

    if (-not $Pain1 -and -not $Pain2) { return 1.0 }
    if (-not $Pain1 -or -not $Pain2) { return 0.0 }

    # Compare pain location and severity
    if ($Pain1.location -eq $Pain2.location) {
        $severityDiff = [math]::Abs($Pain1.severity - $Pain2.severity)
        if ($severityDiff -le 1.0) {
            return 1.0  # Same location, similar severity
        } elseif ($severityDiff -le 2.0) {
            return 0.5  # Same location, moderate difference
        }
    }

    return 0.0  # Different location or very different severity
}

# Function to compare activity data (unified schema v2.0)
function Compare-Activities {
    param($Act1, $Act2)

    if (-not $Act1 -and -not $Act2) { return 1.0 }
    if (-not $Act1 -or -not $Act2) { return 0.0 }

    # Compare activity name and duration
    if ($Act1.activity_name -eq $Act2.activity_name) {
        $durationDiff = [math]::Abs($Act1.duration_minutes - $Act2.duration_minutes)
        if ($durationDiff -le 5) {
            return 1.0  # Same activity, similar duration
        } elseif ($durationDiff -le 15) {
            return 0.5  # Same activity, moderate difference
        }
    }

    return 0.0  # Different activity or very different duration
}

# Function to compare vital signs (unified schema v2.0)
function Compare-Vitals {
    param($Entry1, $Entry2)

    if (-not $Entry1.data.vitals -and -not $Entry2.data.vitals) { return 1.0 }
    if (-not $Entry1.data.vitals -or -not $Entry2.data.vitals) { return 0.0 }

    $vitals1 = $Entry1.data.vitals
    $vitals2 = $Entry2.data.vitals
    $matches = 0
    $total = 0

    # Compare each vital sign
    if ($vitals1.blood_pressure -or $vitals2.blood_pressure) {
        $total++
        if ($vitals1.blood_pressure -eq $vitals2.blood_pressure) { $matches++ }
    }

    if ($vitals1.oxygen_saturation -or $vitals2.oxygen_saturation) {
        $total++
        if ($vitals1.oxygen_saturation -eq $vitals2.oxygen_saturation) { $matches++ }
    }

    if ($vitals1.heart_rate -or $vitals2.heart_rate) {
        $total++
        if ($vitals1.heart_rate -eq $vitals2.heart_rate) { $matches++ }
    }

    if ($vitals1.temperature -or $vitals2.temperature) {
        $total++
        if ($vitals1.temperature -eq $vitals2.temperature) { $matches++ }
    }

    if ($total -gt 0) {
        return $matches / $total
    } else {
        return 1.0
    }
}

# Function to compare note text
function Compare-NoteText {
    param([string]$Note1, [string]$Note2)

    if ([string]::IsNullOrEmpty($Note1) -and [string]::IsNullOrEmpty($Note2)) { return 1.0 }
    if ([string]::IsNullOrEmpty($Note1) -or [string]::IsNullOrEmpty($Note2)) { return 0.0 }

    $Note1 = $Note1.ToLower().Trim()
    $Note2 = $Note2.ToLower().Trim()

    if ($Note1 -eq $Note2) { return 1.0 }

    # Check if one note contains the other
    if ($Note1.Contains($Note2) -or $Note2.Contains($Note1)) { return 0.8 }

    # Calculate word overlap
    $words1 = $Note1 -split '\s+' | Where-Object { $_.Length -gt 2 }
    $words2 = $Note2 -split '\s+' | Where-Object { $_.Length -gt 2 }

    if ($words1.Count -eq 0 -and $words2.Count -eq 0) { return 1.0 }
    if ($words1.Count -eq 0 -or $words2.Count -eq 0) { return 0.0 }

    $commonWords = $words1 | Where-Object { $words2 -contains $_ }
    $totalWords = ($words1 + $words2) | Sort-Object -Unique

    if ($totalWords.Count -gt 0) {
        return $commonWords.Count / $totalWords.Count
    } else {
        return 0.0
    }
}

# Export the functions so they can be used when the module is imported
Export-ModuleMember -Function Get-PSUCachedEntries, Get-HealthMetrics, Get-SleepHours, Get-AverageBackPain, Get-TotalActivityDuration, Convert-DateToDisplay, Get-EntriesData, Get-DatesList, Sort-HealthDataByDate, Set-CombinedData, Get-DateMedicationData, Get-DateActivityData, Get-DateVitalsData, Clear-CachedData, Find-DuplicateEntries, Compare-EntryData, Compare-Medications, Compare-PainData, Compare-Activities, Compare-Vitals, Compare-NoteText
