function Update-DailyMaxPainLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Entries,

        [Parameter(Mandatory = $true)]
        [string]$Date
    )

    # Calculate the maximum pain level for all entries in the given date
    $maxPainForDay = 0.0

    # Handle new schema format (composite keys)
    $dateEntries = $Entries.Keys | Where-Object { $_ -match "^\d{2}$([datetime]::ParseExact($Date, 'MMdd', $null).ToString('MMdd'))\d{4}$" }

    if ($dateEntries) {
        foreach ($entryId in $dateEntries) {
            $entry = $Entries[$entryId]
            if ($entry -is [hashtable] -and $entry.ContainsKey('data') -and $entry.data.ContainsKey('pain')) {
                $painArray = $entry.data.pain
                if ($painArray -is [array]) {
                    foreach ($painEntry in $painArray) {
                        if ($painEntry -is [hashtable] -and $painEntry.ContainsKey('severity')) {
                            try {
                                $level = [double]$painEntry['severity']
                                if ($level -gt $maxPainForDay) {
                                    $maxPainForDay = $level
                                }
                            }
                            catch {
                                Write-Warning "Invalid pain severity data for entry $entryId - skipping"
                            }
                        }
                    }
                }
            }
        }
    }

    # Handle legacy format (backward compatibility)
    if ($Entries.ContainsKey($Date)) {
        foreach ($timestamp in $Entries[$Date].Keys) {
            # Skip non-timestamp entries like "Sleep", "ScarImage", "max_pain_level"
            if ($timestamp -match '^\d{4}$') {
                $entry = $Entries[$Date][$timestamp]
                if ($entry -is [hashtable] -and $entry.ContainsKey('Pain') -and $entry.Pain) {
                    if ($entry.Pain -is [hashtable]) {
                        foreach ($location in $entry.Pain.Keys) {
                            $painData = $entry.Pain[$location]
                            if ($painData -is [hashtable] -and $painData.ContainsKey('pain_level')) {
                                try {
                                    $level = [double]$painData['pain_level']
                                    if ($level -gt $maxPainForDay) {
                                        $maxPainForDay = $level
                                    }
                                }
                                catch {
                                    Write-Warning "Invalid pain level data for $Date/$timestamp/$location - skipping"
                                }
                            }
                        }
                    }
                }
            }
        }

        # Set the daily max pain level at the date level (legacy format)
        $Entries[$Date]['max_pain_level'] = $maxPainForDay
    }

    Write-Information "Updated daily max pain level for $Date : $maxPainForDay"
    return $maxPainForDay
}
