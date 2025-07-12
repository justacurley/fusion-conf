function Set-UserSession {
    [CmdletBinding()]
    param (
        [PSCustomObject]$UserProfile  # The profile object from authentication
    )
    # NOTE: This function sets custom session variables for compatibility but these
    # variables do NOT persist across PSU contexts (authentication -> dashboard).
    # Primary session validation now relies on PSU's $User variable and dynamic profile loading.
    $Response = @{
        Success = $false
        Message = 'Failed to extract one or more properties from user profile'
    }
    try {
        Write-Verbose "Setting UserProfileId to: $($UserProfile.ProfileId)"
        Write-Verbose "ProfileId type: $($UserProfile.ProfileId.GetType().Name)"
        Write-Verbose 'NOTE: Custom session variables do not persist between authentication and dashboard contexts'
        $Session:UserEmail = $UserProfile.Email
        $Session:UserProfileId = $UserProfile.ProfileId
        $Session:PSUProfileId = $UserProfile.PSUProfileId
        $Session:UserFirstName = $UserProfile.FirstName
        $Session:UserLastName = $UserProfile.LastName
        $Session:UserTimezone = $UserProfile.Timezone
        $Session:LoginTime = (Get-Date)
        $Session:IsAuthenticated = $true
        $Response['Success'] = $true
        $Response['Message'] = 'Set all required session variables (for authentication context only)'
    } catch {
        Write-Error $_
    }
    return $Response
}
