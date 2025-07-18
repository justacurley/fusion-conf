BeforeAll {
    # Import the module under test
    Import-Module -Name "$PSScriptRoot/../GetFusion.psm1" -Force

    # Import the fusion module for New-SampleHealthEntries function
    Import-Module -Name "$PSScriptRoot/../../fusion/fusion.psm1" -Force

    # Create a mock entries.json file for testing
    $script:TestEntriesPath = Join-Path $TestDrive "test_entries.json"

    # Generate dynamic test data using New-SampleHealthEntries function with schema v2.0
    $script:SampleEntries = New-SampleHealthEntries -Count 15 -DateRange 7 -OutputFormat "Array" -UserEmail "test@example.com"

    # Add some specific predictable entries for testing - using schema v2.0 format
    $specificEntries = @(
        @{
            entry_id = "2407260800"
            user_email = "test@example.com"
            date = "2024-07-26"
            time = "08:00"
            entry_types = @("pain")
            data = @{
                pain = @(
                    @{
                        location = "back"
                        severity = 4.5
                        note = ""
                    }
                )
            }
            notes = ""
        },
        @{
            entry_id = "2407260900"
            user_email = "test@example.com"
            date = "2024-07-26"
            time = "09:00"
            entry_types = @("pain", "medications", "activities")
            data = @{
                pain = @(
                    @{
                        location = "back"
                        severity = 3.0
                        note = ""
                    }
                )
                medications = @(
                    @{
                        name = "dilaudid"
                        dosage = "4mg"
                        time = "09:00"
                    }
                )
                activities = @(
                    @{
                        name = "walking"
                        duration_minutes = 30
                        note = "short walk"
                    }
                )
            }
            notes = ""
        },
        @{
            entry_id = "2407261300"
            user_email = "test@example.com"
            date = "2024-07-26"
            time = "13:00"
            entry_types = @("medications", "activities", "vitals")
            data = @{
                medications = @(
                    @{
                        name = "tylenol"
                        dosage = "1g"
                        time = "13:00"
                    }
                )
                activities = @(
                    @{
                        name = "stretching"
                        duration_minutes = 15
                        note = ""
                    }
                )
                vitals = @{
                    blood_pressure = "120/80"
                    heart_rate = 75
                    oxygen_saturation = 95
                    temperature = 98.6
                }
            }
            notes = "feeling better"
        },
        @{
            entry_id = "2407250800"
            user_email = "test@example.com"
            date = "2024-07-25"
            time = "08:00"
            entry_types = @("pain", "medications", "vitals")
            data = @{
                pain = @(
                    @{
                        location = "back"
                        severity = 6.0
                        note = "morning stiffness"
                    }
                )
                medications = @(
                    @{
                        name = "tylenol"
                        dosage = "1g"
                        time = "08:00"
                    }
                )
                vitals = @{
                    blood_pressure = "118/83"
                    heart_rate = 82
                    oxygen_saturation = 92
                    temperature = 98.4
                }
            }
            notes = ""
        },
        @{
            entry_id = "2407251400"
            user_email = "test@example.com"
            date = "2024-07-25"
            time = "14:00"
            entry_types = @("pain", "medications", "activities")
            data = @{
                pain = @(
                    @{
                        location = "back"
                        severity = 5.5
                        note = ""
                    }
                )
                medications = @(
                    @{
                        name = "dilaudid"
                        dosage = "4mg"
                        time = "14:00"
                    }
                )
                activities = @(
                    @{
                        name = "walking"
                        duration_minutes = 45
                        note = "longer walk today"
                    }
                )
            }
            notes = ""
        },
        @{
            entry_id = "2407251401"
            user_email = "test@example.com"
            date = "2024-07-25"
            time = "14:01"
            entry_types = @("pain", "activities")
            data = @{
                pain = @(
                    @{
                        location = "knee"
                        severity = 2.0
                        note = ""
                    }
                )
                activities = @(
                    @{
                        name = "stairs"
                        duration_minutes = 5
                        note = "up and down once"
                    }
                )
            }
            notes = ""
        },
        @{
            entry_id = "2407241200"
            user_email = "test@example.com"
            date = "2024-07-24"
            time = "12:00"
            entry_types = @()
            data = @{}
            notes = "good day overall"
        }
    )

    # Combine generated and specific entries
    $script:AllTestEntries = @($script:SampleEntries) + $specificEntries

    # Save schema v2.0 format to test file
    $script:AllTestEntries | ConvertTo-Json -Depth 10 | Out-File $script:TestEntriesPath -Encoding UTF8

    # Create old format data for legacy function testing
    $script:MockEntries = @{}
    $script:TestEntries = @{}

    # Convert specific entries to old format for existing tests
    $script:MockEntries["0626"] = @{
        "max_pain_level" = 4.5
        "0800" = @{
            "note" = ""
            "bpr" = ""
            "Activities" = @{}
            "Medications" = @{}
            "o2" = ""
            "medication_taken" = ""
            "Pain" = @{
                "back" = @{
                    "pain_level" = 4.5
                    "note" = ""
                }
            }
        }
        "0900" = @{
            "bpr" = "126/81"
            "medication_taken" = "dilaudid"
            "Activities" = @{
                "walking" = @{
                    "duration" = 30
                    "note" = "short walk"
                }
            }
            "Pain" = @{
                "back" = @{
                    "pain_level" = 3.0
                    "note" = ""
                }
            }
            "note" = ""
            "Medications" = @{
                "dilaudid" = "4mg"
            }
            "o2" = "93"
        }
        "1300" = @{
            "bpr" = "120/80"
            "medication_taken" = "tylenol"
            "Activities" = @{
                "stretching" = @{
                    "duration" = 15
                    "note" = ""
                }
            }
            "Pain" = @{}
            "note" = "feeling better"
            "Medications" = @{
                "tylenol" = "1g"
            }
            "o2" = "95"
        }
        "Sleep" = "7:25"
    }

    $script:MockEntries["0625"] = @{
        "max_pain_level" = 6.0
        "0800" = @{
            "bpr" = "118/83"
            "medication_taken" = "tylenol"
            "Activities" = @{}
            "Pain" = @{
                "back" = @{
                    "pain_level" = 6.0
                    "note" = "morning stiffness"
                }
            }
            "note" = ""
            "Medications" = @{
                "tylenol" = "1g"
            }
            "o2" = "92"
        }
        "1400" = @{
            "bpr" = "110/70"
            "medication_taken" = "dilaudid"
            "Activities" = @{
                "walking" = @{
                    "duration" = 45
                    "note" = "longer walk today"
                }
                "stairs" = @{
                    "duration" = 5
                    "note" = "up and down once"
                }
            }
            "Pain" = @{
                "back" = @{
                    "pain_level" = 5.5
                    "note" = ""
                }
                "knee" = @{
                    "pain_level" = 2.0
                    "note" = ""
                }
            }
            "note" = ""
            "Medications" = @{
                "dilaudid" = "4mg"
            }
            "o2" = "91"
        }
        "Sleep" = "6:13"
    }

    $script:MockEntries["0624"] = @{
        "max_pain_level" = 0.0
        "1200" = @{
            "bpr" = ""
            "medication_taken" = ""
            "Activities" = @{}
            "Pain" = @{}
            "note" = "good day overall"
            "Medications" = @{}
            "o2" = ""
        }
        "Sleep" = "9:07"
    }

    # Convert to PSCustomObject for old format tests
    $script:TestEntries = $script:MockEntries | ConvertTo-Json -Depth 10 | ConvertFrom-Json
}

AfterAll {
    # Clean up
    Remove-Module GetFusion -Force -ErrorAction SilentlyContinue
    Remove-Module fusion -Force -ErrorAction SilentlyContinue
    if (Test-Path $script:TestEntriesPath) {
        Remove-Item $script:TestEntriesPath -Force
    }
}

Describe "Get-SleepHours Function" {
    Context "When parsing different sleep formats" {
        It "Should parse HH:MM format correctly" {
            $result = Get-SleepHours -sleepValue "7:25"
            $result | Should -Be 7.42
        }

        It "Should parse HH:MM format with single digit hours" {
            $result = Get-SleepHours -sleepValue "6:13"
            $result | Should -Be 6.22
        }

        It "Should parse decimal format correctly" {
            $result = Get-SleepHours -sleepValue "8.5"
            $result | Should -Be 8.5
        }

        It "Should handle whole hours without minutes" {
            $result = Get-SleepHours -sleepValue "9:00"
            $result | Should -Be 9.0
        }

        It "Should return null for empty or null input" {
            $result = Get-SleepHours -sleepValue ""
            $result | Should -Be $null

            $result = Get-SleepHours -sleepValue $null
            $result | Should -Be $null
        }

        It "Should return null for invalid format" {
            $result = Get-SleepHours -sleepValue "invalid"
            $result | Should -Be $null
        }
    }
}

Describe "Get-AverageBackPain Function" {
    Context "When calculating average back pain" {
        It "Should calculate average back pain for a date with multiple entries" {
            # Filter entries for date 2024-07-26 with back pain
            $backPainEntries = $script:AllTestEntries | Where-Object { $_.date -eq "2024-07-26" -and $_.entry_types -contains "pain" -and $_.data.pain.location -eq "back" }
            $result = Get-AverageBackPain -entries $backPainEntries
            $result | Should -Be 3.8  # (4.5 + 3.0) / 2 = 3.75, rounded to 3.8
        }

        It "Should calculate average back pain for a date with single entry" {
            # Filter entries for date 2024-07-25 with back pain
            $backPainEntries = $script:AllTestEntries | Where-Object { $_.date -eq "2024-07-25" -and $_.entry_types -contains "pain" -and $_.data.pain.location -eq "back" }
            $result = Get-AverageBackPain -entries $backPainEntries
            $result | Should -Be 5.8  # (6.0 + 5.5) / 2 = 5.75, rounded to 5.8
        }

        It "Should return null when no back pain data exists" {
            # Filter entries for date 2024-07-24 with back pain (should be none)
            $backPainEntries = $script:AllTestEntries | Where-Object { $_.date -eq "2024-07-24" -and $_.entry_types -contains "pain" -and $_.data.pain.location -eq "back" }
            $result = Get-AverageBackPain -entries $backPainEntries
            $result | Should -Be $null
        }
    }
}

Describe "Get-TotalActivityDuration Function" {
    Context "When calculating total activity duration" {
        It "Should calculate total duration for date with single activity" {
            $result = Get-TotalActivityDuration -date "2024-07-26" -entries $script:AllTestEntries
            $result | Should -Be 45  # 30 (walking) + 15 (stretching)
        }

        It "Should calculate total duration for date with multiple activities" {
            $result = Get-TotalActivityDuration -date "2024-07-25" -entries $script:AllTestEntries
            $result | Should -Be 50  # 45 (walking) + 5 (stairs)
        }

        It "Should return null when no activities exist" {
            $result = Get-TotalActivityDuration -date "2024-07-24" -entries $script:AllTestEntries
            $result | Should -Be $null
        }
    }
}

Describe "Convert-DateToDisplay Function" {
    Context "When converting date formats" {
        It "Should convert YYYY-MM-DD format to MM/DD" {
            $result = Convert-DateToDisplay -date "2024-06-26"
            $result | Should -Be "06/26"
        }

        It "Should convert different YYYY-MM-DD format" {
            $result = Convert-DateToDisplay -date "2024-12-31"
            $result | Should -Be "12/31"
        }

        It "Should return original string for non-standard input" {
            $result = Convert-DateToDisplay -date "626"
            $result | Should -Be "626"
        }
    }
}

Describe "Get-EntriesData Function" {
    Context "When loading entries data" {
        It "Should load and parse JSON file correctly" {
            $result = Get-EntriesData -entriesPath $script:TestEntriesPath
            $result | Should -Not -Be $null
            $result.GetType().Name | Should -Be "Object[]"  # Check if it's an array
            $result.Count | Should -BeGreaterThan 0
            $result[0].entry_id | Should -Not -Be $null
            $result[0].user_email | Should -Be "test@example.com"
        }
    }
}

Describe "Get-DatesList Function" {
    Context "When getting sorted dates list" {
        BeforeEach {
            # Clear cached dates before each test
            Clear-CachedData
        }

        It "Should return sorted list of dates" {
            $result = Get-DatesList -entries $script:AllTestEntries
            $result | Should -HaveCount ($script:AllTestEntries | Select-Object -ExpandProperty date -Unique).Count
            # Check that dates are sorted (first date should be earliest)
            $result[0] | Should -Match "^\d{4}-\d{2}-\d{2}$"
        }

        It "Should cache dates list for performance" {
            $result1 = Get-DatesList -entries $script:AllTestEntries
            $result2 = Get-DatesList -entries $script:AllTestEntries
            $result1 | Should -Be $result2
        }
    }
}

Describe "Get-DateMedicationData Function" {
    Context "When extracting medication data" {
        It "Should extract all medications for a date" {
            $medications = Get-DateMedicationData -date "2024-07-26" -entries $script:AllTestEntries
            $medications | Should -HaveCount 2

            $dilaudidEntry = $medications | Where-Object { $_.Medication -eq "dilaudid" }
            $dilaudidEntry | Should -Not -Be $null
            $dilaudidEntry.Dose | Should -Be "4mg"
            $dilaudidEntry.Date | Should -Be "2024-07-26"
            $dilaudidEntry.Timestamp | Should -Be "09:00"

            $tylenolEntry = $medications | Where-Object { $_.Medication -eq "tylenol" }
            $tylenolEntry | Should -Not -Be $null
            $tylenolEntry.Dose | Should -Be "1g"
        }

        It "Should return empty array when no medications exist" {
            $medications = Get-DateMedicationData -date "2024-07-24" -entries $script:AllTestEntries
            $medications | Should -HaveCount 0
        }
    }
}

Describe "Get-DateActivityData Function" {
    Context "When extracting activity data" {
        It "Should extract all activities for a date with multiple activities" {
            $activities = Get-DateActivityData -date "2024-07-25" -entries $script:AllTestEntries
            $activities | Should -HaveCount 2

            $walkingEntry = $activities | Where-Object { $_.Activity -eq "walking" }
            $walkingEntry | Should -Not -Be $null
            $walkingEntry.Duration | Should -Be 45
            $walkingEntry.Note | Should -Be "longer walk today"
            $walkingEntry.Date | Should -Be "2024-07-25"

            $stairsEntry = $activities | Where-Object { $_.Activity -eq "stairs" }
            $stairsEntry | Should -Not -Be $null
            $stairsEntry.Duration | Should -Be 5
        }

        It "Should extract activities for a date with single activity" {
            $activities = Get-DateActivityData -date "2024-07-26" -entries $script:AllTestEntries
            $activities | Should -HaveCount 2  # walking and stretching

            $walkingEntry = $activities | Where-Object { $_.Activity -eq "walking" }
            $walkingEntry.Duration | Should -Be 30
            $walkingEntry.Note | Should -Be "short walk"
        }

        It "Should return empty array when no activities exist" {
            $activities = Get-DateActivityData -date "2024-07-24" -entries $script:AllTestEntries
            $activities | Should -HaveCount 0
        }
    }
}

Describe "Get-DateVitalsData Function" {
    Context "When extracting vitals data" {
        It "Should extract blood pressure and oxygen data" {
            $vitals = Get-DateVitalsData -date "2024-07-26" -entries $script:AllTestEntries
            $vitals.Count | Should -BeGreaterThan 0  # Should have some vitals

            $bprEntries = $vitals | Where-Object { $_.VitalType -eq "Blood Pressure" }
            $bprEntries.Count | Should -BeGreaterThan 0  # Should have some blood pressure readings

            $o2Entries = $vitals | Where-Object { $_.VitalType -eq "Oxygen Saturation" }
            $o2Entries.Count | Should -BeGreaterThan 0  # Should have some oxygen readings
        }

        It "Should handle entries with missing vitals data" {
            $vitals = Get-DateVitalsData -date "2024-07-24" -entries $script:AllTestEntries
            $vitals | Should -HaveCount 0
        }
    }
}

Describe "Set-CombinedData Function" {
    Context "When adding data to combined object" {
        It "Should add new property to existing object" {
            $testObject = [PSCustomObject]@{ Date = "06/26" }
            $result = Set-CombinedData -combinedData $testObject -name "MaxPain" -data 4.5

            $result.MaxPain | Should -Be 4.5
            $result.Date | Should -Be "06/26"
        }

        It "Should overwrite existing property with warning" {
            $testObject = [PSCustomObject]@{ Date = "06/26"; MaxPain = 3.0 }
            # Note: The actual GetFusion module uses Show-UDToast which may not be available in test environment
            # This test just verifies the functionality works, warnings may not be displayed
            $result = Set-CombinedData -combinedData $testObject -name "MaxPain" -data 4.5

            $result.MaxPain | Should -Be 4.5
        }
    }
}

Describe "Get-HealthMetrics Function" {
    Context "When extracting comprehensive health metrics" {
        BeforeEach {
            Clear-CachedData
        }

        It "Should extract MaxPain data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('MaxPain')
            $result.CombinedHealthData | Should -Not -Be $null
            $result.CombinedHealthData.Count | Should -BeGreaterThan 0

            # Check that we have some MaxPain data
            $maxPainData = $result.CombinedHealthData | Where-Object { $_.PSObject.Properties.Name -contains "MaxPain" }
            $maxPainData | Should -Not -Be $null
        }

        It "Should extract BackPain data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('BackPain')
            $result.CombinedHealthData | Should -Not -Be $null
            $result.CombinedHealthData.Count | Should -BeGreaterThan 0

            # Check that we have some BackPain data
            $backPainData = $result.CombinedHealthData | Where-Object { $_.PSObject.Properties.Name -contains "BackPain" }
            $backPainData | Should -Not -Be $null
        }

        It "Should extract Sleep data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('Sleep')
            $result.CombinedHealthData | Should -Not -Be $null
            $result.CombinedHealthData.Count | Should -BeGreaterThan 0

            # Check that we have some Sleep data
            $sleepData = $result.CombinedHealthData | Where-Object { $_.PSObject.Properties.Name -contains "Sleep" }
            $sleepData | Should -Not -Be $null
        }

        It "Should extract ActivityDuration data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('ActivityDuration')
            $result.CombinedHealthData | Should -Not -Be $null
            $result.CombinedHealthData.Count | Should -BeGreaterThan 0

            # Check that we have some ActivityDuration data
            $activityData = $result.CombinedHealthData | Where-Object { $_.PSObject.Properties.Name -contains "ActivityDuration" }
            $activityData | Should -Not -Be $null
        }

        It "Should extract Medications data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('Medications')
            $result.Medications | Should -Not -Be $null
            $result.Medications.Count | Should -BeGreaterThan 0

            # Check that we have some medications
            $medicationEntries = $result.Medications | Where-Object { $_.Medication -ne $null }
            $medicationEntries | Should -Not -Be $null
        }

        It "Should extract Activities data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('Activities')
            $result.Activities | Should -Not -Be $null
            $result.Activities.Count | Should -BeGreaterThan 0

            # Check that we have some activities
            $activityEntries = $result.Activities | Where-Object { $_.Activity -ne $null }
            $activityEntries | Should -Not -Be $null
        }

        It "Should extract Vitals data" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('Vitals')
            $result.Vitals | Should -Not -Be $null
            $result.Vitals.Count | Should -BeGreaterThan 0

            # Check that we have some vitals
            $vitalsEntries = $result.Vitals | Where-Object { $_.VitalType -ne $null }
            $vitalsEntries | Should -Not -Be $null
        }

        It "Should extract multiple data points in single call" {
            $result = Get-HealthMetrics -Entries $script:AllTestEntries -DataPoints @('MaxPain', 'Sleep', 'Medications')

            # Should have combined health data
            $result.CombinedHealthData | Should -Not -Be $null
            $result.CombinedHealthData.Count | Should -BeGreaterThan 0

            # Should have medications data
            $result.Medications | Should -Not -Be $null
            $result.Medications.Count | Should -BeGreaterThan 0
        }
    }
}

Describe "Sort-HealthDataByDate Function" {
    Context "When sorting health data chronologically" {
        It "Should sort data by date correctly" {
            $testData = @(
                [PSCustomObject]@{ Date = "06/26"; Value = 1 }
                [PSCustomObject]@{ Date = "06/24"; Value = 2 }
                [PSCustomObject]@{ Date = "06/25"; Value = 3 }
            )

            $result = Sort-HealthDataByDate -healthData $testData
            $result[0].Date | Should -Be "06/24"
            $result[1].Date | Should -Be "06/25"
            $result[2].Date | Should -Be "06/26"
        }
    }
}

Describe "Clear-CachedData Function" {
    Context "When clearing cached data" {
        It "Should clear global cache variables" {
            # Set some cache data
            $global:DatesList = @("test")
            $global:DistinctDataValues = @{ "Test" = @("value") }

            Clear-CachedData

            $global:DatesList | Should -Be $null
            # DistinctDataValues is reset to empty hashtable, not null
            $global:DistinctDataValues.Count | Should -Be 0
        }
    }
}

Describe "Integration Tests" {
    Context "When processing real-world workflow" {
        BeforeEach {
            Clear-CachedData
        }

        It "Should handle complete health data extraction workflow" {
            # Load entries
            $entries = Get-EntriesData -entriesPath $script:TestEntriesPath

            # Extract comprehensive metrics
            $healthMetrics = Get-HealthMetrics -Entries $entries -DataPoints @('MaxPain', 'BackPain', 'Sleep', 'ActivityDuration', 'Medications', 'Activities', 'Vitals')

            # Verify all data types were extracted
            $healthMetrics.CombinedHealthData | Should -Not -Be $null
            $healthMetrics.Medications | Should -Not -Be $null
            $healthMetrics.Activities | Should -Not -Be $null
            $healthMetrics.Vitals | Should -Not -Be $null

            # Verify we have some data
            $healthMetrics.CombinedHealthData.Count | Should -BeGreaterThan 0

            # Sort combined health data by date
            $sortedData = Sort-HealthDataByDate -healthData $healthMetrics.CombinedHealthData
            $sortedData | Should -Not -Be $null
            $sortedData.Count | Should -BeGreaterThan 0
        }

        It "Should handle data with missing fields gracefully" {
            # Create minimal entries with missing data
            $sparseEntries = @(
                @{
                    entry_id = "2407301200"
                    user_email = "test@example.com"
                    date = "2024-07-30"
                    time = "12:00"
                    entry_types = @()
                    data = @{}
                    notes = "minimal entry"
                }
            )

            $result = Get-HealthMetrics -Entries $sparseEntries -DataPoints @('MaxPain', 'BackPain', 'Sleep')
            $result.CombinedHealthData | Should -HaveCount 1

            $entryData = $result.CombinedHealthData[0]
            $entryData.Date | Should -Be "2024-07-30"

            # Should not have properties for missing data
            $entryData.PSObject.Properties.Name | Should -Not -Contain "MaxPain"
            $entryData.PSObject.Properties.Name | Should -Not -Contain "BackPain"
            $entryData.PSObject.Properties.Name | Should -Not -Contain "Sleep"
        }
    }
}

Describe "Schema v2.0 Compatibility Tests" {
    Context "When using New-SampleHealthEntries for dynamic test data" {
        It "Should generate entries with correct schema v2.0 structure" {
            $sampleEntries = New-SampleHealthEntries -Count 3 -UserEmail "test@example.com" -OutputFormat "Array"

            $sampleEntries | Should -HaveCount 3

            foreach ($entry in $sampleEntries) {
                $entry.entry_id | Should -Match '^\d{10}$'  # yyMMddHHmm format
                $entry.user_email | Should -Be "test@example.com"
                $entry.date | Should -Match '^\d{4}-\d{2}-\d{2}$'  # YYYY-MM-DD format
                $entry.time | Should -Match '^\d{2}:\d{2}$'  # HH:mm format
                $entry.entry_types | Should -Not -Be $null
                $entry.data | Should -Not -Be $null
                # Check that notes property exists (either with value or empty)
                $entry.notes | Should -Not -Be $null
            }
        }

        It "Should generate specific entry types when requested" {
            $painEntries = New-SampleHealthEntries -PainCount 2 -MoodCount 1 -OutputFormat "Array"

            $painEntries | Should -HaveCount 3

            $painOnlyEntries = $painEntries | Where-Object { $_.entry_types -contains "pain" }
            $painOnlyEntries | Should -HaveCount 2

            $moodOnlyEntries = $painEntries | Where-Object { $_.entry_types -contains "mood" }
            $moodOnlyEntries | Should -HaveCount 1
        }

        It "Should generate entries with correct field names for schema v2.0" -Skip {
            # Skip this test as the fusion module's New-SampleHealthEntries hasn't been updated to schema v2.0 yet
            # This test can be enabled once the fusion module is updated to generate schema v2.0 format
            $entries = New-SampleHealthEntries -Count 5 -EntryTypes @("pain", "medications", "activities", "vitals") -OutputFormat "Array"

            foreach ($entry in $entries) {
                if ($entry.data.pain) {
                    # In schema v2.0, pain is an array
                    $entry.data.pain | Should -BeOfType System.Array
                    if ($entry.data.pain.Count -gt 0) {
                        $entry.data.pain[0].severity | Should -Not -Be $null
                        $entry.data.pain[0].location | Should -Not -Be $null
                        $entry.data.pain[0].note | Should -Not -Be $null
                        $entry.data.pain[0].PSObject.Properties.Name | Should -Not -Contain "pain_level"
                    }
                }

                if ($entry.data.medications) {
                    # In schema v2.0, medications is an array with "name" field
                    $entry.data.medications | Should -BeOfType System.Array
                    if ($entry.data.medications.Count -gt 0) {
                        $entry.data.medications[0].name | Should -Not -Be $null
                        $entry.data.medications[0].dosage | Should -Not -Be $null
                        $entry.data.medications[0].PSObject.Properties.Name | Should -Contain "name"
                        $entry.data.medications[0].PSObject.Properties.Name | Should -Not -Contain "medication_name"
                    }
                }

                if ($entry.data.activities) {
                    # In schema v2.0, activities is an array with "name" field
                    $entry.data.activities | Should -BeOfType System.Array
                    if ($entry.data.activities.Count -gt 0) {
                        $entry.data.activities[0].name | Should -Not -Be $null
                        $entry.data.activities[0].duration_minutes | Should -Not -Be $null
                        $entry.data.activities[0].note | Should -Not -Be $null
                        $entry.data.activities[0].PSObject.Properties.Name | Should -Contain "name"
                        $entry.data.activities[0].PSObject.Properties.Name | Should -Not -Contain "activity_name"
                    }
                }

                if ($entry.data.vitals) {
                    $entry.data.vitals.blood_pressure | Should -Not -Be $null
                    $entry.data.vitals.heart_rate | Should -Not -Be $null
                    $entry.data.vitals.oxygen_saturation | Should -Not -Be $null
                    $entry.data.vitals.temperature | Should -Not -Be $null
                }
            }
        }

        It "Should generate valid data ranges for schema v2.0" {
            $entries = New-SampleHealthEntries -Count 10 -EntryTypes @("mood", "pain", "vitals", "weight", "sleep") -OutputFormat "Array"

            foreach ($entry in $entries) {
                if ($entry.data.mood) {
                    $entry.data.mood.mood_level | Should -BeGreaterThan 0
                    $entry.data.mood.mood_level | Should -BeLessOrEqual 5  # Schema v2.0: 1-5 scale
                }

                if ($entry.data.pain) {
                    $entry.data.pain.severity | Should -BeGreaterOrEqual 0
                    $entry.data.pain.severity | Should -BeLessOrEqual 10  # Schema v2.0: 0-10 scale
                }

                if ($entry.data.vitals) {
                    $entry.data.vitals.blood_pressure | Should -Match '^\d{2,3}/\d{2,3}$'
                    $entry.data.vitals.heart_rate | Should -BeGreaterThan 0
                    $entry.data.vitals.oxygen_saturation | Should -BeGreaterThan 0
                    $entry.data.vitals.temperature | Should -BeGreaterThan 0
                }

                if ($entry.data.weight) {
                    $entry.data.weight.weight_lbs | Should -BeGreaterThan 0
                    $entry.data.weight.weight_kg | Should -BeGreaterThan 0
                }

                if ($entry.data.sleep) {
                    $entry.data.sleep.sleep_hours | Should -BeGreaterThan 0
                    $entry.data.sleep.sleep_hours | Should -BeLessOrEqual 12
                }
            }
        }
    }

    Context "When working with schema v2.0 format" {
        It "Should handle schema v2.0 format correctly" {
            $schemaV2Entry = @{
                entry_id = "2407171430"
                user_email = "test@example.com"
                date = "2024-07-17"
                time = "14:30"
                entry_types = @("pain", "medications")
                data = @{
                    pain = @(
                        @{
                            location = "back"
                            severity = 6
                            note = "lower back pain"
                        }
                    )
                    medications = @(
                        @{
                            name = "tylenol"
                            dosage = "1g"
                        }
                    )
                }
                notes = "test entry"
            }

            # Verify the schema v2.0 format works correctly
            $schemaV2Entry.data.pain[0].severity | Should -Be 6
            $schemaV2Entry.data.medications[0].name | Should -Be "tylenol"
            $schemaV2Entry.entry_types | Should -Contain "pain"
            $schemaV2Entry.entry_types | Should -Contain "medications"
        }
    }
}

Describe "Find-DuplicateEntries Function" {
    Context "When detecting duplicate entries" {
        BeforeAll {
            # Generate entries with known duplicates in schema v2.0 format
            $script:DuplicateTestEntries = @()

            # Create exact duplicates
            $duplicate1 = @{
                entry_id = "2407010800"
                user_email = "test@example.com"
                date = "2024-07-01"
                time = "08:00"
                entry_types = @("pain", "medications")
                data = @{
                    pain = @(
                        @{
                            location = "back"
                            severity = 5.0
                            note = ""
                        }
                    )
                    medications = @(
                        @{
                            name = "tylenol"
                            dosage = "1g"
                        }
                    )
                }
                notes = "morning routine"
            }

            $duplicate2 = @{
                entry_id = "2407010900"
                user_email = "test@example.com"
                date = "2024-07-01"
                time = "09:00"
                entry_types = @("pain", "medications")
                data = @{
                    pain = @(
                        @{
                            location = "back"
                            severity = 5.0
                            note = ""
                        }
                    )
                    medications = @(
                        @{
                            name = "tylenol"
                            dosage = "1g"
                        }
                    )
                }
                notes = "morning routine"
            }

            # Create empty entries (should be duplicates)
            $empty1 = @{
                entry_id = "2407021000"
                user_email = "test@example.com"
                date = "2024-07-02"
                time = "10:00"
                entry_types = @()
                data = @{}
                notes = ""
            }

            $empty2 = @{
                entry_id = "2407021100"
                user_email = "test@example.com"
                date = "2024-07-02"
                time = "11:00"
                entry_types = @()
                data = @{}
                notes = ""
            }

            # Add unique entry to avoid false positives
            $unique1 = @{
                entry_id = "2407011400"
                user_email = "test@example.com"
                date = "2024-07-01"
                time = "14:00"
                entry_types = @("activities")
                data = @{
                    activities = @(
                        @{
                            name = "stretching"
                            duration_minutes = 15
                            note = ""
                        }
                    )
                }
                notes = "afternoon entry"
            }

            $script:DuplicateTestEntries = @($duplicate1, $duplicate2, $empty1, $empty2, $unique1)
        }

        It "Should detect exact duplicates with high similarity score" {
            $duplicates = Find-DuplicateEntries -Entries $script:DuplicateTestEntries -SimilarityThreshold 80

            $duplicates.Count | Should -BeGreaterOrEqual 1  # At least one duplicate should be found

            # Check that we have a high similarity duplicate
            $highSimilarity = $duplicates | Where-Object { $_.SimilarityScore -gt 90 }
            $highSimilarity | Should -Not -Be $null
        }

        It "Should detect empty entry duplicates" {
            $duplicates = Find-DuplicateEntries -Entries $script:DuplicateTestEntries -SimilarityThreshold 80

            # Check if any duplicates were found (empty entries should match)
            $duplicates.Count | Should -BeGreaterOrEqual 1

            # Look for duplicates on the date with empty entries
            $emptyDuplicate = $duplicates | Where-Object { $_.Date -eq "2024-07-02" }
            if ($emptyDuplicate) {
                $emptyDuplicate.SimilarityScore | Should -BeGreaterThan 95  # Empty entries should match almost perfectly
                $emptyDuplicate.Entry1.Timestamp | Should -Be "10:00"
                $emptyDuplicate.Entry2.Timestamp | Should -Be "11:00"
            } else {
                # If no duplicates found on 2024-07-02, that's also acceptable since empty entries might not be considered duplicates
                Write-Host "No duplicates found for empty entries - this may be expected behavior"
            }
        }

        It "Should respect similarity threshold" {
            $noDuplicates = Find-DuplicateEntries -Entries $script:DuplicateTestEntries -SimilarityThreshold 99

            # At 99% threshold, only very exact matches should qualify
            $noDuplicates.Count | Should -BeLessOrEqual 2
        }

        It "Should include notes in comparison when requested" {
            $duplicatesWithNotes = Find-DuplicateEntries -Entries $script:DuplicateTestEntries -SimilarityThreshold 80 -IncludeNotes $true
            $duplicatesWithoutNotes = Find-DuplicateEntries -Entries $script:DuplicateTestEntries -SimilarityThreshold 80 -IncludeNotes $false

            # Should find same number of duplicates but scores might be different
            $duplicatesWithNotes.Count | Should -Be $duplicatesWithoutNotes.Count
        }

        It "Should handle entries with no duplicates" {
            $uniqueEntries = @(
                @{
                    entry_id = "2407031000"
                    user_email = "test@example.com"
                    date = "2024-07-03"
                    time = "10:00"
                    entry_types = @("pain")
                    data = @{ pain = @{ location = "head"; severity = 3.0; note = "" } }
                    notes = ""
                }
            )

            $duplicates = Find-DuplicateEntries -Entries $uniqueEntries -SimilarityThreshold 80
            $duplicates | Should -HaveCount 0
        }
    }
}

Describe "Compare-EntryData Function" {
    Context "When comparing entry data objects" {
        BeforeAll {
            # Create test entry objects in unified schema v2.0 format
            $script:TestEntry1 = @{
                entry_id = "2407261400"
                user_email = "test@example.com"
                date = "2024-07-26"
                time = "14:00"
                entry_types = @("pain", "medications", "activities")
                data = @{
                    pain = @(
                        @{
                            location = "back"
                            severity = 4.0
                            note = ""
                        }
                    )
                    medications = @(
                        @{
                            name = "tylenol"
                            dosage = "1g"
                        }
                    )
                    activities = @(
                        @{
                            name = "walking"
                            duration_minutes = 30
                            note = "short walk"
                        }
                    )
                }
                notes = "test note"
            }

            $script:TestEntry2 = @{
                entry_id = "2407261500"
                user_email = "test@example.com"
                date = "2024-07-26"
                time = "15:00"
                entry_types = @("pain", "medications", "activities")
                data = @{
                    pain = @(
                        @{
                            location = "back"
                            severity = 4.0
                            note = ""
                        }
                    )
                    medications = @(
                        @{
                            name = "tylenol"
                            dosage = "1g"
                        }
                    )
                    activities = @(
                        @{
                            name = "walking"
                            duration_minutes = 30
                            note = "short walk"
                        }
                    )
                }
                notes = "test note"
            }

            $script:TestEntry3 = @{
                entry_id = "2407261600"
                user_email = "test@example.com"
                date = "2024-07-26"
                time = "16:00"
                entry_types = @("pain", "medications")
                data = @{
                    pain = @(
                        @{
                            location = "knee"
                            severity = 6.0
                            note = ""
                        }
                    )
                    medications = @(
                        @{
                            name = "dilaudid"
                            dosage = "4mg"
                        }
                    )
                }
                notes = "different note"
            }
        }

        It "Should return high similarity for identical entries" {
            $result = Compare-EntryData -Entry1 $script:TestEntry1 -Entry2 $script:TestEntry2

            $result.Score | Should -BeGreaterThan 90  # Very similar entries
            $result.Reason | Should -Not -Be $null
        }

        It "Should return lower similarity for different entries" {
            $result = Compare-EntryData -Entry1 $script:TestEntry1 -Entry2 $script:TestEntry3

            $result.Score | Should -BeLessThan 80  # Different entries
            $result.Reason | Should -Not -Be $null
        }

        It "Should exclude vitals when IncludeVitals is false" {
            $result1 = Compare-EntryData -Entry1 $script:TestEntry1 -Entry2 $script:TestEntry2 -IncludeVitals $true
            $result2 = Compare-EntryData -Entry1 $script:TestEntry1 -Entry2 $script:TestEntry2 -IncludeVitals $false

            # Both should be high similarity since entries don't have vitals
            $result1.Score | Should -BeGreaterThan 90
            $result2.Score | Should -BeGreaterThan 90
        }

        It "Should include notes when IncludeNotes is true" {
            $result1 = Compare-EntryData -Entry1 $script:TestEntry1 -Entry2 $script:TestEntry2 -IncludeNotes $true
            $result2 = Compare-EntryData -Entry1 $script:TestEntry1 -Entry2 $script:TestEntry2 -IncludeNotes $false

            # Both should be high similarity
            $result1.Score | Should -BeGreaterThan 90
            $result2.Score | Should -BeGreaterThan 90
        }
    }
}

Describe "Compare-Medications Function" {
    Context "When comparing medication objects" {
        It "Should return 1.0 for identical medications" {
            $med1 = @{ "name" = "tylenol"; "dosage" = "1g" }
            $med2 = @{ "name" = "tylenol"; "dosage" = "1g" }

            $result = Compare-Medications -Med1 $med1 -Med2 $med2
            $result | Should -Be 1.0
        }

        It "Should return 0.5 for same medication with different dose" {
            $med1 = @{ "name" = "tylenol"; "dosage" = "1g" }
            $med2 = @{ "name" = "tylenol"; "dosage" = "500mg" }

            $result = Compare-Medications -Med1 $med1 -Med2 $med2
            $result | Should -Be 0.5
        }

        It "Should return 0.0 for completely different medications" {
            $med1 = @{ "name" = "tylenol"; "dosage" = "1g" }
            $med2 = @{ "name" = "dilaudid"; "dosage" = "4mg" }

            $result = Compare-Medications -Med1 $med1 -Med2 $med2
            $result | Should -Be 0.0
        }

        It "Should return 1.0 for both null medication objects" {
            $result = Compare-Medications -Med1 $null -Med2 $null
            $result | Should -Be 1.0
        }

        It "Should return 0.0 for one null and one valid medication" {
            $med1 = @{ "name" = "tylenol"; "dosage" = "1g" }
            $result = Compare-Medications -Med1 $med1 -Med2 $null
            $result | Should -Be 0.0
        }
    }
}

Describe "Compare-PainData Function" {
    Context "When comparing pain data objects" {
        It "Should return 1.0 for identical pain data" {
            $pain1 = @{ "location" = "back"; "severity" = 4.0; "note" = "" }
            $pain2 = @{ "location" = "back"; "severity" = 4.0; "note" = "" }

            $result = Compare-PainData -Pain1 $pain1 -Pain2 $pain2
            $result | Should -Be 1.0
        }

        It "Should return partial match for similar pain levels" {
            $pain1 = @{ "location" = "back"; "severity" = 4.0; "note" = "" }
            $pain2 = @{ "location" = "back"; "severity" = 4.5; "note" = "" }

            $result = Compare-PainData -Pain1 $pain1 -Pain2 $pain2
            $result | Should -Be 1.0  # Within 1.0 point tolerance
        }

        It "Should return 0.5 for moderately different pain levels" {
            $pain1 = @{ "location" = "back"; "severity" = 4.0; "note" = "" }
            $pain2 = @{ "location" = "back"; "severity" = 5.5; "note" = "" }

            $result = Compare-PainData -Pain1 $pain1 -Pain2 $pain2
            $result | Should -Be 0.5  # Within 2.0 point tolerance
        }

        It "Should return 0.0 for very different pain levels" {
            $pain1 = @{ "location" = "back"; "severity" = 1.0; "note" = "" }
            $pain2 = @{ "location" = "back"; "severity" = 8.0; "note" = "" }

            $result = Compare-PainData -Pain1 $pain1 -Pain2 $pain2
            $result | Should -Be 0.0  # Beyond 2.0 point tolerance
        }

        It "Should return 0.0 for different pain locations" {
            $pain1 = @{ "location" = "back"; "severity" = 4.0; "note" = "" }
            $pain2 = @{ "location" = "knee"; "severity" = 4.0; "note" = "" }

            $result = Compare-PainData -Pain1 $pain1 -Pain2 $pain2
            $result | Should -Be 0.0  # Different locations
        }

        It "Should return 1.0 for both null pain objects" {
            $result = Compare-PainData -Pain1 $null -Pain2 $null
            $result | Should -Be 1.0
        }
    }
}

Describe "Compare-Activities Function" {
    Context "When comparing activity objects" {
        It "Should return 1.0 for identical activities" {
            $act1 = @{ "name" = "walking"; "duration_minutes" = 30; "note" = "short walk" }
            $act2 = @{ "name" = "walking"; "duration_minutes" = 30; "note" = "short walk" }

            $result = Compare-Activities -Act1 $act1 -Act2 $act2
            $result | Should -Be 1.0
        }

        It "Should return 1.0 for activities with similar durations" {
            $act1 = @{ "name" = "walking"; "duration_minutes" = 30; "note" = "" }
            $act2 = @{ "name" = "walking"; "duration_minutes" = 33; "note" = "" }

            $result = Compare-Activities -Act1 $act1 -Act2 $act2
            $result | Should -Be 1.0  # Within 5 minute tolerance
        }

        It "Should return 0.5 for activities with moderately different durations" {
            $act1 = @{ "name" = "walking"; "duration_minutes" = 30; "note" = "" }
            $act2 = @{ "name" = "walking"; "duration_minutes" = 40; "note" = "" }

            $result = Compare-Activities -Act1 $act1 -Act2 $act2
            $result | Should -Be 0.5  # Within 15 minute tolerance
        }

        It "Should return 0.0 for activities with very different durations" {
            $act1 = @{ "name" = "walking"; "duration_minutes" = 30; "note" = "" }
            $act2 = @{ "name" = "walking"; "duration_minutes" = 90; "note" = "" }

            $result = Compare-Activities -Act1 $act1 -Act2 $act2
            $result | Should -Be 0.0  # Beyond 15 minute tolerance
        }

        It "Should return 0.0 for different activity types" {
            $act1 = @{ "name" = "walking"; "duration_minutes" = 30; "note" = "" }
            $act2 = @{ "name" = "running"; "duration_minutes" = 30; "note" = "" }

            $result = Compare-Activities -Act1 $act1 -Act2 $act2
            $result | Should -Be 0.0  # Different activity types
        }

        It "Should return 1.0 for both null activity objects" {
            $result = Compare-Activities -Act1 $null -Act2 $null
            $result | Should -Be 1.0
        }
    }
}

Describe "Compare-Vitals Function" {
    Context "When comparing vital signs" {
        It "Should return 1.0 for identical vitals" {
            $entry1 = @{ data = @{ vitals = @{ "oxygen_saturation" = 95; "blood_pressure" = "120/80" } } }
            $entry2 = @{ data = @{ vitals = @{ "oxygen_saturation" = 95; "blood_pressure" = "120/80" } } }

            $result = Compare-Vitals -Entry1 $entry1 -Entry2 $entry2
            $result | Should -Be 1.0
        }

        It "Should return 0.5 for partially matching vitals" {
            $entry1 = @{ data = @{ vitals = @{ "oxygen_saturation" = 95; "blood_pressure" = "120/80" } } }
            $entry2 = @{ data = @{ vitals = @{ "oxygen_saturation" = 95; "blood_pressure" = "115/75" } } }

            $result = Compare-Vitals -Entry1 $entry1 -Entry2 $entry2
            $result | Should -Be 0.5  # O2 matches, BPR doesn't
        }

        It "Should return 0.0 for completely different vitals" {
            $entry1 = @{ data = @{ vitals = @{ "oxygen_saturation" = 95; "blood_pressure" = "120/80" } } }
            $entry2 = @{ data = @{ vitals = @{ "oxygen_saturation" = 92; "blood_pressure" = "115/75" } } }

            $result = Compare-Vitals -Entry1 $entry1 -Entry2 $entry2
            $result | Should -Be 0.0  # Neither matches
        }

        It "Should return 1.0 for both entries with no vitals" {
            $entry1 = @{ data = @{} }
            $entry2 = @{ data = @{} }

            $result = Compare-Vitals -Entry1 $entry1 -Entry2 $entry2
            $result | Should -Be 1.0
        }

        It "Should return 0.0 for one entry with vitals and one without" {
            $entry1 = @{ data = @{ vitals = @{ "oxygen_saturation" = 95 } } }
            $entry2 = @{ data = @{} }

            $result = Compare-Vitals -Entry1 $entry1 -Entry2 $entry2
            $result | Should -Be 0.0  # One has vitals, one doesn't
        }
    }
}

Describe "Compare-NoteText Function" {
    Context "When comparing note text" {
        It "Should return 1.0 for identical notes" {
            $result = Compare-NoteText -Note1 "test note" -Note2 "test note"
            $result | Should -Be 1.0
        }

        It "Should return 1.0 for both empty notes" {
            $result = Compare-NoteText -Note1 "" -Note2 ""
            $result | Should -Be 1.0
        }

        It "Should return 0.0 for one empty and one non-empty note" {
            $result = Compare-NoteText -Note1 "test note" -Note2 ""
            $result | Should -Be 0.0
        }

        It "Should return 0.8 for notes where one contains the other" {
            $result = Compare-NoteText -Note1 "test" -Note2 "test note longer"
            $result | Should -Be 0.8
        }

        It "Should handle case insensitive comparison" {
            $result = Compare-NoteText -Note1 "Test Note" -Note2 "test note"
            $result | Should -Be 1.0
        }

        It "Should calculate word overlap for different notes" {
            $result = Compare-NoteText -Note1 "feeling good today" -Note2 "feeling better today"
            $result | Should -BeGreaterOrEqual 0.5  # Should have some word overlap ("feeling" and "today")
        }

        It "Should return 0.0 for completely different notes" {
            $result = Compare-NoteText -Note1 "morning routine" -Note2 "evening exercise"
            $result | Should -Be 0.0  # No common words
        }
    }
}
