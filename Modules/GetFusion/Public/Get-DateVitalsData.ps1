# Function to extract vitals data (unified schema v2.0)
function Get-DateVitalsData {
    param([string]$date, $entries)

    $vitals = @()

    # Get all vitals entries for the specified date
    $dateEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "vitals" }

    foreach ($entry in $dateEntries) {
        if ($entry.data.vitals) {
            $vitalsData = $entry.data.vitals

            # Blood pressure
            if ($vitalsData.blood_pressure) {
                $bprWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Blood Pressure'
                    Vital     = $vitalsData.blood_pressure
                    Notes     = $entry.notes
                }
                $vitals += $bprWithContext
            }

            # Oxygen saturation
            if ($vitalsData.oxygen_saturation) {
                $o2WithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Oxygen Saturation'
                    Vital     = "$($vitalsData.oxygen_saturation)%"
                    Notes     = $entry.notes
                }
                $vitals += $o2WithContext
            }

            # Heart rate
            if ($vitalsData.heart_rate) {
                $hrWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Heart Rate'
                    Vital     = "$($vitalsData.heart_rate) bpm"
                    Notes     = $entry.notes
                }
                $vitals += $hrWithContext
            }

            # Temperature
            if ($vitalsData.temperature) {
                $tempWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    VitalType = 'Temperature'
                    Vital     = "$($vitalsData.temperature)°F"
                    Notes     = $entry.notes
                }
                $vitals += $tempWithContext
            }
        }
    }

    return $vitals
}
