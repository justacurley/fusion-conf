function Clear-UserSession {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success          = $false
            Message          = 'Failed to clear user session'
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
                } catch {
                    # Variable doesn't exist or can't be removed - this is OK
                    Write-Verbose "Session variable $Variable not found or could not be removed: $($_.Exception.Message)"
                }
            }

            $Response['Success'] = $true
            $Response['Message'] = "User session cleared successfully. Cleared variables: $($ClearedVariables -join ', ')"
            $Response['ClearedVariables'] = $ClearedVariables
        } catch {
            $Response['Message'] = "Error clearing user session: $($_.Exception.Message)"
            $Response['ClearedVariables'] = @()  # Ensure it's always an array
            Write-Error "Error in Clear-UserSession: $($_.Exception.Message)"
        }
        return $Response
    }
}
