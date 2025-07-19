function Initialize-UserContext {
    [CmdletBinding()]
    param (
        [string]$UserEmail,
        [int]$ExpirationHours = 1,
        [switch]$SuppressToast,
        [bool]$UpdateCache = $false
    )
    end {
        # Check if user is authenticated
        if ([string]::IsNullOrEmpty($UserEmail)) {
            if (-not $SuppressToast) {
                Show-UDToast -Message 'No user session found. Please log in.' -MessageColor red -Duration 5000
            }
            return $null
        }

        $UserData = $null

        if ($UpdateCache) {
            try {
                $CurrentUser = Get-CurrentUser
                if ($CurrentUser.Success) {
                    $UserData = $CurrentUser.Data
                    # Set cache for future requests
                    Set-UserCacheData -UserData $UserData -ExpirationHours $ExpirationHours
                    if (-not $SuppressToast) {
                        Show-UDToast -Message 'User data loaded and cached successfully' -MessageColor green -Duration 3000
                    }
                    return $UserData
                }
                else {
                    throw "Failed to get current user: $($CurrentUser.Message)"
                }
            }
            catch {
                Write-Warning "Failed to load user data: $($_.Exception.Message)"
                if (-not $SuppressToast) {
                    Show-UDToast -Message 'Warning: User data not available. Using default view.' -MessageColor orange -Duration 5000
                    Show-UDToast -Message 'Please try refreshing the page.' -MessageColor orange -Duration 5000
                }
            }
        }
        try {
            # Try to get cached user data first
            $UserData = Get-UserCacheData $UserEmail -EA Stop
            if ($null -eq $UserData) { throw }
            if (-not $SuppressToast) {
                Show-UDToast -Message 'User data loaded from cache' -MessageColor green -Duration 3000
            }
        }
        catch {
            Write-Warning "Cache miss for user $UserEmail, attempting to load and cache user data"

            # Cache miss - load user data and set cache
            try {
                $CurrentUser = Get-CurrentUser
                if ($CurrentUser.Success) {
                    $UserData = $CurrentUser.Data
                    # Set cache for future requests
                    Set-UserCacheData -UserData $UserData -ExpirationHours $ExpirationHours
                    if (-not $SuppressToast) {
                        Show-UDToast -Message 'User data loaded and cached successfully' -MessageColor green -Duration 3000
                    }
                }
                else {
                    throw "Failed to get current user: $($CurrentUser.Message)"
                }
            }
            catch {
                Write-Warning "Failed to load user data: $($_.Exception.Message)"
                if (-not $SuppressToast) {
                    Show-UDToast -Message 'Warning: User data not available. Using default view.' -MessageColor orange -Duration 5000
                    Show-UDToast -Message 'Please try refreshing the page.' -MessageColor orange -Duration 5000
                }
            }
        }

        return $UserData
    }
}
