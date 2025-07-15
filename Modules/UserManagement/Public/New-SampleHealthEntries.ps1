function New-SampleHealthEntries {
    <#
    .SYNOPSIS
    Generates unified sample health entries for testing and development purposes.

    .DESCRIPTION
    Creates realistic unified health data entries that group multiple health types together
    (mood, vitals, medication, activity, pain, weight, sleep) using the new composite key
    format (yyMMddHHmm). This simulates realistic user behavior where multiple health
    metrics are submitted together rather than as separate individual entries.

    The function creates entries with:
    - Composite entry_id in yyMMddHHmm format
    - entry_types array containing 1-4 health types per entry
    - Unified data object with all health metrics for that submission
    - Combined notes describing all activities in the entry

    .PARAMETER Email
    User's email address to identify the profile

    .PARAMETER DaysBack
    Number of days back from today to generate data for (default: 30)

    .PARAMETER EntriesPerDay
    Average number of unified entries to generate per day (default: 2)

    .PARAMETER SaveToFile
    If specified, saves the unified data to the provided file path. If not specified, only returns the data.

    .EXAMPLE
    New-SampleHealthEntries -Email "user@example.com" -DaysBack 14 -EntriesPerDay 3
    Generates 14 days of unified health entries with approximately 3 entries per day

    .EXAMPLE
    New-SampleHealthEntries -Email "user@example.com" -SaveToFile "/path/to/entries.json"
    Generates unified entries and saves to specified file

    .NOTES
    Schema Changes from Previous Version:
    - Uses composite entry_id (yyMMddHHmm) instead of auto-incrementing IDs
    - Groups multiple health types in single entries instead of individual entries
    - Eliminates metadata duplication by consolidating related submissions
    - Maintains all existing health type data structures within unified format

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Email,

        [int]$DaysBack = 30,
        [int]$EntriesPerDay = 2,
        [string]$SaveToFile
    )


    $Response = @{
        Success = $false
        Message = ''
        EntriesGenerated = 0
        SampleData = @()
        FilePath = ''
    }

    try {
        # Get user profile path if SaveToFile is specified
        if ($SaveToFile) {
            # Use the provided path directly
            $EntriesPath = $SaveToFile

            # Ensure the directory exists
            $Directory = Split-Path $EntriesPath -Parent
            if ($Directory -and -not (Test-Path $Directory)) {
                New-Item -Path $Directory -ItemType Directory -Force | Out-Null
            }
        }

        # Sample data arrays for realistic generation
        $Activities = @('Walking', 'Jogging', 'Swimming', 'Cycling', 'Yoga', 'Weight Training', 'Stretching', 'Dancing')
        $PainLocations = @('Lower Back', 'Neck', 'Shoulders', 'Knees', 'Headache', 'Wrist', 'Ankle')
        $Medications = @('Lisinopril', 'Metformin', 'Atorvastatin', 'Vitamin D', 'Multivitamin', 'Aspirin')

        # Mood tracking data (matching your 5-point scale implementation)
        $MoodLevels = @{
            1 = @{ emoji = '😞'; description = 'Awful'; notes = @('Having a really tough day', 'Feeling overwhelmed', 'Everything seems difficult') }
            2 = @{ emoji = '🙁'; description = 'Bad'; notes = @('Not feeling great today', 'Stressed about work', 'Having some challenges') }
            3 = @{ emoji = '😐'; description = 'Meh'; notes = @('Feeling neutral today', 'Neither good nor bad', 'Just getting through the day') }
            4 = @{ emoji = '🙂'; description = 'Good'; notes = @('Having a nice day', 'Feeling positive', 'Things are going well') }
            5 = @{ emoji = '😃'; description = 'Rad'; notes = @('Feeling fantastic!', 'Amazing day so far', 'Everything is going great', 'Really happy today') }
        }

        $SampleEntries = @()

        # Generate unified entries for each time period
        for ($day = $DaysBack; $day -ge 0; $day--) {
            $CurrentDate = (Get-Date).AddDays(-$day)
            $EntriesForDay = Get-Random -Minimum 1 -Maximum ($EntriesPerDay + 2)

            for ($entry = 0; $entry -lt $EntriesForDay; $entry++) {
                # Random time during the day
                $Hour = Get-Random -Minimum 6 -Maximum 23
                $Minute = Get-Random -Minimum 0 -Maximum 59
                $EntryTime = $CurrentDate.Date.AddHours($Hour).AddMinutes($Minute)

                # Generate entry_id in yyMMddHHmm format
                $EntryId = $EntryTime.ToString('yyMMddHHmm')

                # Create base unified entry structure
                $UnifiedEntry = @{
                    entry_id = $EntryId
                    user_email = $Email
                    date = $EntryTime.ToString('yyyy-MM-dd')
                    time = $EntryTime.ToString('HH:mm')
                    entry_types = @()
                    data = @{}
                    notes = ''
                }

                # Randomly determine which health types to include (1-4 types per entry)
                $AllTypes = @('mood', 'vitals', 'medication', 'activity', 'pain', 'weight', 'sleep')
                $NumTypes = Get-Random -Minimum 1 -Maximum 4
                $SelectedTypes = $AllTypes | Get-Random -Count $NumTypes

                $NoteParts = @()

                foreach ($Type in $SelectedTypes) {
                    $UnifiedEntry.entry_types += $Type

                    switch ($Type) {
                        'vitals' {
                            $Systolic = Get-Random -Minimum 110 -Maximum 140
                            $Diastolic = Get-Random -Minimum 70 -Maximum 90
                            $UnifiedEntry.data[$Type] = @{
                                blood_pressure = "$Systolic/$Diastolic"
                                heart_rate = Get-Random -Minimum 60 -Maximum 100
                                oxygen_saturation = Get-Random -Minimum 95 -Maximum 100
                                temperature = [math]::Round((Get-Random -Minimum 97.0 -Maximum 99.5), 1)
                            }
                            $NoteParts += 'Vital signs check'
                        }

                        'medication' {
                            $Med = $Medications | Get-Random
                            $UnifiedEntry.data[$Type] = @{
                                medication_name = $Med
                                dosage = switch ($Med) {
                                    'Lisinopril' { '10mg' }
                                    'Metformin' { '500mg' }
                                    'Atorvastatin' { '20mg' }
                                    'Vitamin D' { '1000 IU' }
                                    'Multivitamin' { '1 tablet' }
                                    'Aspirin' { '81mg' }
                                    default { '1 tablet' }
                                }
                            }
                            $NoteParts += "Took $Med"
                        }

                        'activity' {
                            $Activity = $Activities | Get-Random
                            $ActivityNotes = @(
                                'Great workout session',
                                'Feeling energized after this',
                                'Good way to start the day',
                                'Needed this after sitting all day',
                                'Really enjoyed this activity',
                                'Challenging but rewarding',
                                'Perfect weather for this'
                            )
                            $UnifiedEntry.data[$Type] = @{
                                activity_name = $Activity
                                duration_minutes = Get-Random -Minimum 15 -Maximum 90
                                note = $ActivityNotes | Get-Random
                            }
                            $NoteParts += "$Activity session"
                        }

                        'pain' {
                            $Location = $PainLocations | Get-Random
                            $PainNotes = @(
                                'Started gradually this morning',
                                'Woke up with this pain',
                                'Got worse during the day',
                                'Comes and goes throughout the day',
                                'Sharp stabbing sensation',
                                'Dull ache that persists',
                                'Feels tight and stiff'
                            )
                            $UnifiedEntry.data[$Type] = @{
                                location = $Location
                                severity = Get-Random -Minimum 1 -Maximum 10
                                note = $PainNotes | Get-Random
                            }
                            $NoteParts += "Pain in $Location"
                        }

                        'mood' {
                            # Generate realistic mood data matching your 5-point scale
                            $MoodLevel = Get-Random -Minimum 1 -Maximum 5
                            $MoodData = $MoodLevels[$MoodLevel]
                            $MoodNote = $MoodData.notes | Get-Random

                            $UnifiedEntry.data[$Type] = @{
                                mood_level = $MoodLevel
                                mood_note = $MoodNote
                            }
                            $NoteParts += "Mood: $($MoodData.description) $($MoodData.emoji)"
                        }

                        'weight' {
                            $WeightLbs = [math]::Round((Get-Random -Minimum 120.0 -Maximum 220.0), 1)
                            $WeightKg = [math]::Round(($WeightLbs * 0.453592), 1)
                            $UnifiedEntry.data[$Type] = @{
                                weight_lbs = $WeightLbs
                                weight_kg = $WeightKg
                            }
                            $NoteParts += 'Weight check'
                        }

                        'sleep' {
                            $SleepHours = [math]::Round((Get-Random -Minimum 5.0 -Maximum 10.0), 1)
                            $UnifiedEntry.data[$Type] = @{
                                sleep_hours = $SleepHours
                            }
                            $NoteParts += "Slept $SleepHours hours"
                        }
                    }
                }

                # Create a meaningful combined note
                $UnifiedEntry.notes = $NoteParts -join ', '

                $SampleEntries += $UnifiedEntry
            }
        }

        # Sort entries by entry_id (chronological order)
        $SampleEntries = $SampleEntries | Sort-Object entry_id

        $Response.EntriesGenerated = $SampleEntries.Count
        $Response.SampleData = $SampleEntries

        # Save to file if requested
        if ($SaveToFile) {
            $SampleEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $EntriesPath -Force -ErrorAction Stop
            $Response.FilePath = $EntriesPath
            $Response.Message = "Successfully generated and saved $($SampleEntries.Count) unified entries to $EntriesPath"
        } else {
            $Response.Message = "Successfully generated $($SampleEntries.Count) unified entries"
        }

        $Response.Success = $true

        # Display summary with unified entry statistics
        $TypeCounts = @{}
        foreach ($entry in $SampleEntries) {
            foreach ($type in $entry.entry_types) {
                if ($TypeCounts.ContainsKey($type)) {
                    $TypeCounts[$type]++
                } else {
                    $TypeCounts[$type] = 1
                }
            }
        }

        $TypeSummary = $TypeCounts.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }
        Write-Host "✓ Generated $($SampleEntries.Count) unified health entries for $Email" -ForegroundColor Green
        Write-Host "  Health type occurrences: $($TypeSummary -join ', ')" -ForegroundColor Cyan
        Write-Host "  Date range: $((Get-Date).AddDays(-$DaysBack).ToString('yyyy-MM-dd')) to $((Get-Date).ToString('yyyy-MM-dd'))" -ForegroundColor Cyan

        if ($SaveToFile) {
            Write-Host "  Saved to: $EntriesPath" -ForegroundColor Green
        }
        return $Response

    }
    catch {
        $Response.Message = "Failed to generate sample entries: $($_.Exception.Message)"
        Write-Error $Response.Message
        return $Response
    }
}
