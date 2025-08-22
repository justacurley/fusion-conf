function New-UserHealthPreferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Email,

        [string]$UserId = $null,

        # Basic Profile Settings
        [string]$Timezone = 'UTC',
        [ValidateSet('fahrenheit', 'celsius')]
        [string]$TemperatureUnit = 'fahrenheit',
        [ValidateSet('pounds', 'kilograms')]
        [string]$WeightUnit = 'pounds',
        [string]$Language = 'en',
        [ValidateSet('light', 'dark')]
        [string]$Theme = 'light',

        # Vital Signs Tracking
        [switch]$TrackBloodPressure,
        [switch]$TrackOxygen,
        [switch]$TrackHeartRate,
        [switch]$TrackTemperature,
        [switch]$TrackWeight,
        [switch]$TrackGlucose,

        # Health Targets (optional)
        [int]$BloodPressureTargetSystolic = 120,
        [int]$BloodPressureTargetDiastolic = 80,
        [int]$OxygenTargetMin = 95,
        [int]$HeartRateTargetResting = 70,
        [int]$GlucoseTargetMin = 80,
        [int]$GlucoseTargetMax = 120,

        # Device Information (optional)
        [string]$BloodPressureDevice = '',
        [string]$OxygenSaturationDevice = '',
        [string]$BloodGlucoseDevice = '',
        [string]$HeartRateDevice = '',
        [string]$StepsDevice = '',

        # Other Health Tracking
        [switch]$TrackMedications,
        [switch]$TrackPain,
        [switch]$TrackActivities,
        [switch]$TrackSleep,
        [switch]$TrackWater,
        [switch]$TrackMeals,
        [switch]$TrackMood,
        [switch]$TrackSteps,

        # Goals and Targets
        [int]$DailyStepGoal = 10000,
        [decimal]$SleepTargetHours = 8,
        [int]$DailyWaterGoal = 8,

        # Notifications
        [switch]$NotificationsEnabled,
        [switch]$CriticalAlerts,
        [switch]$DailySummary,
        [switch]$WeeklyReport,
        [string]$ReminderTime = '09:00',

        # Medications (array of hashtables)
        [hashtable[]]$Medications = @(),

        # Pain locations (array of strings or hashtables)
        [object[]]$PainLocations = @(),

        # Activities (array of strings or hashtables)
        [object[]]$Activities = @()
    )

    $Response = @{
        Success = $false
        Message = ''
        PreferencesPath = ''
        PreferencesSet = @()
    }

    try {
        # Build preference data hashtable from parameters
        $PreferenceData = @{
            timezone = $Timezone
            temperature_unit = $TemperatureUnit
            weight_unit = $WeightUnit
            language = $Language
            theme = $Theme

            # Tracking flags
            track_blood_pressure = $TrackBloodPressure.IsPresent
            track_oxygen = $TrackOxygen.IsPresent
            track_heart_rate = $TrackHeartRate.IsPresent
            track_temperature = $TrackTemperature.IsPresent
            track_weight = $TrackWeight.IsPresent
            track_glucose = $TrackGlucose.IsPresent
            track_medications = $TrackMedications.IsPresent
            track_pain = $TrackPain.IsPresent
            track_activities = $TrackActivities.IsPresent
            track_sleep = $TrackSleep.IsPresent
            track_water = $TrackWater.IsPresent
            track_meals = $TrackMeals.IsPresent
            track_mood = $TrackMood.IsPresent
            track_steps = $TrackSteps.IsPresent

            # Targets and goals
            bp_target_systolic = $BloodPressureTargetSystolic
            bp_target_diastolic = $BloodPressureTargetDiastolic
            o2_target_min = $OxygenTargetMin
            hr_target_resting = $HeartRateTargetResting
            glucose_target_min = $GlucoseTargetMin
            glucose_target_max = $GlucoseTargetMax
            daily_step_goal = $DailyStepGoal
            sleep_target_hours = $SleepTargetHours
            daily_water_goal = $DailyWaterGoal

            # Device information
            bp_device = $BloodPressureDevice
            o2_device = $OxygenSaturationDevice
            glucose_device = $BloodGlucoseDevice
            hr_device = $HeartRateDevice
            steps_device = $StepsDevice
            # Notifications
            notifications_enabled = if ($PSBoundParameters.ContainsKey('NotificationsEnabled')) { $NotificationsEnabled.IsPresent } else { $true }
            critical_alerts = if ($PSBoundParameters.ContainsKey('CriticalAlerts')) { $CriticalAlerts.IsPresent } else { $true }
            daily_summary = $DailySummary.IsPresent
            weekly_report = $WeeklyReport.IsPresent
            reminder_time = $ReminderTime

            # Complex data
            medications = $Medications
            pain_locations = $PainLocations
            activities = $Activities
        }

        if (-not (Get-Module UserManagement)) {
            Import-Module UserManagement -Force
        }

        # Verify UserProfile class is available
        try {
            $TestClass = [UserProfile]
            Write-Information "UserProfile class loaded successfully"
        } catch {
            throw "UserProfile class is not available: $($_.Exception.Message)"
        }

        # Call the static method to set preferences
        $Result = [UserProfile]::SetUserPreferences($Email, $UserId, $PreferenceData)

        $Response.Success = $Result.Success
        $Response.Message = $Result.Message
        $Response.PreferencesPath = $Result.PreferencesPath
        $Response.PreferencesSet = $Result.PreferencesSet

        if ($Result.Success) {
            Write-Host "✓ Health preferences configured successfully for $Email" -ForegroundColor Green
            if ($Result.PreferencesSet.Count -gt 0) {
                Write-Host "  Custom items configured:" -ForegroundColor Cyan
                $Result.PreferencesSet | ForEach-Object { Write-Host "    • $_" -ForegroundColor Gray }
            }
        } else {
            Write-Warning "Failed to configure preferences: $($Result.Message)"
        }

    } catch {
        $Response.Message = "Error configuring user preferences: $($_.Exception.Message)"
        Write-Error $Response.Message
    }

    return $Response
}
