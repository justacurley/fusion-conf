BeforeAll {
    # Import the module under test
    Import-Module -Name "$PSScriptRoot/../GetFusion.psm1" -Force
    
    # Create a mock entries.json file for testing
    $script:TestEntriesPath = Join-Path $TestDrive "test_entries.json"
    
    # Mock data based on real entries.json structure
    $script:MockEntries = @{
        "0626" = @{
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
        "0625" = @{
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
        "0624" = @{
            "max_pain_level" = 3.0
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
    }
    
    # Convert to JSON and save to test file
    $script:MockEntries | ConvertTo-Json -Depth 10 | Out-File $script:TestEntriesPath -Encoding UTF8
    
    # Load mock entries as PSCustomObject for testing
    $script:TestEntries = Get-Content $script:TestEntriesPath | ConvertFrom-Json
}

AfterAll {
    # Clean up
    Remove-Module GetFusion -Force -ErrorAction SilentlyContinue
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
            $dateEntry = $script:TestEntries."0626"
            $result = Get-AverageBackPain -dateEntry $dateEntry
            $result | Should -Be 3.8  # (4.5 + 3.0) / 2 = 3.75, rounded to 3.8
        }
        
        It "Should calculate average back pain for a date with single entry" {
            $dateEntry = $script:TestEntries."0625"
            $result = Get-AverageBackPain -dateEntry $dateEntry
            $result | Should -Be 5.8  # (6.0 + 5.5) / 2 = 5.75, rounded to 5.8
        }
        
        It "Should return null when no back pain data exists" {
            $dateEntry = $script:TestEntries."0624"
            $result = Get-AverageBackPain -dateEntry $dateEntry
            $result | Should -Be $null
        }
    }
}

Describe "Get-TotalActivityDuration Function" {
    Context "When calculating total activity duration" {
        It "Should calculate total duration for date with single activity" {
            $dateEntry = $script:TestEntries."0626"
            $result = Get-TotalActivityDuration -dateEntry $dateEntry
            $result | Should -Be 45  # 30 (walking) + 15 (stretching)
        }
        
        It "Should calculate total duration for date with multiple activities" {
            $dateEntry = $script:TestEntries."0625"
            $result = Get-TotalActivityDuration -dateEntry $dateEntry
            $result | Should -Be 50  # 45 (walking) + 5 (stairs)
        }
        
        It "Should return null when no activities exist" {
            $dateEntry = $script:TestEntries."0624"
            $result = Get-TotalActivityDuration -dateEntry $dateEntry
            $result | Should -Be $null
        }
    }
}

Describe "Convert-DateToDisplay Function" {
    Context "When converting date formats" {
        It "Should convert MMDD format to MM/DD" {
            $result = Convert-DateToDisplay -date "0626"
            $result | Should -Be "06/26"
        }
        
        It "Should convert different MMDD format" {
            $result = Convert-DateToDisplay -date "1231"
            $result | Should -Be "12/31"
        }
        
        It "Should return original string for non-4-digit input" {
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
            $result."0626" | Should -Not -Be $null
            $result."0626".max_pain_level | Should -Be 4.5
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
            $result = Get-DatesList -entries $script:TestEntries
            $result | Should -HaveCount 3
            $result[0] | Should -Be "0624"
            $result[1] | Should -Be "0625"
            $result[2] | Should -Be "0626"
        }
        
        It "Should cache dates list for performance" {
            $result1 = Get-DatesList -entries $script:TestEntries
            $result2 = Get-DatesList -entries $script:TestEntries
            $result1 | Should -Be $result2
        }
    }
}

Describe "Get-DateMedicationData Function" {
    Context "When extracting medication data" {
        It "Should extract all medications for a date" {
            $medications = Get-DateMedicationData -date "0626" -dateEntry $script:TestEntries."0626"
            $medications | Should -HaveCount 2
            
            $dilaudidEntry = $medications | Where-Object { $_.Medication -eq "dilaudid" }
            $dilaudidEntry | Should -Not -Be $null
            $dilaudidEntry.Dose | Should -Be "4mg"
            $dilaudidEntry.Date | Should -Be "06/26"
            $dilaudidEntry.Timestamp | Should -Be "0900"
            
            $tylenolEntry = $medications | Where-Object { $_.Medication -eq "tylenol" }
            $tylenolEntry | Should -Not -Be $null
            $tylenolEntry.Dose | Should -Be "1g"
        }
        
        It "Should return empty array when no medications exist" {
            $medications = Get-DateMedicationData -date "0624" -dateEntry $script:TestEntries."0624"
            $medications | Should -HaveCount 0
        }
    }
}

Describe "Get-DateActivityData Function" {
    Context "When extracting activity data" {
        It "Should extract all activities for a date with multiple activities" {
            $activities = Get-DateActivityData -date "0625" -dateEntry $script:TestEntries."0625"
            $activities | Should -HaveCount 2
            
            $walkingEntry = $activities | Where-Object { $_.Activity -eq "walking" }
            $walkingEntry | Should -Not -Be $null
            $walkingEntry.Duration | Should -Be 45
            $walkingEntry.Note | Should -Be "longer walk today"
            $walkingEntry.Date | Should -Be "06/25"
            
            $stairsEntry = $activities | Where-Object { $_.Activity -eq "stairs" }
            $stairsEntry | Should -Not -Be $null
            $stairsEntry.Duration | Should -Be 5
        }
        
        It "Should extract activities for a date with single activity" {
            $activities = Get-DateActivityData -date "0626" -dateEntry $script:TestEntries."0626"
            $activities | Should -HaveCount 2  # walking and stretching
            
            $walkingEntry = $activities | Where-Object { $_.Activity -eq "walking" }
            $walkingEntry.Duration | Should -Be 30
            $walkingEntry.Note | Should -Be "short walk"
        }
        
        It "Should return empty array when no activities exist" {
            $activities = Get-DateActivityData -date "0624" -dateEntry $script:TestEntries."0624"
            $activities | Should -HaveCount 0
        }
    }
}

Describe "Get-DateVitalsData Function" {
    Context "When extracting vitals data" {
        It "Should extract blood pressure and oxygen data" {
            $vitals = Get-DateVitalsData -date "0626" -dateEntry $script:TestEntries."0626"
            $vitals | Should -HaveCount 4  # 2 bpr entries and 2 o2 entries
            
            $bprEntries = $vitals | Where-Object { $_.VitalType -eq "Blood Pressure" }
            $bprEntries | Should -HaveCount 2
            # Check that we have the expected blood pressure readings (order may vary)
            $bprValues = $bprEntries | ForEach-Object { $_.Vital }
            $bprValues | Should -Contain "126/81"
            $bprValues | Should -Contain "120/80"
            
            $o2Entries = $vitals | Where-Object { $_.VitalType -eq "Oxygen Level" }
            $o2Entries | Should -HaveCount 2
            # Check that we have the expected oxygen readings
            $o2Values = $o2Entries | ForEach-Object { $_.Vital }
            $o2Values | Should -Contain "93"
            $o2Values | Should -Contain "95"
        }
        
        It "Should handle entries with missing vitals data" {
            $vitals = Get-DateVitalsData -date "0624" -dateEntry $script:TestEntries."0624"
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
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('MaxPain')
            $result.CombinedHealthData | Should -HaveCount 3
            
            $june26Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/26" }
            $june26Entry.MaxPain | Should -Be 4.5
            
            $june25Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/25" }
            $june25Entry.MaxPain | Should -Be 6.0
        }
        
        It "Should extract BackPain data" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('BackPain')
            $result.CombinedHealthData | Should -HaveCount 3
            
            $june26Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/26" }
            $june26Entry.BackPain | Should -Be 3.8
            
            $june25Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/25" }
            $june25Entry.BackPain | Should -Be 5.8
        }
        
        It "Should extract Sleep data" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('Sleep')
            $result.CombinedHealthData | Should -HaveCount 3
            
            $june26Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/26" }
            $june26Entry.Sleep | Should -Be 7.42
            
            $june25Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/25" }
            $june25Entry.Sleep | Should -Be 6.22
        }
        
        It "Should extract ActivityDuration data" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('ActivityDuration')
            $result.CombinedHealthData | Should -HaveCount 3
            
            $june26Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/26" }
            $june26Entry.ActivityDuration | Should -Be 45
            
            $june25Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/25" }
            $june25Entry.ActivityDuration | Should -Be 50
        }
        
        It "Should extract Medications data" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('Medications')
            $result.Medications | Should -HaveCount 4  # 2 from 0626, 2 from 0625
            
            $dilaudidEntries = $result.Medications | Where-Object { $_.Medication -eq "dilaudid" }
            $dilaudidEntries | Should -HaveCount 2
        }
        
        It "Should extract Activities data" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('Activities')
            $result.Activities | Should -HaveCount 4  # 2 from 0626, 2 from 0625
            
            $walkingEntries = $result.Activities | Where-Object { $_.Activity -eq "walking" }
            $walkingEntries | Should -HaveCount 2
        }
        
        It "Should extract Vitals data" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('Vitals')
            # Total vitals: 0625 has 4 (2 bpr + 2 o2), 0626 has 4 (2 bpr + 2 o2) = 8 total
            $result.Vitals | Should -HaveCount 8
            
            $bprEntries = $result.Vitals | Where-Object { $_.VitalType -eq "Blood Pressure" }
            $bprEntries | Should -HaveCount 4
        }
        
        It "Should extract multiple data points in single call" {
            $result = Get-HealthMetrics -Entries $script:TestEntries -DataPoints @('MaxPain', 'Sleep', 'Medications')
            
            # Should have combined health data
            $result.CombinedHealthData | Should -HaveCount 3
            $june26Entry = $result.CombinedHealthData | Where-Object { $_.Date -eq "06/26" }
            $june26Entry.MaxPain | Should -Be 4.5
            $june26Entry.Sleep | Should -Be 7.42
            
            # Should have medications data
            $result.Medications | Should -HaveCount 4
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
            
            # Sort combined health data by date
            $sortedData = Sort-HealthDataByDate -healthData $healthMetrics.CombinedHealthData
            $sortedData[0].Date | Should -Be "06/24"
            $sortedData[-1].Date | Should -Be "06/26"
            
            # Verify data integrity
            $june26Data = $sortedData | Where-Object { $_.Date -eq "06/26" }
            $june26Data.MaxPain | Should -Be 4.5
            $june26Data.BackPain | Should -Be 3.8
            $june26Data.Sleep | Should -Be 7.42
            $june26Data.ActivityDuration | Should -Be 45
        }
        
        It "Should handle data with missing fields gracefully" {
            # Create entries with missing data
            $sparseEntries = [PSCustomObject]@{
                "0630" = @{
                    "1200" = @{
                        "note" = "minimal entry"
                        "bpr" = ""
                        "Activities" = @{}
                        "Medications" = @{}
                        "o2" = ""
                        "Pain" = @{}
                    }
                }
            }
            
            $result = Get-HealthMetrics -Entries $sparseEntries -DataPoints @('MaxPain', 'BackPain', 'Sleep')
            $result.CombinedHealthData | Should -HaveCount 1
            
            $entryData = $result.CombinedHealthData[0]
            $entryData.Date | Should -Be "06/30"
            
            # Should not have properties for missing data
            $entryData.PSObject.Properties.Name | Should -Not -Contain "MaxPain"
            $entryData.PSObject.Properties.Name | Should -Not -Contain "BackPain"
            $entryData.PSObject.Properties.Name | Should -Not -Contain "Sleep"
        }
    }
}
