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

Describe "ConvertTo-EntriesFormat Function" {
    
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

Describe "Update-DailyMaxPainLevel Function" {
    
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

Describe "Save-ConvertedEntry Function" {
    
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

Describe "Integration Tests" {
    
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
