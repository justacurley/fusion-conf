function Get-UserCacheData {
    [CmdletBinding()]
    param (
        # This is the postfix of the cachekey
        [string]$UserEmail
    )
    end {
        try {
            $CacheKey = "UserContext_$UserEmail"
            $Cache = Get-PSUCache -Key $CacheKey -ErrorAction Stop
            Write-Information ($Cache)
            Write-Informaiton ($Cache.GetType())
            if (! $Cache) {
                Write-Warning "No cache data found for key: $CacheKey"
                throw
            }
            return $Cache
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Failed to retrieve cache for user $UserEmail : $errorMessage"
            return $null
        }
    }
}
