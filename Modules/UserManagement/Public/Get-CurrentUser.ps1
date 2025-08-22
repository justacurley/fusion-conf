function Get-CurrentUser {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = 'Failed to get current user'
            Data    = @{}
        }
        try {
            # Ensure the UserManagement module is imported
            if (-not (Get-Module UserManagement)) {
                Import-Module UserManagement -Force
            }

            # First check if we have a valid session
            if ( -not (Test-UserSession).Success) {
                throw "No valid user session found"
            }

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
            $Response['Message'] = "Error retrieving current user: $($_.Exception.Message)"
        }
        return $Response
    }
}
