function Update-DailyMaxPainLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Entries,

        [Parameter(Mandatory = $true)]
        [string]$Date
    )

    # Calculate the maximum pain level for all timestamps in the given date
    $maxPainForDay = 0.0

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

        # Set the daily max pain level at the date level
        $Entries[$Date]['max_pain_level'] = $maxPainForDay
    }

    Write-Information "Updated daily max pain level for $Date : $maxPainForDay"
    return $maxPainForDay
}
