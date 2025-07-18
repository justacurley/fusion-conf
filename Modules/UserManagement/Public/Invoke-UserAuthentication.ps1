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
            # Ensure the UserManagement module is imported
            if (-not (Get-Module UserManagement)) {
                Import-Module UserManagement -Force
            }

            $UserExists = Test-PSUUserExists -Email $Email
            if (! $UserExists) {
                return $Response
            }

            try {
                $UserProfile = [UserProfile]::GetUserProfile($Email)
                $Response['Success'] = $true
                $Response['Message'] = "Profile for $Email was found"
                $Response['UserProfile'] = $UserProfile
            } catch {
                # Handle GetUserProfile exceptions gracefully without writing to error stream
                $Response['Message'] = "Profile for $Email was not found"
                return $Response
            }
        } catch {
            # Only write to error stream for unexpected exceptions
            $Response['Message'] = "Error during authentication: $($_.Exception.Message)"
            Write-Error $_
        }
        return $Response
    }
}
