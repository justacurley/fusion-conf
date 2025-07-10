using namespace System.Collections.Generic

class UserProfile {
    [ValidateNotNullOrEmpty()]
    [string]$Email
    [ValidateNotNullOrEmpty()]
    [string]$FirstName
    [ValidateNotNullOrEmpty()]
    [string]$LastName
    [ValidateNotNullOrEmpty()]
    [securestring]$Password
    [ValidateNotNullOrEmpty()]
    [string]$Timezone
    [switch]$TOSAccepted
    [datetime]$CreatedOn = (Get-Date)
    [guid]$ProfileId = (New-Guid)
    [int]$PSUProfileId = 0

    UserProfile() {}

    UserProfile([string]$Email, [string]$FirstName, [string]$LastName, [securestring]$Password, [string]$Timezone, [switch]$TOSAccepted) {
        if ($TOSAccepted -eq $false) {
            throw 'Terms of Service must be accepted'
        }
        $this.Email = $Email
        $this.FirstName = $FirstName
        $this.LastName = $LastName
        $this.Password = $Password
        $this.Timezone = $Timezone
        $this.TOSAccepted = $TOSAccepted
    }

    [bool] PSUIdentityExists() {
        return $null -ne (Get-PSUIdentity -Name $this.Email)
    }

    [System.Object] GetPSUIdentity([string]$email) {
        return Get-PSUIdentity -Name $this.Email
    }

    static [bool] UserExists([string]$Email) {
        try {
            return $null -ne (Get-PSUIdentity -Name $Email)
        } catch {
            return $false
        }
    }

    [System.Object] CreatePSUIdentity() {
        $Identity = $null
        try {
            if (-not $this.PSUIdentityExists()) {
                $UserRole = Get-PSURole -Name 'User' -ErrorAction Stop
                $Identity = New-PSUIdentity -Name $this.Email -Role $UserRole -Password $this.Password -Integrated -CredentialVault 'Database' -ErrorAction Stop
                $this.PSUProfileId = $Identity.Id
            } else {
                Write-Warning "Profile for $($this.Email) already exists"
            }
        } catch {
            Write-Warning "Failed to create user for $($this.email)"
            throw $_
        }
        return $Identity
    }

    [string] CreateUserDirectory() {
        $ProfilesPath = '/home/data/users/'
        try {
            if ($null -ne ($this.GetPSUIdentity($this.Email))) {
                New-Item -ItemType Directory -Path $ProfilesPath -Name $this.ProfileId -ErrorAction Stop
                $UserPath = Join-Path $ProfilesPath $this.ProfileId
                New-Item -ItemType Directory -Path $UserPath -Name 'health-data' -ErrorAction Stop
                @('profile.json', 'preferences.json').ForEach({ New-Item -ItemType File -Path $UserPath -Name $_ -ErrorAction Stop })
                return $UserPath
            } else {
                throw "Could not find identity for $($this.Email)"
            }            
        } catch {
            Write-Warning "Failed to create directory for user profile $($this.Email)"
            throw $_
        }
    }
    
    [string] SaveUserProfile() {
        try {
            $UserPath = "/home/data/users/$($this.ProfileId)"
            $UserSettingsPath = Join-Path $UserPath profile.json
            $this | Select-Object Email, FirstName, LastName, Timezone, CreatedOn, ProfileId, PSUProfileId, TOSAccepted | ConvertTo-Json | Out-File $UserSettingsPath 
            return $UserSettingsPath
        } catch {
            Write-Warning "Failed to update profile.json for user profile $($this.Email)"
            throw $_
        }
    }

    static [PSCustomobject] GetUserProfile([string]$Email) {
        try {
            $UserPath = '/home/data/users/'
            $Profiles = Get-ChildItem $UserPath -Recurse -File 'profile.json'
            foreach ($ProfilePath in $Profiles) {
                $ProfileContent = Get-Content $ProfilePath | ConvertFrom-Json
                if ($ProfileContent.Email -eq $Email) {
                    return $ProfileContent
                }
            }
            return $false
        } catch {
            return $false
        }
    }
}

function New-PSUUser {
    param (
        [string]$Email,
        [string]$FirstName,
        [string]$LastName,
        [securestring]$Password,
        [string]$Timezone,
        [switch]$TOSAccepted
    )
    $Response = @{}
    try {
        $NewUser = [UserProfile]::new($Email, $FirstName, $LastName, $Password, $Timezone, $TOSAccepted)
        $NewUser.CreatePSUIdentity()
        $NewUser.CreateUserDirectory()
        $NewUser.SaveUserProfile()
        $Response['Success'] = $true
        $Response['Message'] = "User $Email registered successfully"
        $Response['UserProfile'] = $NewUser
    } catch {
        $Response['Success'] = $false
        $Response['Message'] = "User $Email failed to register"
        $Response['UserProfile'] = $null
        Write-Error $_
    }    
    return $Response
}
function Test-PSUUserExists {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Email
    )
    return [UserProfile]::UserExists($Email)
}

function Invoke-UserAuthentication {
    [CmdletBinding()]
    param (
        [string]$Email
    )
    end {
        $Response = @{
            'Success'     = $false
            'Message'     = "Profile for $Email was not found"
            'UserProfile' = [PSCustomObject]@{}
        }
        try {
            $UserExists = Test-PSUUserExists -Email $Email
            if (! $UserExists) {                
                return $Response
            }
            $Profile = [UserProfile]::GetUserProfile($Email)
            if ($Profile -eq $false -or $null -eq $Profile) {
                $Response['Message'] = "Profile.json was not found for $Email"
                return $Response
            }
            $Response['Success'] = $true
            $Response['Message'] = "Profile for $Email was found"
            $Response['UserProfile'] = $Profile
        } catch {
            Write-Error $_
        }
        return $Response
    }
}

function Set-UserSession {
    [CmdletBinding()]
    param (
        [PSCustomObject]$UserProfile  # The profile object from authentication
    )
    $Response = @{
        Success = $false
        Message = "Failed to extract one or more properties from user profile"
    }
    try {
        Write-Verbose "Setting UserProfileId to: $($UserProfile.ProfileId)"
        Write-Verbose "ProfileId type: $($UserProfile.ProfileId.GetType().Name)"
        $Session:UserEmail = $UserProfile.Email
        $Session:UserProfileId = $UserProfile.ProfileId
        $Session:PSUProfileId = $UserProfile.PSUProfileId
        $Session:UserFirstName = $UserProfile.FirstName
        $Session:UserLastName = $UserProfile.LastName
        $Session:UserTimezone = $UserProfile.Timezone
        $Session:LoginTime = (Get-Date)
        $Session:IsAuthenticated = $true
        $Response['Success'] = $true
        $Response['Message'] = "Set all required session variables"
    }
    catch {
       Write-Error $_
    }
    return $Response
}

function Test-UserSession {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = "Failed to get user session"
            Data = @{}
        }
        try {
            # Check if PSU User variable exists
            Get-Variable User -ErrorAction Stop | Out-Null
            
            # Validate PSU authentication
            if ([string]::IsNullOrEmpty($User)) {
                $Response['Message'] = "PSU User identity not found"
                return $Response
            }
            
            # Validate custom session variables
            if ($Session:UserEmail -and ($User -ne $Session:UserEmail)) {
                $Response['Message'] = "PSU user ($User) does not match session user ($Session:UserEmail)"
                return $Response
            }
            
            if (-not $Session:UserProfileId) {
                $Response['Message'] = "Session variable UserProfileId is missing"
                return $Response
            }
            
            if (-not $Session:IsAuthenticated) {
                $Response['Message'] = "Custom session authentication flag is missing or false"
                return $Response
            }
            
            # All validations passed - return combined session data
            $Response['Success'] = $true
            $Response['Message'] = "Valid user session found"
            $Response['Data'] = @{
                PSUUser = $User
                PSUUserRoles = $Roles
                UserEmail = $Session:UserEmail
                UserProfileId = $Session:UserProfileId
                PSUProfileId = $Session:PSUProfileId
                UserFirstName = $Session:UserFirstName
                UserLastName = $Session:UserLastName
                UserTimezone = $Session:UserTimezone
                LoginTime = $Session:LoginTime
                IsAuthenticated = $Session:IsAuthenticated
            }
        }
        catch {
            $Response['Message'] = "Could not access PSU User session variable"
            Write-Error "Could not find User session: $($_.Exception.Message)"
        }
        return $Response
    }
}

function Get-CurrentUser {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = "Failed to get current user"
            Data = @{}
        }
        try {
            # First check if we have a valid session
            $SessionCheck = Test-UserSession
            if (-not $SessionCheck.Success) {
                $Response['Message'] = "No valid user session found: $($SessionCheck.Message)"
                return $Response
            }
            
            # Use the data from Test-UserSession since it already validates and extracts everything
            $CurrentUser = $SessionCheck.Data
            
            $Response['Success'] = $true
            $Response['Message'] = "Current user retrieved successfully"
            $Response['Data'] = $CurrentUser
        }
        catch {
            $Response['Message'] = "Error retrieving current user: $($_.Exception.Message)"
            Write-Error "Error in Get-CurrentUser: $($_.Exception.Message)"
        }
        return $Response
    }
}

function Clear-UserSession {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = "Failed to clear user session"
            ClearedVariables = @()
        }
        try {
            # Clear all custom session variables
            $SessionVariables = @(
                'UserEmail',
                'UserProfileId', 
                'PSUProfileId',
                'UserFirstName',
                'UserLastName',
                'UserTimezone',
                'LoginTime',
                'IsAuthenticated'
            )
            
            $ClearedVariables = @()
            foreach ($Variable in $SessionVariables) {
                try {
                    # Try to remove the session variable directly
                    # In PSU context, this will work with Session: scope
                    # In test context, this may fail gracefully
                    Remove-Variable -Name "Session:$Variable" -ErrorAction Stop
                    $ClearedVariables += $Variable
                }
                catch {
                    # Variable doesn't exist or can't be removed - this is OK
                    Write-Verbose "Session variable $Variable not found or could not be removed: $($_.Exception.Message)"
                }
            }
            
            $Response['Success'] = $true
            $Response['Message'] = "User session cleared successfully. Cleared variables: $($ClearedVariables -join ', ')"
            $Response['ClearedVariables'] = $ClearedVariables
        }
        catch {
            $Response['Message'] = "Error clearing user session: $($_.Exception.Message)"
            $Response['ClearedVariables'] = @()  # Ensure it's always an array
            Write-Error "Error in Clear-UserSession: $($_.Exception.Message)"
        }
        return $Response
    }
}   