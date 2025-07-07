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
