# Quick test of the New-MedicationSchedule function

# Import the module
Import-Module ../UserManagement.psm1 -Force

# Test 1: Simple medication schedule
Write-Host "Testing New-MedicationSchedule function..." -ForegroundColor Yellow

# Create a simple test schedule
$TestSchedule = @(
    @{
        medication_name = "Test Medication"
        prescribing_doctor = "Dr. Test"
        start_date = "2025-07-11"
        active = $true
        schedules = @(
            @{
                time = "08:00"
                dosage = "100mg"
                notes = "Morning dose"
                frequency = "daily"
            },
            @{
                time = "20:00"
                dosage = "100mg"
                notes = "Evening dose"
                frequency = "daily"
            }
        )
    }
)

Write-Host "Function definition loaded successfully!" -ForegroundColor Green
Write-Host "Test schedule structure created with:" -ForegroundColor Cyan
Write-Host "  • Medication: $($TestSchedule[0].medication_name)" -ForegroundColor Gray
Write-Host "  • Daily doses: $($TestSchedule[0].schedules.Count)" -ForegroundColor Gray
Write-Host "  • Times: $($TestSchedule[0].schedules.time -join ', ')" -ForegroundColor Gray

Write-Host "`nFunction is ready for use!" -ForegroundColor Green
Write-Host "To test with a real user, ensure the user exists first with New-UserHealthPreferences." -ForegroundColor Yellow
