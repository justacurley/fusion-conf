# Example: How to use the New-MedicationSchedule function

# Import the UserManagement module
Import-Module ../UserManagement.psm1

Write-Host "=== Medication Schedule Generation Examples ===" -ForegroundColor Yellow

# Example 1: Single medication with multiple daily dosages
Write-Host "`n=== Example 1: Metformin - Multiple Daily Doses ===" -ForegroundColor Cyan

$MetforminSchedule = @(
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
                taken_with_food = $true
                special_instructions = "Monitor blood sugar levels"
            },
            @{
                time = "20:00"
                dosage = "500mg"
                notes = "Take with dinner"
                frequency = "daily"
                taken_with_food = $true
                special_instructions = "Avoid alcohol"
            }
        )
    }
)

# Create the schedule (assuming user exists)
$Result1 = New-MedicationSchedule -Email "john.doe@example.com" -MedicationSchedules $MetforminSchedule -ScheduleName "Daily Metformin Schedule"
Write-Host "Result: $($Result1.Message)" -ForegroundColor $(if($Result1.Success){'Green'}else{'Red'})
if ($Result1.Success) {
    Write-Host "Schedule saved to: $($Result1.SchedulePath)" -ForegroundColor Gray
}

# Example 2: Complex multi-medication schedule (like for diabetes management)
Write-Host "`n=== Example 2: Complex Diabetes Management Schedule ===" -ForegroundColor Cyan

$DiabetesSchedule = @(
    @{
        medication_name = "Insulin Rapid-Acting"
        prescribing_doctor = "Dr. Williams"
        start_date = "2025-07-11"
        active = $true
        schedules = @(
            @{
                time = "07:30"
                dosage = "15 units"
                notes = "Before breakfast - check blood sugar first"
                frequency = "daily"
                special_instructions = "Inject 15-30 minutes before eating"
            },
            @{
                time = "12:30"
                dosage = "12 units"
                notes = "Before lunch - adjust based on carb intake"
                frequency = "daily"
                special_instructions = "May need to adjust dose based on meal size"
            },
            @{
                time = "18:30"
                dosage = "18 units"
                notes = "Before dinner - largest meal dose"
                frequency = "daily"
                special_instructions = "Monitor for evening hypoglycemia"
            }
        )
    },
    @{
        medication_name = "Insulin Long-Acting"
        prescribing_doctor = "Dr. Williams"
        start_date = "2025-07-11"
        active = $true
        schedules = @(
            @{
                time = "22:00"
                dosage = "25 units"
                notes = "Bedtime dose for overnight coverage"
                frequency = "daily"
                special_instructions = "Same time every night for consistency"
            }
        )
    },
    @{
        medication_name = "Metformin Extended Release"
        prescribing_doctor = "Dr. Williams"
        start_date = "2025-07-11"
        active = $true
        schedules = @(
            @{
                time = "19:00"
                dosage = "1000mg"
                notes = "With dinner - extended release formula"
                frequency = "daily"
                taken_with_food = $true
                special_instructions = "Do not crush or chew tablet"
            }
        )
    }
)

$Result2 = New-MedicationSchedule -Email "jane.smith@example.com" -MedicationSchedules $DiabetesSchedule -ScheduleName "Diabetes Management Schedule" -OutputType "separate_file"
Write-Host "Result: $($Result2.Message)" -ForegroundColor $(if($Result2.Success){'Green'}else{'Red'})
if ($Result2.Success) {
    Write-Host "Separate schedule file created: $($Result2.SchedulePath)" -ForegroundColor Gray
}

# Example 3: Blood pressure medication with morning and evening doses
Write-Host "`n=== Example 3: Blood Pressure Management - Morning & Evening ===" -ForegroundColor Cyan

$BloodPressureSchedule = @(
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
                special_instructions = "Monitor for dizziness when standing"
            }
        )
    },
    @{
        medication_name = "Amlodipine"
        prescribing_doctor = "Dr. Johnson"
        start_date = "2025-07-11"
        active = $true
        schedules = @(
            @{
                time = "21:00"
                dosage = "5mg"
                notes = "Evening dose - may cause ankle swelling"
                frequency = "daily"
                special_instructions = "Take at bedtime to minimize side effects"
            }
        )
    }
)

$Result3 = New-MedicationSchedule -Email "bob.wilson@example.com" -MedicationSchedules $BloodPressureSchedule -ScheduleName "Blood Pressure Control Schedule"
Write-Host "Result: $($Result3.Message)" -ForegroundColor $(if($Result3.Success){'Green'}else{'Red'})

# Example 4: Pain management with multiple doses throughout the day
Write-Host "`n=== Example 4: Pain Management - Multiple Daily Doses ===" -ForegroundColor Cyan

$PainManagementSchedule = @(
    @{
        medication_name = "Ibuprofen"
        prescribing_doctor = "Dr. Brown"
        start_date = "2025-07-11"
        end_date = "2025-07-25"  # 2-week course
        active = $true
        schedules = @(
            @{
                time = "08:00"
                dosage = "400mg"
                notes = "Morning dose with breakfast"
                frequency = "daily"
                taken_with_food = $true
                special_instructions = "Take with food to prevent stomach upset"
            },
            @{
                time = "14:00"
                dosage = "400mg"
                notes = "Afternoon dose"
                frequency = "daily"
                taken_with_food = $true
                special_instructions = "Monitor for stomach pain"
            },
            @{
                time = "20:00"
                dosage = "400mg"
                notes = "Evening dose with dinner"
                frequency = "daily"
                taken_with_food = $true
                special_instructions = "Last dose of the day"
            }
        )
    },
    @{
        medication_name = "Acetaminophen"
        prescribing_doctor = "Dr. Brown"
        start_date = "2025-07-11"
        active = $true
        schedules = @(
            @{
                time = "11:00"
                dosage = "500mg"
                notes = "Between ibuprofen doses for breakthrough pain"
                frequency = "as_needed"
                special_instructions = "Do not exceed 4000mg total daily"
            },
            @{
                time = "17:00"
                dosage = "500mg"
                notes = "Evening breakthrough pain management"
                frequency = "as_needed"
                special_instructions = "Can be taken between ibuprofen doses"
            }
        )
    }
)

$Result4 = New-MedicationSchedule -Email "mary.jones@example.com" -MedicationSchedules $PainManagementSchedule -ScheduleName "Pain Management Schedule" -OutputType "separate_file"
Write-Host "Result: $($Result4.Message)" -ForegroundColor $(if($Result4.Success){'Green'}else{'Red'})

Write-Host "`n=== Summary of Medication Schedule Features ===" -ForegroundColor Yellow
Write-Host @"
✅ Features Demonstrated:

📊 Multiple Daily Dosages:
   • Same medication multiple times per day (Metformin: 8AM + 8PM)
   • Complex insulin regimens (before each meal + bedtime)
   • Pain management with overlapping medications

⏰ Flexible Scheduling:
   • Precise time specifications (HH:mm format)
   • Frequency options (daily, as_needed)
   • Start and end dates for limited courses

🏥 Clinical Integration:
   • Prescribing doctor tracking
   • Special instructions and notes
   • Food interaction flags
   • Reminder settings

💾 Storage Options:
   • Add to user preferences.json
   • Create separate schedule files
   • Overwrite protection with manual override

📋 Schedule Management:
   • Automatic sorting by time
   • Schedule summaries and statistics
   • Active/inactive medication tracking
   • Version control and metadata

🔍 Validation:
   • Required field checking
   • Time format validation
   • Duplicate schedule name protection
   • User existence verification
"@ -ForegroundColor Gray

Write-Host "`n=== Integration with Existing Preference System ===" -ForegroundColor Yellow
Write-Host @"
The medication schedule function integrates seamlessly with the existing health preference system:

1. Uses same user lookup system (Email + optional UserId)
2. Can add schedules to existing preferences.json 
3. Builds on medication tracking foundation from SetUserPreferences
4. Maintains consistent JSON structure and metadata
5. Supports the medication preference structure already established

Next steps for full integration:
• Dashboard UI for schedule management
• Reminder notification system
• Schedule adherence tracking
• Integration with health entry logging
"@ -ForegroundColor Gray
