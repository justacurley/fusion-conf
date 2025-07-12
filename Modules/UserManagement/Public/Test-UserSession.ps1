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
            $AllUserData = [UserProfile]::GetUserProfile($User)
            $UserProfile = $AllUserData.Profile
            if ($AllUserData -eq $false -or $null -eq $AllUserData) {
                $Response['Message'] = "User profile not found for PSU user: $User"
                return $Response
            }

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
                Entries         = $AllUSerData.Entries
            }
        } catch {
            $Response['Message'] = "Error validating user session: $($_.Exception.Message)"
            Write-Error "Error in Test-UserSession: $($_.Exception.Message)"
        }
        return $Response
    }
}
