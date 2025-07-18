# Function to extract activity data (unified schema v2.0)
function Get-DateActivityData {
    param([string]$date, $entries)

    # Initialize Activities array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Activities')) {
        $global:DistinctDataValues['Activities'] = @()
    }

    $activities = @()

    # Get all activity entries for the specified date - updated for schema v2.0
    $dateEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "activities" }

    foreach ($entry in $dateEntries) {
        if ($entry.data.activities) {
            # Handle activities as array in schema v2.0
            foreach ($activity in $entry.data.activities) {
                $activityName = $activity.name

                # Track unique activities in global variable
                if ($global:DistinctDataValues['Activities'] -notcontains $activityName) {
                    $global:DistinctDataValues['Activities'] += $activityName
                }

                $activityWithContext = [PSCustomObject]@{
                    Date      = $entry.date
                    Timestamp = $entry.time
                    EntryId   = $entry.entry_id
                    Activity  = $activityName
                    Note      = $activity.note
                    Duration  = $activity.duration_minutes
                    Notes     = $entry.notes
                }
                $activities += $activityWithContext
            }
        }
    }

    return $activities
}
