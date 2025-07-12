function Get-UserCacheData {
    [CmdletBinding()]
    param (
        # This is the postfix of the cachekey
        [string]$UserEmail
    )
    end {
        try {
            $CacheKey = "UserContext_$UserEmail"
            $CacheJson = Get-PSUCache -Key $CacheKey -ErrorAction Stop
            Write-Information "Raw cache data: $CacheJson"
            Write-Information "Cache data type: $($CacheJson.GetType())"

            if (-not $CacheJson) {
                Write-Warning "No cache data found for key: $CacheKey"
                throw "Cache miss"
            }

            # Deserialize the JSON back to an object
            $Cache = $CacheJson | ConvertFrom-Json
            Write-Information "Deserialized cache data type: $($Cache.GetType())"

            return $Cache
        } catch {
            $errorMessage = $_.Exception.Message
            Write-Warning "Failed to retrieve cache for user $UserEmail : $errorMessage"
            return $null
        }
    }
}
