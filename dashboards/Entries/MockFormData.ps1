# Mock $EventData[0] objects for testing the Entries.ps1 form submission workflow
# These represent realistic form submissions with various scenarios

# Scenario 1: Complete entry with all fields filled
$script:MockFormData_Complete = [PSCustomObject]@{
    # Core fields
    date = "2025-06-30"
    timestamp = "14:30"
    notes = "Feeling much better today after starting new medication routine"
    sleep = "7:45"
    
    # Medication checkboxes (based on medications_lookup.json structure)
    med_dilaudid_4mg = $true
    med_dilaudid_2mg = $false
    med_tylenol_1g = $true
    med_tylenol_500mg = $false
    med_valium_5mg = $false
    med_vitaminD_500mg = $true
    med_lexapro_10mg = $false
    
    # Activity fields - Activity #1
    add_activity = $true
    activities_type_1 = "Walking"
    activities_length_1 = "30"
    activities_note_1 = "Morning walk around the neighborhood"
    
    # Activity fields - Additional activities (dynamically added)
    activities_type_456 = "Stretching"
    activities_length_456 = "15"
    activities_note_456 = "Post-walk stretching routine"
    
    # Pain fields - Pain Entry #1
    add_pain = $true
    pain_location_1 = "back"
    pain_level_1 = "4"
    pain_note_1 = "Lower back stiffness in morning"
    
    # Pain fields - Additional pain entry
    pain_location_789 = "right_glute"
    pain_level_789 = "3"
    pain_note_789 = "Mild discomfort when sitting"
    
    # Vitals
    add_vitals = $true
    o2 = "96"
    bpr = "118/76"
    
    # Image file (simulated)
    ImageFile = $null
}

# Scenario 2: Minimal entry with just required fields
$script:MockFormData_Minimal = [PSCustomObject]@{
    date = "2025-06-29"
    timestamp = "08:00"
    notes = ""
    sleep = ""
    
    # No medications selected
    med_dilaudid_4mg = $false
    med_dilaudid_2mg = $false
    med_tylenol_1g = $false
    med_tylenol_500mg = $false
    med_valium_5mg = $false
    med_vitaminD_500mg = $false
    med_lexapro_10mg = $false
    
    # No activities
    add_activity = $false
    
    # No pain entries
    add_pain = $false
    
    # No vitals
    add_vitals = $false
    
    ImageFile = $null
}

# Scenario 3: Medications only entry
$script:MockFormData_MedicationsOnly = [PSCustomObject]@{
    date = "2025-06-28"
    timestamp = "22:00"
    notes = "Evening medication routine"
    sleep = "8:30"
    
    # Multiple medications selected
    med_dilaudid_4mg = $true
    med_dilaudid_2mg = $false
    med_tylenol_1g = $false
    med_tylenol_500mg = $false
    med_valium_5mg = $true
    med_vitaminD_500mg = $false
    med_lexapro_10mg = $true
    
    # No activities
    add_activity = $false
    
    # No pain entries
    add_pain = $false
    
    # No vitals
    add_vitals = $false
    
    ImageFile = $null
}

# Scenario 4: Multiple activities and pain entries
$script:MockFormData_MultipleEntries = [PSCustomObject]@{
    date = "2025-06-27"
    timestamp = "16:45"
    notes = "Physical therapy session today"
    sleep = "6:15"
    
    # Some medications
    med_dilaudid_4mg = $false
    med_dilaudid_2mg = $true
    med_tylenol_1g = $true
    med_tylenol_500mg = $false
    med_valium_5mg = $false
    med_vitaminD_500mg = $true
    med_lexapro_10mg = $false
    
    # Multiple activities
    add_activity = $true
    activities_type_1 = "Physical Therapy"
    activities_length_1 = "60"
    activities_note_1 = "Focused on core strengthening"
    
    activities_type_234 = "Swimming"
    activities_length_234 = "45"
    activities_note_234 = "Light swimming in therapy pool"
    
    activities_type_567 = "Walking"
    activities_length_567 = "20"
    activities_note_567 = "Cool down walk"
    
    # Multiple pain entries
    add_pain = $true
    pain_location_1 = "back"
    pain_level_1 = "6"
    pain_note_1 = "Increased pain during therapy"
    
    pain_location_345 = "left_glute"
    pain_level_345 = "4"
    pain_note_345 = "Muscle tension"
    
    pain_location_678 = "hips"
    pain_level_678 = "3"
    pain_note_678 = "Mild stiffness"
    
    # Vitals
    add_vitals = $true
    o2 = "94"
    bpr = "125/82"
    
    ImageFile = $null
}

# Scenario 5: Edge cases with unusual values
$script:MockFormData_EdgeCases = [PSCustomObject]@{
    date = "2025-06-26"
    timestamp = "23:59"
    notes = "Late night entry with some unusual readings"
    sleep = "4.25"  # Decimal format
    
    # Only one medication
    med_dilaudid_4mg = $false
    med_dilaudid_2mg = $false
    med_tylenol_1g = $false
    med_tylenol_500mg = $true
    med_valium_5mg = $false
    med_vitaminD_500mg = $false
    med_lexapro_10mg = $false
    
    # Single activity with long duration
    add_activity = $true
    activities_type_1 = "Meditation"
    activities_length_1 = "120"  # 2 hours
    activities_note_1 = "Extended mindfulness session for pain management"
    
    # High pain level
    add_pain = $true
    pain_location_1 = "back"
    pain_level_1 = "8"
    pain_note_1 = "Severe flare-up requiring immediate attention"
    
    # Unusual vitals
    add_vitals = $true
    o2 = "89"  # Lower oxygen
    bpr = "140/95"  # Higher blood pressure
    
    ImageFile = $null
}

# Scenario 6: Empty/null values (error testing)
$script:MockFormData_EmptyValues = [PSCustomObject]@{
    date = ""
    timestamp = ""
    notes = $null
    sleep = $null
    
    # No medications
    med_dilaudid_4mg = $false
    med_dilaudid_2mg = $false
    med_tylenol_1g = $false
    med_tylenol_500mg = $false
    med_valium_5mg = $false
    med_vitaminD_500mg = $false
    med_lexapro_10mg = $false
    
    # Activities with empty values
    add_activity = $true
    activities_type_1 = ""
    activities_length_1 = ""
    activities_note_1 = $null
    
    # Pain with missing values
    add_pain = $true
    pain_location_1 = ""
    pain_level_1 = ""
    pain_note_1 = ""
    
    # Empty vitals
    add_vitals = $true
    o2 = ""
    bpr = ""
    
    ImageFile = $null
}

# Scenario 7: Sleep format variations
$script:MockFormData_SleepFormats = [PSCustomObject]@{
    date = "2025-06-25"
    timestamp = "07:30"
    notes = "Testing different sleep formats"
    sleep = "9:15"  # HH:MM format
    
    # Minimal other data
    med_dilaudid_4mg = $false
    med_dilaudid_2mg = $false
    med_tylenol_1g = $false
    med_tylenol_500mg = $false
    med_valium_5mg = $false
    med_vitaminD_500mg = $false
    med_lexapro_10mg = $false
    
    add_activity = $false
    add_pain = $false
    add_vitals = $false
    
    ImageFile = $null
}

# Helper function to simulate the form processing transformation
function ConvertTo-ProcessedFormData {
    param([PSCustomObject]$MockFormData)
    
    # Create a copy of the mock data
    $ProcessedData = $MockFormData.PSObject.Copy()
    
    # Apply the same transformations as in the actual form submission
    if ($ProcessedData.date) {
        $ProcessedData.timestamp = [datetime]::Parse($ProcessedData.timestamp).ToString("HHmm")
        $ProcessedData.date = [datetime]::Parse($ProcessedData.date).ToString("MMdd")
    }
    
    return $ProcessedData
}

# Export the mock data for use in tests
# Note: These variables will be available in the script scope when dot-sourced
# Export-ModuleMember -Variable MockFormData_Complete, MockFormData_Minimal, MockFormData_MedicationsOnly, MockFormData_MultipleEntries, MockFormData_EdgeCases, MockFormData_EmptyValues, MockFormData_SleepFormats
# Export-ModuleMember -Function ConvertTo-ProcessedFormData

# Example usage comments:
<#
# In test files, you can use like this:
. "$PSScriptRoot/MockFormData.ps1"

# Test with complete data
$testFormData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Complete
$convertedEntry = ConvertTo-EntriesFormat -Entry $testFormData

# Test with minimal data
$minimalFormData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Minimal
$minimalEntry = ConvertTo-EntriesFormat -Entry $minimalFormData

# Test edge cases
$edgeCaseData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_EdgeCases
$edgeCaseEntry = ConvertTo-EntriesFormat -Entry $edgeCaseData
#>
