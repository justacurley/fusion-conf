# Unit Tests for HealthEntryClasses
# Uses Pester testing framework (built into PowerShell 5+ and PowerShell Core)

using module ../HealthEntryClasses.psm1

Describe 'MedicationValidator Tests' -Tag MedicationValidator, Medication {
    BeforeAll {
        $validator = [MedicationValidator]::new()
    }

    It 'Should allow any medication names (no longer validates against lookup)' {
        $validMeds = $validator.GetValidValues()
        $validMeds | Should -Be @()  # Returns empty array - accepts any medication
    }

    It 'Should allow any dosages (no longer validates against lookup)' {
        $dosages = $validator.GetValidDosages('any-medication')
        $dosages | Should -Be @()  # Returns empty array - accepts any dosage
    }

    It 'Should validate medication name is not empty using static method' {
        [MedicationValidator]::IsValidMedicationName('aspirin') | Should -Be $true
        [MedicationValidator]::IsValidMedicationName('') | Should -Be $false
        [MedicationValidator]::IsValidMedicationName($null) | Should -Be $false
        [MedicationValidator]::IsValidMedicationName('   ') | Should -Be $false
    }

    It 'Should validate dosage is not empty using static method' {
        [MedicationValidator]::IsValidDosage('500mg') | Should -Be $true
        [MedicationValidator]::IsValidDosage('1 tablet') | Should -Be $true
        [MedicationValidator]::IsValidDosage('') | Should -Be $false
        [MedicationValidator]::IsValidDosage($null) | Should -Be $false
        [MedicationValidator]::IsValidDosage('   ') | Should -Be $false
    }
}

Describe 'Mood Tests' -Tag Mood {
    Context 'Default Constructor' {
        It 'Should create with default values' {
            $mood = [Mood]::new()
            $mood.MoodLevel | Should -Be 3
            $mood.Note | Should -Be ''
        }

        It 'Should validate default values as valid' {
            $mood = [Mood]::new()
            $mood.IsValid() | Should -Be $true
        }
    }

    Context 'Parameterized Constructor' {
        It 'Should create with mood level and note' {
            $mood = [Mood]::new(4, 'Feeling good today')
            $mood.MoodLevel | Should -Be 4
            $mood.Note | Should -Be 'Feeling good today'
        }

        It 'Should throw for invalid mood level less than 1' {
            { [Mood]::new(0, 'Invalid mood') } | Should -Throw -ExpectedMessage '*Mood level must be between 1 and 5*'
        }

        It 'Should throw for invalid mood level greater than 5' {
            { [Mood]::new(6, 'Invalid mood') } | Should -Throw -ExpectedMessage '*Mood level must be between 1 and 5*'
        }

        It 'Should accept boundary values' {
            { [Mood]::new(1, 'Lowest mood') } | Should -Not -Throw
            { [Mood]::new(5, 'Highest mood') } | Should -Not -Throw
        }
    }

    Context 'Validation Method' {
        It 'Should validate mood level boundaries' {
            $mood = [Mood]::new(3, 'Normal mood')
            $mood.IsValid() | Should -Be $true

            # Test edge cases by directly setting properties
            $mood.MoodLevel = 0
            $mood.IsValid() | Should -Be $false

            $mood.MoodLevel = 6
            $mood.IsValid() | Should -Be $false

            $mood.MoodLevel = 1
            $mood.IsValid() | Should -Be $true

            $mood.MoodLevel = 5
            $mood.IsValid() | Should -Be $true
        }
    }

    Context 'ToHashtable Method' {
        It 'Should return correct hashtable structure' {
            $mood = [Mood]::new(4, 'Good day')
            $hashtable = $mood.ToHashtable()

            $hashtable | Should -BeOfType [hashtable]
            $hashtable.Keys | Should -Contain 'mood_level'
            $hashtable.Keys | Should -Contain 'mood_note'
            $hashtable.mood_level | Should -Be 4
            $hashtable.mood_note | Should -Be 'Good day'
        }
    }
}

Describe 'MedicationTaken Tests' -Tag MedicationTaken, Medication {
    Context 'Valid Medication Creation' {
        It 'Should create with any valid medication name and dosage' {
            { [MedicationTaken]::new('500mg', 'aspirin') } | Should -Not -Throw
            { [MedicationTaken]::new('1 tablet', 'multivitamin') } | Should -Not -Throw
            { [MedicationTaken]::new('10mg', 'custom-medication') } | Should -Not -Throw
        }

        It 'Should set properties correctly and trim whitespace' {
            $med = [MedicationTaken]::new('  500mg  ', '  aspirin  ')
            $med.medication | Should -Be 'aspirin'
            $med.dosage | Should -Be '500mg'
        }

        It 'Should validate as valid for any non-empty values' {
            $med = [MedicationTaken]::new('500mg', 'aspirin')
            $med.IsValid() | Should -Be $true

            $med2 = [MedicationTaken]::new('1 tablet', 'custom-med')
            $med2.IsValid() | Should -Be $true
        }

        It 'Should convert to hashtable correctly' {
            $med = [MedicationTaken]::new('500mg', 'aspirin')
            $hashtable = $med.ToHashtable()
            $hashtable.name | Should -Be 'aspirin'
            $hashtable.dosage | Should -Be '500mg'
        }
    }

    Context 'Invalid Medication Validation' {
        It 'Should throw for empty medication name' {
            { [MedicationTaken]::new('500mg', '') } | Should -Throw
        }

        It 'Should throw for null medication name' {
            { [MedicationTaken]::new('500mg', $null) } | Should -Throw
        }

        It 'Should throw for whitespace-only medication name' {
            { [MedicationTaken]::new('500mg', '   ') } | Should -Throw
        }

        It 'Should throw for empty dosage' {
            { [MedicationTaken]::new('', 'aspirin') } | Should -Throw
        }

        It 'Should throw for null dosage' {
            { [MedicationTaken]::new($null, 'aspirin') } | Should -Throw
        }

        It 'Should throw for whitespace-only dosage' {
            { [MedicationTaken]::new('   ', 'aspirin') } | Should -Throw
        }
    }

    Context 'Default Constructor' {
        It 'Should create with default values' {
            $med = [MedicationTaken]::new()
            $med.medication | Should -Be 'aspirin'
            $med.dosage | Should -Be '325mg'
        }

        It 'Should validate default values as valid' {
            $med = [MedicationTaken]::new()
            $med.IsValid() | Should -Be $true
        }
    }
}

Describe 'PainLocation Tests' -Tag Pain, PainLocation {
    Context 'Valid Pain Location Creation' {
        It 'Should create with valid parameters' {
            { [PainLocation]::new('back', 7.5, 'Test pain') } | Should -Not -Throw
        }

        It 'Should set properties correctly' {
            $pain = [PainLocation]::new('back', 7.5, 'Test pain')
            $pain.pain_level | Should -Be 7.5
            $pain.location | Should -Be 'back'
            $pain.note | Should -Be 'Test pain'
        }

        It 'Should validate as valid' {
            $pain = [PainLocation]::new('back', 7.5, 'Test pain')
            $pain.IsValid() | Should -Be $true
        }

        It 'Should convert to hashtable correctly' {
            $pain = [PainLocation]::new('back', 7.5, 'Test pain')
            $hashtable = $pain.ToHashtable()
            $hashtable.severity | Should -Be 7.5
            $hashtable.location | Should -Be 'back'
            $hashtable.note | Should -Be 'Test pain'
        }
    }

    Context 'Pain Level Validation' {
        It 'Should accept pain level 0.0' {
            $pain = [PainLocation]::new('back', 0.0, 'No pain')
            $pain.IsValid() | Should -Be $true
        }

        It 'Should accept pain level 10.0' {
            $pain = [PainLocation]::new('back', 10.0, 'Maximum pain')
            $pain.IsValid() | Should -Be $true
        }

        It 'Should accept pain level 5.5' {
            $pain = [PainLocation]::new('back', 5.5, 'Medium pain')
            $pain.IsValid() | Should -Be $true
        }
    }

    Context 'Default Constructor' {
        It 'Should create with default values' {
            $pain = [PainLocation]::new()
            $pain.pain_level | Should -Be 0.0
            $pain.location | Should -Be 'back'
            $pain.note | Should -Be ''
        }

        It 'Should validate default values as valid' {
            $pain = [PainLocation]::new()
            $pain.IsValid() | Should -Be $true
        }
    }

    Context 'Two Parameter Constructor' {
        It 'Should create with location and level' {
            $pain = [PainLocation]::new('shoulder', 6.0)
            $pain.location | Should -Be 'shoulder'
            $pain.pain_level | Should -Be 6.0
            $pain.note | Should -Be ''
        }

        It 'Should normalize location to lowercase' {
            $pain = [PainLocation]::new('UPPER_BACK', 5.0)
            $pain.location | Should -Be 'upper_back'
        }

        It 'Should set empty note by default' {
            $pain = [PainLocation]::new('knee', 3.0)
            $pain.note | Should -Be ''
        }
    }
}

Describe 'Vitals Tests' -Tag Vitals {
    Context 'Default Constructor' {
        It 'Should create with default values' {
            $vital = [Vitals]::new()
            $vital.o2 | Should -Be 95
            $vital.bpr | Should -Be '120/80'
        }

        It 'Should validate default values as valid' {
            $vital = [Vitals]::new()
            $vital.IsValid() | Should -Be $true
        }
    }

    Context 'Valid Vitals Creation' {
        It 'Should create construct' {
            { [Vitals]::new(90, '111/90') } | Should -Not -Throw
        }

        It 'Should assign properties correctly' {
            $vitals = [Vitals]::new(90, '111/90')
            $vitals.o2 | Should -Be 90
            $vitals.o2 | Should -BeOfType [int]
            $vitals.bpr | Should -Be '111/90'
        }
    }

    Context 'Four Parameter Constructor (Schema v2.0)' {
        It 'Should create with all vital signs' {
            $vitals = [Vitals]::new(92, '130/85', 75, 99.2)
            $vitals.o2 | Should -Be 92
            $vitals.bpr | Should -Be '130/85'
            $vitals.heart_rate | Should -Be 75
            $vitals.temperature | Should -Be 99.2
        }

        It 'Should validate heart rate range' {
            { [Vitals]::new(95, '120/80', 39, 98.6) } | Should -Throw -ExpectedMessage '*heart rate*must be between 40-220*'
            { [Vitals]::new(95, '120/80', 221, 98.6) } | Should -Throw -ExpectedMessage '*heart rate*must be between 40-220*'
        }

        It 'Should validate temperature range' {
            { [Vitals]::new(95, '120/80', 70, 94.9) } | Should -Throw -ExpectedMessage '*temperature*must be between 95.0-110.0*'
            { [Vitals]::new(95, '120/80', 70, 110.1) } | Should -Throw -ExpectedMessage '*temperature*must be between 95.0-110.0*'
        }

        It 'Should accept boundary values for heart rate and temperature' {
            { [Vitals]::new(95, '120/80', 40, 95.0) } | Should -Not -Throw
            { [Vitals]::new(95, '120/80', 220, 110.0) } | Should -Not -Throw
        }
    }

    Context 'Oxygen Level Validation' {
        It 'Should throw on invalid o2' {
            { [Vitals]::new(101, '120/80') } | Should -Throw
        }
        It 'Should throw on invalid bpr, too low' {
            { [Vitals]::new(95, '10/80') } | Should -Throw
        }
        It 'Should throw on invalid bpr, too high' {
            { [Vitals]::new(95, '100/1000') } | Should -Throw
        }
    }

    Context 'ToHashtable() Validation' {
        It 'Should return a hashtable with valid keys and values' {
            $vitals = [Vitals]::new(90, '111/90')
            $VitalsHashtable = $vitals.ToHashtable()
            $VitalsHashtable | Should -BeOfType [hashtable]
            $VitalsHashtable.Keys | Should -Contain 'oxygen_saturation'
            $VitalsHashtable.Keys | Should -Contain 'blood_pressure'
            $VitalsHashtable.Keys | Should -Contain 'heart_rate'
            $VitalsHashtable.Keys | Should -Contain 'temperature'
            $VitalsHashtable['oxygen_saturation'] | Should -Be 90
            $VitalsHashtable['blood_pressure'] | Should -Be '111/90'
            $VitalsHashtable['heart_rate'] | Should -Be 70  # Default value
            $VitalsHashtable['temperature'] | Should -Be 98.6  # Default value
        }
    }

    Context 'Blood Pressure Validation' {
        It 'Should accept valid BP formats' {
            { [Vitals]::new(95, '120/80') } | Should -Not -Throw
            { [Vitals]::new(95, '110/70') } | Should -Not -Throw
            { [Vitals]::new(95, '140/90') } | Should -Not -Throw
        }

        It 'Should throw on invalid BP format - letters' {
            { [Vitals]::new(95, 'abc/def') } | Should -Throw -ExpectedMessage '*Cannot convert value "abc" to type "System.Int32"*'
        }

        It 'Should throw on invalid BP format - missing diastolic' {
            { [Vitals]::new(95, '120') } | Should -Throw -ExpectedMessage '*The provided diastolic*value*between 40-200*'
        }

        It 'Should throw on invalid BP format - too many parts' {
            { [Vitals]::new(95, '120/80/60') } | Should -Throw -ExpectedMessage '*Cannot convert*value*to type*'
        }

        It 'Should throw on invalid BP format - missing systolic' {
            { [Vitals]::new(95, '/80') } | Should -Throw -ExpectedMessage '*The provided systolic value*between 40-200*'
        }
    }
}

Describe 'Activity Tests' -Tag Activity {
    Context 'Default Constructor' {
        It 'Should create with default values' {
            $action = [Activity]::new()
            $action.ActivityName | Should -Be 'Walking'
            $action.ActivityDuration | Should -Be 10
            $action.Note | Should -Be ''
        }
        It 'Should validate default values as valid' {
            [Activity]::new().IsValid() | Should -BeTrue
        }
    }
}

Describe 'Weight Tests' -Tag Weight {
    Context 'Default Constructor' {
        It 'Should create with default values' {
            $weight = [Weight]::new()
            $weight.weight_lbs | Should -Be 150.0
            $weight.weight_kg | Should -Be 68.0
        }

        It 'Should validate default values as valid' {
            $weight = [Weight]::new()
            $weight.IsValid() | Should -Be $true
        }
    }

    Context 'Single Parameter Constructor' {
        It 'Should create with weight in pounds' {
            $weight = [Weight]::new(175.0)
            $weight.weight_lbs | Should -Be 175.0
            $weight.weight_kg | Should -Be 79.4  # 175 * 0.453592 rounded to 1 decimal
        }

        It 'Should calculate kg from lbs correctly' {
            $weight = [Weight]::new(100.0)
            $weight.weight_kg | Should -Be 45.4  # 100 * 0.453592 rounded to 1 decimal
        }

        It 'Should throw for weight too low' {
            { [Weight]::new(49.0) } | Should -Throw -ExpectedMessage '*Weight in pounds must be between 50.0 and 500.0*'
        }

        It 'Should throw for weight too high' {
            { [Weight]::new(501.0) } | Should -Throw -ExpectedMessage '*Weight in pounds must be between 50.0 and 500.0*'
        }

        It 'Should accept boundary values' {
            { [Weight]::new(50.0) } | Should -Not -Throw
            { [Weight]::new(500.0) } | Should -Not -Throw
        }
    }

    Context 'Dual Parameter Constructor' {
        It 'Should create with both lbs and kg' {
            $weight = [Weight]::new(150.0, 68.0)
            $weight.weight_lbs | Should -Be 150.0
            $weight.weight_kg | Should -Be 68.0
        }

        It 'Should validate both pound and kg ranges' {
            { [Weight]::new(49.0, 68.0) } | Should -Throw -ExpectedMessage '*Weight in pounds must be between 50.0 and 500.0*'
            { [Weight]::new(150.0, 19.0) } | Should -Throw -ExpectedMessage '*Weight in kilograms must be between 20.0 and 250.0*'
            { [Weight]::new(501.0, 68.0) } | Should -Throw -ExpectedMessage '*Weight in pounds must be between 50.0 and 500.0*'
            { [Weight]::new(150.0, 251.0) } | Should -Throw -ExpectedMessage '*Weight in kilograms must be between 20.0 and 250.0*'
        }

        It 'Should accept boundary values for both parameters' {
            { [Weight]::new(50.0, 20.0) } | Should -Not -Throw
            { [Weight]::new(500.0, 250.0) } | Should -Not -Throw
        }
    }

    Context 'Validation Method' {
        It 'Should validate weight ranges correctly' {
            $weight = [Weight]::new(150.0, 68.0)
            $weight.IsValid() | Should -Be $true

            # Test edge cases by directly setting properties
            $weight.weight_lbs = 49.0
            $weight.IsValid() | Should -Be $false

            $weight.weight_lbs = 501.0
            $weight.IsValid() | Should -Be $false

            $weight.weight_lbs = 150.0
            $weight.weight_kg = 19.0
            $weight.IsValid() | Should -Be $false

            $weight.weight_kg = 251.0
            $weight.IsValid() | Should -Be $false
        }
    }

    Context 'ToHashtable Method' {
        It 'Should return correct hashtable structure' {
            $weight = [Weight]::new(175.0, 79.4)
            $hashtable = $weight.ToHashtable()

            $hashtable | Should -BeOfType [hashtable]
            $hashtable.Keys | Should -Contain 'weight_lbs'
            $hashtable.Keys | Should -Contain 'weight_kg'
            $hashtable.weight_lbs | Should -Be 175.0
            $hashtable.weight_kg | Should -Be 79.4
        }
    }
}

Describe 'Sleep Tests' -Tag Sleep {
    Context 'Default Constructor' {
        It 'Should create with default 8 hours' {
            $sleep = [Sleep]::new()
            $sleep.sleep_hours | Should -Be 8.0
        }

        It 'Should validate default values as valid' {
            $sleep = [Sleep]::new()
            $sleep.IsValid() | Should -Be $true
        }
    }

    Context 'Parameterized Constructor' {
        It 'Should create with specified hours' {
            $sleep = [Sleep]::new(7.5)
            $sleep.sleep_hours | Should -Be 7.5
        }

        It 'Should throw for negative hours' {
            { [Sleep]::new(-1.0) } | Should -Throw -ExpectedMessage '*Sleep hours must be between 0.0 and 24.0*'
        }

        It 'Should throw for more than 24 hours' {
            { [Sleep]::new(25.0) } | Should -Throw -ExpectedMessage '*Sleep hours must be between 0.0 and 24.0*'
        }

        It 'Should accept boundary values' {
            { [Sleep]::new(0.0) } | Should -Not -Throw
            { [Sleep]::new(24.0) } | Should -Not -Throw
        }
    }

    Context 'Validation Method' {
        It 'Should validate sleep hours range 0-24' {
            $sleep = [Sleep]::new(8.0)
            $sleep.IsValid() | Should -Be $true

            # Test edge cases by directly setting properties
            $sleep.sleep_hours = -1.0
            $sleep.IsValid() | Should -Be $false

            $sleep.sleep_hours = 25.0
            $sleep.IsValid() | Should -Be $false

            $sleep.sleep_hours = 0.0
            $sleep.IsValid() | Should -Be $true

            $sleep.sleep_hours = 24.0
            $sleep.IsValid() | Should -Be $true
        }
    }

    Context 'ToHashtable Method' {
        It 'Should return correct hashtable structure' {
            $sleep = [Sleep]::new(7.5)
            $hashtable = $sleep.ToHashtable()

            $hashtable | Should -BeOfType [hashtable]
            $hashtable.Keys | Should -Contain 'sleep_hours'
            $hashtable.sleep_hours | Should -Be 7.5
        }
    }
}

Describe 'HealthEntry Tests' -Tag HealthEntry {
    Context 'Default Constructor' {
        BeforeAll {
            $script:DefaultEntry = [HealthEntry]::new()
        }
        It 'Should create with default values' {
            { [HealthEntry]::new() } | Should -Not -Throw
            $script:DefaultEntry.Pain | Should -Be @()
            $script:DefaultEntry.Medication | Should -Be @()
            $script:DefaultEntry.Activity | Should -Be @()
            $script:DefaultEntry.Vitals | Should -Be $null
            $script:DefaultEntry.Note | Should -Be ''
        }

        It 'Should be valid when user email and data are present' {
            $entry = [HealthEntry]::new("test@example.com")
            $entry.Mood = [Mood]::new(3, "Test mood")
            $entry.UpdateEntryTypes()
            $entry.IsValid() | Should -BeTrue
        }
    }

    Context 'Validation Method' {
        BeforeEach {
            $script:TestEntry = [HealthEntry]::new("test@example.com")
        }
        It 'Should return true when Note is present and entry has data' {
            $script:TestEntry.Note = 'mock'
            $script:TestEntry.Mood = [Mood]::new(3, "Test")
            $script:TestEntry.UpdateEntryTypes()
            $script:TestEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Pain is present' {
            $script:TestEntry.Pain += [PainLocation]::new('back', 1.0, '')
            $script:TestEntry.UpdateEntryTypes()
            $script:TestEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Medication is present' {
            $script:TestEntry.Medication += [MedicationTaken]::new()
            $script:TestEntry.UpdateEntryTypes()
            $script:TestEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Activity is present' {
            $script:TestEntry.Activity += [Activity]::new()
            $script:TestEntry.UpdateEntryTypes()
            $script:TestEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Vitals is present' {
            $script:TestEntry.Vitals = [Vitals]::new()
            $script:TestEntry.UpdateEntryTypes()
            $script:TestEntry.IsValid() | Should -BeTrue
        }
    }

    Context 'ToHashtable Method' {
        BeforeEach {
            $script:TestEntry = [HealthEntry]::new("test@example.com")
        }

        It 'Should return schema v2.0 structure for entry with minimal data' {
            $script:TestEntry.Mood = [Mood]::new(3, "Test")
            $hash = $script:TestEntry.ToHashtable()

            # Should have all expected keys for schema v2.0
            $hash.Keys | Should -Contain 'entry_id'
            $hash.Keys | Should -Contain 'user_email'
            $hash.Keys | Should -Contain 'date'
            $hash.Keys | Should -Contain 'time'
            $hash.Keys | Should -Contain 'entry_types'
            $hash.Keys | Should -Contain 'data'
            $hash.Keys | Should -Contain 'notes'

            # Should have correct values
            $hash.user_email | Should -Be 'test@example.com'
            $hash.entry_id | Should -Match '^\d{10}$'
            $hash.date | Should -Match '^\d{4}-\d{2}-\d{2}$'
            $hash.time | Should -Match '^\d{2}:\d{2}$'
            $hash.entry_types | Should -Contain 'mood'
            $hash.data.mood.mood_level | Should -Be 3
            $hash.notes | Should -Be ''
        }

        It 'Should serialize Pain data correctly' {
            $script:TestEntry.Pain += [PainLocation]::new('back', 7.5, 'Lower back pain')
            $script:TestEntry.Pain += [PainLocation]::new('rquad', 3.0, 'Mild quad pain')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Pain data as array in data section
            $hash.data.Keys | Should -Contain 'pain'
            $hash.data.pain.Count | Should -Be 2

            # Check first pain entry
            $backPain = $hash.data.pain | Where-Object { $_.location -eq 'back' }
            $backPain.severity | Should -Be 7.5
            $backPain.note | Should -Be 'Lower back pain'

            # Check second pain entry
            $quadPain = $hash.data.pain | Where-Object { $_.location -eq 'rquad' }
            $quadPain.severity | Should -Be 3.0
            $quadPain.note | Should -Be 'Mild quad pain'
        }

        It 'Should serialize multiple Medications as array' {
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')
            $script:TestEntry.Medication += [MedicationTaken]::new('2mg', 'dilaudid')

            $hash = $script:TestEntry.ToHashtable()

            # Should have medications as array in data section
            $hash.data.Keys | Should -Contain 'medications'
            $hash.data.medications.Count | Should -Be 2

            # Check individual medication entries
            $firstMed = $hash.data.medications[0]
            $firstMed.name | Should -Be 'dilaudid'
            $firstMed.dosage | Should -Be '4mg'

            $secondMed = $hash.data.medications[1]
            $secondMed.name | Should -Be 'dilaudid'
            $secondMed.dosage | Should -Be '2mg'
        }

        It 'Should serialize single Medication correctly' {
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')

            $hash = $script:TestEntry.ToHashtable()

            # Should have medications as array in data section
            $hash.data.Keys | Should -Contain 'medications'
            $hash.data.medications.Count | Should -Be 1

            # Check medication entry
            $med = $hash.data.medications[0]
            $med.name | Should -Be 'dilaudid'
            $med.dosage | Should -Be '4mg'
        }

        It 'Should serialize Activity data correctly' {
            $script:TestEntry.Activity += [Activity]::new('Walking', 30, 'Morning walk')
            $script:TestEntry.Activity += [Activity]::new('Swimming', 45, 'Pool exercise')

            $hash = $script:TestEntry.ToHashtable()

            # Should have activities as array in data section
            $hash.data.Keys | Should -Contain 'activities'
            $hash.data.activities.Count | Should -Be 2

            # Check Walking structure
            $walkingActivity = $hash.data.activities | Where-Object { $_.name -eq 'Walking' }
            $walkingActivity.duration_minutes | Should -Be 30
            $walkingActivity.note | Should -Be 'Morning walk'

            # Check Swimming structure
            $swimmingActivity = $hash.data.activities | Where-Object { $_.name -eq 'Swimming' }
            $swimmingActivity.duration_minutes | Should -Be 45
            $swimmingActivity.note | Should -Be 'Pool exercise'
        }

        It 'Should serialize Vitals data correctly' {
            $script:TestEntry.Vitals = [Vitals]::new(92, '140/90')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Vitals data in data section
            $hash.data.Keys | Should -Contain 'vitals'
            $hash.data.vitals.oxygen_saturation | Should -Be 92
            $hash.data.vitals.blood_pressure | Should -Be '140/90'
        }

        It 'Should include note when present' {
            $script:TestEntry.Note = 'Had a rough day with pain'

            $hash = $script:TestEntry.ToHashtable()

            $hash.Keys | Should -Contain 'notes'
            $hash.notes | Should -Be 'Had a rough day with pain'
        }

        It 'Should handle complex entry with all components' {
            # Add all types of data
            $script:TestEntry.Pain += [PainLocation]::new('back', 8.0, 'Severe back pain')
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')
            $script:TestEntry.Activity += [Activity]::new('Walking', 15, 'Short walk')
            $script:TestEntry.Vitals = [Vitals]::new(94, '130/85')
            $script:TestEntry.Mood = [Mood]::new(2, 'Tough day')
            $script:TestEntry.Weight = [Weight]::new(175.0)
            $script:TestEntry.Sleep = [Sleep]::new(6.5)
            $script:TestEntry.Note = 'Complex health entry'

            $hash = $script:TestEntry.ToHashtable()

            # Verify all components are present in data section
            $hash.data.Keys | Should -Contain 'pain'
            $hash.data.Keys | Should -Contain 'medications'
            $hash.data.Keys | Should -Contain 'activities'
            $hash.data.Keys | Should -Contain 'vitals'
            $hash.data.Keys | Should -Contain 'mood'
            $hash.data.Keys | Should -Contain 'weight'
            $hash.data.Keys | Should -Contain 'sleep'

            $hash.data.pain.Count | Should -Be 1
            $hash.data.medications.Count | Should -Be 1
            $hash.data.activities.Count | Should -Be 1
            $hash.data.vitals.oxygen_saturation | Should -Be 94
            $hash.data.vitals.blood_pressure | Should -Be '130/85'
            $hash.data.mood.mood_level | Should -Be 2
            $hash.data.mood.mood_note | Should -Be 'Tough day'
            $hash.data.weight.weight_lbs | Should -Be 175.0
            $hash.data.sleep.sleep_hours | Should -Be 6.5
            $hash.notes | Should -Be 'Complex health entry'

            # Verify structure integrity
            $hash | Should -BeOfType [hashtable]
            $hash.Keys.Count | Should -Be 7  # entry_id, user_email, date, time, entry_types, data, notes
        }

        It 'Should handle multiple medications of same type' {
            $script:TestEntry.Medication += [MedicationTaken]::new('2mg', 'dilaudid')
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')

            $hash = $script:TestEntry.ToHashtable()

            # Should create array for multiple medications
            $hash.data.Keys | Should -Contain 'medications'
            $hash.data.medications.Count | Should -Be 2

            # Check both medications are present
            $firstMed = $hash.data.medications[0]
            $firstMed.name | Should -Be 'dilaudid'
            $firstMed.dosage | Should -Be '2mg'

            $secondMed = $hash.data.medications[1]
            $secondMed.name | Should -Be 'dilaudid'
            $secondMed.dosage | Should -Be '4mg'
        }

        It 'Should serialize Weight data correctly' {
            $script:TestEntry.Weight = [Weight]::new(175.0, 79.4)

            $hash = $script:TestEntry.ToHashtable()

            # Should have Weight data in data section
            $hash.data.Keys | Should -Contain 'weight'
            $hash.data.weight.weight_lbs | Should -Be 175.0
            $hash.data.weight.weight_kg | Should -Be 79.4
        }

        It 'Should serialize Sleep data correctly' {
            $script:TestEntry.Sleep = [Sleep]::new(7.5)

            $hash = $script:TestEntry.ToHashtable()

            # Should have Sleep data in data section
            $hash.data.Keys | Should -Contain 'sleep'
            $hash.data.sleep.sleep_hours | Should -Be 7.5
        }

        It 'Should serialize Mood data correctly' {
            $script:TestEntry.Mood = [Mood]::new(4, 'Good day')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Mood data in data section
            $hash.data.Keys | Should -Contain 'mood'
            $hash.data.mood.mood_level | Should -Be 4
            $hash.data.mood.mood_note | Should -Be 'Good day'
        }
    }

    Context 'FromHashtable Static Method Tests' {
        It 'Should create HealthEntry from minimal hashtable' {
            $data = @{
                entry_id = '2507171430'
                user_email = 'test@example.com'
                date = '2025-07-17'
                time = '14:30'
                entry_types = @('mood')
                data = @{
                    mood = @{
                        mood_level = 4
                        mood_note = 'Good day'
                    }
                }
                notes = 'Test entry'
            }

            $entry = [HealthEntry]::FromHashtable($data)

            $entry.EntryId | Should -Be '2507171430'
            $entry.UserEmail | Should -Be 'test@example.com'
            $entry.Date | Should -Be '2025-07-17'
            $entry.Time | Should -Be '14:30'
            $entry.EntryTypes | Should -Contain 'mood'
            $entry.Note | Should -Be 'Test entry'
            $entry.Mood.MoodLevel | Should -Be 4
            $entry.Mood.Note | Should -Be 'Good day'
        }

        It 'Should handle empty hashtable gracefully' {
            $data = @{}
            $entry = [HealthEntry]::FromHashtable($data)
            $entry.GetType().Name | Should -Be 'HealthEntry'
            $entry.EntryId | Should -BeNullOrEmpty
            $entry.UserEmail | Should -BeNullOrEmpty
        }

        It 'Should reconstruct complex entry with all data types' {
            $data = @{
                entry_id = '2507171445'
                user_email = 'complex@test.com'
                date = '2025-07-17'
                time = '14:45'
                entry_types = @('mood', 'vitals', 'medications', 'activities', 'pain', 'weight', 'sleep')
                data = @{
                    mood = @{
                        mood_level = 3
                        mood_note = 'Average day'
                    }
                    vitals = @{
                        oxygen_saturation = 95
                        blood_pressure = '120/80'
                        heart_rate = 72
                        temperature = 98.6
                    }
                    medications = @(
                        @{ name = 'aspirin'; dosage = '325mg' },
                        @{ name = 'vitamins'; dosage = '1 tablet' }
                    )
                    activities = @(
                        @{ name = 'Walking'; duration_minutes = 30; note = 'Morning walk' },
                        @{ name = 'Swimming'; duration_minutes = 45; note = 'Pool exercise' }
                    )
                    pain = @(
                        @{ location = 'back'; severity = 6.5; note = 'Lower back' },
                        @{ location = 'knee'; severity = 3.0; note = 'Right knee' }
                    )
                    weight = @{
                        weight_lbs = 175.0
                        weight_kg = 79.4
                    }
                    sleep = @{
                        sleep_hours = 7.5
                    }
                }
                notes = 'Complex test entry'
            }

            $entry = [HealthEntry]::FromHashtable($data)

            # Verify all components were reconstructed correctly
            $entry.Mood.MoodLevel | Should -Be 3
            $entry.Mood.Note | Should -Be 'Average day'

            $entry.Vitals.o2 | Should -Be 95
            $entry.Vitals.bpr | Should -Be '120/80'
            $entry.Vitals.heart_rate | Should -Be 72
            $entry.Vitals.temperature | Should -Be 98.6

            $entry.Medication.Count | Should -Be 2
            $entry.Medication[0].medication | Should -Be 'aspirin'
            $entry.Medication[0].dosage | Should -Be '325mg'
            $entry.Medication[1].medication | Should -Be 'vitamins'
            $entry.Medication[1].dosage | Should -Be '1 tablet'

            $entry.Activity.Count | Should -Be 2
            $entry.Activity[0].ActivityName | Should -Be 'Walking'
            $entry.Activity[0].ActivityDuration | Should -Be 30
            $entry.Activity[0].Note | Should -Be 'Morning walk'

            $entry.Pain.Count | Should -Be 2
            $entry.Pain[0].location | Should -Be 'back'
            $entry.Pain[0].pain_level | Should -Be 6.5
            $entry.Pain[0].note | Should -Be 'Lower back'

            $entry.Weight.weight_lbs | Should -Be 175.0
            $entry.Weight.weight_kg | Should -Be 79.4

            $entry.Sleep.sleep_hours | Should -Be 7.5
        }

        It 'Should handle missing data section' {
            $data = @{
                entry_id = '2507171500'
                user_email = 'minimal@test.com'
                date = '2025-07-17'
                time = '15:00'
                entry_types = @()
                notes = 'No data'
            }

            $entry = [HealthEntry]::FromHashtable($data)
            $entry.EntryId | Should -Be '2507171500'
            $entry.UserEmail | Should -Be 'minimal@test.com'
            $entry.Mood | Should -Be $null
            $entry.Vitals | Should -Be $null
            $entry.Medication.Count | Should -Be 0
        }

        It 'Should handle activities without notes' {
            $data = @{
                entry_id = '2507171515'
                user_email = 'activity@test.com'
                date = '2025-07-17'
                time = '15:15'
                entry_types = @('activities')
                data = @{
                    activities = @(
                        @{ name = 'Running'; duration_minutes = 20 }
                    )
                }
                notes = ''
            }

            $entry = [HealthEntry]::FromHashtable($data)
            $entry.Activity.Count | Should -Be 1
            $entry.Activity[0].ActivityName | Should -Be 'Running'
            $entry.Activity[0].ActivityDuration | Should -Be 20
            $entry.Activity[0].Note | Should -Be ''
        }

        It 'Should handle pain without notes' {
            $data = @{
                entry_id = '2507171530'
                user_email = 'pain@test.com'
                date = '2025-07-17'
                time = '15:30'
                entry_types = @('pain')
                data = @{
                    pain = @(
                        @{ location = 'shoulder'; severity = 4.0 }
                    )
                }
                notes = ''
            }

            $entry = [HealthEntry]::FromHashtable($data)
            $entry.Pain.Count | Should -Be 1
            $entry.Pain[0].location | Should -Be 'shoulder'
            $entry.Pain[0].pain_level | Should -Be 4.0
            $entry.Pain[0].note | Should -Be ''
        }

        It 'Should round-trip correctly with ToHashtable' {
            # Create original entry
            $original = [HealthEntry]::new('roundtrip@test.com')
            $original.Mood = [Mood]::new(4, 'Happy')
            $original.Vitals = [Vitals]::new(96, '125/85', 75, 98.7)
            $original.Medication += [MedicationTaken]::new('500mg', 'ibuprofen')
            $original.Activity += [Activity]::new('Cycling', 60, 'Bike ride')
            $original.Pain += [PainLocation]::new('wrist', 2.5, 'Minor pain')
            $original.Weight = [Weight]::new(160.0, 72.6)
            $original.Sleep = [Sleep]::new(8.0)
            $original.Note = 'Round-trip test'

            # Convert to hashtable and back
            $hashtable = $original.ToHashtable()
            $reconstructed = [HealthEntry]::FromHashtable($hashtable)

            # Verify all data survived the round trip
            $reconstructed.UserEmail | Should -Be 'roundtrip@test.com'
            $reconstructed.Mood.MoodLevel | Should -Be 4
            $reconstructed.Mood.Note | Should -Be 'Happy'
            $reconstructed.Vitals.o2 | Should -Be 96
            $reconstructed.Vitals.bpr | Should -Be '125/85'
            $reconstructed.Medication[0].medication | Should -Be 'ibuprofen'
            $reconstructed.Medication[0].dosage | Should -Be '500mg'
            $reconstructed.Activity[0].ActivityName | Should -Be 'Cycling'
            $reconstructed.Pain[0].location | Should -Be 'wrist'
            $reconstructed.Weight.weight_lbs | Should -Be 160.0
            $reconstructed.Sleep.sleep_hours | Should -Be 8.0
            $reconstructed.Note | Should -Be 'Round-trip test'
        }
    }

    Context 'ValidateSchemaV2 Method Tests' {
        BeforeEach {
            $script:TestEntry = [HealthEntry]::new('validation@test.com')
            $script:TestEntry.Mood = [Mood]::new(3, 'Test')
            $script:TestEntry.UpdateEntryTypes()
        }

        It 'Should validate correct entry_id format (yyMMddHHmm)' {
            $script:TestEntry.EntryId = '2507171600'
            $script:TestEntry.ValidateSchemaV2() | Should -Be $true

            $script:TestEntry.EntryId = '0101010101'
            $script:TestEntry.ValidateSchemaV2() | Should -Be $true
        }

        It 'Should reject invalid entry_id formats' {
            # Too short
            $script:TestEntry.EntryId = '250717160'
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false

            # Too long
            $script:TestEntry.EntryId = '25071716000'
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false

            # Contains letters
            $script:TestEntry.EntryId = '250717160A'
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false

            # Contains special characters
            $script:TestEntry.EntryId = '2507171-60'
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false

            # Empty string
            $script:TestEntry.EntryId = ''
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false
        }

        It 'Should validate correct entry_types' {
            $validTypes = @('mood', 'vitals', 'medications', 'activities', 'pain', 'weight', 'sleep')

            foreach ($type in $validTypes) {
                $script:TestEntry.EntryTypes = @($type)
                $script:TestEntry.ValidateSchemaV2() | Should -Be $true
            }
        }

        It 'Should reject invalid entry_types' {
            $script:TestEntry.EntryTypes = @('invalid_type')
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false

            $script:TestEntry.EntryTypes = @('mood', 'invalid_type')
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false

            $script:TestEntry.EntryTypes = @('MOOD')  # Case sensitive
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false
        }

        It 'Should handle empty entry_types array' {
            $script:TestEntry.EntryTypes = @()
            $script:TestEntry.ValidateSchemaV2() | Should -Be $false  # Should fail IsValid() check
        }

        It 'Should validate multiple valid entry_types' {
            $script:TestEntry.EntryTypes = @('mood', 'vitals', 'medications')
            $script:TestEntry.ValidateSchemaV2() | Should -Be $true

            $script:TestEntry.EntryTypes = @('activities', 'pain', 'weight', 'sleep')
            $script:TestEntry.ValidateSchemaV2() | Should -Be $true
        }

        It 'Should call IsValid() as part of validation' {
            # Create entry that will fail IsValid() due to missing user email
            $invalidEntry = [HealthEntry]::new('')
            $invalidEntry.EntryId = '2507171630'
            $invalidEntry.EntryTypes = @('mood')

            $invalidEntry.ValidateSchemaV2() | Should -Be $false
        }

        It 'Should handle exceptions gracefully' {
            # Force an exception by setting EntryId to null
            $script:TestEntry.EntryId = $null
            $result = $script:TestEntry.ValidateSchemaV2()
            $result | Should -Be $false
        }

        It 'Should validate complete schema v2.0 compliant entry' {
            $script:TestEntry.EntryId = '2507171645'
            $script:TestEntry.UserEmail = 'complete@test.com'
            $script:TestEntry.Date = '2025-07-17'
            $script:TestEntry.Time = '16:45'
            $script:TestEntry.EntryTypes = @('mood', 'vitals')
            $script:TestEntry.Mood = [Mood]::new(4, 'Good')
            $script:TestEntry.Vitals = [Vitals]::new(95, '120/80')

            $script:TestEntry.ValidateSchemaV2() | Should -Be $true
        }
    }
}

Describe 'Integration Tests' {
    It 'Should be able to create both classes together' {
        $med = [MedicationTaken]::new('4mg', 'dilaudid')
        $pain = [PainLocation]::new('back', 8.0, 'Lower back pain')

        $med.IsValid() | Should -Be $true
        $pain.IsValid() | Should -Be $true
    }

    It 'Should serialize both classes to hashtables for potential JSON export' {
        $med = [MedicationTaken]::new('4mg', 'dilaudid')
        $pain = [PainLocation]::new('back', 8.0, 'Lower back pain')

        $medHash = $med.ToHashtable()
        $painHash = $pain.ToHashtable()

        $medHash.Keys.Count | Should -Be 2
        $painHash.Keys.Count | Should -Be 3  # location, severity, and note
    }
}
