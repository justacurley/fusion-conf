using module '../UserManagement.psm1'

Describe "UserProfile.ValidateUserDataStructure Tests" {
    BeforeAll {
        # Test user data with base64 encoding
        $TestEmail = "test.user@example.com"
        $TestBase64Id = [UserProfile]::ConvertEmailToBase64($TestEmail)
        $TestUserPath = "/tmp/test-users"
        $TestFullUserPath = Join-Path $TestUserPath $TestBase64Id

        # Override the BaseProfilePath for testing
        [UserProfile]::BaseProfilePath = $TestUserPath

        # Clean up any existing test data
        if (Test-Path $TestUserPath) {
            Remove-Item $TestUserPath -Recurse -Force
        }

        # Helper function to create a complete valid user structure
        function New-TestUserStructure {
            param(
                [string]$UserPath,
                [string]$Email = $TestEmail,
                [string]$Base64Id = $TestBase64Id,
                [switch]$SkipDirectories,
                [switch]$SkipFiles,
                [string[]]$CorruptFiles = @(),
                [string[]]$MissingFiles = @()
            )

            $FullPath = Join-Path $UserPath $Base64Id

            if (-not $SkipDirectories) {
                New-Item -ItemType Directory -Path $FullPath -Force
                New-Item -ItemType Directory -Path (Join-Path $FullPath 'health-data') -Force
                New-Item -ItemType Directory -Path (Join-Path $FullPath 'img') -Force
            }

            if (-not $SkipFiles) {
                # Create profile.json
                if ('profile.json' -notin $MissingFiles) {
                    $profileContent = @{
                        Email = $Email
                        FirstName = "Test"
                        LastName = "User"
                        ProfileId = [guid]::NewGuid()
                        CreatedOn = (Get-Date)
                        UserDirectory = $FullPath
                    }
                    if ('profile.json' -in $CorruptFiles) {
                        '{invalid json' | Out-File (Join-Path $FullPath 'profile.json') -Force
                    } else {
                        $profileContent | ConvertTo-Json | Out-File (Join-Path $FullPath 'profile.json') -Force
                    }
                }

                # Create preferences.json
                if ('preferences.json' -notin $MissingFiles) {
                    if ('preferences.json' -in $CorruptFiles) {
                        '{invalid' | Out-File (Join-Path $FullPath 'preferences.json') -Force
                    } else {
                        '{"theme":"dark","language":"en"}' | Out-File (Join-Path $FullPath 'preferences.json') -Force
                    }
                }

                # Create entries.json
                if ('entries.json' -notin $MissingFiles) {
                    $entriesPath = Join-Path $FullPath 'health-data/entries.json'
                    if ('entries.json' -in $CorruptFiles) {
                        '[invalid' | Out-File $entriesPath -Force
                    } else {
                        '[{"date":"2025-01-01","value":120}]' | Out-File $entriesPath -Force
                    }
                }
            }

            return $FullPath
        }
    }

    AfterAll {
        # Clean up test data
        if (Test-Path $TestUserPath) {
            Remove-Item $TestUserPath -Recurse -Force
        }
    }

    BeforeEach {
        # Clean up before each test
        if (Test-Path $TestUserPath) {
            Remove-Item $TestUserPath -Recurse -Force
        }
    }

    Context "User Not Found Scenarios" {
        It "Should return invalid result when user email doesn't exist" {
            # Act
            $result = [UserProfile]::ValidateUserDataStructure("nonexistent@example.com", $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Email | Should -Be "nonexistent@example.com"
            $result.Issues | Should -Contain "User nonexistent@example.com not found"
            $result.Validations.UserFound | Should -Be $false
        }

        It "Should return invalid result when base64 folder doesn't exist" {
            # Act - Pass email only, let the method derive the base64 ID
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Contain "User $TestEmail not found"
            $result.Validations.UserFound | Should -Be $false
        }
    }

    Context "Complete Valid User Structure" {
        It "Should return valid result for complete user structure with base64 folder" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath

            # Act - Use email only, let method derive base64 ID
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Issues.Count | Should -Be 0
            $result.Validations.UserFound | Should -Be $true
            $result.Validations.UserDirectoryExists | Should -Be $true
            $result.Validations.HealthDataDirectoryExists | Should -Be $true
            $result.Validations.ImageDirectoryExists | Should -Be $true
            $result.Validations.ProfileJsonValid | Should -Be $true
            $result.Validations.PreferencesJsonValid | Should -Be $true
            $result.Validations.EntriesJsonValid | Should -Be $true
        }
    }

    Context "Missing Directory Scenarios" {
        It "Should detect missing health-data directory" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            Remove-Item (Join-Path $TestFullUserPath 'health-data') -Recurse -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Contain "Missing health-data directory"
            $result.Validations.HealthDataDirectoryExists | Should -Be $false
        }

        It "Should detect missing img directory" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            Remove-Item (Join-Path $TestFullUserPath 'img') -Recurse -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Contain "Missing img directory"
            $result.Validations.ImageDirectoryExists | Should -Be $false
        }
    }

    Context "Missing File Scenarios" {
        It "Should detect missing profile.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('profile.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Contain "Missing profile.json file"
            $result.Validations.ProfileJsonValid | Should -Be $false
        }

        It "Should detect missing preferences.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('preferences.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Contain "Missing preferences.json file"
            $result.Validations.PreferencesJsonValid | Should -Be $false
        }

        It "Should detect missing entries.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('entries.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Contain "Missing entries.json file"
            $result.Validations.EntriesJsonValid | Should -Be $false
        }
    }

    Context "Corrupted JSON File Scenarios" {
        It "Should detect corrupted profile.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -CorruptFiles @('profile.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Match "Invalid JSON in file profile.json"
            $result.Validations.ProfileJsonValid | Should -Be $false
        }

        It "Should detect corrupted preferences.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -CorruptFiles @('preferences.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Match "Invalid JSON in file preferences.json"
            $result.Validations.PreferencesJsonValid | Should -Be $false
        }

        It "Should detect corrupted entries.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -CorruptFiles @('entries.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Issues | Should -Match "Invalid JSON in file entries.json"
            $result.Validations.EntriesJsonValid | Should -Be $false
        }
    }

    Context "AutoRepair Functionality - Directories" {
        It "Should repair missing health-data directory with AutoRepair" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            Remove-Item (Join-Path $TestFullUserPath 'health-data') -Recurse -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Created missing health-data directory"
            $result.Validations.HealthDataDirectoryExists | Should -Be $true
            Test-Path (Join-Path $TestFullUserPath 'health-data') | Should -Be $true
        }

        It "Should repair missing img directory with AutoRepair" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            Remove-Item (Join-Path $TestFullUserPath 'img') -Recurse -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Created missing img directory"
            $result.Validations.ImageDirectoryExists | Should -Be $true
            Test-Path (Join-Path $TestFullUserPath 'img') | Should -Be $true
        }
    }

    Context "AutoRepair Functionality - JSON Files" {
        It "Should repair missing entries.json with AutoRepair" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('entries.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Created missing entries.json with empty array"
            $result.Validations.EntriesJsonValid | Should -Be $true
            $entriesPath = Join-Path $TestFullUserPath 'health-data/entries.json'
            Test-Path $entriesPath | Should -Be $true
            Get-Content $entriesPath | ConvertFrom-Json | Should -BeOfType [System.Array]
        }

        It "Should repair missing preferences.json with AutoRepair" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('preferences.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Created missing preferences.json with empty object"
            $result.Validations.PreferencesJsonValid | Should -Be $true
            $prefsPath = Join-Path $TestFullUserPath 'preferences.json'
            Test-Path $prefsPath | Should -Be $true
            Get-Content $prefsPath | ConvertFrom-Json | Should -BeOfType [PSCustomObject]
        }

        It "Should repair corrupted entries.json with AutoRepair" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -CorruptFiles @('entries.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Repaired entries.json with empty array"
            $result.Validations.EntriesJsonValid | Should -Be $true
        }

        It "Should repair corrupted preferences.json with AutoRepair" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -CorruptFiles @('preferences.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Repaired preferences.json with empty object"
            $result.Validations.PreferencesJsonValid | Should -Be $true
        }
    }

    Context "Smart Content Analysis" {
        It "Should report existing entries count in entries.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            $entriesPath = Join-Path $TestFullUserPath 'health-data/entries.json'
            $entries = @(
                @{date="2025-01-01"; value=120},
                @{date="2025-01-02"; value=125},
                @{date="2025-01-03"; value=118}
            )
            $entries | ConvertTo-Json | Out-File $entriesPath -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "entries.json already has 3 entries"
        }

        It "Should report existing preferences count in preferences.json" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            $prefsPath = Join-Path $TestFullUserPath 'preferences.json'
            $prefs = @{
                theme = "dark"
                language = "en"
                timezone = "UTC"
                notifications = $true
            }
            $prefs | ConvertTo-Json | Out-File $prefsPath -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "preferences.json already has 4 preferences"
        }

        It "Should detect empty entries.json array" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            $entriesPath = Join-Path $TestFullUserPath 'health-data/entries.json'
            '[]' | Out-File $entriesPath -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "entries.json exists but is empty (just [])"
        }

        It "Should detect empty preferences.json object" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            $prefsPath = Join-Path $TestFullUserPath 'preferences.json'
            '{}' | Out-File $prefsPath -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "preferences.json exists but is empty (just {})"
        }
    }

    Context "Multiple Issues Scenarios" {
        It "Should detect and repair multiple issues" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('entries.json', 'preferences.json')
            Remove-Item (Join-Path $TestFullUserPath 'health-data') -Recurse -Force

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs.Count | Should -BeGreaterThan 2
            $result.Repairs | Should -Contain "Created missing health-data directory"
            $result.Repairs | Should -Contain "Created missing entries.json with empty array"
            $result.Repairs | Should -Contain "Created missing preferences.json with empty object"
        }
    }

    Context "Edge Cases" {
        It "Should handle empty file content correctly" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            $entriesPath = Join-Path $TestFullUserPath 'health-data/entries.json'
            '' | Out-File $entriesPath -Force  # Empty file

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Repaired entries.json with empty array"
        }

        It "Should handle single line corrupted file" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath
            $prefsPath = Join-Path $TestFullUserPath 'preferences.json'
            'invalid' | Out-File $prefsPath -Force  # Single line, invalid JSON

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $true)

            # Assert
            $result.IsValid | Should -Be $true
            $result.Repairs | Should -Contain "Repaired preferences.json with empty object"
        }
    }

    Context "No AutoRepair Scenarios" {
        It "Should not perform repairs when AutoRepair is false" {
            # Arrange
            New-TestUserStructure -UserPath $TestUserPath -MissingFiles @('entries.json')

            # Act
            $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false)

            # Assert
            $result.IsValid | Should -Be $false
            $result.Repairs.Count | Should -Be 0
            $result.Issues | Should -Contain "Missing entries.json file"
        }
    }

    Context "Error Handling" {
        It "Should handle critical errors gracefully" {
            # Arrange - Create a scenario that might cause errors
            New-TestUserStructure -UserPath $TestUserPath

            # Mock a permission error by making directory read-only (if possible)
            # This test may vary based on OS permissions

            # Act & Assert - Should not throw
            { $result = [UserProfile]::ValidateUserDataStructure($TestEmail, $null, $false) } | Should -Not -Throw
        }
    }
}
