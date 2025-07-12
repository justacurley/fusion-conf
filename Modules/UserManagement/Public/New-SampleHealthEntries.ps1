function New-SampleHealthEntries {
    <#
    .SYNOPSIS
    Generates sample health entries data for testing and development purposes.

    .DESCRIPTION
    Creates realistic sample health data entries including vital signs, medications,
    pain levels, activities, and mood tracking for a specified number of days.

    .PARAMETER Email
    User's email address to identify the profile

    .PARAMETER DaysBack
    Number of days back from today to generate data for (default: 30)

    .PARAMETER EntriesPerDay
    Average number of entries to generate per day (default: 2)

    .PARAMETER SaveToFile
    If specified, saves the data directly to the user's entries.json file

    .EXAMPLE
    New-SampleHealthEntries -Email "user@example.com" -DaysBack 14 -EntriesPerDay 3

    .EXAMPLE
    New-SampleHealthEntries -Email "user@example.com" -SaveToFile

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Email,

        [int]$DaysBack = 30,
        [int]$EntriesPerDay = 2,
        [switch]$SaveToFile
    )


    $Response = @{
        Success = $false
        Message = ''
        EntriesGenerated = 0
        SampleData = @()
        FilePath = ''
    }

    try {
        # Ensure the UserManagement module is imported
        if (-not (Get-Module UserManagement)) {
            Import-Module UserManagement -Force
        }

        # Get user profile path if SaveToFile is specified
        if ($SaveToFile) {
            $UserData = [UserProfile]::GetUserProfilePath($Email)
            if ($UserData.Count -eq 0) {
                $Response.Message = "User $Email not found"
                return $Response
            }
            $UserPath = $UserData['UserDataPath']
            $EntriesPath = Join-Path $UserPath 'health-data/entries.json'
        }

        # Sample data arrays for realistic generation
        $Activities = @('Walking', 'Jogging', 'Swimming', 'Cycling', 'Yoga', 'Weight Training', 'Stretching', 'Dancing')
        $PainLocations = @('Lower Back', 'Neck', 'Shoulders', 'Knees', 'Headache', 'Wrist', 'Ankle')
        $MoodDescriptions = @('Excellent', 'Good', 'Fair', 'Poor', 'Anxious', 'Stressed', 'Relaxed', 'Energetic')
        $Medications = @('Lisinopril', 'Metformin', 'Atorvastatin', 'Vitamin D', 'Multivitamin', 'Aspirin')

        $SampleEntries = @()
        $EntryId = 1

        # Generate entries for each day
        for ($day = $DaysBack; $day -ge 0; $day--) {
            $CurrentDate = (Get-Date).AddDays(-$day)
            $EntriesForDay = Get-Random -Minimum 1 -Maximum ($EntriesPerDay + 2)

            for ($entry = 0; $entry -lt $EntriesForDay; $entry++) {
                # Random time during the day
                $Hour = Get-Random -Minimum 6 -Maximum 23
                $Minute = Get-Random -Minimum 0 -Maximum 59
                $EntryTime = $CurrentDate.Date.AddHours($Hour).AddMinutes($Minute)

                # Generate random entry type
                $EntryTypes = @('vitals', 'medication', 'activity', 'pain', 'mood', 'weight', 'sleep')
                $EntryType = $EntryTypes | Get-Random

                $BaseEntry = @{
                    id = $EntryId++
                    timestamp = $EntryTime.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
                    date = $EntryTime.ToString('yyyy-MM-dd')
                    time = $EntryTime.ToString('HH:mm')
                    type = $EntryType
                    user_email = $Email
                }

                # Generate specific data based on entry type
                switch ($EntryType) {
                    'vitals' {
                        $BaseEntry['data'] = @{
                            blood_pressure = @{
                                systolic = Get-Random -Minimum 110 -Maximum 140
                                diastolic = Get-Random -Minimum 70 -Maximum 90
                            }
                            heart_rate = Get-Random -Minimum 60 -Maximum 100
                            oxygen_saturation = Get-Random -Minimum 95 -Maximum 100
                            temperature = [math]::Round((Get-Random -Minimum 97.0 -Maximum 99.5), 1)
                        }
                        $BaseEntry['notes'] = 'Regular vital signs check'
                    }

                    'medication' {
                        $Med = $Medications | Get-Random
                        $BaseEntry['data'] = @{
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
                            taken_at = $EntryTime.ToString('HH:mm')
                            taken_as_prescribed = $true
                        }
                        $BaseEntry['notes'] = "Took $Med as scheduled"
                    }

                    'activity' {
                        $Activity = $Activities | Get-Random
                        $BaseEntry['data'] = @{
                            activity_name = $Activity
                            duration_minutes = Get-Random -Minimum 15 -Maximum 90
                            intensity = @('light', 'moderate', 'vigorous') | Get-Random
                            calories_burned = Get-Random -Minimum 50 -Maximum 400
                        }
                        $BaseEntry['notes'] = "Completed $Activity session"
                    }

                    'pain' {
                        $Location = $PainLocations | Get-Random
                        $BaseEntry['data'] = @{
                            location = $Location
                            severity = Get-Random -Minimum 1 -Maximum 10
                            duration_hours = Get-Random -Minimum 1 -Maximum 8
                            pain_type = @('sharp', 'dull', 'throbbing', 'burning', 'aching') | Get-Random
                        }
                        $BaseEntry['notes'] = "Pain in $Location area"
                    }

                    'mood' {
                        $Mood = $MoodDescriptions | Get-Random
                        $BaseEntry['data'] = @{
                            mood_rating = Get-Random -Minimum 1 -Maximum 10
                            mood_description = $Mood
                            stress_level = Get-Random -Minimum 1 -Maximum 10
                            energy_level = Get-Random -Minimum 1 -Maximum 10
                        }
                        $BaseEntry['notes'] = "Daily mood check - feeling $($Mood.ToLower())"
                    }

                    'weight' {
                        $BaseEntry['data'] = @{
                            weight_lbs = [math]::Round((Get-Random -Minimum 120.0 -Maximum 220.0), 1)
                            bmi = [math]::Round((Get-Random -Minimum 18.5 -Maximum 32.0), 1)
                        }
                        $BaseEntry['notes'] = 'Daily weight check'
                    }

                    'sleep' {
                        $SleepHours = [math]::Round((Get-Random -Minimum 5.0 -Maximum 10.0), 1)
                        $BaseEntry['data'] = @{
                            sleep_hours = $SleepHours
                            sleep_quality = Get-Random -Minimum 1 -Maximum 10
                            bedtime = (Get-Date).AddDays(-1).Date.AddHours(22).AddMinutes((Get-Random -Minimum 0 -Maximum 120)).ToString('HH:mm')
                            wake_time = (Get-Date).Date.AddHours(6).AddMinutes((Get-Random -Minimum 0 -Maximum 120)).ToString('HH:mm')
                        }
                        $BaseEntry['notes'] = "Slept $SleepHours hours"
                    }
                }

                $SampleEntries += $BaseEntry
            }
        }

        # Sort entries by timestamp (newest first)
        $SampleEntries = $SampleEntries | Sort-Object timestamp -Descending

        $Response.EntriesGenerated = $SampleEntries.Count
        $Response.SampleData = $SampleEntries

        # Save to file if requested
        if ($SaveToFile) {
            $SampleEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $EntriesPath -Force -ErrorAction Stop
            $Response.FilePath = $EntriesPath
            $Response.Message = "Successfully generated and saved $($SampleEntries.Count) sample entries to $EntriesPath"
        } else {
            $Response.Message = "Successfully generated $($SampleEntries.Count) sample entries"
        }

        $Response.Success = $true

        # Display summary
        $TypeCounts = $SampleEntries | Group-Object type | ForEach-Object { "$($_.Name): $($_.Count)" }
        Write-Host "✓ Generated $($SampleEntries.Count) sample health entries for $Email" -ForegroundColor Green
        Write-Host "  Entry types: $($TypeCounts -join ', ')" -ForegroundColor Cyan
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
