# Example: How to use the New-UserHealthPreferences function in a PSU Dashboard form

# Import the UserManagement module
Import-Module ../UserManagement.psm1

# Example 1: Basic preferences setup for a new user
Write-Host "=== Example 1: Basic Health Tracking Setup ===" -ForegroundColor Yellow

$BasicPreferences = @{
    Email = "john.doe@example.com"
    UserId = "12345678-1234-1234-1234-123456789012"
    Timezone = "America/New_York"
    TemperatureUnit = "fahrenheit"
    WeightUnit = "pounds"
    TrackBloodPressure = $true
    TrackWeight = $true
    TrackMedications = $true
    BloodPressureTargetSystolic = 130
    BloodPressureTargetDiastolic = 85
    TargetWeight = 175
    NotificationsEnabled = $true
    CriticalAlerts = $true
}

# This is how you'd call it from a PSU form submission
$Result1 = New-UserHealthPreferences @BasicPreferences
Write-Host "Result: $($Result1.Message)" -ForegroundColor $(if($Result1.Success){'Green'}else{'Red'})

Write-Host "`n=== Example 2: Comprehensive Setup with Medications and Pain Tracking ===" -ForegroundColor Yellow

# Example 2: More comprehensive setup including medications and pain locations
$ComprehensivePreferences = @{
    Email = "jane.smith@example.com"
    UserId = "87654321-4321-4321-4321-210987654321"
    
    # Basic settings
    Timezone = "Pacific/Los_Angeles"
    TemperatureUnit = "celsius"
    WeightUnit = "kilograms"
    Theme = "dark"
    
    # Comprehensive tracking
    TrackBloodPressure = $true
    TrackOxygen = $true
    TrackHeartRate = $true
    TrackWeight = $true
    TrackGlucose = $true
    TrackMedications = $true
    TrackPain = $true
    TrackActivities = $true
    TrackSleep = $true
    TrackWater = $true
    TrackMood = $true
    
    # Health targets
    BloodPressureTargetSystolic = 120
    BloodPressureTargetDiastolic = 80
    OxygenTargetMin = 95
    HeartRateTargetResting = 65
    TargetWeight = 68.5
    GlucoseTargetMin = 80
    GlucoseTargetMax = 120
    
    # Activity and lifestyle goals
    DailyStepGoal = 12000
    DailyExerciseMinutes = 45
    SleepTargetHours = 8.5
    DailyWaterGoal = 10
    
    # Notifications
    NotificationsEnabled = $true
    CriticalAlerts = $true
    DailySummary = $true
    WeeklyReport = $true
    ReminderTime = "08:30"
    
    # Complex data: Medications
    Medications = @(
        @{
            name = "Lisinopril"
            dosage = "10mg"
            frequency = "daily"
            time_of_day = @("morning")
            doctor = "Dr. Johnson"
            reminders = $true
            notes = "For blood pressure control"
        },
        @{
            name = "Metformin"
            dosage = "500mg"
            frequency = "twice_daily"
            time_of_day = @("morning", "evening")
            doctor = "Dr. Williams"
            reminders = $true
            notes = "Take with meals"
        }
    )
    
    # Pain locations
    PainLocations = @(
        @{
            name = "Lower Back"
            chronic = $true
            baseline = 4
            description = "Chronic lower back pain from old injury"
        },
        @{
            name = "Right Knee"
            chronic = $false
            baseline = 2
            description = "Occasional knee pain during exercise"
        }
    )
    
    # Activities
    Activities = @(
        @{
            name = "Morning Walk"
            category = "cardio"
            intensity = "moderate"
            typical_duration = 30
            frequency = "daily"
            notes = "Around the neighborhood"
        },
        @{
            name = "Yoga"
            category = "flexibility"
            intensity = "light"
            typical_duration = 45
            frequency = "weekly"
            notes = "Helps with back pain"
        },
        @{
            name = "Swimming"
            category = "cardio"
            intensity = "moderate"
            typical_duration = 60
            frequency = "weekly"
            notes = "Low impact exercise"
        }
    )
}

$Result2 = New-UserHealthPreferences @ComprehensivePreferences
Write-Host "Result: $($Result2.Message)" -ForegroundColor $(if($Result2.Success){'Green'}else{'Red'})

Write-Host "`n=== Example 3: Getting Default Template for UI Forms ===" -ForegroundColor Yellow

# Example 3: Get the default template structure (useful for building UI forms)
$Template = [UserProfile]::GetDefaultPreferenceTemplate()
Write-Host "Default template structure available with these properties:" -ForegroundColor Cyan
$Template.PSObject.Properties | ForEach-Object { 
    Write-Host "  • $($_.Name): $($_.Value)" -ForegroundColor Gray 
}

Write-Host "`n=== PSU Dashboard Integration Notes ===" -ForegroundColor Yellow
Write-Host @"
To integrate this into a PSU Dashboard registration form:

1. Create form fields for each preference using the template above
2. Use New-UDForm with validation for required fields
3. On form submission, collect all values into a hashtable
4. Call New-UserHealthPreferences with the collected data
5. Display success/error messages using New-UDAlert

Example PSU form structure:
  New-UDForm -Content {
      New-UDTextbox -Id 'email' -Label 'Email' -Required
      New-UDSwitch -Id 'trackBP' -Label 'Track Blood Pressure'
      New-UDNumberInput -Id 'bpTarget' -Label 'Blood Pressure Target'
      # ... more form fields ...
  } -OnSubmit {
      param(\$EventData)
      \$Prefs = @{
          Email = \$EventData.email
          TrackBloodPressure = \$EventData.trackBP
          BloodPressureTargetSystolic = \$EventData.bpTarget
          # ... map all form fields ...
      }
      \$Result = New-UserHealthPreferences @Prefs
      if (\$Result.Success) {
          Show-UDToast -Message "Preferences saved!" -MessageColor Green
      } else {
          Show-UDToast -Message \$Result.Message -MessageColor Red
      }
  }
"@ -ForegroundColor Gray

Write-Host "`n=== Example 4: Creating Medication Schedules ===" -ForegroundColor Yellow

# Example 4: After setting up health preferences, create detailed medication schedules
# This demonstrates how medication schedules integrate with the preference system

# First, let's create a user with medication tracking enabled
$UserWithMedications = @{
    Email = "medication.user@example.com"
    UserId = "11111111-2222-3333-4444-555555555555"
    TrackMedications = $true
    NotificationsEnabled = $true
    CriticalAlerts = $true
    
    # Basic medication in preferences (simple tracking)
    Medications = @(
        @{
            name = "Lisinopril"
            dosage = "10mg"
            frequency = "daily"
            time_of_day = @("morning")
            doctor = "Dr. Johnson"
            reminders = $true
        }
    )
}

# Set up the basic preferences first
$BasicResult = New-UserHealthPreferences @UserWithMedications
if ($BasicResult.Success) {
    Write-Host "✓ Basic preferences with medication tracking set up" -ForegroundColor Green
    
    # Now create a detailed medication schedule that supports multiple daily doses
    $DetailedMedicationSchedule = @(
        @{
            medication_name = "Metformin Extended Release"
            prescribing_doctor = "Dr. Johnson"
            start_date = "2025-07-11"
            active = $true
            schedules = @(
                @{
                    time = "08:00"
                    dosage = "500mg"
                    notes = "With breakfast - helps reduce stomach upset"
                    frequency = "daily"
                    taken_with_food = $true
                    special_instructions = "Monitor blood glucose levels"
                },
                @{
                    time = "20:00"
                    dosage = "500mg"
                    notes = "With dinner - evening dose"
                    frequency = "daily"
                    taken_with_food = $true
                    special_instructions = "Avoid alcohol consumption"
                }
            )
        },
        @{
            medication_name = "Atorvastatin"
            prescribing_doctor = "Dr. Johnson"
            start_date = "2025-07-11"
            active = $true
            schedules = @(
                @{
                    time = "22:00"
                    dosage = "20mg"
                    notes = "Bedtime dose - statins work best at night"
                    frequency = "daily"
                    special_instructions = "Report any muscle pain or weakness"
                }
            )
        }
    )
    
    # Create the detailed schedule
    $ScheduleResult = New-MedicationSchedule -Email "medication.user@example.com" -MedicationSchedules $DetailedMedicationSchedule -ScheduleName "Daily Medication Regimen"
    
    if ($ScheduleResult.Success) {
        Write-Host "✓ Detailed medication schedule created successfully!" -ForegroundColor Green
        Write-Host "  📊 Total daily doses: $($ScheduleResult.TotalDailyDoses)" -ForegroundColor Cyan
        Write-Host "  💊 Medications scheduled:" -ForegroundColor Cyan
        $ScheduleResult.ScheduleCreated | ForEach-Object { Write-Host "    • $_" -ForegroundColor Gray }
        Write-Host "  📁 Saved to: $($ScheduleResult.SchedulePath)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Failed to create medication schedule: $($ScheduleResult.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "✗ Failed to set up basic preferences: $($BasicResult.Message)" -ForegroundColor Red
}

Write-Host "`n=== Integration Summary ===" -ForegroundColor Yellow
Write-Host @"
🔄 Medication Tracking Integration:

1. Basic Preferences (New-UserHealthPreferences):
   • Sets up medication tracking flag
   • Creates simple medication list in preferences.json
   • Establishes notification and reminder preferences

2. Detailed Schedules (New-MedicationSchedule):
   • Adds comprehensive scheduling to preferences.json
   • Supports multiple daily doses of same medication
   • Includes detailed clinical information and instructions
   • Provides time-based scheduling with precise dosing

3. Combined Benefits:
   • User preferences control whether medication tracking is enabled
   • Detailed schedules provide the actual medication timing
   • Notifications and reminders are controlled by preference settings
   • All data is stored in user's isolated directory structure
"@ -ForegroundColor Gray
