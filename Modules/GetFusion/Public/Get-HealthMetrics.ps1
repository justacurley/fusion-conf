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
                    $maxPain = 0
                    foreach ($entry in $painEntries) {
                        if ($entry.data.pain) {
                            foreach ($painItem in $entry.data.pain) {
                                if ($painItem.severity -gt $maxPain) {
                                    $maxPain = $painItem.severity
                                }
                            }
                        }
                    }
                    if ($maxPain -gt 0) {
                        $baseObject = Set-CombinedData -combinedData $baseObject -name 'MaxPain' -data $maxPain
                    }
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
                # Calculate total activity duration for the day - updated for schema v2.0
                $activityEntries = $dateEntries | Where-Object { $_.entry_types -contains "activities" }
                if ($activityEntries) {
                    $totalDuration = 0
                    foreach ($entry in $activityEntries) {
                        if ($entry.data.activities) {
                            foreach ($activity in $entry.data.activities) {
                                $totalDuration += $activity.duration_minutes
                            }
                        }
                    }
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
                    # Handle pain as array in schema v2.0
                    foreach ($painItem in $entry.data.pain) {
                        $painWithContext = [PSCustomObject]@{
                            Date      = $entry.date
                            Timestamp = $entry.time
                            EntryId   = $entry.entry_id
                            Location  = $painItem.location
                            Severity  = $painItem.severity
                            Note      = $painItem.note
                            Notes     = $entry.notes
                        }
                        $results['Pain'] += $painWithContext
                    }
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
