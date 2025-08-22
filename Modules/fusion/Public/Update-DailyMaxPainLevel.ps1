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

    # Handle new schema format (composite keys) - schema v2.0 only
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

    Write-Information "Updated daily max pain level for $Date : $maxPainForDay"
    return $maxPainForDay
}
