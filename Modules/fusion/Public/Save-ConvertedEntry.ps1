function Save-ConvertedEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if ($_.ContainsKey('SchemaEntry')) {
                    if (-not $_.SchemaEntry.entry_id -or -not $_.SchemaEntry.user_email) {
                        throw 'SchemaEntry must contain entry_id and user_email properties'
                    } elseif (-not $_.SchemaEntry.date -or -not $_.SchemaEntry.time) {
                        throw 'SchemaEntry must contain data and time properties'
                    } else {
                        return $true
                    }
                }
            })]
        [hashtable]$ConvertedEntry,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ($_ -and -not (Test-Path (Split-Path $_ -Parent))) {
                    throw "Parent directory does not exist: $(Split-Path $_ -Parent)"
                }
                return $true
            })]
        [string]$EntriesPath,
        [parameter(Mandatory = $false)]
        [object[]]$CachedEntries
    )

    Write-Information 'Starting Save-ConvertedEntry'

    # Handle new schema format
    if ($ConvertedEntry.ContainsKey('SchemaEntry')) {
        $schemaEntry = $ConvertedEntry.SchemaEntry
        $entryId = [string]$schemaEntry.entry_id  # Ensure it's treated as a string

        # Determine save path based on user email if not provided
        if (-not $EntriesPath) {
            $EntriesPath = Get-UserEntriesPath -UserEmail $schemaEntry.user_email
        }

        # Load existing entries
        $Entries = if ($CachedEntries) {
            $CachedEntries
        } else {
            Get-CachedEntriesData -EntriesPath $EntriesPath
        }

        # Save entry using composite key (ensure key is string)
        $Entries += $schemaEntry

        # Save the entries
        Write-Information "Saving new schema entry to $EntriesPath"
        $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8

        Write-Information 'New schema entry saved successfully'
        return $true
    }

    # Legacy format handling (backward compatibility)
    # if (-not $EntriesPath) {
    #     throw 'EntriesPath is required for legacy format entries'
    # }

    # # Load existing entries
    # $Entries = @{}
    # if (Test-Path $EntriesPath) {
    #     $Entries = Get-Content -Path $EntriesPath | ConvertFrom-Json -AsHashtable
    # }

    # # Extract date and timestamp from the converted entry (handle both naming conventions)
    # $Date = if ($ConvertedEntry.ContainsKey('Date')) { $ConvertedEntry.Date } else { $ConvertedEntry.date }
    # $Timestamp = if ($ConvertedEntry.ContainsKey('Timestamp')) { $ConvertedEntry.Timestamp } else { $ConvertedEntry.timestamp }
    # $EntryStructure = $ConvertedEntry.EntryStructure

    # Write-Information "Saving entry for Date: $Date, Timestamp: $Timestamp"

    # # Add to entries structure
    # if (-not $Entries.ContainsKey($Date)) {
    #     $Entries[$Date] = @{}
    # }

    # $Entries[$Date][$Timestamp] = $EntryStructure

    # # Add all date-level fields from FullEntry if present
    # if ($ConvertedEntry.FullEntry[$Date]) {
    #     $dateLevelFields = @('Sleep', 'ScarImage')  # Could be expanded
    #     foreach ($field in $dateLevelFields) {
    #         if ($ConvertedEntry.FullEntry[$Date].ContainsKey($field)) {
    #             $Entries[$Date][$field] = $ConvertedEntry.FullEntry[$Date][$field]
    #         }
    #     }
    # }

    # # Update the daily max pain level
    # Write-Information "Updating daily max pain level for $Date"
    # $null = Update-DailyMaxPainLevel -Entries $Entries -Date $Date

    # # Save the entries
    # Write-Information "Saving entries to $EntriesPath"
    # $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8

    # Write-Information 'Entry saved successfully'
    # return $true
}
