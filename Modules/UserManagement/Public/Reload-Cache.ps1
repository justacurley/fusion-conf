# Updates cache from file
function Reload-Cache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $UserEmail
    )
    end {
        $Response = @{
            Success = $false
            Message = 'Failed to update user cache'
            Data    = @{}
        }
        try {
            # Ensure the UserManagement module is imported
            if (-not (Get-Module UserManagement)) {
                Import-Module UserManagement -Force
            }
            $UserFile = [UserProfile]::GetUserProfile($UserEmail)
            $CacheKey = "UserContext_$($UserEmail)"
            Remove-PSUCache -Key $CacheKey
            Set-UserCacheData -UserData $UserFile
        }
        catch {
            throw $_
        }
    }
}
