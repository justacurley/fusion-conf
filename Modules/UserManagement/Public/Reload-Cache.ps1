# Updates cache from file
function Reload-Cache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $UserEmail
    )
    end {
        try {
            # Ensure the UserManagement module is imported
            if (-not (Get-Module UserManagement)) {
                Write-Information "Importing UserManagement module again"
                Import-Module UserManagement -Force
            }
            $UserData = Get-CurrentUser
            $CacheKey = "UserContext_$($UserEmail)"
            Remove-PSUCache -Key $CacheKey
            Set-UserCacheData -UserData $UserData.Data
            Show-UDToast -Message 'User cache reloaded with latest data' -MessageColor green -Duration 3000
        }
        catch {
            Show-UDToast -Message "Failed to reload cache $($_.Exception.Message)" -MessageColor red -Duration 3000
            throw $_
        }
    }
}
