# Pester tests for fusion.psm1 module
BeforeAll {
    # Force removal of any existing modules
    Remove-Module fusion -Force -ErrorAction SilentlyContinue
    Remove-Module HealthEntryClasses -Force -ErrorAction SilentlyContinue

    # Import the module
    Import-Module -Name "$PSScriptRoot/../fusion.psm1" -Force

    # Set up test environment variables to avoid conflicts with production data
    $global:TestEntriesPath = Join-Path $TestDrive "test_entries.json"
    $global:TestSchemaPath = Join-Path $PSScriptRoot "entries_schema.json"
    $global:TestImagePath = Join-Path $TestDrive "test_img"

    # Create test directories
    New-Item -ItemType Directory -Path $global:TestImagePath -Force

    # Mock the global variables used by the module
    Mock -ModuleName fusion -CommandName Get-ChildItem -ParameterFilter { $Path -eq "Env:HOSTNAME" } -MockWith {
        return $null  # This will use the local/dev paths
    }

    # Create a basic test entries.json structure using new schema v2.0
    $testEntries = @{
        "2506291200" = @{
            entry_id = "2506291200"
            user_email = "test@example.com"
            date = "2025-06-29"
            time = "12:00"
            entry_types = @("medications")
            data = @{
                medications = @(
                    @{ name = "tylenol"; dosage = "1g" }
                )
            }
            notes = "Test entry"
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
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"
            $result | Should -Not -BeNullOrEmpty
            $result.SchemaEntry | Should -Not -BeNullOrEmpty
            $result.Date | Should -Be "0630"
            $result.Timestamp | Should -Be "1425"
            $result.EntryId | Should -Match "^\d{10}$"
            $result.SchemaEntry.entry_id | Should -Be $result.EntryId
            $result.SchemaEntry.user_email | Should -Not -BeNullOrEmpty
            $result.SchemaEntry.date | Should -Match "^\d{4}-\d{2}-\d{2}$"
            $result.SchemaEntry.time | Should -Match "^\d{2}:\d{2}$"
            $result.SchemaEntry.entry_types | Should -Not -BeNullOrEmpty
            $result.SchemaEntry.data | Should -Not -BeNullOrEmpty
        }

        It "Should correctly parse medications with boolean flags" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"
            $result.SchemaEntry.data.medications | Should -Not -BeNullOrEmpty

            # Check medications are in the array format
            $medications = $result.SchemaEntry.data.medications
            $medNames = $medications | ForEach-Object { $_.name }

            $medNames | Should -Contain "tylenol"
            $medNames | Should -Contain "dilaudid"
            $medNames | Should -Contain "lexapro"
            $medNames | Should -Contain "vitaminD"

            # Check dosages
            ($medications | Where-Object { $_.name -eq "tylenol" }).dosage | Should -Be "1g"
            ($medications | Where-Object { $_.name -eq "dilaudid" }).dosage | Should -Be "4mg"
            ($medications | Where-Object { $_.name -eq "lexapro" }).dosage | Should -Be "20mg"
            ($medications | Where-Object { $_.name -eq "vitaminD" }).dosage | Should -Be "500mg"
        }

        It "Should correctly parse multiple activities with different IDs" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            $result.SchemaEntry.data.activities | Should -Not -BeNullOrEmpty

            # Check activities are in the array format
            $activities = $result.SchemaEntry.data.activities
            $activityNames = $activities | ForEach-Object { $_.name }

            $activityNames | Should -Contain "Walking"
            $activityNames | Should -Contain "Stretching"
            $activityNames | Should -Contain "Physical Therapy"

            # Check durations and notes
            ($activities | Where-Object { $_.name -eq "Walking" }).duration_minutes | Should -Be 25
            ($activities | Where-Object { $_.name -eq "Walking" }).note | Should -Be "Short walk to mailbox"
            ($activities | Where-Object { $_.name -eq "Stretching" }).duration_minutes | Should -Be 15
            ($activities | Where-Object { $_.name -eq "Physical Therapy" }).duration_minutes | Should -Be 60
        }

        It "Should correctly parse multiple pain entries" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            $result.SchemaEntry.data.pain | Should -Not -BeNullOrEmpty

            # Check pain entries are in the array format
            $painEntries = $result.SchemaEntry.data.pain
            $painLocations = $painEntries | ForEach-Object { $_.location }

            $painLocations | Should -Contain "back"
            $painLocations | Should -Contain "right_glute"
            $painLocations | Should -Contain "lhip"

            # Check severity and notes
            ($painEntries | Where-Object { $_.location -eq "back" }).severity | Should -Be 6.0
            ($painEntries | Where-Object { $_.location -eq "back" }).note | Should -Be "Sharp pain when bending"
            ($painEntries | Where-Object { $_.location -eq "right_glute" }).severity | Should -Be 3.0
            ($painEntries | Where-Object { $_.location -eq "lhip" }).severity | Should -Be 2.0
        }

        It "Should correctly parse vital signs" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            $result.SchemaEntry.data.vitals | Should -Not -BeNullOrEmpty
            $result.SchemaEntry.data.vitals.oxygen_saturation | Should -Be 94
            $result.SchemaEntry.data.vitals.blood_pressure | Should -Be "125/82"
            $result.SchemaEntry.data.vitals.heart_rate | Should -BeOfType [int]
            $result.SchemaEntry.data.vitals.temperature | Should -BeOfType [double]
        }

        It "Should correctly parse notes and include sleep in SchemaEntry" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            $result.SchemaEntry.notes | Should -Be "Had a difficult night, pain levels higher than usual. PT session helped."
            $result.SchemaEntry.data.sleep | Should -Not -BeNullOrEmpty
            $result.SchemaEntry.data.sleep.sleep_hours | Should -Be 5.5
        }

        It "Should process all medications into data.medications array" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            $result.SchemaEntry.data.medications | Should -Not -BeNullOrEmpty

            # Should contain all medications that were set to true
            $medications = $result.SchemaEntry.data.medications
            $medNames = $medications | ForEach-Object { $_.name }

            $medNames | Should -Contain "tylenol"
            $medNames | Should -Contain "dilaudid"
            $medNames | Should -Contain "lexapro"
            $medNames | Should -Contain "vitaminD"

            # Should have 4 medications total
            $medications.Count | Should -Be 4
        }
    }

    Context "When processing minimal form data" {
        BeforeEach {
            $mockEntry = [PSCustomObject]$script:MockEventDataMinimal
            $mockEntry.date = "0630"
            $mockEntry.timestamp = "1630"
        }

        It "Should handle entries with no medications, activities, or pain" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            # In schema v2.0, these should either not exist or be empty arrays
            if ($result.SchemaEntry.data.medications) {
                $result.SchemaEntry.data.medications.Count | Should -Be 0
            }
            if ($result.SchemaEntry.data.activities) {
                $result.SchemaEntry.data.activities.Count | Should -Be 0
            }
            if ($result.SchemaEntry.data.pain) {
                $result.SchemaEntry.data.pain.Count | Should -Be 0
            }
        }

        It "Should handle empty vital signs and notes" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            # In schema v2.0, vitals might not exist if not provided
            if ($result.SchemaEntry.data.vitals) {
                $result.SchemaEntry.data.vitals | Should -Not -BeNullOrEmpty
            }
            $result.SchemaEntry.notes | Should -Be ""
        }
    }

    Context "When processing multiple medications of same type" {
        BeforeEach {
            $mockEntry = [PSCustomObject]$script:MockEventDataMedications
            $mockEntry.date = "0630"
            $mockEntry.timestamp = "0915"
        }

        It "Should handle multiple doses of same medication as separate entries" {
            $result = ConvertTo-EntriesFormat -Entry $mockEntry -UserEmail "test@example.com"

            $result.SchemaEntry.data.medications | Should -Not -BeNullOrEmpty

            $medications = $result.SchemaEntry.data.medications

            # Should have 4 total medication entries
            $medications.Count | Should -Be 4

            # Check dilaudid entries
            $dilaudidMeds = $medications | Where-Object { $_.name -eq "dilaudid" }
            $dilaudidMeds.Count | Should -Be 2
            $dilaudidMeds.dosage | Should -Contain "2mg"
            $dilaudidMeds.dosage | Should -Contain "4mg"

            # Check tylenol entries
            $tylenolMeds = $medications | Where-Object { $_.name -eq "tylenol" }
            $tylenolMeds.Count | Should -Be 2
            $tylenolMeds.dosage | Should -Contain "500mg"
            $tylenolMeds.dosage | Should -Contain "1g"
        }
    }
}

Describe "Update-DailyMaxPainLevel Function" -Tag Update-DailyMaxPainLevel,Function {

    Context "When updating pain levels" {
        BeforeEach {
            $testEntries = @{
                "2506301200" = @{
                    entry_id = "2506301200"
                    user_email = "test@example.com"
                    date = "2025-06-30"
                    time = "12:00"
                    entry_types = @("pain")
                    data = @{
                        pain = @(
                            @{ location = "back"; severity = 5.0; note = "test" }
                            @{ location = "hip"; severity = 3.0; note = "test" }
                        )
                    }
                    notes = "Test entry"
                }
                "2506301400" = @{
                    entry_id = "2506301400"
                    user_email = "test@example.com"
                    date = "2025-06-30"
                    time = "14:00"
                    entry_types = @("pain")
                    data = @{
                        pain = @(
                            @{ location = "back"; severity = 7.0; note = "test" }
                        )
                    }
                    notes = "Test entry"
                }
            }
        }

        It "Should calculate the maximum pain level for the day" {
            $maxPain = Update-DailyMaxPainLevel -Entries $testEntries -Date "0630"

            $maxPain | Should -Be 7.0
        }

        It "Should handle entries with no pain data" {
            $testEntries["2506301600"] = @{
                entry_id = "2506301600"
                user_email = "test@example.com"
                date = "2025-06-30"
                time = "16:00"
                entry_types = @("medications")
                data = @{
                    medications = @(
                        @{ name = "tylenol"; dosage = "1g" }
                    )
                }
                notes = "Test entry"
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

            # Create a converted entry structure using new schema
            $script:testConvertedEntry = @{
                Date = "0630"
                Timestamp = "1425"
                EntryId = "2507140630"
                SchemaEntry = @{
                    entry_id = "2507140630"
                    user_email = "test@example.com"
                    date = "2025-07-14"
                    time = "14:25"
                    entry_types = @("medications", "pain", "activities", "vitals")
                    data = @{
                        medications = @(
                            @{ name = "tylenol"; dosage = "1g" }
                            @{ name = "dilaudid"; dosage = "4mg" }
                        )
                        pain = @(
                            @{ location = "back"; severity = 6.0; note = "Sharp pain" }
                        )
                        activities = @(
                            @{ name = "Walking"; duration_minutes = 25; note = "Short walk" }
                        )
                        vitals = @{
                            oxygen_saturation = 94
                            blood_pressure = "125/82"
                            heart_rate = 72
                            temperature = 98.6
                        }
                    }
                    notes = "Test entry"
                }
            }
        }

        It "Should save entry to new file when file doesn't exist" {
            # Create test directory structure
            $testUserPath = Join-Path $TestDrive "test_user_entries.json"
            $script:testConvertedEntry.SchemaEntry.user_email = "test@example.com"

            $result = Save-ConvertedEntry -ConvertedEntry $script:testConvertedEntry -EntriesPath $testUserPath

            $result | Should -Be $true
            Test-Path $testUserPath | Should -Be $true

            $savedData = Get-Content $testUserPath | ConvertFrom-Json -AsHashtable
            $savedData["2507140630"] | Should -Not -BeNullOrEmpty
            $savedData["2507140630"].entry_id | Should -Be "2507140630"
            $savedData["2507140630"].data.medications[0].name | Should -Be "tylenol"
            $savedData["2507140630"].data.medications[0].dosage | Should -Be "1g"
        }

        It "Should append to existing entries file" {
            # Create test directory structure
            $testUserPath = Join-Path $TestDrive "test_user_entries2.json"

            # Create initial entry in new schema format
            $initialEntries = @{
                "2507140900" = @{
                    entry_id = "2507140900"
                    user_email = "test@example.com"
                    date = "2025-07-14"
                    time = "09:00"
                    entry_types = @("medications")
                    data = @{
                        medications = @(
                            @{ name = "lexapro"; dosage = "20mg" }
                        )
                    }
                    notes = "Initial entry"
                }
            }
            $initialEntries | ConvertTo-Json -Depth 99 | Out-File $testUserPath -Encoding UTF8

            # Save new entry
            $result = Save-ConvertedEntry -ConvertedEntry $script:testConvertedEntry -EntriesPath $testUserPath

            $result | Should -Be $true

            $savedData = Get-Content $testUserPath | ConvertFrom-Json -AsHashtable
            $savedData["2507140900"] | Should -Not -BeNullOrEmpty  # Original entry preserved
            $savedData["2507140900"].data.medications[0].name | Should -Be "lexapro"
            $savedData["2507140630"] | Should -Not -BeNullOrEmpty  # New entry added
            $savedData["2507140630"].data.medications[0].name | Should -Be "tylenol"
        }

        It "Should save entry with new schema format" {
            $testUserPath = Join-Path $TestDrive "schema_test_entries.json"

            $result = Save-ConvertedEntry -ConvertedEntry $script:testConvertedEntry -EntriesPath $testUserPath

            $result | Should -Be $true

            $savedData = Get-Content $testUserPath | ConvertFrom-Json -AsHashtable
            $savedData["2507140630"] | Should -Not -BeNullOrEmpty
            $savedData["2507140630"].data.pain[0].severity | Should -Be 6.0
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
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData -UserEmail "integration.test@example.com"

            # Create test path for integration test
            $testIntegrationPath = Join-Path $TestDrive "integration_test_entries.json"

            # Save the entry
            $saveResult = Save-ConvertedEntry -ConvertedEntry $convertedEntry -EntriesPath $testIntegrationPath

            # Verify the complete workflow
            $saveResult | Should -Be $true

            $savedData = Get-Content $testIntegrationPath | ConvertFrom-Json -AsHashtable

            # Check that data was saved using new schema format
            $entryId = $convertedEntry.EntryId
            $savedData[$entryId] | Should -Not -BeNullOrEmpty
            $savedData[$entryId].data.medications | Should -Not -BeNullOrEmpty
            $savedData[$entryId].data.pain | Should -Not -BeNullOrEmpty
            $savedData[$entryId].data.activities | Should -Not -BeNullOrEmpty
            $savedData[$entryId].data.sleep | Should -Not -BeNullOrEmpty
            $savedData[$entryId].data.sleep.sleep_hours | Should -Be 5.5
        }
    }
}

Describe "Input Validation Tests" -Tag Validation {

    Context "ConvertTo-EntriesFormat Parameter Validation" {
        It "Should throw when Entry parameter is null" {
            { ConvertTo-EntriesFormat -Entry $null } | Should -Throw
        }

        It "Should handle non-PSCustomObject input gracefully" {
            # With schema v2.0, we now require valid date/timestamp, so this should throw
            { ConvertTo-EntriesFormat -Entry "not an object" -UserEmail "test@example.com" } | Should -Throw
        }

        It "Should handle Entry with missing required fields gracefully" {
            $incompleteEntry = [PSCustomObject]@{
                # Missing date and timestamp
                notes = "Test note"
            }

            # With schema v2.0, missing date/timestamp should throw an error
            { ConvertTo-EntriesFormat -Entry $incompleteEntry -UserEmail "test@example.com" } | Should -Throw
        }

        It "Should handle Entry with null/empty date and timestamp" {
            $entryWithNulls = [PSCustomObject]@{
                date = $null
                timestamp = ""
                notes = "Test note"
            }

            # With schema v2.0, null/empty date and timestamp should throw an error
            { ConvertTo-EntriesFormat -Entry $entryWithNulls -UserEmail "test@example.com" } | Should -Throw
        }

        It "Should validate medication property format" {
            $invalidMedEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                med_invalid_format = $true  # Should not match pattern
                med_tylenol_1g = $true      # Should match pattern
            }

            $result = ConvertTo-EntriesFormat -Entry $invalidMedEntry -UserEmail "test@example.com"
            # Should only process valid medication format
            if ($result.SchemaEntry.data.medications) {
                $medNames = $result.SchemaEntry.data.medications | ForEach-Object { $_.name }
                $medNames | Should -Contain "tylenol"
                $medNames | Should -Not -Contain "invalid"
            }
        }

        It "Should handle non-boolean medication values" {
            $invalidMedValues = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                med_tylenol_1g = "not a boolean"  # Should be ignored
                med_dilaudid_4mg = $true          # Should be processed
            }

            $result = ConvertTo-EntriesFormat -Entry $invalidMedValues -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.medications) {
                $medNames = $result.SchemaEntry.data.medications | ForEach-Object { $_.name }
                $medNames | Should -Not -Contain "tylenol"
                $medNames | Should -Contain "dilaudid"
            }
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

            # With schema v2.0, invalid pain levels should throw an exception
            { ConvertTo-EntriesFormat -Entry $invalidPainEntry -UserEmail "test@example.com" } | Should -Throw
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

            # With schema v2.0, invalid activity durations should throw an exception
            { ConvertTo-EntriesFormat -Entry $invalidActivityEntry -UserEmail "test@example.com" } | Should -Throw
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

            $result = ConvertTo-EntriesFormat -Entry $extremeEntry -UserEmail "test@example.com"
            # Should reject pain levels outside medical range (0-10)
            if ($result.SchemaEntry.data.pain) {
                $painLocations = $result.SchemaEntry.data.pain | ForEach-Object { $_.location }
                $painLocations | Should -Not -Contain "back"
            }
            # But should accept large activity durations
            if ($result.SchemaEntry.data.activities) {
                $walkingActivity = $result.SchemaEntry.data.activities | Where-Object { $_.name -eq "Walking" }
                $walkingActivity.duration_minutes | Should -Be 999999999
            }
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

            $result = ConvertTo-EntriesFormat -Entry $negativeEntry -UserEmail "test@example.com"
            # Should reject negative pain levels (medical standard is 0-10)
            if ($result.SchemaEntry.data.pain) {
                $painLocations = $result.SchemaEntry.data.pain | ForEach-Object { $_.location }
                $painLocations | Should -Not -Contain "back"
            }
            # But should accept negative activity durations (might represent adjustments)
            if ($result.SchemaEntry.data.activities) {
                $walkingActivity = $result.SchemaEntry.data.activities | Where-Object { $_.name -eq "Walking" }
                $walkingActivity.duration_minutes | Should -Be -30
            }
        }

        It "Should handle decimal pain levels" {
            $decimalEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5.5"  # Decimal pain level
            }

            $result = ConvertTo-EntriesFormat -Entry $decimalEntry -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.pain) {
                $backPain = $result.SchemaEntry.data.pain | Where-Object { $_.location -eq "back" }
                $backPain.severity | Should -Be 5.5
                $backPain.severity | Should -BeOfType [double]
            }
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

            $result = ConvertTo-EntriesFormat -Entry $specialCharsEntry -UserEmail "test@example.com"
            $result.SchemaEntry.notes | Should -Be $specialCharsText
            if ($result.SchemaEntry.data.pain) {
                $backPain = $result.SchemaEntry.data.pain | Where-Object { $_.location -eq "back" }
                $backPain.note | Should -Be $unicodeText
            }
        }

        It "Should handle very long text fields" {
            $longText = "a" * 10000  # 10KB of text
            $longTextEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                notes = $longText
            }

            $result = ConvertTo-EntriesFormat -Entry $longTextEntry -UserEmail "test@example.com"
            $result.SchemaEntry.notes | Should -Be $longText
            $result.SchemaEntry.notes.Length | Should -Be 10000
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
                "2506301200" = @{
                    entry_id = "2506301200"
                    user_email = "test@example.com"
                    date = "2025-06-30"
                    time = "12:00"
                    entry_types = @("pain")
                    data = @{
                        pain = "not an array"  # Corrupted pain data
                    }
                    notes = "Test entry"
                }
                "2506301400" = @{
                    entry_id = "2506301400"
                    user_email = "test@example.com"
                    date = "2025-06-30"
                    time = "14:00"
                    entry_types = @("pain")
                    data = @{
                        pain = @(
                            "not an object"  # Corrupted pain entry
                        )
                    }
                    notes = "Test entry"
                }
                "2506301600" = @{
                    entry_id = "2506301600"
                    user_email = "test@example.com"
                    date = "2025-06-30"
                    time = "16:00"
                    entry_types = @("pain")
                    data = @{
                        pain = @(
                            @{
                                location = "hip"
                                severity = "not a number"  # Invalid pain level
                                note = "test"
                            }
                        )
                    }
                    notes = "Test entry"
                }
            }

            # Should handle gracefully without throwing
            $result = Update-DailyMaxPainLevel -Entries $corruptedEntries -Date "0630"
            $result | Should -Be 0.0
        }
    }
}

Describe "Input Validation Tests" -Tag Validation {

    Context "ConvertTo-EntriesFormat Parameter Validation" {
        It "Should throw when Entry parameter is null" {
            { ConvertTo-EntriesFormat -Entry $null } | Should -Throw
        }

        It "Should handle non-PSCustomObject input gracefully" {
            # With schema v2.0, we now require valid date/timestamp, so this should throw
            { ConvertTo-EntriesFormat -Entry "not an object" -UserEmail "test@example.com" } | Should -Throw
        }

        It "Should handle Entry with missing required fields gracefully" {
            $incompleteEntry = [PSCustomObject]@{
                # Missing date and timestamp
                notes = "Test note"
            }

            # With schema v2.0, missing date/timestamp should throw an error
            { ConvertTo-EntriesFormat -Entry $incompleteEntry -UserEmail "test@example.com" } | Should -Throw
        }

        It "Should handle Entry with null/empty date and timestamp" {
            $entryWithNulls = [PSCustomObject]@{
                date = $null
                timestamp = ""
                notes = "Test note"
            }

            # With schema v2.0, null/empty date and timestamp should throw an error
            { ConvertTo-EntriesFormat -Entry $entryWithNulls -UserEmail "test@example.com" } | Should -Throw
        }

        It "Should validate medication property format" {
            $invalidMedEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                med_invalid_format = $true  # Should not match pattern
                med_tylenol_1g = $true      # Should match pattern
            }

            $result = ConvertTo-EntriesFormat -Entry $invalidMedEntry -UserEmail "test@example.com"
            # Should only process valid medication format
            if ($result.SchemaEntry.data.medications) {
                $medNames = $result.SchemaEntry.data.medications | ForEach-Object { $_.name }
                $medNames | Should -Contain "tylenol"
                $medNames | Should -Not -Contain "invalid"
            }
        }

        It "Should handle non-boolean medication values" {
            $invalidMedValues = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                med_tylenol_1g = "not a boolean"  # Should be ignored
                med_dilaudid_4mg = $true          # Should be processed
            }

            $result = ConvertTo-EntriesFormat -Entry $invalidMedValues -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.medications) {
                $medNames = $result.SchemaEntry.data.medications | ForEach-Object { $_.name }
                $medNames | Should -Not -Contain "tylenol"
                $medNames | Should -Contain "dilaudid"
            }
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

            # With schema v2.0, invalid pain levels should throw an exception
            { ConvertTo-EntriesFormat -Entry $invalidPainEntry -UserEmail "test@example.com" } | Should -Throw
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

            # With schema v2.0, invalid activity durations should throw an exception
            { ConvertTo-EntriesFormat -Entry $invalidActivityEntry -UserEmail "test@example.com" } | Should -Throw
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

            $result = ConvertTo-EntriesFormat -Entry $extremeEntry -UserEmail "test@example.com"
            # Should reject pain levels outside medical range (0-10)
            if ($result.SchemaEntry.data.pain) {
                $painLocations = $result.SchemaEntry.data.pain | ForEach-Object { $_.location }
                $painLocations | Should -Not -Contain "back"
            }
            # But should accept large activity durations
            if ($result.SchemaEntry.data.activities) {
                $walkingActivity = $result.SchemaEntry.data.activities | Where-Object { $_.name -eq "Walking" }
                $walkingActivity.duration_minutes | Should -Be 999999999
            }
        }

        It "Should reject negative pain levels" {
            $negativeEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "-5"  # Negative pain level - should be rejected
                add_activity = $true
            }

            $result = ConvertTo-EntriesFormat -Entry $negativeEntry -UserEmail "test@example.com"
            # Should reject negative pain levels (medical standard is 0-10)
            if ($result.SchemaEntry.data.pain) {
                $painLocations = $result.SchemaEntry.data.pain | ForEach-Object { $_.location }
                $painLocations | Should -Not -Contain "back"
            }
        }

        It "Should handle decimal pain levels" {
            $decimalEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5.5"  # Decimal pain level - should be accepted
            }

            $result = ConvertTo-EntriesFormat -Entry $decimalEntry -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.pain) {
                $backPain = $result.SchemaEntry.data.pain | Where-Object { $_.location -eq "back" }
                $backPain.severity | Should -Be 5.5
            }
        }

        It "Should handle special characters in text fields" {
            $specialCharsText = "Test with special chars: !@#$%^&*()_+-=[]{}|;':`",./<>?~"
            $unicodeText = "Pain with émojis 😵‍💫 and unicode ñoté"

            $specialCharsEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5"
                pain_note_1 = $specialCharsText
                notes = $unicodeText
            }

            $result = ConvertTo-EntriesFormat -Entry $specialCharsEntry -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.pain) {
                $backPain = $result.SchemaEntry.data.pain | Where-Object { $_.location -eq "back" }
                $backPain.note | Should -Be $specialCharsText
            }
            $result.SchemaEntry.notes | Should -Be $unicodeText
        }

        It "Should handle very long text fields" {
            $longText = "A" * 10000  # 10KB of text
            $longEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                notes = $longText
            }

            $result = ConvertTo-EntriesFormat -Entry $longEntry -UserEmail "test@example.com"
            $result.SchemaEntry.notes | Should -Be $longText
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
            # Should handle gracefully
            $result = Update-DailyMaxPainLevel -Entries $testEntries -Date "invalid-date"
            $result | Should -Be 0.0
        }

        It "Should handle entries with corrupted data gracefully" {
            $corruptedEntries = @{
                "2506301200" = @{
                    # Missing required fields
                    some_field = "value"
                }
                "2506301400" = @{
                    entry_id = "2506301400"
                    # Missing data field
                }
            }

            # Should handle gracefully
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
                # Missing Date, Timestamp, SchemaEntry
            }

            # Should handle gracefully or throw appropriate error
            { Save-ConvertedEntry -ConvertedEntry $incompleteEntry -EntriesPath $global:TestEntriesPath } | Should -Throw
        }

        It "Should handle invalid file path" {
            $validEntry = @{
                Date = "0630"
                Timestamp = "1200"
                SchemaEntry = @{
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
                EntryId = "2507140630"
                SchemaEntry = @{
                    entry_id = "2507140630"
                    user_email = "test@example.com"
                    date = "2025-07-14"
                    time = "06:30"
                    entry_types = @("medications")
                    data = @{
                        medications = @(
                            @{ name = "tylenol"; dosage = "500mg" }
                        )
                    }
                }
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
                SchemaEntry = @{
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

            $result = ConvertTo-EntriesFormat -Entry $midnightEntry -UserEmail "test@example.com"
            $result.Timestamp | Should -Be "0000"
        }

        It "Should handle timestamp at end of day boundary" {
            $endOfDayEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "2359"
                notes = "End of day entry"
            }

            $result = ConvertTo-EntriesFormat -Entry $endOfDayEntry -UserEmail "test@example.com"
            $result.Timestamp | Should -Be "2359"
        }

        It "Should handle leap year date formats" {
            $leapYearEntry = [PSCustomObject]@{
                date = "0229"  # Feb 29 (leap year) - but 2025 is not a leap year
                timestamp = "1200"
                notes = "Leap year test"
            }

            # Since 2025 is not a leap year, this should throw an error
            { ConvertTo-EntriesFormat -Entry $leapYearEntry -UserEmail "test@example.com" } | Should -Throw
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

            $result = ConvertTo-EntriesFormat -Entry $manyActivitiesEntry -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.activities) {
                $result.SchemaEntry.data.activities.Count | Should -Be 50
            }
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

            $result = ConvertTo-EntriesFormat -Entry $manyPainEntry -UserEmail "test@example.com"
            # Should only accept pain levels 1-10 (levels 11-20 should be rejected)
            if ($result.SchemaEntry.data.pain) {
                $result.SchemaEntry.data.pain.Count | Should -Be 10

                # Verify that only valid pain levels are included
                foreach ($painEntry in $result.SchemaEntry.data.pain) {
                    $painEntry.severity | Should -BeLessOrEqual 10
                    $painEntry.severity | Should -BeGreaterThan 0
                }
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

            $result = ConvertTo-EntriesFormat -Entry $stringNumberEntry -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.activities) {
                $result.SchemaEntry.data.activities[0].duration_minutes | Should -BeOfType [int]
                $result.SchemaEntry.data.activities[0].duration_minutes | Should -Be 30
            }
        }

        It "Should handle string numbers that should be doubles" {
            $stringDoubleEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_pain = $true
                pain_location_1 = "back"
                pain_level_1 = "5.5"  # String that should become double
            }

            $result = ConvertTo-EntriesFormat -Entry $stringDoubleEntry -UserEmail "test@example.com"
            if ($result.SchemaEntry.data.pain) {
                $result.SchemaEntry.data.pain[0].severity | Should -BeOfType [double]
                $result.SchemaEntry.data.pain[0].severity | Should -Be 5.5
            }
        }

        It "Should handle boolean-like strings" {
            $booleanStringEntry = [PSCustomObject]@{
                date = "0630"
                timestamp = "1200"
                add_activity = "true"  # String instead of boolean
                add_pain = "false"     # String instead of boolean
            }

            # Should handle gracefully
            { ConvertTo-EntriesFormat -Entry $booleanStringEntry -UserEmail "test@example.com" } | Should -Not -Throw
        }
    }
}

# Tests for new multi-user functions
Describe "Get-UserEntriesPath Function" -Tag Get-UserEntriesPath,Function {

    Context "When generating user entries paths" {
        It "Should generate correct path for valid email" {
            $result = Get-UserEntriesPath -UserEmail "user@example.com"

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "users"
            $result | Should -Match "health-data"
            $result | Should -Match "entries\.json$"

            # Should contain base64 encoded email
            $encodedEmail = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("user@example.com"))
            $result | Should -Match $encodedEmail
        }

        It "Should handle custom base data path" {
            $customPath = "/custom/data/path"
            $result = Get-UserEntriesPath -UserEmail "user@example.com" -BaseDataPath $customPath

            $result | Should -Match "^/custom/data/path"
        }

        It "Should generate different paths for different users" {
            $path1 = Get-UserEntriesPath -UserEmail "user1@example.com"
            $path2 = Get-UserEntriesPath -UserEmail "user2@example.com"

            $path1 | Should -Not -Be $path2
        }

        It "Should handle special characters in email" {
            $result = Get-UserEntriesPath -UserEmail "user+tag@sub.domain.com"

            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match "entries\.json$"
        }

        It "Should throw for invalid email format" {
            { Get-UserEntriesPath -UserEmail "not-an-email" } | Should -Throw
            { Get-UserEntriesPath -UserEmail "missing@domain" } | Should -Throw
            { Get-UserEntriesPath -UserEmail "@domain.com" } | Should -Throw
        }
    }
}

Describe "Get-CachedEntriesData Function" -Tag Get-CachedEntriesData, Function {

    Context "When loading entries data" {
        BeforeEach {
            $script:TestUserEntriesPath = Join-Path $TestDrive "user_entries.json"

            # Create test entries file with unified schema
            $testUnifiedEntries = @{
                "2507140900" = @{
                    entry_id = "2507140900"
                    user_email = "test@example.com"
                    date = "2025-07-14"
                    time = "09:00"
                    entry_types = @("mood", "vitals")
                    data = @{
                        mood = @{
                            mood_level = 4
                            mood_note = "Feeling good today"
                        }
                        vitals = @{
                            blood_pressure = "120/80"
                            heart_rate = 75
                            oxygen_saturation = 98
                            temperature = 98.6
                        }
                    }
                    notes = "Morning check-in"
                }
            }
            $testUnifiedEntries | ConvertTo-Json -Depth 10 | Out-File $script:TestUserEntriesPath -Encoding UTF8
        }

        It "Should load entries from file when cache is empty" {
            $result = Get-CachedEntriesData -EntriesPath $script:TestUserEntriesPath

            $result | Should -Not -BeNullOrEmpty
            $result["2507140900"] | Should -Not -BeNullOrEmpty
            $result["2507140900"]["entry_id"] | Should -Be "2507140900"
        }

        It "Should create empty structure for non-existent file" {
            $nonExistentPath = Join-Path $TestDrive "nonexistent.json"
            $result = Get-CachedEntriesData -EntriesPath $nonExistentPath

            Test-Path $nonExistentPath | Should -Be $true
            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
        }

        It "Should handle force reload" {
            # First load
            $result1 = Get-CachedEntriesData -EntriesPath $script:TestUserEntriesPath
            $result1 | Should -Not -BeNullOrEmpty

            # Force reload
            $result2 = Get-CachedEntriesData -EntriesPath $script:TestUserEntriesPath -ForceReload

            $result2 | Should -Not -BeNullOrEmpty
        }

        It "Should throw for invalid parent directory" {
            $invalidPath = "/nonexistent/path/entries.json"
            { Get-CachedEntriesData -EntriesPath $invalidPath } | Should -Throw
        }
}

# Tests for unified schema functions
Describe "New-SampleHealthEntries Function" -Tag New-SampleHealthEntries,UnifiedSchema {

    Context "When generating unified schema sample data" {
        It "Should generate entries with proper unified schema structure" {
            $result = New-SampleHealthEntries -Count 3

            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -Be "Hashtable"
            $result.Keys.Count | Should -Be 3
        }

        It "Should use composite key format (yyMMddHHmm)" {
            $result = New-SampleHealthEntries -Count 1

            $key = $result.Keys | Select-Object -First 1
            $key | Should -Match "^\d{10}$"  # 10-digit composite key

            # Verify key components
            $year = [int]($key.Substring(0, 2))
            $month = [int]($key.Substring(2, 2))
            $day = [int]($key.Substring(4, 2))
            $hour = [int]($key.Substring(6, 2))
            $minute = [int]($key.Substring(8, 2))

            $year | Should -BeGreaterOrEqual 20
            $month | Should -BeGreaterOrEqual 1
            $month | Should -BeLessOrEqual 12
            $day | Should -BeGreaterOrEqual 1
            $day | Should -BeLessOrEqual 31
            $hour | Should -BeGreaterOrEqual 0
            $hour | Should -BeLessOrEqual 23
            $minute | Should -BeGreaterOrEqual 0
            $minute | Should -BeLessOrEqual 59
        }

        It "Should have proper entry structure for each entry" {
            $result = New-SampleHealthEntries -Count 1
            $entryKey = $result.Keys | Select-Object -First 1
            $entry = $result[$entryKey]  # Direct hashtable access instead of pipeline

            # Required fields
            $entry.entry_id | Should -Not -BeNullOrEmpty
            $entry.user_email | Should -Not -BeNullOrEmpty
            $entry.date | Should -Not -BeNullOrEmpty
            $entry.time | Should -Not -BeNullOrEmpty
            $entry.entry_types | Should -Not -BeNullOrEmpty
            $entry.data | Should -Not -BeNullOrEmpty

            # Validate date format (YYYY-MM-DD)
            $entry.date | Should -Match "^\d{4}-\d{2}-\d{2}$"

            # Validate time format (HH:mm)
            $entry.time | Should -Match "^\d{2}:\d{2}$"

            # Validate entry_types is array by checking if it has array properties
            # Use Count property instead of type checking to avoid Pester unwrapping
            $entry.entry_types.Count | Should -BeGreaterThan 0
            $entry.entry_types.GetType().IsArray | Should -Be $true
        }

        It "Should use string format for blood_pressure" {
            $result = New-SampleHealthEntries -Count 10  # Generate more to ensure we get a vitals entry

            $vitalEntries = $result.Values | Where-Object { $_.entry_types -contains "vitals" }
            $vitalEntries | Should -Not -BeNullOrEmpty

            $vitalsEntry = $vitalEntries | Select-Object -First 1
            $vitalsEntry.data.vitals.blood_pressure | Should -Match "^\d{2,3}/\d{2,3}$"  # Format: "120/80"
        }

        It "Should generate different entry types" {
            $result = New-SampleHealthEntries -Count 20  # Generate enough to get variety

            $allEntryTypes = $result.Values | ForEach-Object { $_.entry_types } | Sort-Object -Unique

            # Should have multiple entry types
            $allEntryTypes.Count | Should -BeGreaterThan 1

            # Check for expected types (from schema v2.0)
            $expectedTypes = @("mood", "vitals", "medications", "activities", "pain", "weight", "sleep")
            $hasExpectedType = $false
            foreach ($type in $expectedTypes) {
                if ($allEntryTypes -contains $type) {
                    $hasExpectedType = $true
                    break
                }
            }
            $hasExpectedType | Should -Be $true
        }

        It "Should handle Count parameter correctly" {
            $result1 = New-SampleHealthEntries -Count 1
            $result5 = New-SampleHealthEntries -Count 5
            $result10 = New-SampleHealthEntries -Count 10

            $result1.Keys.Count | Should -Be 1
            $result5.Keys.Count | Should -Be 5
            $result10.Keys.Count | Should -Be 10
        }

        It "Should generate unique composite keys" {
            $result = New-SampleHealthEntries -Count 20

            $uniqueKeys = $result.Keys | Sort-Object -Unique
            $uniqueKeys.Count | Should -Be $result.Keys.Count  # All keys should be unique
        }

        It "Should validate mood data structure when present" {
            $result = New-SampleHealthEntries -Count 20

            $moodEntries = $result.Values | Where-Object { $_.entry_types -contains "mood" }
            if ($moodEntries) {
                $moodEntry = $moodEntries | Select-Object -First 1
                $moodData = $moodEntry.data.mood

                $moodData.mood_level | Should -BeGreaterOrEqual 1
                $moodData.mood_level | Should -BeLessOrEqual 10
                $moodData.mood_note | Should -Not -BeNullOrEmpty
            }
        }

        It "Should validate pain data structure when present" {
            $result = New-SampleHealthEntries -Count 20

            $painEntries = $result.Values | Where-Object { $_.entry_types -contains "pain" }
            if ($painEntries) {
                $painEntry = $painEntries | Select-Object -First 1
                $painDataArray = $painEntry.data.pain

                # Schema v2.0: pain is an array of pain objects
                $painDataArray | Should -Not -BeNullOrEmpty
                $painDataArray.Count | Should -BeGreaterThan 0

                $painData = $painDataArray[0]  # Get first pain object from array
                $painData.severity | Should -BeGreaterOrEqual 0
                $painData.severity | Should -BeLessOrEqual 10
                $painData.location | Should -Not -BeNullOrEmpty
            }
        }

        It "Should use realistic sample user email" {
            $result = New-SampleHealthEntries -Count 1
            $entry = $result.Values | Select-Object -First 1

            $entry.user_email | Should -Match "@.*\."  # Basic email format
        }

        It "Should handle zero count gracefully" {
            $result = New-SampleHealthEntries -Count 0

            $result | Should -Not -Be $null
            $result | Should -BeOfType [hashtable]
            $result.Keys.Count | Should -Be 0
        }

        It "Should validate generated JSON is well-formed" {
            $result = New-SampleHealthEntries -Count 5

            # Convert to JSON and back to ensure it's valid
            $json = $result | ConvertTo-Json -Depth 10
            $roundTrip = $json | ConvertFrom-Json -AsHashtable

            $roundTrip.Keys.Count | Should -Be $result.Keys.Count
        }
    }
}

# Tests for compatibility between old and new schemas
Describe "Schema Compatibility Tests" -Tag SchemaCompatibility {

    Context "When working with mixed schema data" {
        BeforeEach {
            $script:TestMixedPath = Join-Path $TestDrive "mixed_schema.json"
        }

        It "Should handle loading old schema data with new functions" {
            # Create old schema data
            $oldData = @{
                "0714" = @{
                    "0900" = @{
                        "Medications" = @{ "tylenol" = "1g" }
                        "Pain" = @{ "back" = @{ "pain_level" = 5.0; "note" = "test" } }
                        "bpr" = "120/80"
                        "note" = "Old format entry"
                    }
                }
            }
            $oldData | ConvertTo-Json -Depth 10 | Out-File $script:TestMixedPath -Encoding UTF8

            # Should be able to load with new function
            $result = Get-CachedEntriesData -EntriesPath $script:TestMixedPath

            $result | Should -Not -BeNullOrEmpty
            $result["0714"] | Should -Not -BeNullOrEmpty
        }

        It "Should preserve blood pressure string format across schemas" {
            # Both old and new schemas should use string format for blood pressure
            $newSample = New-SampleHealthEntries -Count 10

            # Find a vitals entry in new format
            $vitalsEntry = $newSample.Values | Where-Object { $_.entry_types -contains "vitals" } | Select-Object -First 1

            if ($vitalsEntry) {
                $vitalsEntry.data.vitals.blood_pressure | Should -Match "^\d{2,3}/\d{2,3}$"
                $vitalsEntry.data.vitals.blood_pressure | Should -BeOfType [string]
                # Verify it follows the expected "systolic/diastolic" pattern (110-140 / 70-90)
                $vitalsEntry.data.vitals.blood_pressure | Should -Match "^1[1-4][0-9]/[7-9][0-9]$"
            }
        }
    }
}
}
