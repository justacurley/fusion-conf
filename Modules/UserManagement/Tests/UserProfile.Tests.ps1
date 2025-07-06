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
            # TODO: Test directory creation method
        }
        
        It "Should serialize profile to JSON" {
            # TODO: Test profile serialization
        }
    }
}
