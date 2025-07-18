function Get-CachedEntriesData {
    <#
    .SYNOPSIS
    Gets entries data from PSU cache or file with automatic cache management

    .DESCRIPTION
    This function attempts to load entries data from PSU cache first, falling back to file if cache is empty.
    It handles PSCustomObject to hashtable conversion and updates the cache when loading from file.

    .PARAMETER EntriesPath
    The full path to the user's entries.json file (required for multi-user support)

    .PARAMETER CacheKey
    The PSU cache key to use. Defaults to 'entriesData'

    .PARAMETER ForceReload
    If true, bypasses cache and loads directly from file, then updates cache

    .EXAMPLE
    $entries = Get-CachedEntriesData -EntriesPath "/home/alex/data/users/user@example.com/health-data/entries.json"

    .EXAMPLE
    $entries = Get-CachedEntriesData -EntriesPath $userEntriesPath -ForceReload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                $parentDir = Split-Path $_ -Parent
                if (-not (Test-Path $parentDir)) {
                    throw "Parent directory does not exist: $parentDir"
                }
                $true
            })]
        [string]$EntriesPath,

        [Parameter(Mandatory = $false)]
        [string]$CacheKey = 'entriesData',

        [Parameter(Mandatory = $false)]
        [switch]$ForceReload
    )

    try {
        $AllEntries = $null

        # Try to get from cache unless force reload is requested
        if (-not $ForceReload) {
            try {
                $AllEntries = Get-PSUCache -Key $CacheKey
                Write-Information "Attempted to load from PSU cache with key: $CacheKey"
            }
            catch {
                Write-Information "PSU cache not available or failed: $($_.Exception.Message)"
            }
        }

        if (-not $AllEntries -or $ForceReload) {
            # Fallback to loading from file if cache is empty or force reload requested
            Write-Information 'Loading entries from file (cache empty or force reload)'

            if (-not (Test-Path $EntriesPath)) {
            Write-Information "Entries file does not exist, creating empty structure: $EntriesPath"
            # Create directory if it doesn't exist
            $parentDir = Split-Path $EntriesPath -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
            }
            # Create empty entries file
            @{} | ConvertTo-Json -Depth 1 | Out-File $EntriesPath -Encoding UTF8
            # Initialize with empty hashtable - ensure it's not null
            $AllEntries = @{}
        } else {
            $content = Get-Content -Path $EntriesPath -Raw
            if ([string]::IsNullOrWhiteSpace($content)) {
                # Handle empty file
                $AllEntries = @{}
            } else {
                $AllEntries = $content | ConvertFrom-Json -AsHashtable
            }
        }

            # Update cache for next time (only if PSU cache is available)
            try {
                Set-PSUCache -Key $CacheKey -Value $AllEntries -AbsoluteExpiration (Get-Date).AddDays(1)
                Write-Information "Updated PSU cache with key: $CacheKey"
            }
            catch {
                Write-Information "Could not update PSU cache: $($_.Exception.Message)"
            }
        }
        else {
            Write-Information 'Loaded entries from PSU cache'

            # Convert PSCustomObject to hashtable if needed
            if ($AllEntries -is [System.Management.Automation.PSCustomObject]) {
                Write-Information 'Converting cached PSCustomObject to hashtable'
                $AllEntries = $AllEntries | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
            }
        }

        return $AllEntries

    }
    catch {
        Write-Error "Error in Get-CachedEntriesData: $($_.Exception.Message)"
        throw
    }
}
