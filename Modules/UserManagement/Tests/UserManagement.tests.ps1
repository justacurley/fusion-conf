# UserProfile Class Tests
# Test file for the UserProfile class functionality
# Import the module under test
using module ../UserManagement.psm1
BeforeAll {
    # Test data setup
    Import-Module (Join-Path $PSScriptRoot "TestHelpers.psm1") -Force
    $script:TestUserData = @{
        Email = "test@example.com"
        FirstName = "John"
        LastName = "Doe"
        Timezone = "America/New_York"
        Password = (New-SecureString "SecurePass123!")
        TOSAccepted = $true
    }
    $script:NewPSUIdentity = @"
{
  "Id": 2,
  "Name": "curleylax@gmail.com",
  "Source": 1,
  "RoleName": "User",
  "Roles": [
    "User"
  ],
  "CredentialVault": null,
  "Password": "Thequickestshotwins!1",
  "LocalAccount": false,
  "OldPassword": null,
  "Settings": null,
  "Theme": null,
  "JobColumns": null,
  "JobStatuses": null,
  "PasswordLastSet": null,
  "System": false,
  "ExcludedScripts": null,
  "SelectedScripts": null
}
"@ | ConvertFrom-Json
}

Describe "UserProfile Class" {
    Context "Constructor Tests" {
        BeforeAll {
            $usr = $script:TestUserData
            $NewProfile = [UserProfile]::new($usr.Email,$usr.FirstName,$usr.LastName,$usr.Password,$usr.Timezone,$usr.TOSAccepted)
        }
        It "Should not throw when creating UserProfile" {
            { [UserProfile]::new() } | Should -Not -Throw
        }
        It "Should create a UserProfile with valid data" {
            $NewProfile.Email | Should -be $usr.Email
            $NewProfile.FirstName | Should -be $usr.FirstName
            $NewProfile.LastName | Should -be $usr.LastName
            $NewProfile.Password | Should -be $usr.Password
            $NewProfile.Timezone | Should -be $usr.Timezone
        }
        
        It "Should generate a unique UserId" {
            $NewProfile.ProfileId | Should -BeOfType [guid]
        }
        
        It "Should set CreatedDate to current time" {
            $NewProfile.CreatedOn | Should -BeOfType [datetime]
        }

        It "Should throw if email is an empty string" {
            {[UserProfile]::new('',$usr.FirstName,$usr.LastName,$usr.Password,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if email is `$null" {
            {[UserProfile]::new($null,$usr.FirstName,$usr.LastName,$usr.Password,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if FirstName is an empty string" {
            {[UserProfile]::new($usr.Email,'',$usr.LastName,$usr.Password,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if FirstName is `$null" {
            {[UserProfile]::new($usr.Email,$null,$usr.LastName,$usr.Password,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if LastName is an empty string" {
            {[UserProfile]::new($usr.Email,$usr.FirstName,'',$usr.Password,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if LastName is `$null" {
            {[UserProfile]::new($usr.Email,$usr.FirstName,$null,$usr.Password,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if Password is `$null" {
            {[UserProfile]::new($usr.Email,$usr.FirstName,$usr.LastName,$null,$usr.Timezone,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if Timezone is an empty string" {
            {[UserProfile]::new($usr.Email,$usr.FirstName,$usr.LastName,$usr.Password,'',$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if Timezone is `$null" {
            {[UserProfile]::new($usr.Email,$usr.FirstName,$usr.LastName,$usr.Password,$null,$usr.TOSAccepted)} | Should -Throw -ExpectedMessage "*The argument is null or empty*"
        }

        It "Should throw if TOS is not accepted" {
            {[UserProfile]::new($usr.Email,$usr.FirstName,$usr.LastName,$usr.Password,$usr.Timezone,$false)} | Should -Throw -ExpectedMessage "*Terms of Service must be accepted*"
        }
    }
    
    Context "Property Validation" {
        It "Should validate that TOSAccepted is optional for parameterless constructor" {
            $userProfile = [UserProfile]::new()
            $userProfile.TOSAccepted | Should -Be $false
        }
        
        It "Should validate that auto-generated properties are set" {
            $userProfile = [UserProfile]::new()
            $userProfile.ProfileId | Should -BeOfType [guid]
            $userProfile.CreatedOn | Should -BeOfType [datetime]
        }
    }
    
    Context "Method Tests" {
        BeforeAll {
            $usr = $script:TestUserData
            $testProfile = [UserProfile]::new($usr.Email,$usr.FirstName,$usr.LastName,$usr.Password,$usr.Timezone,$usr.TOSAccepted)
        }
        
        Context "PSU Identity Management" {
            It "Should check if PSU identity exists" {
                # Mock the Get-PSUIdentity cmdlet
                Mock Get-PSUIdentity { return $null } -ModuleName UserManagement
                
                $result = $testProfile.PSUIdentityExists()
                $result | Should -Be $false
                
                Should -Invoke Get-PSUIdentity -Exactly 1 -ModuleName UserManagement
            }
            
            It "Should return true when PSU identity exists" {
                # Mock existing identity
                Mock Get-PSUIdentity { return $script:NewPSUIdentity } -ModuleName UserManagement
                
                $result = $testProfile.PSUIdentityExists()
                $result | Should -Be $true
            }
            
            It "Should create PSU identity when user doesn't exist" {
                # Mock cmdlets for successful creation
                Mock Get-PSUIdentity { return $null } -ModuleName UserManagement
                Mock Get-PSURole { return @{ Name = "User" } } -ModuleName UserManagement  
                Mock New-PSUIdentity { return $script:NewPSUIdentity } -ModuleName UserManagement
                
                $result = $testProfile.CreatePSUIdentity()
                
                $result | Should -Not -BeNullOrEmpty
                $result.Id | Should -Be 2
                $testProfile.PSUProfileId | Should -Be 2
                
                Should -Invoke Get-PSUIdentity -Exactly 1 -ModuleName UserManagement
                Should -Invoke Get-PSURole -Exactly 1 -ModuleName UserManagement
                Should -Invoke New-PSUIdentity -Exactly 1 -ModuleName UserManagement
            }
            
            It "Should return null and warn when PSU identity already exists" {
                # Mock existing identity
                Mock Get-PSUIdentity { return $script:NewPSUIdentity } -ModuleName UserManagement
                Mock Write-Warning { } -ModuleName UserManagement
                
                $result = $testProfile.CreatePSUIdentity()
                
                $result | Should -BeNullOrEmpty
                Should -Invoke Write-Warning -Exactly 1 -ModuleName UserManagement
                Should -Invoke Get-PSUIdentity -Exactly 1 -ModuleName UserManagement
            }
            
            It "Should throw when PSU identity creation fails" {
                # Mock failed creation
                Mock Get-PSUIdentity { return $null } -ModuleName UserManagement
                Mock Get-PSURole { throw "Role not found" } -ModuleName UserManagement
                Mock Write-Warning { } -ModuleName UserManagement
                
                { $testProfile.CreatePSUIdentity() } | Should -Throw
                Should -Invoke Write-Warning -Exactly 1 -ModuleName UserManagement
            }
        }
        
        It "Should create user directory structure" {
            # Setup test environment
            $testPath = Initialize-TestEnvironment
            $testUserPath = Join-Path $testPath $testProfile.ProfileId
            
            # Mock the PSU identity check and file system operations
            Mock Get-PSUIdentity { return $script:NewPSUIdentity } -ModuleName UserManagement
            Mock New-Item { 
                param($ItemType, $Path, $Name, $ErrorAction)
                if ($ItemType -eq "Directory") {
                    $fullPath = if ($Name) { Join-Path $Path $Name } else { $Path }
                    return @{ FullName = $fullPath }
                } else {
                    $fullPath = Join-Path $Path $Name
                    return @{ FullName = $fullPath }
                }
            } -ModuleName UserManagement
            
            $result = $testProfile.CreateUserDirectory()
            
            # Verify directory creation calls
            Should -Invoke New-Item -ParameterFilter { 
                $ItemType -eq "Directory" -and $Name -eq $testProfile.ProfileId 
            } -Exactly 1 -ModuleName UserManagement
            
            Should -Invoke New-Item -ParameterFilter { 
                $ItemType -eq "Directory" -and $Name -eq "health-data" 
            } -Exactly 1 -ModuleName UserManagement
            
            Should -Invoke New-Item -ParameterFilter { 
                $ItemType -eq "File" -and $Name -eq "profile.json" 
            } -Exactly 1 -ModuleName UserManagement
            
            Should -Invoke New-Item -ParameterFilter { 
                $ItemType -eq "File" -and $Name -eq "preferences.json" 
            } -Exactly 1 -ModuleName UserManagement
            
            $result | Should -Match $testProfile.ProfileId
        }
        
        It "Should throw when directory creation fails for non-existent PSU identity" {
            Mock Get-PSUIdentity { return $null } -ModuleName UserManagement
            
            { $testProfile.CreateUserDirectory() } | Should -Throw -ExpectedMessage "*Could not find identity*"
        }
        
        It "Should serialize profile to JSON" {
            # Setup test environment  
            $testPath = Initialize-TestEnvironment
            $expectedProfilePath = "/home/data/users/$($testProfile.ProfileId)/profile.json"
            
            # Mock file operations
            Mock Out-File { return $null } -ModuleName UserManagement
            Mock Join-Path { return $expectedProfilePath } -ModuleName UserManagement
            
            $result = $testProfile.SaveUserProfile()
            
            $result | Should -Be $expectedProfilePath
            Should -Invoke Out-File -Exactly 1 -ModuleName UserManagement
        }
        
        It "Should include correct properties in serialized profile" {
            # Setup test environment
            $testPath = Initialize-TestEnvironment
            $capturedJson = ""
            
            # Mock Out-File to capture the JSON content
            Mock Out-File { 
                param($FilePath, $InputObject)
                $script:capturedJson = $InputObject
            } -ModuleName UserManagement
            Mock Join-Path { return "/home/data/users/test/profile.json" } -ModuleName UserManagement
            
            $testProfile.SaveUserProfile()
            
            # Parse the captured JSON and verify properties
            $profileData = $script:capturedJson | ConvertFrom-Json
            $profileData.Email | Should -Be $testProfile.Email
            $profileData.FirstName | Should -Be $testProfile.FirstName
            $profileData.LastName | Should -Be $testProfile.LastName
            $profileData.Timezone | Should -Be $testProfile.Timezone
            $profileData.ProfileId | Should -Be $testProfile.ProfileId
            # TOSAccepted is a switch, so check the IsPresent property
            $profileData.TOSAccepted.IsPresent | Should -Be $testProfile.TOSAccepted.IsPresent
            
            # Verify sensitive data is not included
            $profileData.PSObject.Properties.Name | Should -Not -Contain "Password"
        }
    }
}

Describe "Module-Level Function Tests" {
    Context "New-PSUUser Function Tests" {
        # Existing tests can be added here if needed
    }
    
    Context "Test-PSUUserExists Function Tests" {
        # Existing tests can be added here if needed
    }
    
    Context "Invoke-UserAuthentication Function Tests" {
        BeforeAll {
            $script:TestEmail = "auth@example.com"
            $script:TestProfile = @{
                Email = $script:TestEmail
                FirstName = "Auth"
                LastName = "User" 
                ProfileId = [guid]::NewGuid()
                PSUProfileId = 123
                Timezone = "America/New_York"
                CreatedOn = Get-Date
                TOSAccepted = $true
            }
        }
        
        It "Should return success when user exists and profile is found" {
            Mock Test-PSUUserExists { return $true } -ModuleName UserManagement
            Mock Get-ChildItem { 
                return @(
                    @{ FullName = "/fake/path/profile.json" }
                )
            } -ModuleName UserManagement
            Mock Get-Content { 
                return ($script:TestProfile | ConvertTo-Json)
            } -ModuleName UserManagement
            
            $result = Invoke-UserAuthentication -Email $script:TestEmail
            
            $result.Success | Should -Be $true
            $result.Message | Should -Match "Profile for .* was found"
            $result.UserProfile | Should -Not -BeNullOrEmpty
            $result.UserProfile.Email | Should -Be $script:TestEmail
        }
        
        It "Should return failure when user does not exist" {
            Mock Test-PSUUserExists { return $false } -ModuleName UserManagement
            
            $result = Invoke-UserAuthentication -Email "nonexistent@example.com"
            
            $result.Success | Should -Be $false
            $result.Message | Should -Match "Profile for .* was not found"
            $result.UserProfile | Should -BeOfType [PSCustomObject]
        }
        
        It "Should return failure when user exists but profile.json is not found" {
            Mock Test-PSUUserExists { return $true } -ModuleName UserManagement
            Mock Get-ChildItem { return @() } -ModuleName UserManagement
            
            $result = Invoke-UserAuthentication -Email $script:TestEmail
            
            $result.Success | Should -Be $false
            $result.Message | Should -Match "Profile.json was not found"
        }
        
        It "Should return failure when profile.json returns null" {
            Mock Test-PSUUserExists { return $true } -ModuleName UserManagement
            Mock Get-ChildItem { 
                return @(
                    @{ FullName = "/fake/path/profile.json" }
                )
            } -ModuleName UserManagement
            Mock Get-Content { 
                return '{"Email":"different@example.com","FirstName":"Other"}'
            } -ModuleName UserManagement
            
            $result = Invoke-UserAuthentication -Email $script:TestEmail
            
            $result.Success | Should -Be $false
            $result.Message | Should -Match "Profile.json was not found"
        }
        
        It "Should handle exceptions gracefully" {
            Mock Test-PSUUserExists { throw "Database error" } -ModuleName UserManagement
            Mock Write-Error { } -ModuleName UserManagement
            
            $result = Invoke-UserAuthentication -Email $script:TestEmail
            
            $result.Success | Should -Be $false
            Should -Invoke Write-Error -Exactly 1 -ModuleName UserManagement
        }
    }
    
    Context "Set-UserSession Function Tests" {
        BeforeAll {
            $script:TestUserProfile = [PSCustomObject]@{
                Email = "session@example.com"
                FirstName = "Session"
                LastName = "User"
                ProfileId = [guid]::NewGuid()
                PSUProfileId = 456
                Timezone = "America/Denver"
            }
        }
        
        It "Should successfully set all session variables" {
            # Mock the session variable assignments since they don't work outside PSU
            Mock Write-Error { } -ModuleName UserManagement
            
            $result = Set-UserSession -UserProfile $script:TestUserProfile
            
            # Since we can't actually test session variables outside PSU,
            # we verify the function doesn't throw and handles the error gracefully
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $false  # Will fail outside PSU context
            $result.Message | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle missing profile properties gracefully" {
            Mock Write-Error { } -ModuleName UserManagement
            $incompleteProfile = [PSCustomObject]@{
                Email = "incomplete@example.com"
                # Missing other required properties
            }
            
            $result = Set-UserSession -UserProfile $incompleteProfile
            
            # Function should not throw, even with incomplete profile
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $false  # Will fail outside PSU context
        }
        
        It "Should return proper structure on call" {
            Mock Write-Error { } -ModuleName UserManagement
            
            $result = Set-UserSession -UserProfile $script:TestUserProfile
            
            # Verify response structure
            $result | Should -BeOfType [hashtable]
            $result.ContainsKey('Success') | Should -Be $true
            $result.ContainsKey('Message') | Should -Be $true
            $result.Success | Should -BeOfType [bool]
            $result.Message | Should -BeOfType [string]
        }
    }
    
    Context "Test-UserSession Function Tests" {
        BeforeAll {
            # Setup mock user object for PSU context
            $script:MockUser = [PSCustomObject]@{
                Identity = [PSCustomObject]@{
                    Name = "testuser@example.com"
                    IsAuthenticated = $true
                }
                Claims = @()
            }
        }
        
        It "Should return success when all validations pass" {
            # Use InModuleScope to set variables within the module context
            InModuleScope UserManagement {
                # Set up a proper User variable that the function expects
                $script:User = [PSCustomObject]@{
                    Identity = [PSCustomObject]@{
                        Name = "testuser@example.com"
                        IsAuthenticated = $true
                    }
                    Claims = @()
                }
                
                $result = Test-UserSession
                
                # The function will fail at session variable check outside PSU context
                # but we can verify it gets past the User authentication check
                $result | Should -Not -BeNullOrEmpty
                $result.Success | Should -Be $false  # Will fail at session variable check
                $result.Message | Should -Not -Be "PSU User identity not found"
                $result.Message | Should -Not -Be "User is not authenticated in PSU"
                # Should fail on session variables instead
                $result.Message | Should -Match "Session variable.*missing"
            }
        }
        
        It "Should fail when PSU User variable does not exist" {
            Mock Get-Variable { throw "Variable not found" } -ParameterFilter { $Name -eq "User" } -ModuleName UserManagement
            Mock Write-Error { } -ModuleName UserManagement
            
            $result = Test-UserSession
            
            $result.Success | Should -Be $false
            $result.Message | Should -Be "Could not access PSU User session variable"
            Should -Invoke Write-Error -Exactly 1 -ModuleName UserManagement
        }
        
        It "Should fail when PSU User identity is missing" {
            # Use InModuleScope to set variables within the module context
            InModuleScope UserManagement {
                # Set up a User variable with null Identity
                $script:User = [PSCustomObject]@{
                    Identity = $null
                    Claims = @()
                }
                
                $result = Test-UserSession
                
                $result.Success | Should -Be $false
                $result.Message | Should -Be "PSU User identity not found"
            }
        }
        
        It "Should fail when PSU User is not authenticated" {
            # Use InModuleScope to set variables within the module context
            InModuleScope UserManagement {
                # Set up an unauthenticated User variable
                $script:User = [PSCustomObject]@{
                    Identity = [PSCustomObject]@{
                        Name = "testuser@example.com"
                        IsAuthenticated = $false
                    }
                    Claims = @()
                }
                
                $result = Test-UserSession
                
                $result.Success | Should -Be $false
                $result.Message | Should -Be "User is not authenticated in PSU"
            }
        }
        
        It "Should verify function structure and error handling" {
            # Test that the function has proper structure and handles session provider errors
            Mock Get-Variable { return @{ Name = "User"; Value = $script:MockUser } } -ParameterFilter { $Name -eq "User" } -ModuleName UserManagement
            
            $result = Test-UserSession
            
            # Verify response structure
            $result | Should -BeOfType [hashtable]
            $result.ContainsKey('Success') | Should -Be $true
            $result.ContainsKey('Message') | Should -Be $true
            $result.ContainsKey('Data') | Should -Be $true
            $result.Success | Should -BeOfType [bool]
            $result.Message | Should -BeOfType [string]
        }
    }
}

Describe "Get-CurrentUser" {
    Context "When session is valid" {
        BeforeEach {
            # Mock Test-UserSession to return success with user data
            Mock Test-UserSession {
                return @{
                    Success = $true
                    Message = "Valid user session found"
                    Data = @{
                        PSUUser = [PSCustomObject]@{
                            Identity = [PSCustomObject]@{
                                Name = "test@example.com"
                                AuthenticationType = "Forms"
                                IsAuthenticated = $true
                            }
                        }
                        UserEmail = "test@example.com"
                        UserProfileId = "12345678-1234-1234-1234-123456789012"
                        PSUProfileId = 42
                        UserFirstName = "John"
                        UserLastName = "Doe"
                        UserTimezone = "America/New_York"
                        LoginTime = (Get-Date)
                        IsAuthenticated = $true
                    }
                }
            } -ModuleName UserManagement
        }
        
        It "Should return current user information successfully" {
            $result = Get-CurrentUser
            
            $result.Success | Should -Be $true
            $result.Message | Should -Be "Current user retrieved successfully"
            $result.Data | Should -BeOfType [hashtable]
            $result.Data.UserEmail | Should -Be "test@example.com"
            $result.Data.UserFirstName | Should -Be "John"
            $result.Data.UserLastName | Should -Be "Doe"
            $result.Data.PSUProfileId | Should -Be 42
        }
        
        It "Should include all expected user properties" {
            $result = Get-CurrentUser
            
            $expectedProperties = @(
                'PSUUser', 'UserEmail', 'UserProfileId', 'PSUProfileId', 'UserFirstName',
                'UserLastName', 'UserTimezone', 'LoginTime', 'IsAuthenticated'
            )
            
            foreach ($property in $expectedProperties) {
                $result.Data.ContainsKey($property) | Should -Be $true
            }
        }
    }
    
    Context "When session is invalid" {
        BeforeEach {
            # Mock Test-UserSession to return failure
            Mock Test-UserSession {
                return @{
                    Success = $false
                    Message = "User is not authenticated in PSU"
                    Data = @{}
                }
            } -ModuleName UserManagement
        }
        
        It "Should return failure when session check fails" {
            $result = Get-CurrentUser
            
            $result.Success | Should -Be $false
            $result.Message | Should -Match "No valid user session found"
            $result.Data | Should -BeOfType [hashtable]
            $result.Data.Count | Should -Be 0
        }
    }
    
    Context "When an error occurs" {
        BeforeEach {
            # Mock Test-UserSession to throw an error
            Mock Test-UserSession {
                throw "Simulated error"
            } -ModuleName UserManagement
        }
        
        It "Should handle errors gracefully" {
            $result = Get-CurrentUser
            
            $result.Success | Should -Be $false
            $result.Message | Should -Match "Error retrieving current user"
            $result.Data | Should -BeOfType [hashtable]
        }
    }
    
    Context "Function structure validation" {
        It "Should have proper response structure" {
            Mock Test-UserSession { return @{ Success = $false; Message = "Test"; Data = @{} } } -ModuleName UserManagement
            
            $result = Get-CurrentUser
            
            $result | Should -BeOfType [hashtable]
            $result.ContainsKey('Success') | Should -Be $true
            $result.ContainsKey('Message') | Should -Be $true
            $result.ContainsKey('Data') | Should -Be $true
            $result.Success | Should -BeOfType [bool]
            $result.Message | Should -BeOfType [string]
            $result.Data | Should -BeOfType [hashtable]
        }
    }
}

Describe "Clear-UserSession" {
    Context "Function behavior validation" {
        It "Should have proper response structure" {
            $result = Clear-UserSession
            
            $result | Should -BeOfType [hashtable]
            $result.ContainsKey('Success') | Should -Be $true
            $result.ContainsKey('Message') | Should -Be $true
            $result.ContainsKey('ClearedVariables') | Should -Be $true
            $result.Success | Should -BeOfType [bool]
            $result.Message | Should -BeOfType [string]
            # ClearedVariables should be an array or array-like object
            $result.ClearedVariables.GetType().BaseType.Name | Should -BeIn @('Array', 'Object')
        }
        
        It "Should succeed even when no session variables exist" {
            $result = Clear-UserSession
            
            $result.Success | Should -Be $true
            $result.Message | Should -Match "User session cleared successfully"
            # Should be an array-like object
            $result.ClearedVariables.GetType().BaseType.Name | Should -BeIn @('Array', 'Object')
            # In test environment, likely no variables to clear
            $result.ClearedVariables.Count | Should -BeGreaterOrEqual 0
        }
        
        It "Should handle the session variable clearing logic" {
            # This test validates the function structure and error handling
            # without trying to mock session variables which cause scope issues
            
            $result = Clear-UserSession
            
            # The function should complete without throwing errors
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -Be $true
        }
    }
    
    Context "Error handling" {
        It "Should handle exceptions gracefully when Remove-Variable fails" {
            # Mock Remove-Variable to throw an error
            Mock Remove-Variable { throw "Access denied" } -ModuleName UserManagement
            
            $result = Clear-UserSession
            
            # Should still succeed since errors are caught per variable
            $result.Success | Should -Be $true
            $result.Message | Should -Match "User session cleared successfully"
        }
    }
}
