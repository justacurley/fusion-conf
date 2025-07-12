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
            $UserProfile = [UserProfile]::GetUserProfile($Email)
            if ($UserProfile -eq $false -or $null -eq $UserProfile) {
                $Response['Message'] = "Profile.json was not found for $Email"
                return $Response
            }
            $Response['Success'] = $true
            $Response['Message'] = "Profile for $Email was found"
            $Response['UserProfile'] = $UserProfile
        } catch {
            Write-Error $_
        }
        return $Response
    }
}
