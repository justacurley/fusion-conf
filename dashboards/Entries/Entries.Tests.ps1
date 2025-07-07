BeforeAll {
    # Import required modules
    Import-Module -Name "$PSScriptRoot/../../Modules/GetFusion/GetFusion.psm1" -Force
    Import-Module -Name "$PSScriptRoot/../../Modules/fusion/fusion.psm1" -Force
    
    # Load mock form data
    . "$PSScriptRoot/MockFormData.ps1"
    
    # Create a test entries file path
    $script:TestEntriesPath = Join-Path $TestDrive "test_entries.json"
    
    # Initialize with empty entries structure
    $script:InitialEntries = @{}
    $script:InitialEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:TestEntriesPath -Encoding UTF8
    
    # Mock the entries file path for the fusion module functions
    $script:OriginalEntriesPath = $null
    if (Get-Variable -Name "EntriesFilePath" -Scope Global -ErrorAction SilentlyContinue) {
        $script:OriginalEntriesPath = $Global:EntriesFilePath
    }
    $Global:EntriesFilePath = $script:TestEntriesPath
}

AfterAll {
    # Restore original entries path if it existed
    if ($script:OriginalEntriesPath) {
        $Global:EntriesFilePath = $script:OriginalEntriesPath
    } else {
        Remove-Variable -Name "EntriesFilePath" -Scope Global -ErrorAction SilentlyContinue
    }
}

Describe "Entries.ps1 Form Submission Workflow" {
    
    Context "When processing form data with ConvertTo-EntriesFormat" {
        BeforeEach {
            # Reset the test entries file
            $script:InitialEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:TestEntriesPath -Encoding UTF8
        }
        
        It "Should process complete form data correctly" {
            # Arrange
            $formData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Complete
            
            # Act
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Assert
            $convertedEntry | Should -Not -Be $null
            $convertedEntry.FullEntry.Keys | Should -Contain "0630"
            
            # Check the timestamp entry exists
            $dateEntry = $convertedEntry.FullEntry["0630"]
            $dateEntry.Keys | Should -Contain "1430"
            
            # Check medications were processed
            $timestampEntry = $dateEntry["1430"]
            $timestampEntry.Medications.Keys | Should -Contain "dilaudid"
            $timestampEntry.Medications["dilaudid"] | Should -Be "4mg"
            $timestampEntry.Medications.Keys | Should -Contain "tylenol"
            $timestampEntry.Medications["tylenol"] | Should -Be "1g"
            $timestampEntry.Medications.Keys | Should -Contain "vitaminD"
            $timestampEntry.Medications["vitaminD"] | Should -Be "500mg"
            
            # Check activities were processed
            $timestampEntry.Activities.Keys | Should -Contain "Walking"
            $timestampEntry.Activities["Walking"].duration | Should -Be 30
            $timestampEntry.Activities["Walking"].note | Should -Be "Morning walk around the neighborhood"
            
            $timestampEntry.Activities.Keys | Should -Contain "Stretching"
            $timestampEntry.Activities["Stretching"].duration | Should -Be 15
            
            # Check pain data was processed
            $timestampEntry.Pain.Keys | Should -Contain "back"
            $timestampEntry.Pain["back"].pain_level | Should -Be 4.0
            $timestampEntry.Pain["back"].note | Should -Be "Lower back stiffness in morning"
            
            $timestampEntry.Pain.Keys | Should -Contain "right_glute"
            $timestampEntry.Pain["right_glute"].pain_level | Should -Be 3.0
            
            # Check vitals were processed
            $timestampEntry.o2 | Should -Be "96"
            $timestampEntry.bpr | Should -Be "118/76"
            
            # Check notes and sleep
            $timestampEntry.note | Should -Be "Feeling much better today after starting new medication routine"
            $dateEntry.Sleep | Should -Be "7:45"
        }
        
        It "Should process minimal form data correctly" {
            # Arrange
            $formData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Minimal
            
            # Act
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Assert
            $convertedEntry | Should -Not -Be $null
            $convertedEntry.FullEntry.Keys | Should -Contain "0629"
            
            $dateEntry = $convertedEntry.FullEntry["0629"]
            $dateEntry.Keys | Should -Contain "0800"
            
            $timestampEntry = $dateEntry["0800"]
            # Should have empty/default structures
            $timestampEntry.Medications.Keys.Count | Should -Be 0
            $timestampEntry.Activities.Keys.Count | Should -Be 0
            $timestampEntry.Pain.Keys.Count | Should -Be 0
            $timestampEntry.note | Should -Be ""
            $timestampEntry.o2 | Should -Be ""
            $timestampEntry.bpr | Should -Be ""
        }
        
        It "Should process medications-only entry correctly" {
            # Arrange
            $formData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_MedicationsOnly
            
            # Act
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Assert
            $convertedEntry | Should -Not -Be $null
            $dateEntry = $convertedEntry.FullEntry["0628"]
            $timestampEntry = $dateEntry["2200"]
            
            # Check medications
            $timestampEntry.Medications.Keys | Should -Contain "dilaudid"
            $timestampEntry.Medications["dilaudid"] | Should -Be "4mg"
            $timestampEntry.Medications.Keys | Should -Contain "valium"
            $timestampEntry.Medications["valium"] | Should -Be "5mg"
            $timestampEntry.Medications.Keys | Should -Contain "lexapro"
            $timestampEntry.Medications["lexapro"] | Should -Be "10mg"
            
            # Should have empty activities and pain
            $timestampEntry.Activities.Keys.Count | Should -Be 0
            $timestampEntry.Pain.Keys.Count | Should -Be 0
            
            # Check sleep was processed
            $dateEntry.Sleep | Should -Be "8:30"
        }
        
        It "Should process multiple activities and pain entries correctly" {
            # Arrange
            $formData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_MultipleEntries
            
            # Act
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Assert
            $convertedEntry | Should -Not -Be $null
            $dateEntry = $convertedEntry.FullEntry["0627"]
            $timestampEntry = $dateEntry["1645"]
            
            # Check multiple activities
            $timestampEntry.Activities.Keys | Should -Contain "Physical Therapy"
            $timestampEntry.Activities["Physical Therapy"].duration | Should -Be 60
            $timestampEntry.Activities["Physical Therapy"].note | Should -Be "Focused on core strengthening"
            
            $timestampEntry.Activities.Keys | Should -Contain "Swimming"
            $timestampEntry.Activities["Swimming"].duration | Should -Be 45
            
            $timestampEntry.Activities.Keys | Should -Contain "Walking"
            $timestampEntry.Activities["Walking"].duration | Should -Be 20
            
            # Check multiple pain entries
            $timestampEntry.Pain.Keys | Should -Contain "back"
            $timestampEntry.Pain["back"].pain_level | Should -Be 6.0
            
            $timestampEntry.Pain.Keys | Should -Contain "left_glute"
            $timestampEntry.Pain["left_glute"].pain_level | Should -Be 4.0
            
            $timestampEntry.Pain.Keys | Should -Contain "hips"
            $timestampEntry.Pain["hips"].pain_level | Should -Be 3.0
        }
        
        It "Should handle edge cases appropriately" {
            # Arrange
            $formData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_EdgeCases
            
            # Act
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Assert
            $convertedEntry | Should -Not -Be $null
            $dateEntry = $convertedEntry.FullEntry["0626"]
            $timestampEntry = $dateEntry["2359"]
            
            # Check high pain level
            $timestampEntry.Pain["back"].pain_level | Should -Be 8.0
            
            # Check long activity duration
            $timestampEntry.Activities["Meditation"].duration | Should -Be 120
            
            # Check unusual vitals
            $timestampEntry.o2 | Should -Be "89"
            $timestampEntry.bpr | Should -Be "140/95"
            
            # Check decimal sleep format
            $dateEntry.Sleep | Should -Be "4.25"
        }
    }
    
    Context "When saving converted entries with Save-ConvertedEntry" {
        BeforeEach {
            # Reset the test entries file
            $script:InitialEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:TestEntriesPath -Encoding UTF8
        }
        
        It "Should save a new entry successfully" {
            # Arrange
            $formData = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Complete
            $convertedEntry = ConvertTo-EntriesFormat -Entry $formData
            
            # Act
            $result = Save-ConvertedEntry -ConvertedEntry $convertedEntry -EntriesPath $script:TestEntriesPath
            
            # Assert
            $result | Should -Be $true
            
            # Verify the file was updated
            $savedEntries = Get-Content -Path $script:TestEntriesPath | ConvertFrom-Json
            $savedEntries.PSObject.Properties.Name | Should -Contain "0630"
            $savedEntries."0630".PSObject.Properties.Name | Should -Contain "1430"
        }
        
        It "Should merge with existing entries" {
            # Arrange
            # First, save an entry
            $formData1 = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Complete
            $convertedEntry1 = ConvertTo-EntriesFormat -Entry $formData1
            Save-ConvertedEntry -ConvertedEntry $convertedEntry1 -EntriesPath $script:TestEntriesPath | Should -Be $true
            
            # Then save a different entry for the same date
            $formData2 = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Minimal
            $convertedEntry2 = ConvertTo-EntriesFormat -Entry $formData2
            
            # Act
            $result = Save-ConvertedEntry -ConvertedEntry $convertedEntry2 -EntriesPath $script:TestEntriesPath
            
            # Assert
            $result | Should -Be $true
            
            # Verify both entries exist
            $savedEntries = Get-Content -Path $script:TestEntriesPath | ConvertFrom-Json
            $savedEntries.PSObject.Properties.Name | Should -Contain "0630"
            $savedEntries.PSObject.Properties.Name | Should -Contain "0629"
            
            # Verify the 0630 entry still has its original data
            $savedEntries."0630".PSObject.Properties.Name | Should -Contain "1430"
            $savedEntries."0630"."1430".Medications.PSObject.Properties.Name | Should -Contain "dilaudid"
        }
        
        It "Should handle multiple timestamps for the same date" {
            # Arrange
            $formData1 = ConvertTo-ProcessedFormData -MockFormData $script:MockFormData_Complete
            $convertedEntry1 = ConvertTo-EntriesFormat -Entry $formData1
            Save-ConvertedEntry -ConvertedEntry $convertedEntry1 -EntriesPath $script:TestEntriesPath | Should -Be $true
            
            # Create a second entry for the same date but different time
            $formData2 = $script:MockFormData_Complete.PSObject.Copy()
            $formData2.timestamp = "09:15"
            $formData2.notes = "Second entry for the day"
            $processedData2 = ConvertTo-ProcessedFormData -MockFormData $formData2
            $convertedEntry2 = ConvertTo-EntriesFormat -Entry $processedData2
            
            # Act
            $result = Save-ConvertedEntry -ConvertedEntry $convertedEntry2 -EntriesPath $script:TestEntriesPath
            
            # Assert
            $result | Should -Be $true
            
            # Verify both timestamps exist for the same date
            $savedEntries = Get-Content -Path $script:TestEntriesPath | ConvertFrom-Json
            $savedEntries."0630".PSObject.Properties.Name | Should -Contain "1430"
            $savedEntries."0630".PSObject.Properties.Name | Should -Contain "0915"
            
            # Verify different notes
            $savedEntries."0630"."1430".note | Should -Be "Feeling much better today after starting new medication routine"
            $savedEntries."0630"."0915".note | Should -Be "Second entry for the day"
        }
    }
    
    Context "When processing form data end-to-end" {
        BeforeEach {
            # Reset the test entries file
            $script:InitialEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:TestEntriesPath -Encoding UTF8
        }
        
        It "Should complete the full workflow successfully" {
            # Arrange - Simulate the exact workflow from Entries.ps1
            $FormEvent = $script:MockFormData_Complete.PSObject.Copy()
            
            # Act - Apply the same transformations as in Entries.ps1
            $FormEvent.timestamp = [datetime]::Parse($FormEvent.timestamp).ToString("HHmm")
            $FormEvent.date = [datetime]::Parse($FormEvent.date).ToString("MMdd")
            
            $entry = ConvertTo-EntriesFormat -Entry ($FormEvent | ConvertTo-Json -Depth 99 | ConvertFrom-Json)
            $saveResult = Save-ConvertedEntry -ConvertedEntry $entry -EntriesPath $script:TestEntriesPath
            
            # Assert
            $saveResult | Should -Be $true
            
            # Verify the data can be read back using GetFusion functions
            $entries = Get-EntriesData -entriesPath $script:TestEntriesPath
            $healthMetrics = Get-HealthMetrics -Entries $entries -DataPoints @('Medications', 'Activities', 'Vitals')
            
            $healthMetrics.Medications | Should -Not -Be $null
            $healthMetrics.Activities | Should -Not -Be $null
            $healthMetrics.Vitals | Should -Not -Be $null
            
            # Check specific data integrity
            $medications = $healthMetrics.Medications | Where-Object { $_.Date -eq "06/30" }
            $medications | Should -Not -Be $null
            ($medications | Where-Object { $_.Medication -eq "dilaudid" }).Dose | Should -Be "4mg"
            
            $activities = $healthMetrics.Activities | Where-Object { $_.Date -eq "06/30" }
            $activities | Should -Not -Be $null
            ($activities | Where-Object { $_.Activity -eq "Walking" }).Duration | Should -Be "30"
            
            $vitals = $healthMetrics.Vitals | Where-Object { $_.Date -eq "06/30" }
            $vitals | Should -Not -Be $null
            ($vitals | Where-Object { $_.VitalType -eq "Oxygen Level" }).Vital | Should -Be "96"
        }
        
        It "Should handle errors gracefully" {
            # Arrange - Create invalid form data
            $invalidFormData = [PSCustomObject]@{
                date = "invalid-date"
                timestamp = "invalid-time"
            }
            
            # Act & Assert
            { 
                $invalidFormData.timestamp = [datetime]::Parse($invalidFormData.timestamp).ToString("HHmm")
                $invalidFormData.date = [datetime]::Parse($invalidFormData.date).ToString("MMdd")
            } | Should -Throw
        }
    }
    
    Context "When validating form data processing" {
        It "Should preserve medication names correctly" {
            # Test that medication IDs are properly converted to names and dosages
            $testData = [PSCustomObject]@{
                date = "2025-06-30"
                timestamp = "14:30"
                med_dilaudid_4mg = $true
                med_tylenol_1g = $true
                med_vitaminD_500mg = $true
                med_lexapro_10mg = $false
            }
            
            $processedData = ConvertTo-ProcessedFormData -MockFormData $testData
            $convertedEntry = ConvertTo-EntriesFormat -Entry $processedData
            
            $medications = $convertedEntry.FullEntry["0630"]["1430"].Medications
            $medications.Keys | Should -Contain "dilaudid"
            $medications.Keys | Should -Contain "tylenol"
            $medications.Keys | Should -Contain "vitaminD"
            $medications.Keys | Should -Not -Contain "lexapro"
        }
        
        It "Should handle sleep format variations correctly" {
            # Test different sleep formats
            $testCases = @(
                @{ Input = "7:45"; Expected = "7:45" }
                @{ Input = "8.5"; Expected = "8.5" }
                @{ Input = "9:00"; Expected = "9:00" }
                @{ Input = ""; Expected = $null }
            )
            
            foreach ($testCase in $testCases) {
                $testData = [PSCustomObject]@{
                    date = "2025-06-30"
                    timestamp = "14:30"
                    sleep = $testCase.Input
                }
                
                $processedData = ConvertTo-ProcessedFormData -MockFormData $testData
                $convertedEntry = ConvertTo-EntriesFormat -Entry $processedData
                
                if ($testCase.Expected) {
                    $convertedEntry.FullEntry["0630"].Sleep | Should -Be $testCase.Expected
                } else {
                    $convertedEntry.FullEntry["0630"].Keys | Should -Not -Contain "Sleep"
                }
            }
        }
    }
}
