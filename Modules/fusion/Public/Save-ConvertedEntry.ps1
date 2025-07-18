function Save-ConvertedEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                # Check for new schema format
                if ($_.ContainsKey('SchemaEntry')) {
                    $schemaEntry = $_.SchemaEntry
                    if (-not $schemaEntry.entry_id -or -not $schemaEntry.user_email) {
                        throw 'SchemaEntry must contain entry_id and user_email properties'
                    }
                    return $true
                }

                # Check for legacy format (backward compatibility)
                $hasDate = $_.ContainsKey('Date') -or $_.ContainsKey('date')
                $hasTimestamp = $_.ContainsKey('Timestamp') -or $_.ContainsKey('timestamp')

                if (-not $hasDate -or -not $hasTimestamp) {
                    throw 'ConvertedEntry must contain Date/date and Timestamp/timestamp properties or SchemaEntry'
                }

                $dateValue = if ($_.ContainsKey('Date')) { $_.Date } else { $_.date }
                $timestampValue = if ($_.ContainsKey('Timestamp')) { $_.Timestamp } else { $_.timestamp }

                if ([string]::IsNullOrWhiteSpace($dateValue) -or [string]::IsNullOrWhiteSpace($timestampValue)) {
                    throw 'Date and Timestamp values cannot be null or empty'
                }
                return $true
            })]
        [hashtable]$ConvertedEntry,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ($_ -and -not (Test-Path (Split-Path $_ -Parent))) {
                    throw "Parent directory does not exist: $(Split-Path $_ -Parent)"
                }
                return $true
            })]
        [string]$EntriesPath
    )

    Write-Information 'Starting Save-ConvertedEntry'

    # Handle new schema format
    if ($ConvertedEntry.ContainsKey('SchemaEntry')) {
        $schemaEntry = $ConvertedEntry.SchemaEntry
        $entryId = $schemaEntry.entry_id

        # Determine save path based on user email if not provided
        if (-not $EntriesPath) {
            $EntriesPath = Get-UserEntriesPath -UserEmail $schemaEntry.user_email
        }

        # Load existing entries
        $Entries = Get-CachedEntriesData -EntriesPath $EntriesPath

        # Save entry using composite key
        $Entries[$entryId] = $schemaEntry

        # Save the entries
        Write-Information "Saving new schema entry to $EntriesPath"
        $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8

        Write-Information 'New schema entry saved successfully'
        return $true
    }

    # Legacy format handling (backward compatibility)
    if (-not $EntriesPath) {
        throw 'EntriesPath is required for legacy format entries'
    }

    # Load existing entries
    $Entries = @{}
    if (Test-Path $EntriesPath) {
        $Entries = Get-Content -Path $EntriesPath | ConvertFrom-Json -AsHashtable
    }

    # Extract date and timestamp from the converted entry (handle both naming conventions)
    $Date = if ($ConvertedEntry.ContainsKey('Date')) { $ConvertedEntry.Date } else { $ConvertedEntry.date }
    $Timestamp = if ($ConvertedEntry.ContainsKey('Timestamp')) { $ConvertedEntry.Timestamp } else { $ConvertedEntry.timestamp }
    $EntryStructure = $ConvertedEntry.EntryStructure

    Write-Information "Saving entry for Date: $Date, Timestamp: $Timestamp"

    # Add to entries structure
    if (-not $Entries.ContainsKey($Date)) {
        $Entries[$Date] = @{}
    }

    $Entries[$Date][$Timestamp] = $EntryStructure

    # Add all date-level fields from FullEntry if present
    if ($ConvertedEntry.FullEntry[$Date]) {
        $dateLevelFields = @('Sleep', 'ScarImage')  # Could be expanded
        foreach ($field in $dateLevelFields) {
            if ($ConvertedEntry.FullEntry[$Date].ContainsKey($field)) {
                $Entries[$Date][$field] = $ConvertedEntry.FullEntry[$Date][$field]
            }
        }
    }

    # Update the daily max pain level
    Write-Information "Updating daily max pain level for $Date"
    $null = Update-DailyMaxPainLevel -Entries $Entries -Date $Date

    # Save the entries
    Write-Information "Saving entries to $EntriesPath"
    $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8

    Write-Information 'Entry saved successfully'
    return $true
}
