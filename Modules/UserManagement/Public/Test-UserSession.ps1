function Test-UserSession {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = 'Failed to get user session'
            Data    = @{}
        }
        try {
            # Ensure the UserManagement module is imported
            if (-not (Get-Module UserManagement)) {
                Import-Module UserManagement -Force
            }

            # Check if PSU User variable exists and has a value
            if (-not (Get-Variable User -ErrorAction SilentlyContinue) -or [string]::IsNullOrEmpty($User)) {
                $Response['Message'] = 'PSU User identity not found or empty'
                return $Response
            }

            # Validate that the user still exists in PSU
            if (-not [UserProfile]::UserExists($User)) {
                $Response['Message'] = "PSU identity no longer exists for user: $User"
                return $Response
            }

            # Dynamically load user profile using the PSU User variable
            try {
                $AllUserData = [UserProfile]::GetUserProfile($User)
                $UserProfile = $AllUserData.Profile

                # All validations passed - return session data based on PSU User and loaded profile
                $Response['Success'] = $true
                $Response['Message'] = 'Valid user session found via dynamic profile loading'
                $Response['Data'] = @{
                    PSUUser         = $User
                    PSUUserRoles    = if (Get-Variable Roles -ErrorAction SilentlyContinue) { $Roles } else { @() }
                    UserEmail       = $UserProfile.Email
                    UserProfileId   = $UserProfile.ProfileId
                    PSUProfileId    = $UserProfile.PSUProfileId
                    UserFirstName   = $UserProfile.FirstName
                    UserLastName    = $UserProfile.LastName
                    UserTimezone    = $UserProfile.Timezone
                    CreatedOn       = $UserProfile.CreatedOn
                    TOSAccepted     = $UserProfile.TOSAccepted
                    IsAuthenticated = $true
                    Preferences     = $AllUserData.Preferences
                    UserDataPath    = $AllUserData.UserDataPath
                    Entries         = $AllUserData.Entries
                }
            } catch {
                # Handle GetUserProfile exceptions gracefully
                $Response['Message'] = "PSU identity no longer exists for user: $User"
                return $Response
            }
        } catch {
            $Response['Message'] = "Error validating user session: $($_.Exception.Message)"
            # Don't write to error stream for expected exceptions in test environment
        }
        return $Response
    }
}
