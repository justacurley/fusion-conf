# Unit Tests for HealthEntryClasses
# Uses Pester testing framework (built into PowerShell 5+ and PowerShell Core)

using module ./HealthEntryClasses.psm1

Describe 'PainLocationEnum Tests' -Tag Enum, Pain {
    It 'Should have all expected enum values' {
        $enumValues = [System.Enum]::GetNames([PainLocationEnum])
        $expectedValues = @('Back', 'RQuad', 'LQuad', 'Quads', 'RHip', 'LHip', 'Hips', 'RGlute', 'LGlute', 'Glutes')
        
        foreach ($expected in $expectedValues) {
            $enumValues | Should -Contain $expected
        }
    }
}

Describe 'MedicationValidator Tests' -Tag MedicationValidator, Medication {
    BeforeAll {
        $validator = [MedicationValidator]::new()
    }

    It 'Should return valid medications from JSON' {
        $validMeds = $validator.GetValidValues()
        $validMeds | Should -Not -BeNullOrEmpty
        $validMeds | Should -Contain 'dilaudid'
    }

    It 'Should return valid dosages for dilaudid' {
        $dosages = $validator.GetValidDosages('dilaudid')
        $dosages | Should -Not -BeNullOrEmpty
        $dosages | Should -Contain '4mg'
    }

    It 'Should return empty array for invalid medication' {
        $dosages = $validator.GetValidDosages('nonexistent-med')
        $dosages | Should -Be @()
    }
}

Describe 'MedicationTaken Tests' -Tag MedicationTaken, Medication {
    Context 'Valid Medication Creation' {
        It 'Should create with valid medication and dosage' {
            { [MedicationTaken]::new('4mg', 'dilaudid', 'Test Note') } | Should -Not -Throw
        }

        It 'Should set properties correctly' {
            $med = [MedicationTaken]::new('4mg', 'dilaudid', 'Test Note')
            $med.medication | Should -Be 'dilaudid'
            $med.dosage | Should -Be '4mg'
            $med.Note | Should -Be 'Test Note'
        }

        It 'Should validate as valid' {
            $med = [MedicationTaken]::new('4mg', 'dilaudid', 'Test Note')
            $med.IsValid() | Should -Be $true
        }

        It 'Should convert to hashtable correctly' {
            $med = [MedicationTaken]::new('4mg', 'dilaudid', 'Test Note')
            $hashtable = $med.ToHashtable()
            $hashtable.medication | Should -Be 'dilaudid'
            $hashtable.dosage | Should -Be '4mg'
            $hashtable.Note | Should -Be 'Test Note'
        }
    }

    Context 'Invalid Medication Validation' {
        It 'Should throw for invalid medication' {
            { [MedicationTaken]::new('4mg', 'invalid-med', 'Test Note') } | Should -Throw '*Must provide valid medication*'
        }

        It 'Should throw for invalid dosage' {
            { [MedicationTaken]::new('999mg', 'dilaudid', 'Test Note') } | Should -Throw '*Must provide valid dosage*'
        }
    }

    Context 'Default Constructor' {
        It 'Should create with default values' {
            $med = [MedicationTaken]::new()
            $med.medication | Should -Be 'dilaudid'
            $med.dosage | Should -Be '4mg'
            $med.Note | Should -Be ''
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
            { [PainLocation]::new(7.5, [PainLocationEnum]::Back, 'Test pain') } | Should -Not -Throw
        }

        It 'Should set properties correctly' {
            $pain = [PainLocation]::new(7.5, [PainLocationEnum]::Back, 'Test pain')
            $pain.pain_level | Should -Be 7.5
            $pain.location | Should -Be ([PainLocationEnum]::Back)
            $pain.Note | Should -Be 'Test pain'
        }

        It 'Should validate as valid' {
            $pain = [PainLocation]::new(7.5, [PainLocationEnum]::Back, 'Test pain')
            $pain.IsValid() | Should -Be $true
        }

        It 'Should convert to hashtable correctly' {
            $pain = [PainLocation]::new(7.5, [PainLocationEnum]::Back, 'Test pain')
            $hashtable = $pain.ToHashtable()
            $hashtable.pain_level | Should -Be 7.5
            $hashtable.location | Should -Be ([PainLocationEnum]::Back)
            $hashtable.Note | Should -Be 'Test pain'
        }
    }

    Context 'Pain Level Validation' {
        It 'Should accept pain level 0.0' {
            $pain = [PainLocation]::new(0.0, [PainLocationEnum]::Back, 'No pain')
            $pain.IsValid() | Should -Be $true
        }

        It 'Should accept pain level 10.0' {
            $pain = [PainLocation]::new(10.0, [PainLocationEnum]::Back, 'Maximum pain')
            $pain.IsValid() | Should -Be $true
        }

        It 'Should accept pain level 5.5' {
            $pain = [PainLocation]::new(5.5, [PainLocationEnum]::Back, 'Medium pain')
            $pain.IsValid() | Should -Be $true
        }

        # Note: PowerShell's ValidateRange attribute should prevent invalid values at assignment
        # but we can test the IsValid() method logic
    }

    Context 'Default Constructor' {
        It 'Should create with default values' {
            $pain = [PainLocation]::new()
            $pain.pain_level | Should -Be 0.0
            $pain.location | Should -Be ([PainLocationEnum]::Back)
            $pain.Note | Should -Be ''
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
        # Test parameterized constructor
        It 'Should create construct' {
            { [Vitals]::new(90, '111/90') } | Should -Not -Throw       
        }
        # Test property assignment 
        It 'Should assign properties correctly' {
            $vitals = [Vitals]::new(90, '111/90')
            $vitals.o2 | Should -Be 90 
            $vitals.o2 | Should -BeOfType [int]
            $vitals.bpr | Should -Be '111/90'
        }
        # Test validation with valid values
    }
    
    Context 'Oxygen Level Validation' {
        # Test edge cases: 90%, 95%, 100%
        # Test invalid values if possible
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
        
        It 'Should be invalid when empty' {
            $script:DefaultEntry.IsValid() | Should -BeFalse
        }
    }
    
    Context 'Validation Method' {
        BeforeEach {
            $script:DefaultEntry = [HealthEntry]::new()
        }
        It 'Should return true when Note is present' {
            $script:DefaultEntry.IsValid() | Should -BeFalse
            $script:DefaultEntry.Note = 'mock'
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }
        
        It 'Should return true when Pain is present' {
            $script:DefaultEntry.IsValid() | Should -BeFalse
            $script:DefaultEntry.Pain += [PainLocation]::new(1.0, [PainLocationEnum]::Back, '')
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }
        
        It 'Should return true when Medication is present' {
            $script:DefaultEntry.IsValid() | Should -BeFalse
            $script:DefaultEntry.Medication += [MedicationTaken]::new()
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Activity is present' {
            $script:DefaultEntry.IsValid() | Should -BeFalse
            $script:DefaultEntry.Activity += [Activity]::new()
            $script:DefaultEntry.IsValid() | Should -BeTrue
        }

        It 'Should return true when Vitals is present' {
            $script:DefaultEntry.IsValid() | Should -BeFalse
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
        
            # No note key when empty
            $hash.Keys | Should -Not -Contain 'note'
        }

        It 'Should serialize Pain data correctly' {
            $script:TestEntry.Pain += [PainLocation]::new(7.5, [PainLocationEnum]::Back, 'Lower back pain')
            $script:TestEntry.Pain += [PainLocation]::new(3.0, [PainLocationEnum]::RQuad, 'Mild quad pain')
        
            $hash = $script:TestEntry.ToHashtable()
        
            # Should have Pain data
            $hash.Pain.Keys | Should -Contain 'Back'
            $hash.Pain.Keys | Should -Contain 'RQuad'
        
            # Check Back pain structure
            $hash.Pain.Back.pain_level | Should -Be 7.5
            $hash.Pain.Back.note | Should -Be 'Lower back pain'
        
            # Check RQuad pain structure  
            $hash.Pain.RQuad.pain_level | Should -Be 3.0
            $hash.Pain.RQuad.note | Should -Be 'Mild quad pain'
        }

        It 'Should serialize Medication data correctly' {
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid', 'For pain')
            $script:TestEntry.Medication += [MedicationTaken]::new('2mg', 'dilaudid', 'Second dose')
        
            $hash = $script:TestEntry.ToHashtable()
        
            # Should have Medications hashtable with dosage
            $hash.Medications.Keys | Should -Contain 'dilaudid'
            $hash.Medications.dilaudid | Should -Be '2mg'  # Last one wins
        
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
            $script:TestEntry.Pain += [PainLocation]::new(8.0, [PainLocationEnum]::Back, 'Severe back pain')
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid', 'Pain relief')
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
            $script:TestEntry.Medication += [MedicationTaken]::new('2mg', 'dilaudid', 'Morning dose')
            $script:TestEntry.Medication += [MedicationTaken]::new('4mg', 'dilaudid', 'Evening dose')
        
            $hash = $script:TestEntry.ToHashtable()
        
            # Last dosage should win in Medications hashtable
            $hash.Medications.dilaudid | Should -Be '4mg'
        
            # But medication_taken should still list it once
            $hash.medication_taken | Should -Be 'dilaudid'
        }
    }
}

Describe 'Integration Tests' {
    It 'Should be able to create both classes together' {
        $med = [MedicationTaken]::new('4mg', 'dilaudid', 'For pain management')
        $pain = [PainLocation]::new(8.0, [PainLocationEnum]::Back, 'Lower back pain')
        
        $med.IsValid() | Should -Be $true
        $pain.IsValid() | Should -Be $true
    }

    It 'Should serialize both classes to hashtables for potential JSON export' {
        $med = [MedicationTaken]::new('4mg', 'dilaudid', 'For pain management')
        $pain = [PainLocation]::new(8.0, [PainLocationEnum]::Back, 'Lower back pain')
        
        $medHash = $med.ToHashtable()
        $painHash = $pain.ToHashtable()
        
        $medHash.Keys.Count | Should -Be 3
        $painHash.Keys.Count | Should -Be 3
    }
}
