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
            # First check if we have a valid session
            $SessionCheck = Test-UserSession
            if (-not $SessionCheck.Success) {
                $Response['Message'] = "No valid user session found: $($SessionCheck.Message)"
                return $Response
            }

            # Use the data from Test-UserSession since it already validates and extracts everything
            $CurrentUser = $SessionCheck.Data

            $Response['Success'] = $true
            $Response['Message'] = 'Current user retrieved successfully'
            $Response['Data'] = $CurrentUser
        } catch {
            $Response['Message'] = "Error retrieving current user: $($_.Exception.Message)"
            Write-Error "Error in Get-CurrentUser: $($_.Exception.Message)"
        }
        return $Response
    }
}
