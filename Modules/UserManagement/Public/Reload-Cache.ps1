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
            $UserData = Get-CurrentUser
            Write-Information "Got user file: $($UserData.Data.Keys)"
            $CacheKey = "UserContext_$($UserEmail)"
            Remove-PSUCache -Key $CacheKey
            Write-Information "Removed $CacheKey"
            Set-UserCacheData -UserData $UserData.Data
            Show-UDToast -Message 'User data reloaded from cache' -MessageColor green -Duration 3000
        }
        catch {
            Show-UDToast -Message "Failed to reload cache $($_.Exception.Message)" -MessageColor red -Duration 3000
            throw $_
        }
    }
}
