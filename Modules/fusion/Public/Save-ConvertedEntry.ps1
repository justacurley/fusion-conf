function Save-ConvertedEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                # Check for both possible key names (Date/Timestamp or date/timestamp)
                $hasDate = $_.ContainsKey('Date') -or $_.ContainsKey('date')
                $hasTimestamp = $_.ContainsKey('Timestamp') -or $_.ContainsKey('timestamp')

                if (-not $hasDate -or -not $hasTimestamp) {
                    throw 'ConvertedEntry must contain Date/date and Timestamp/timestamp properties'
                }

                $dateValue = if ($_.ContainsKey('Date')) { $_.Date } else { $_.date }
                $timestampValue = if ($_.ContainsKey('Timestamp')) { $_.Timestamp } else { $_.timestamp }

                if ([string]::IsNullOrWhiteSpace($dateValue) -or [string]::IsNullOrWhiteSpace($timestampValue)) {
                    throw 'Date and Timestamp values cannot be null or empty'
                }
                return $true
            })]
        [hashtable]$ConvertedEntry,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path (Split-Path $_ -Parent))) {
                    throw "Parent directory does not exist: $(Split-Path $_ -Parent)"
                }
                return $true
            })]
        [string]$EntriesPath
    )

    Write-Information 'Starting Save-ConvertedEntry'

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
