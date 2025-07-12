function Set-UserCacheData {
    [CmdletBinding()]
    param (
        [ValidateScript({ -not [string]::IsNullOrEmpty($_.UserEmail) })]
        [PSCustomObject]$UserData,
        [ValidateScript({ $_ -gt 0 })]
        [int]$ExpirationHours = 1
    )
    end {
        try {
            $CacheKey = "UserContext_$($UserData.UserEmail)"
            $CacheValue = $UserData | ConvertTo-Json -Compress
            Set-PSUCache -Key $CacheKey -Value $CacheValue -AbsoluteExpiration (Get-Date).AddHours($ExpirationHours) -ErrorAction Stop
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Failed to set cache for user $($UserData.UserEmail): $errorMessage"
            # Don't throw - cache failures shouldn't break the application
        }
    }
}
