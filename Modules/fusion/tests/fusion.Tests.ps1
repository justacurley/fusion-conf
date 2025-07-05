# Pester tests for fusion.psm1 module
BeforeAll {
    # Import the module
    Import-Module -Name "$PSScriptRoot/../fusion.psm1" -Force
    
    # Set up test environment variables to avoid conflicts with production data
    $global:TestEntriesPath = Join-Path $TestDrive "test_entries.json"
    $global:TestSchemaPath = Join-Path $PSScriptRoot "entries_schema.json"
    $global:TestMedicationsPath = Join-Path $PSScriptRoot "medications_lookup.json"
    $global:TestImagePath = Join-Path $TestDrive "test_img"
    
    # Create test directories
    New-Item -ItemType Directory -Path $global:TestImagePath -Force
    
    # Mock the global variables used by the module
    Mock -ModuleName fusion -CommandName Get-ChildItem -ParameterFilter { $Path -eq "Env:HOSTNAME" } -MockWith {
        return $null  # This will use the local/dev paths
    }
    
    # Create a basic test entries.json structure
    $testEntries = @{
        "0629" = @{
            "1200" = @{
                "Medications" = @{
                    "tylenol" = "1g"
                }
                "Pain" = @{}
                "Activities" = @{}
                "o2" = "95"
                "bpr" = "120/80"
                "note" = "Test entry"
                "medication_taken" = "tylenol"
            }
            "max_pain_level" = 0.0
        }
    }
    $testEntries | ConvertTo-Json -Depth 99 | Out-File $global:TestEntriesPath -Encoding UTF8
    
    # Sample mock data based on the form structure
    $script:MockEventDataComprehensive = @{
        # Basic info (in HTML format, gets converted in OnSubmit)
        "date" = "2025-06-30"
        "timestamp" = "14:25"
        
        # Multiple medications
        "med_tylenol_1g" = $true
        "med_dilaudid_4mg" = $true
        "med_valium_5mg" = $false
        "med_lexapro_20mg" = $true
        "med_oxycodone_2_5mg" = $false
        "med_oxycodone_5mg" = $false
        "med_dilaudid_2mg" = $false
        "med_tylenol_500mg" = $false
        "med_valium_2_5mg" = $false
        "med_vitaminD_500mg" = $true
        "med_lexapro_10mg" = $false
        "med_journavx_100mg" = $false
        
        # All sections enabled
        "add_activity" = $true
        "add_pain" = $true
        "add_vitals" = $true
        
        # Multiple activities with different random IDs
        "activities_type_1" = "Walking"
        "activities_length_1" = "25"
        "activities_note_1" = "Short walk to mailbox"
        "activities_type_237" = "Stretching"
        "activities_length_237" = "15"
        "activities_note_237" = "Morning stretches"
        "activities_type_892" = "Physical Therapy"
        "activities_length_892" = "60"
        "activities_note_892" = "Weekly PT session"
        
        # Multiple pain locations
        "pain_location_1" = "back"
        "pain_level_1" = "6"
        "pain_note_1" = "Sharp pain when bending"
        "pain_location_445" = "right_glute"
        "pain_level_445" = "3"
        "pain_note_445" = "Muscle tension"
        "pain_location_778" = "lhip"
        "pain_level_778" = "2"
        "pain_note_778" = "Slight stiffness"
        
        # Vitals
        "o2" = "94"
        "bpr" = "125/82"
        
        # Notes and sleep
        "notes" = "Had a difficult night, pain levels higher than usual. PT session helped."
        "sleep" = "5.5 hours - interrupted by pain"
    }
    
    $script:MockEventDataMinimal = @{
        "date" = "2025-06-30"
        "timestamp" = "16:30"
        
        # All medications false
        "med_tylenol_500mg" = $false
        "med_tylenol_1g" = $false
        "med_dilaudid_2mg" = $false
        "med_dilaudid_4mg" = $false
        "med_valium_2_5mg" = $false
        "med_valium_5mg" = $false
        "med_vitaminD_500mg" = $false
        "med_lexapro_10mg" = $false
        "med_lexapro_20mg" = $false
        "med_journavx_100mg" = $false
        "med_oxycodone_2_5mg" = $false
        "med_oxycodone_5mg" = $false
        
        # No optional sections
        "add_activity" = $false
        "add_pain" = $false
        "add_vitals" = $false
        
        # Empty additional fields
        "notes" = ""
        "sleep" = ""
    }
    
    $script:MockEventDataMedications = @{
        "date" = "2025-06-30"
        "timestamp" = "09:15"
        
        # Multiple medications of same type (should create array)
        "med_dilaudid_2mg" = $true
        "med_dilaudid_4mg" = $true
        "med_tylenol_500mg" = $true
        "med_tylenol_1g" = $true
        "med_valium_2_5mg" = $false
        "med_valium_5mg" = $false
        "med_vitaminD_500mg" = $false
        "med_lexapro_10mg" = $false
        "med_lexapro_20mg" = $false
        "med_journavx_100mg" = $false
        "med_oxycodone_2_5mg" = $false
        "med_oxycodone_5mg" = $false
        
        "add_activity" = $false
        "add_pain" = $false
        "add_vitals" = $false
        "notes" = ""
        "sleep" = ""
    }
}

Describe "ConvertTo-EntriesFormat Function" -Tag ConvertTo-EntriesFormat,Function {
    
    Context "When processing comprehensive form data" {
        BeforeEach {
            # Convert mock data to PSCustomObject (simulating form submission)
            $mockEntry = [PSCustomObject]$script:MockEventDataComprehensive
            # Simulate the date/time conversion that happens in OnSubmit
            $mockEntry.date = "0630"
            $mockEntry.timestamp = "1425"
        }
        
        It "Should return a valid conversion result structure" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result | Should -Not -BeNullOrEmpty
            $result.FullEntry | Should -Not -BeNullOrEmpty
            $result.EntryStructure | Should -Not -BeNullOrEmpty
            $result.Date | Should -Be "0630"
            $result.Timestamp | Should -Be "1425"
        }
        
        It "Should correctly parse medications with boolean flags" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.Medications | Should -Not -BeNullOrEmpty
            $result.EntryStructure.Medications.Keys | Should -Contain "tylenol"
            $result.EntryStructure.Medications.Keys | Should -Contain "dilaudid"
            $result.EntryStructure.Medications.Keys | Should -Contain "lexapro"
            $result.EntryStructure.Medications.Keys | Should -Contain "vitaminD"
            
            $result.EntryStructure.Medications["tylenol"] | Should -Be "1g"
            $result.EntryStructure.Medications["dilaudid"] | Should -Be "4mg"
            $result.EntryStructure.Medications["lexapro"] | Should -Be "20mg"
            $result.EntryStructure.Medications["vitaminD"] | Should -Be "500mg"
        }
        
        It "Should correctly parse multiple activities with different IDs" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.Activities | Should -Not -BeNullOrEmpty
            $result.EntryStructure.Activities.Keys | Should -Contain "Walking"
            $result.EntryStructure.Activities.Keys | Should -Contain "Stretching"
            $result.EntryStructure.Activities.Keys | Should -Contain "Physical Therapy"
            
            $result.EntryStructure.Activities["Walking"].duration | Should -Be 25
            $result.EntryStructure.Activities["Walking"].note | Should -Be "Short walk to mailbox"
            $result.EntryStructure.Activities["Stretching"].duration | Should -Be 15
            $result.EntryStructure.Activities["Physical Therapy"].duration | Should -Be 60
        }
        
        It "Should correctly parse multiple pain entries" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.Pain | Should -Not -BeNullOrEmpty
            $result.EntryStructure.Pain.Keys | Should -Contain "back"
            $result.EntryStructure.Pain.Keys | Should -Contain "right_glute"
            $result.EntryStructure.Pain.Keys | Should -Contain "lhip"
            
            $result.EntryStructure.Pain["back"].pain_level | Should -Be 6.0
            $result.EntryStructure.Pain["back"].note | Should -Be "Sharp pain when bending"
            $result.EntryStructure.Pain["right_glute"].pain_level | Should -Be 3.0
            $result.EntryStructure.Pain["lhip"].pain_level | Should -Be 2.0
        }
        
        It "Should correctly parse vital signs" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.o2 | Should -Be "94"
            $result.EntryStructure.bpr | Should -Be "125/82"
        }
        
        It "Should correctly parse notes and include sleep in FullEntry" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.note | Should -Be "Had a difficult night, pain levels higher than usual. PT session helped."
            $result.FullEntry["0630"]["Sleep"] | Should -Be "5.5 hours - interrupted by pain"
        }
        
        It "Should set medication_taken field for GSI" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.medication_taken | Should -Not -BeNullOrEmpty
            $result.EntryStructure.medication_taken | Should -Match "tylenol"
            $result.EntryStructure.medication_taken | Should -Match "dilaudid"
            $result.EntryStructure.medication_taken | Should -Match "lexapro"
            $result.EntryStructure.medication_taken | Should -Match "vitaminD"
        }
    }
    
    Context "When processing minimal form data" {
        BeforeEach {
            $mockEntry = [PSCustomObject]$script:MockEventDataMinimal
            $mockEntry.date = "0630"
            $mockEntry.timestamp = "1630"
        }
        
        It "Should handle entries with no medications, activities, or pain" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.Medications.Keys.Count | Should -Be 0
            $result.EntryStructure.Activities.Keys.Count | Should -Be 0
            $result.EntryStructure.Pain.Keys.Count | Should -Be 0
            $result.EntryStructure.medication_taken | Should -Be ""
        }
        
        It "Should handle empty vital signs and notes" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            $result.EntryStructure.o2 | Should -Be ""
            $result.EntryStructure.bpr | Should -Be ""
            $result.EntryStructure.note | Should -Be ""
        }
    }
    
    Context "When processing multiple medications of same type" {
        BeforeEach {
            $mockEntry = [PSCustomObject]$script:MockEventDataMedications
            $mockEntry.date = "0630"
            $mockEntry.timestamp = "0915"
        }
        
        It "Should create arrays for multiple doses of same medication" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry
            
            # Debug output to see what we actually get
            Write-Host "Dilaudid value: $($result.EntryStructure.Medications['dilaudid'])"
            Write-Host "Dilaudid type: $($result.EntryStructure.Medications['dilaudid'].GetType().Name)"
            Write-Host "Is array: $($result.EntryStructure.Medications['dilaudid'] -is [Array])"
            
            # Should have dilaudid and tylenol with multiple dosages
            # Test that medications exist and are arrays
            $result.EntryStructure.Medications.ContainsKey("dilaudid") | Should -Be $true
            $result.EntryStructure.Medications.ContainsKey("tylenol") | Should -Be $true
            
            # Test array properties
            $dilaudidMeds = $result.EntryStructure.Medications["dilaudid"]
            $tylenolMeds = $result.EntryStructure.Medications["tylenol"]
            
            # Check if they are arrays using -is operator
            ($dilaudidMeds -is [Array]) | Should -Be $true
            ($tylenolMeds -is [Array]) | Should -Be $true
            
            # Check array contents
            $dilaudidMeds | Should -Contain "2mg"
            $dilaudidMeds | Should -Contain "4mg"
            $dilaudidMeds.Length | Should -Be 2
            
            $tylenolMeds | Should -Contain "500mg"
            $tylenolMeds | Should -Contain "1g"
            $tylenolMeds.Length | Should -Be 2
        }
    }
}

Describe "Update-DailyMaxPainLevel Function" -Tag Update-DailyMaxPainLevel,Function {
    
    Context "When updating pain levels" {
        BeforeEach {
            $testEntries = @{
                "0630" = @{
                    "1200" = @{
                        "Pain" = @{
                            "back" = @{ "pain_level" = 5.0; "note" = "test" }
                            "hip" = @{ "pain_level" = 3.0; "note" = "test" }
                        }
                    }
                    "1400" = @{
                        "Pain" = @{
                            "back" = @{ "pain_level" = 7.0; "note" = "test" }
                        }
                    }
                    "Sleep" = "8 hours"
                }
            }
        }
        
        It "Should calculate the maximum pain level for the day" {
            $maxPain = Update-DailyMaxPainLevel -Entries $testEntries -Date "0630"
            
            $maxPain | Should -Be 7.0
            $testEntries["0630"]["max_pain_level"] | Should -Be 7.0
        }
        
        It "Should handle entries with no pain data" {
            $testEntries["0630"]["1600"] = @{
                "Pain" = @{}
                "Medications" = @{ "tylenol" = "1g" }
            }
            
            $maxPain = Update-DailyMaxPainLevel -Entries $testEntries -Date "0630"
            
            $maxPain | Should -Be 7.0  # Should still be 7.0 from other entries
        }
        
        It "Should handle dates with no entries" {
            $maxPain = Update-DailyMaxPainLevel -Entries $testEntries -Date "0701"
            
            $maxPain | Should -Be 0.0
        }
    }
}

Describe "Save-ConvertedEntry Function" -Tag Save-ConvertedEntry,Function {
    
    Context "When saving entries" {
        BeforeEach {
            # Clean up test file
            if (Test-Path $global:TestEntriesPath) {
                Remove-Item $global:TestEntriesPath -Force
            }
            
            # Create a converted entry structure
            $script:testConvertedEntry = @{
                Date = "0630"
                Timestamp = "1425"
                EntryStructure = @{
                    "Medications" = @{
                        "tylenol" = "1g"
                        "dilaudid" = "4mg"
                    }
                    "Pain" = @{
                        "back" = @{ "pain_level" = 6.0; "note" = "Sharp pain" }
                    }
                    "Activities" = @{
                        "Walking" = @{ "duration" = 25; "note" = "Short walk" }
                    }
                    "o2" = "94"
                    "bpr" = "125/82"
                    "note" = "Test entry"
                    "medication_taken" = "tylenol,dilaudid"
                }
                FullEntry = @{
                    "0630" = @{
                        "1425" = @{
                            # EntryStructure content would be here
                        }
                        "Sleep" = "8 hours"
                    }
                }
            }
        }
        
        It "Should save entry to new file when file doesn't exist" {
            $result = Save-ConvertedEntry -ConvertedEntry $script:testConvertedEntry -EntriesPath $global:TestEntriesPath
            
            $result | Should -Be $true
            Test-Path $global:TestEntriesPath | Should -Be $true
            
            $savedData = Get-Content $global:TestEntriesPath | ConvertFrom-Json -AsHashtable
            $savedData["0630"]["1425"]["Medications"]["tylenol"] | Should -Be "1g"
            $savedData["0630"]["Sleep"] | Should -Be "8 hours"
        }
        
        It "Should append to existing entries file" {
            # Create initial entry
            $initialEntries = @{
                "0629" = @{
                    "1200" = @{
                        "Medications" = @{ "lexapro" = "20mg" }
                        "Pain" = @{}
                        "Activities" = @{}
                        "o2" = ""
                        "bpr" = ""
                        "note" = "Initial entry"
                        "medication_taken" = "lexapro"
                    }
                    "max_pain_level" = 0.0
                }
            }
            $initialEntries | ConvertTo-Json -Depth 99 | Out-File $global:TestEntriesPath -Encoding UTF8
            
            # Save new entry
            $result = Save-ConvertedEntry -ConvertedEntry $script:testConvertedEntry -EntriesPath $global:TestEntriesPath
            
            $result | Should -Be $true
            
            $savedData = Get-Content $global:TestEntriesPath | ConvertFrom-Json -AsHashtable
            $savedData["0629"]["1200"]["Medications"]["lexapro"] | Should -Be "20mg"  # Original entry preserved
            $savedData["0630"]["1425"]["Medications"]["tylenol"] | Should -Be "1g"   # New entry added
        }
        
        It "Should update daily max pain level" {
            $result = Save-ConvertedEntry -ConvertedEntry $script:testConvertedEntry -EntriesPath $global:TestEntriesPath
            
            $savedData = Get-Content $global:TestEntriesPath | ConvertFrom-Json -AsHashtable
            $savedData["0630"]["max_pain_level"] | Should -Be 6.0
        }
    }
}

Describe "Integration Tests" -Tag Integration {
    
    Context "When processing full form submission workflow" {
        It "Should handle complete form-to-save workflow" {
            # Simulate form submission data
            $formData = [PSCustomObject]$script:MockEventDataComprehensive
            $formData.date = "0630"
            $formData.timestamp = "1425"
            
            # Convert form data
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Save the entry
            $saveResult = Save-ConvertedEntry -ConvertedEntry $convertedEntry -EntriesPath $global:TestEntriesPath
            
            # Verify the complete workflow
            $saveResult | Should -Be $true
            
            $savedData = Get-Content $global:TestEntriesPath | ConvertFrom-Json -AsHashtable
            $savedData["0630"]["1425"]["Medications"]["tylenol"] | Should -Be "1g"
            $savedData["0630"]["1425"]["Pain"]["back"]["pain_level"] | Should -Be 6.0
            $savedData["0630"]["1425"]["Activities"]["Walking"]["duration"] | Should -Be 25
            $savedData["0630"]["max_pain_level"] | Should -Be 6.0
            $savedData["0630"]["Sleep"] | Should -Be "5.5 hours - interrupted by pain"
        }
    }
}

Describe "Input Validation Tests" -Tag Validation {
    
    Context "ConvertTo-EntriesFormat Parameter Validation" {
        It "Should throw when Entry parameter is null" {
            { ConvertTo-EntriesFormat -Entry $null } | Should -Throw
        }
        
        It "Should handle non-PSCustomObject input gracefully" {
            # PowerShell automatically converts strings to PSCustomObject, so this should not throw
            # but will result in empty/default values
            $result = ConvertTo-EntriesFormat -Entry "not an object"
            $result | Should -Not -BeNullOrEmpty
            $result.Date | Should -Be ""
            $result.Timestamp | Should -Be ""
        }
        
        It "Should handle Entry with missing required fields gracefully" {
            $incompleteEntry = [PSCustomObject]@{
                # Missing date and timestamp
                notes = "Test note"
            }
            
            # Should not throw, but should handle gracefully
            { ConvertTo-EntriesFormat -Entry $incompleteEntry } | Should -Not -Throw
        }
        
        It "Should handle Entry with null/empty date and timestamp" {
            $entryWithNulls = [PSCustomObject]@{
                date = $null
                timestamp = ""
                notes = "Test"
            }
            
            $result = ConvertTo-EntriesFormat -Entry $entryWithNulls
            $result.Date | Should -Be ""
            $result.Timestamp | Should -Be ""
        }
        
        It "Should validate medication property format" {
            $invalidMedEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                med_invalid_format = $true  # Should not match pattern
                med_tylenol_1g = $true      # Should match pattern
            }
            
            $result = ConvertTo-EntriesFormat -Entry $invalidMedEntry
            # Should only process valid medication format
            $result.EntryStructure.Medications.Keys | Should -Contain "tylenol"
            $result.EntryStructure.Medications.Keys | Should -Not -Contain "invalid"
        }
        
        It "Should handle non-boolean medication values" {
            $invalidMedValues = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                med_tylenol_1g = "not a boolean"  # Should be ignored
                med_dilaudid_4mg = $true          # Should be processed
            }
            
            $result = ConvertTo-EntriesFormat -Entry $invalidMedValues
            $result.EntryStructure.Medications.Keys | Should -Not -Contain "tylenol"
            $result.EntryStructure.Medications.Keys | Should -Contain "dilaudid"
        }
        
        It "Should validate pain level as numeric" {
            $invalidPainEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "not a number"  # Invalid
                pain_location_2 = "hip"
                pain_level_2 = "5"             # Valid
            }
            
            $result = ConvertTo-EntriesFormat -Entry $invalidPainEntry
            # Should skip invalid pain entries but process valid ones
            $result.EntryStructure.Pain.Keys | Should -Not -Contain "back"
            $result.EntryStructure.Pain.Keys | Should -Contain "hip"
        }
        
        It "Should validate activity duration as integer" {
            $invalidActivityEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_activity = $true
                activities_type_1 = "Walking"
                activities_length_1 = "not a number"  # Invalid
                activities_type_2 = "Swimming"
                activities_length_2 = "30"            # Valid
            }
            
            $result = ConvertTo-EntriesFormat -Entry $invalidActivityEntry
            # Should skip invalid activity entries but process valid ones
            $result.EntryStructure.Activities.Keys | Should -Not -Contain "Walking"
            $result.EntryStructure.Activities.Keys | Should -Contain "Swimming"
        }
        
        It "Should reject extremely large numeric values for pain levels" {
            $extremeEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "999999999"  # Very large number - should be rejected
                add_activity = $true
                activities_type_1 = "Walking"
                activities_length_1 = "999999999"  # Very large duration - should be accepted
            }
            
            $result = ConvertTo-EntriesFormat -Entry $extremeEntry
            # Should reject pain levels outside medical range (0-10)
            $result.EntryStructure.Pain.Keys | Should -Not -Contain "back"
            # But should accept large activity durations
            $result.EntryStructure.Activities["Walking"].duration | Should -Be 999999999
        }
        
        It "Should reject negative pain levels" {
            $negativeEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "-5"  # Negative pain level - should be rejected
                add_activity = $true
                activities_type_1 = "Walking"
                activities_length_1 = "-30"  # Negative duration - should be accepted
            }
            
            $result = ConvertTo-EntriesFormat -Entry $negativeEntry
            # Should reject negative pain levels (medical standard is 0-10)
            $result.EntryStructure.Pain.Keys | Should -Not -Contain "back"
            # But should accept negative activity durations (might represent adjustments)
            $result.EntryStructure.Activities["Walking"].duration | Should -Be -30
        }
        
        It "Should handle decimal pain levels" {
            $decimalEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5.5"  # Decimal pain level
            }
            
            $result = ConvertTo-EntriesFormat -Entry $decimalEntry
            $result.EntryStructure.Pain["back"].pain_level | Should -Be 5.5
            $result.EntryStructure.Pain["back"].pain_level | Should -BeOfType [double]
        }
        
        It "Should handle special characters in text fields" {
            $specialCharsText = "Test with special chars: !@#$%^&*()_+-=[]{}|;':`",./<>?~"
            $unicodeText = "Pain with émojis 😵‍💫 and unicode ñoté"
            
            $specialCharsEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                notes = $specialCharsText
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5"
                pain_note_1 = $unicodeText
            }
            
            $result = ConvertTo-EntriesFormat -Entry $specialCharsEntry
            $result.EntryStructure.note | Should -Be $specialCharsText
            $result.EntryStructure.Pain["back"].note | Should -Be $unicodeText
        }
        
        It "Should handle very long text fields" {
            $longText = "a" * 10000  # 10KB of text
            $longTextEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                notes = $longText
            }
            
            $result = ConvertTo-EntriesFormat -Entry $longTextEntry
            $result.EntryStructure.note | Should -Be $longText
            $result.EntryStructure.note.Length | Should -Be 10000
        }
    }
    
    Context "Update-DailyMaxPainLevel Parameter Validation" {
        It "Should throw when Entries parameter is null" {
            { Update-DailyMaxPainLevel -Entries $null -Date "0630" } | Should -Throw
        }
        
        It "Should throw when Date parameter is null or empty" {
            $testEntries = @{}
            { Update-DailyMaxPainLevel -Entries $testEntries -Date $null } | Should -Throw
            { Update-DailyMaxPainLevel -Entries $testEntries -Date "" } | Should -Throw
        }
        
        It "Should handle non-hashtable Entries parameter" {
            { Update-DailyMaxPainLevel -Entries "not a hashtable" -Date "0630" } | Should -Throw
        }
        
        It "Should handle malformed date strings" {
            $testEntries = @{}
            # Should not throw, but should handle gracefully
            $result = Update-DailyMaxPainLevel -Entries $testEntries -Date "invalid-date"
            $result | Should -Be 0.0
        }
        
        It "Should handle entries with corrupted pain data" {
            $corruptedEntries = @{
                "0630" = @{
                    "1200" = @{
                        "Pain" = "not a hashtable"  # Corrupted pain data
                    }
                    "1400" = @{
                        "Pain" = @{
                            "back" = "not an object"  # Corrupted pain entry
                        }
                    }
                    "1600" = @{
                        "Pain" = @{
                            "hip" = @{
                                "pain_level" = "not a number"  # Invalid pain level
                            }
                        }
                    }
                }
            }
            
            # Should handle gracefully without throwing
            $result = Update-DailyMaxPainLevel -Entries $corruptedEntries -Date "0630"
            $result | Should -Be 0.0
        }
    }
    
    Context "Save-ConvertedEntry Parameter Validation" {
        It "Should throw when ConvertedEntry parameter is null" {
            { Save-ConvertedEntry -ConvertedEntry $null } | Should -Throw
        }
        
        It "Should throw when ConvertedEntry is not a hashtable" {
            { Save-ConvertedEntry -ConvertedEntry "not a hashtable" } | Should -Throw
        }
        
        It "Should handle ConvertedEntry missing required properties" {
            $incompleteEntry = @{
                # Missing Date, Timestamp, EntryStructure
            }
            
            # Should handle gracefully or throw appropriate error
            { Save-ConvertedEntry -ConvertedEntry $incompleteEntry -EntriesPath $global:TestEntriesPath } | Should -Throw
        }
        
        It "Should handle invalid file path" {
            $validEntry = @{
                Date = "0630"
                Timestamp = "1200"
                EntryStructure = @{
                    Medications = @{}
                    Pain = @{}
                    Activities = @{}
                }
                FullEntry = @{}
            }
            
            # Test with invalid/inaccessible path
            { Save-ConvertedEntry -ConvertedEntry $validEntry -EntriesPath "/invalid/path/entries.json" } | Should -Throw
        }
        
        It "Should handle entries path with special characters" {
            $validEntry = @{
                Date = "0630"
                Timestamp = "1200"
                EntryStructure = @{
                    Medications = @{}
                    Pain = @{}
                    Activities = @{}
                }
                FullEntry = @{}
            }
            
            $specialPath = Join-Path $TestDrive "test entries with spaces & symbols!@#.json"
            $result = Save-ConvertedEntry -ConvertedEntry $validEntry -EntriesPath $specialPath
            $result | Should -Be $true
            Test-Path $specialPath | Should -Be $true
        }
        
        It "Should handle corrupted existing entries file" {
            # Create corrupted JSON file
            $corruptedPath = Join-Path $TestDrive "corrupted.json"
            "{ invalid json content" | Out-File $corruptedPath -Encoding UTF8
            
            $validEntry = @{
                Date = "0630"
                Timestamp = "1200"
                EntryStructure = @{
                    Medications = @{}
                    Pain = @{}
                    Activities = @{}
                }
                FullEntry = @{}
            }
            
            # Should handle corrupted file gracefully
            { Save-ConvertedEntry -ConvertedEntry $validEntry -EntriesPath $corruptedPath } | Should -Throw
        }
    }
    
    Context "Edge Cases and Boundary Conditions" {
        It "Should handle timestamp at midnight boundary" {
            $midnightEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "0000"
                notes = "Midnight entry"
            }
            
            $result = ConvertTo-EntriesFormat -Entry $midnightEntry
            $result.Timestamp | Should -Be "0000"
        }
        
        It "Should handle timestamp at end of day boundary" {
            $endOfDayEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "2359"
                notes = "End of day entry"
            }
            
            $result = ConvertTo-EntriesFormat -Entry $endOfDayEntry
            $result.Timestamp | Should -Be "2359"
        }
        
        It "Should handle leap year date formats" {
            $leapYearEntry = [PSCustomObject]@{
                date = "0229"  # Feb 29 (leap year)
                timestamp = "1200"
                notes = "Leap year test"
            }
            
            $result = ConvertTo-EntriesFormat -Entry $leapYearEntry
            $result.Date | Should -Be "0229"
        }
        
        It "Should handle maximum number of activities" {
            # Create entry with many activities (stress test)
            $manyActivitiesEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_activity = $true
            }
            
            # Add 50 activities with different IDs
            for ($i = 1; $i -le 50; $i++) {
                $manyActivitiesEntry | Add-Member -NotePropertyName "activities_type_$i" -NotePropertyValue "Activity$i"
                $manyActivitiesEntry | Add-Member -NotePropertyName "activities_length_$i" -NotePropertyValue "$i"
                $manyActivitiesEntry | Add-Member -NotePropertyName "activities_note_$i" -NotePropertyValue "Note $i"
            }
            
            $result = ConvertTo-EntriesFormat -Entry $manyActivitiesEntry
            $result.EntryStructure.Activities.Keys.Count | Should -Be 50
        }
        
        It "Should reject pain levels outside medical range (0-10)" {
            # Create entry with pain levels outside medical range
            $manyPainEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
            }
            
            # Add 20 pain locations, but only 10 should be valid (levels 1-10)
            for ($i = 1; $i -le 20; $i++) {
                $manyPainEntry | Add-Member -NotePropertyName "pain_location_$i" -NotePropertyValue "location$i"
                $manyPainEntry | Add-Member -NotePropertyName "pain_level_$i" -NotePropertyValue "$i"
                $manyPainEntry | Add-Member -NotePropertyName "pain_note_$i" -NotePropertyValue "Pain note $i"
            }
            
            $result = ConvertTo-EntriesFormat -Entry $manyPainEntry
            # Should only accept pain levels 1-10 (levels 11-20 should be rejected)
            $result.EntryStructure.Pain.Keys.Count | Should -Be 10
            
            # Verify that only valid pain levels are included
            $validLocations = 1..10 | ForEach-Object { "location$_" }
            foreach ($location in $result.EntryStructure.Pain.Keys) {
                $validLocations | Should -Contain $location
            }
        }
    }
    
    Context "Data Type Conversion and Coercion" {
        It "Should handle string numbers that should be integers" {
            $stringNumberEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_activity = $true
                activities_type_1 = "Walking"
                activities_length_1 = "30"  # String that should become int
            }
            
            $result = ConvertTo-EntriesFormat -Entry $stringNumberEntry
            $result.EntryStructure.Activities["Walking"].duration | Should -BeOfType [int]
            $result.EntryStructure.Activities["Walking"].duration | Should -Be 30
        }
        
        It "Should handle string numbers that should be doubles" {
            $stringDoubleEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5.5"  # String that should become double
            }
            
            $result = ConvertTo-EntriesFormat -Entry $stringDoubleEntry
            $result.EntryStructure.Pain["back"].pain_level | Should -BeOfType [double]
            $result.EntryStructure.Pain["back"].pain_level | Should -Be 5.5
        }
        
        It "Should handle boolean-like strings" {
            $booleanStringEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_activity = "true"  # String instead of boolean
                add_pain = "false"     # String instead of boolean
            }
            
            # Should handle gracefully
            { ConvertTo-EntriesFormat -Entry $booleanStringEntry } | Should -Not -Throw
        }
    }
}
