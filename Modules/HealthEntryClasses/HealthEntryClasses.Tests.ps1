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
        it 'Should assign properties correctly' {
            $vitals = [Vitals]::new(90, '111/90')
            $vitals.o2 | Should -be 90 
            $vitals.o2 | Should -BeOfType [int]
            $vitals.bpr | Should -be '111/90'
        }
        # Test validation with valid values
    }
    
    Context 'Oxygen Level Validation' {
        # Test edge cases: 90%, 95%, 100%
        # Test invalid values if possible
        it 'Should throw on invalid o2' {
            {[Vitals]::new(101,'120/80')} | Should -Throw
        }
        it 'Should throw on invalid bpr, too low' {
            {[Vitals]::new(95,'10/80')} | Should -Throw
        }
        it 'Should throw on invalid bpr, too high' {
            {[Vitals]::new(95,'100/1000')} | Should -Throw
        }
    }
    
    Context "ToHashtable() Validation" {
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

Describe "Activity Tests" -Tag Activity {
    Context "Default Constructor" {
        it "Should create with default values" {
            $action = [Activity]::new()
            $action.ActivityName | Should -be 'Walking'
            $action.ActivityDuration | Should -be 10
            $action.Note | Should -be ''
        }
        it "Should validate default values as valid" {
            [Activity]::new().IsValid() | Should -BeTrue
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
