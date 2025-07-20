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
                Write-Information "Importing UserManagement module again"
                Import-Module UserManagement -Force
            }
            $UserFile = [UserProfile]::GetUserProfile($UserEmail)
            Write-Information "Got user file"
            $CacheKey = "UserContext_$($UserEmail)"
            Remove-PSUCache -Key $CacheKey
            Write-Information "Removed $CacheKey"
            Set-UserCacheData -UserData $UserFile
            Show-UDToast -Message 'User data reloaded from cache' -MessageColor green -Duration 3000
        }
        catch {
            Show-UDToast -Message "Failed to reload cache $($_.Exception.Message)" -MessageColor red -Duration 3000
            throw $_
        }
    }
}
