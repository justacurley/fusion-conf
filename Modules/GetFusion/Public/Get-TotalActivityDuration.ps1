# Function to calculate total activity duration for a date (unified schema v2.0)
function Get-TotalActivityDuration {
    param([string]$date, $entries)

    $activityEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "activities" }

    if ($activityEntries) {
        $totalDuration = 0
        foreach ($entry in $activityEntries) {
            if ($entry.data.activities) {
                # Handle activities as array in schema v2.0
                foreach ($activity in $entry.data.activities) {
                    $totalDuration += $activity.duration_minutes
                }
            }
        }
        return $totalDuration
    }

    return $null
}
