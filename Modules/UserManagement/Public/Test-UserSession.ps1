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

            $Response['Message'] = "Found user for existing session of $User"
            $Response['Success'] = $true
        } catch {
            $Response['Message'] = "Error validating user session: $($_.Exception.Message)"
            # Don't write to error stream for expected exceptions in test environment
        }
        return $Response
    }
}
