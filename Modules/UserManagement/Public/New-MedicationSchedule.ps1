function New-MedicationSchedule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Email,

        [string]$UserId = $null,

        [Parameter(Mandatory = $true)]
        [hashtable[]]$MedicationSchedules,

        [ValidateSet('preferences', 'separate_file')]
        [string]$OutputType = 'preferences',

        [string]$ScheduleName = "Medication Schedule - $(Get-Date -Format 'yyyy-MM-dd')",

        [switch]$OverwriteExisting
    )

    <#
    .SYNOPSIS
    Generates a detailed medication schedule supporting multiple daily dosages of the same medication.

    .DESCRIPTION
    Creates comprehensive medication schedules with support for:
    - Same medication multiple times per day with different dosages
    - Flexible time-based scheduling
    - Integration with existing user preferences
    - Export to preferences.json or separate schedule file

    .PARAMETER Email
    User's email address to identify the profile

    .PARAMETER UserId
    Optional user ID for direct lookup

    .PARAMETER MedicationSchedules
    Array of hashtables defining medication schedules. Each hashtable should contain:
    - medication_name (required): Name of the medication
    - schedules (required): Array of schedule entries with time, dosage, notes
    - prescribing_doctor: Doctor who prescribed the medication
    - start_date: When to start this medication schedule
    - end_date: When to end this medication schedule (optional)
    - active: Whether this schedule is currently active

    .PARAMETER OutputType
    Where to save the schedule: 'preferences' (add to preferences.json) or 'separate_file' (create dedicated schedule file)

    .PARAMETER ScheduleName
    Name for the medication schedule

    .PARAMETER OverwriteExisting
    Whether to overwrite existing medication schedules

    .EXAMPLE
    # Single medication with multiple daily dosages
    $Schedule = @(
        @{
            medication_name = "Metformin"
            prescribing_doctor = "Dr. Smith"
            start_date = "2025-07-11"
            active = $true
            schedules = @(
                @{
                    time = "08:00"
                    dosage = "500mg"
                    notes = "Take with breakfast"
                    frequency = "daily"
                },
                @{
                    time = "20:00"
                    dosage = "500mg"
                    notes = "Take with dinner"
                    frequency = "daily"
                }
            )
        }
    )

    New-MedicationSchedule -Email "user@example.com" -MedicationSchedules $Schedule

    .EXAMPLE
    # Multiple medications with complex schedules
    $ComplexSchedule = @(
        @{
            medication_name = "Lisinopril"
            prescribing_doctor = "Dr. Johnson"
            start_date = "2025-07-11"
            active = $true
            schedules = @(
                @{
                    time = "09:00"
                    dosage = "10mg"
                    notes = "Morning dose with water"
                    frequency = "daily"
                }
            )
        },
        @{
            medication_name = "Insulin"
            prescribing_doctor = "Dr. Williams"
            start_date = "2025-07-11"
            active = $true
            schedules = @(
                @{
                    time = "07:30"
                    dosage = "15 units"
                    notes = "Before breakfast"
                    frequency = "daily"
                },
                @{
                    time = "12:30"
                    dosage = "12 units"
                    notes = "Before lunch"
                    frequency = "daily"
                },
                @{
                    time = "18:30"
                    dosage = "18 units"
                    notes = "Before dinner"
                    frequency = "daily"
                }
            )
        }
    )

    New-MedicationSchedule -Email "user@example.com" -MedicationSchedules $ComplexSchedule -OutputType "separate_file"
    #>

    $Response = @{
        Success = $false
        Message = ''
        SchedulePath = ''
        ScheduleCreated = @()
        TotalDailyDoses = 0
    }

    try {
        # Validate user exists
        $UserData = [UserProfile]::GetUserProfilePath($Email, $UserId)
        if ($UserData.Count -eq 0) {
            $Response.Message = "User $Email not found"
            return $Response
        }

        $UserPath = $UserData['UserDataPath']

        # Validate and process medication schedules
        $ProcessedSchedules = @()
        $TotalDoses = 0

        foreach ($MedSchedule in $MedicationSchedules) {
            # Validate required fields
            if (-not $MedSchedule.medication_name) {
                throw "medication_name is required for all medication schedules"
            }
            if (-not $MedSchedule.schedules -or $MedSchedule.schedules.Count -eq 0) {
                throw "schedules array is required and must contain at least one schedule entry for $($MedSchedule.medication_name)"
            }

            # Process each schedule entry for this medication
            $ProcessedMedication = @{
                medication_name = $MedSchedule.medication_name
                prescribing_doctor = $MedSchedule.prescribing_doctor ?? ''
                start_date = $MedSchedule.start_date ?? (Get-Date -Format 'yyyy-MM-dd')
                end_date = $MedSchedule.end_date ?? $null
                active = [bool]($MedSchedule.active ?? $true)
                total_daily_doses = $MedSchedule.schedules.Count
                daily_schedules = @()
            }

            # Validate and process each time/dosage entry
            foreach ($Schedule in $MedSchedule.schedules) {
                if (-not $Schedule.time) {
                    throw "time is required for all schedule entries for $($MedSchedule.medication_name)"
                }
                if (-not $Schedule.dosage) {
                    throw "dosage is required for all schedule entries for $($MedSchedule.medication_name)"
                }

                # Validate time format (basic check for HH:mm)
                if ($Schedule.time -notmatch '^\d{1,2}:\d{2}$') {
                    throw "Invalid time format '$($Schedule.time)' for $($MedSchedule.medication_name). Use HH:mm format (e.g., '08:30')"
                }

                $ScheduleEntry = @{
                    time = $Schedule.time
                    dosage = $Schedule.dosage
                    notes = $Schedule.notes ?? ''
                    frequency = $Schedule.frequency ?? 'daily'
                    reminder_enabled = [bool]($Schedule.reminder_enabled ?? $true)
                    taken_with_food = [bool]($Schedule.taken_with_food ?? $false)
                    special_instructions = $Schedule.special_instructions ?? ''
                }

                $ProcessedMedication.daily_schedules += $ScheduleEntry
                $TotalDoses++
            }

            # Sort schedules by time for better organization
            $ProcessedMedication.daily_schedules = $ProcessedMedication.daily_schedules | Sort-Object { [DateTime]::ParseExact($_.time, 'H:mm', $null) }

            $ProcessedSchedules += $ProcessedMedication
            $Response.ScheduleCreated += "$($ProcessedMedication.medication_name) ($($ProcessedMedication.total_daily_doses) daily doses)"
        }

        $Response.TotalDailyDoses = $TotalDoses

        # Create the complete schedule structure
        $MedicationScheduleData = @{
            schedule_info = @{
                schedule_name = $ScheduleName
                created_date = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
                created_by = $Email
                total_medications = $ProcessedSchedules.Count
                total_daily_doses = $TotalDoses
                schedule_type = 'daily_medication_schedule'
                version = '1.0'
            }
            medications = $ProcessedSchedules
            schedule_summary = @{
                earliest_dose = ($ProcessedSchedules.daily_schedules | Sort-Object { [DateTime]::ParseExact($_.time, 'H:mm', $null) } | Select-Object -First 1).time
                latest_dose = ($ProcessedSchedules.daily_schedules | Sort-Object { [DateTime]::ParseExact($_.time, 'H:mm', $null) } | Select-Object -Last 1).time
                medications_with_multiple_doses = @($ProcessedSchedules | Where-Object { $_.total_daily_doses -gt 1 }).Count
                active_medications = @($ProcessedSchedules | Where-Object { $_.active }).Count
            }
        }

        if ($OutputType -eq 'separate_file') {
            # Save to separate medication schedule file
            $ScheduleFileName = "medication-schedule-$(Get-Date -Format 'yyyy-MM-dd-HHmm').json"
            $SchedulePath = Join-Path $UserPath $ScheduleFileName

            $MedicationScheduleData | ConvertTo-Json -Depth 10 | Out-File -FilePath $SchedulePath -Force -ErrorAction Stop
            $Response.SchedulePath = $SchedulePath
            $Response.Message = "Medication schedule saved to separate file: $ScheduleFileName"

        } else {
            # Add to existing preferences.json
            $PreferencesPath = Join-Path $UserPath 'preferences.json'

            if (Test-Path $PreferencesPath) {
                # Load existing preferences
                $ExistingPrefs = Get-Content $PreferencesPath | ConvertFrom-Json

                # Add or update medication schedule section
                if (-not $ExistingPrefs.PSObject.Properties['medication_schedules']) {
                    $ExistingPrefs | Add-Member -MemberType NoteProperty -Name 'medication_schedules' -Value @()
                }

                if ($OverwriteExisting) {
                    $ExistingPrefs.medication_schedules = @($MedicationScheduleData)
                } else {
                    # Check if a schedule with the same name exists
                    $ExistingSchedule = $ExistingPrefs.medication_schedules | Where-Object { $_.schedule_info.schedule_name -eq $ScheduleName }
                    if ($ExistingSchedule) {
                        throw "A medication schedule named '$ScheduleName' already exists. Use -OverwriteExisting to replace it."
                    }
                    $ExistingPrefs.medication_schedules += $MedicationScheduleData
                }

                # Update metadata
                if ($ExistingPrefs.PSObject.Properties['meta']) {
                    $ExistingPrefs.meta.last_updated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
                }

                # Save updated preferences
                $ExistingPrefs | ConvertTo-Json -Depth 10 | Out-File -FilePath $PreferencesPath -Force -ErrorAction Stop
                $Response.SchedulePath = $PreferencesPath
                $Response.Message = "Medication schedule added to user preferences"

            } else {
                throw "Preferences file not found. Please run New-UserHealthPreferences first to create the preferences structure."
            }
        }

        $Response.Success = $true

        # Generate summary message
        $SummaryLines = @(
            "✓ Medication schedule created successfully",
            "  📊 Total medications: $($ProcessedSchedules.Count)",
            "  💊 Total daily doses: $TotalDoses",
            "  ⏰ Schedule span: $($MedicationScheduleData.schedule_summary.earliest_dose) - $($MedicationScheduleData.schedule_summary.latest_dose)",
            "  📝 Medications configured:"
        )
        $Response.ScheduleCreated | ForEach-Object { $SummaryLines += "    • $_" }

        Write-Host ($SummaryLines -join "`n") -ForegroundColor Green

        return $Response

    } catch {
        $Response.Message = "Failed to create medication schedule: $($_.Exception.Message)"
        Write-Error $Response.Message
        return $Response
    }
}
