function Remove-TimeEntry {
    <#
    .SYNOPSIS
    Removes a timestamped entry from a specific date in the entries data

    .DESCRIPTION
    This function safely removes a timestamped entry (e.g., "1430", "0800") from a specific date (MMDD format)
    in the entries.json file. It includes validation, backup options, and automatic cache updates.

    .PARAMETER Date
    The date in MMDD format (e.g., "0701", "1225") from which to remove the entry

    .PARAMETER Time
    The timestamp in HHMM format (e.g., "1430", "0800") to remove from the specified date

    .PARAMETER EntriesPath
    The full path to the user's entries.json file (required for multi-user support)

    .PARAMETER CreateBackup
    Optional. If true, creates a backup of the entries file before making changes. Default is true

    .PARAMETER UpdateCache
    Optional. If true, updates the PSU cache after successful removal. Default is true

    .EXAMPLE
    Remove-TimeEntry -Date "0701" -Time "1430" -EntriesPath "/home/alex/data/users/user@example.com/health-data/entries.json"

    .EXAMPLE
    Remove-TimeEntry -Date "1225" -Time "0800" -EntriesPath $userEntriesPath -WhatIf

    .EXAMPLE
    Remove-TimeEntry -Date "0615" -Time "2130" -EntriesPath $userEntriesPath -CreateBackup:$false

    .OUTPUTS
    Returns $true if the entry was successfully removed, $false otherwise
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d{4}$')]
        [string]$Date,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d{3,4}$')]
        [string]$Time,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path (Split-Path $_ -Parent))) {
                    throw "Parent directory does not exist: $(Split-Path $_ -Parent)"
                }
                return $true
            })]
        [string]$EntriesPath,

        [Parameter(Mandatory = $false)]
        [bool]$CreateBackup = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UpdateCache = $true
    )

    try {
        Write-Information "Starting Remove-TimeEntry for Date: $Date, Time: $Time"

        # Validate entries file exists
        if (-not (Test-Path $EntriesPath)) {
            throw "Entries file not found at path: $EntriesPath"
        }

        # Load existing entries
        Write-Information "Loading entries from: $EntriesPath"
        $Entries = Get-Content -Path $EntriesPath | ConvertFrom-Json -AsHashtable

        # Validate that the date exists
        if (-not $Entries.ContainsKey($Date)) {
            Write-Warning "Date '$Date' not found in entries data"
            return $false
        }

        # Normalize time format (ensure 4 digits)
        $NormalizedTime = if ($Time.Length -eq 3) { "0$Time" } else { $Time }

        # Validate that the timestamp exists
        if (-not $Entries[$Date].ContainsKey($NormalizedTime)) {
            Write-Warning "Timestamp '$NormalizedTime' not found in date '$Date'"
            return $false
        }

        # Get the entry details for logging
        $EntryToRemove = $Entries[$Date][$NormalizedTime]
        $EntryJson = $EntryToRemove | ConvertTo-Json -Depth 5 -Compress

        Write-Information "Found entry to remove: $EntryJson"

        # WhatIf processing (using built-in SupportsShouldProcess)
        if ($WhatIfPreference) {
            Write-Host "WhatIf: Would remove timestamp '$NormalizedTime' from date '$Date'" -ForegroundColor Yellow
            Write-Host "Entry content: $EntryJson" -ForegroundColor Cyan
            return $true
        }

        # ShouldProcess check for -Confirm parameter
        $shouldProcessMessage = "Remove timestamp '$NormalizedTime' from date '$Date'"
        if (-not $PSCmdlet.ShouldProcess($shouldProcessMessage, 'Remove-TimeEntry')) {
            Write-Information 'Operation cancelled by user'
            return $false
        }

        # Create backup if requested
        if ($CreateBackup) {
            $BackupPath = "$EntriesPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Information "Creating backup at: $BackupPath"
            Copy-Item -Path $EntriesPath -Destination $BackupPath -Force
        }

        # Remove the timestamp entry
        Write-Information "Removing timestamp '$NormalizedTime' from date '$Date'"
        $Entries[$Date].Remove($NormalizedTime)

        # If this was the last timestamp for the date, optionally remove the entire date
        $remainingTimeEntries = $Entries[$Date].Keys | Where-Object { $_ -match '^\d{3,4}$' }
        if ($remainingTimeEntries.Count -eq 0) {
            # Check if there are any non-timestamp entries (Sleep, max_pain_level, ScarImage)
            $nonTimeEntries = $Entries[$Date].Keys | Where-Object { $_ -notmatch '^\d{3,4}$' }
            if ($nonTimeEntries.Count -eq 0) {
                Write-Information "No remaining entries for date '$Date', removing entire date entry"
                $Entries.Remove($Date)
            }
            else {
                Write-Information "Date '$Date' still has non-timestamp entries: $($nonTimeEntries -join ', ')"
            }
        }

        # Recalculate daily max pain level if there are still time entries for this date
        if ($Entries.ContainsKey($Date)) {
            Write-Information "Recalculating daily max pain level for date '$Date'"
            $null = Update-DailyMaxPainLevel -Entries $Entries -Date $Date
        }

        # Save the updated entries
        Write-Information "Saving updated entries to: $EntriesPath"
        $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8

        # Update cache if requested and PSU is available
        if ($UpdateCache) {
            try {
                Write-Information 'Updating PSU cache'
                Set-PSUCache -Key 'entriesData' -Value $Entries -AbsoluteExpiration (Get-Date).AddDays(1)
            }
            catch {
                Write-Information "Could not update PSU cache (not in PSU environment): $($_.Exception.Message)"
            }
        }

        Write-Information "Successfully removed timestamp '$NormalizedTime' from date '$Date'"
        return $true

    }
    catch {
        Write-Error "Error in Remove-TimeEntry: $($_.Exception.Message)"
        throw
    }
}
