# PowerShell classes require 'using module' instead of Import-Module
using module ./HealthEntryClasses.psm1

# Test MedicationTaken class
try {

    $med = [MedicationTaken]::new("4mg", "dilaudid", "For severe pain")
    Write-Host "✅ MedicationTaken created successfully"
    Write-Host "   Medication: $($med.medication)"
    Write-Host "   Dosage: $($med.dosage)"
    Write-Host "   Note: $($med.note)"
    Write-Host "   Is Valid: $($med.IsValid())"
} catch {
    Write-Host "❌ Error creating MedicationTaken: $($_.Exception.Message)"
}

# Test PainLocation class
try {
    $pain = [PainLocation]::new(7.5, [PainLocationEnum]::Back, "Lower back pain")
    Write-Host "✅ PainLocation created successfully" 
    Write-Host "   Location: $($pain.location)"
    Write-Host "   Level: $($pain.pain_level)"
    Write-Host "   Note: $($pain.note)"
    Write-Host "   Is Valid: $($pain.IsValid())"
} catch {
    Write-Host "❌ Error creating PainLocation: $($_.Exception.Message)"
}