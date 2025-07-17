# Unit Tests for HealthEntryClasses
# Uses Pester testing framework (built into PowerShell 5+ and PowerShell Core)

using module ./HealthEntryClasses.psm1

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
            $hashtable.medication | Should -Be 'aspirin'
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
            $hashtable.pain_level | Should -Be 7.5
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
            $VitalsHashtable.Keys | Should -Contain 'o2'
            $VitalsHashtable.Keys | Should -Contain 'bpr'
            $VitalsHashtable['o2'] | Should -Be 90
            $VitalsHashtable['bpr'] | Should -Be '111/90'
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

        It 'Should be valid even when empty' {
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }
    }

    Context 'Validation Method' {
        BeforeEach {
            $script:DefaultEntry = [HealthEntry]::new()
        }
        It 'Should return true when Note is present' {
            $script:DefaultEntry.IsValid() | Should -BeTrue
            $script:DefaultEntry.Note = 'mock'
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Pain is present' {
            $script:DefaultEntry.IsValid() | Should -BeTrue
            $script:DefaultEntry.Pain += [PainLocation]::new('back', 1.0, '')
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Medication is present' {
            $script:DefaultEntry.IsValid() | Should -BeTrue
            $script:DefaultEntry.Medication += [MedicationTaken]::new()
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Activity is present' {
            $script:DefaultEntry.IsValid() | Should -BeTrue
            $script:DefaultEntry.Activity += [Activity]::new()
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Vitals is present' {
            $script:DefaultEntry.IsValid() | Should -BeTrue
            $script:DefaultEntry.Vitals = [Vitals]::new()
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }
    }

    Context 'ToHashtable Method' {
        BeforeEach {
            $script:TestEntry = [HealthEntry]::new()
        }

        It 'Should return empty structure for default entry' {
            $hash = $script:TestEntry.ToHashtable()

            # Should have all expected keys
            $hash.Keys | Should -Contain 'Medications'
            $hash.Keys | Should -Contain 'Activities'
            $hash.Keys | Should -Contain 'Pain'
            $hash.Keys | Should -Contain 'o2'
            $hash.Keys | Should -Contain 'bpr'
            $hash.Keys | Should -Contain 'medication_taken'
            $hash.Keys | Should -Contain 'note'

            # Empty arrays/hashtables for no data
            $hash.Medications | Should -BeOfType [hashtable]
            $hash.Medications.Keys.Count | Should -Be 0
            $hash.Activities | Should -BeOfType [hashtable]
            $hash.Activities.Keys.Count | Should -Be 0
            $hash.Pain | Should -BeOfType [hashtable]
            $hash.Pain.Keys.Count | Should -Be 0

            # Empty vitals
            $hash.o2 | Should -Be ''
            $hash.bpr | Should -Be ''
            $hash.medication_taken | Should -Be ''

            # Empty note
            $hash.note | Should -Be ''
        }

        It 'Should serialize Pain data correctly' {
            $script:TestEntry.Pain += [PainLocation]::new('back', 7.5, 'Lower back pain')
            $script:TestEntry.Pain += [PainLocation]::new('rquad', 3.0, 'Mild quad pain')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Pain data
            $hash.Pain.Keys | Should -Contain 'back'
            $hash.Pain.Keys | Should -Contain 'rquad'

            # Check back pain structure
            $hash.Pain.back.pain_level | Should -Be 7.5
            $hash.Pain.back.note | Should -Be 'Lower back pain'

            # Check rquad pain structure
            $hash.Pain.rquad.pain_level | Should -Be 3.0
            $hash.Pain.rquad.note | Should -Be 'Mild quad pain'
        }

        It 'Should serialize multiple Medications as array' {
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')
            $script:TestEntry.Medication += [MedicationTaken]::new('2mg', 'dilaudid')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Medications hashtable with dosage array (multiple doses)
            $hash.Medications.Keys | Should -Contain 'dilaudid'
            $hash.Medications.dilaudid | Should -Contain '4mg'
            $hash.Medications.dilaudid | Should -Contain '2mg'
            $hash.Medications.dilaudid.Count | Should -Be 2

            # Should have medication_taken summary
            $hash.medication_taken | Should -Be 'dilaudid'
        }

        It 'Should serialize single Medication as string' {
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Medications hashtable with single string value
            $hash.Medications.Keys | Should -Contain 'dilaudid'
            $hash.Medications.dilaudid | Should -BeOfType [string]
            $hash.Medications.dilaudid | Should -Be '4mg'

            # Should have medication_taken summary
            $hash.medication_taken | Should -Be 'dilaudid'
        }

        It 'Should serialize Activity data correctly' {
            $script:TestEntry.Activity += [Activity]::new('Walking', 30, 'Morning walk')
            $script:TestEntry.Activity += [Activity]::new('Swimming', 45, 'Pool exercise')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Activities
            $hash.Activities.Keys | Should -Contain 'Walking'
            $hash.Activities.Keys | Should -Contain 'Swimming'

            # Check Walking structure
            $hash.Activities.Walking.duration | Should -Be 30
            $hash.Activities.Walking.note | Should -Be 'Morning walk'

            # Check Swimming structure
            $hash.Activities.Swimming.duration | Should -Be 45
            $hash.Activities.Swimming.note | Should -Be 'Pool exercise'
        }

        It 'Should serialize Vitals data correctly' {
            $script:TestEntry.Vitals = [Vitals]::new(92, '140/90')

            $hash = $script:TestEntry.ToHashtable()

            # Should have Vitals data directly in hash
            $hash.o2 | Should -Be 92
            $hash.bpr | Should -Be '140/90'
        }

        It 'Should include note when present' {
            $script:TestEntry.Note = 'Had a rough day with pain'

            $hash = $script:TestEntry.ToHashtable()

            $hash.Keys | Should -Contain 'note'
            $hash.note | Should -Be 'Had a rough day with pain'
        }

        It 'Should handle complex entry with all components' {
            # Add all types of data
            $script:TestEntry.Pain += [PainLocation]::new('back', 8.0, 'Severe back pain')
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')
            $script:TestEntry.Activity += [Activity]::new('Walking', 15, 'Short walk')
            $script:TestEntry.Vitals = [Vitals]::new(94, '130/85')
            $script:TestEntry.Note = 'Complex health entry'

            $hash = $script:TestEntry.ToHashtable()

            # Verify all components are present
            $hash.Pain.Keys.Count | Should -Be 1
            $hash.Medications.Keys.Count | Should -Be 1
            $hash.Activities.Keys.Count | Should -Be 1
            $hash.o2 | Should -Be 94
            $hash.bpr | Should -Be '130/85'
            $hash.note | Should -Be 'Complex health entry'
            $hash.medication_taken | Should -Be 'dilaudid'

            # Verify structure integrity
            $hash | Should -BeOfType [hashtable]
            $hash.Keys.Count | Should -Be 7  # All expected keys
        }

        It 'Should handle multiple medications of same type' {
            $script:TestEntry.Medication += [MedicationTaken]::new('2mg', 'dilaudid')
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid')

            $hash = $script:TestEntry.ToHashtable()

            # Should create array for multiple dosages
            $hash.Medications.dilaudid | Should -Contain '2mg'
            $hash.Medications.dilaudid | Should -Contain '4mg'
            $hash.Medications.dilaudid.Count | Should -Be 2

            # medication_taken should still list it once
            $hash.medication_taken | Should -Be 'dilaudid'
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
        $painHash.Keys.Count | Should -Be 2  # Updated: pain_level and note only
    }
}
