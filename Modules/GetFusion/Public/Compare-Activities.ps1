# Function to compare activity data (unified schema v2.0)
function Compare-Activities {
    param($Act1, $Act2)

    if (-not $Act1 -and -not $Act2) { return 1.0 }
    if (-not $Act1 -or -not $Act2) { return 0.0 }

    # Compare activity name and duration - updated for schema v2.0
    if ($Act1.name -eq $Act2.name) {
        $durationDiff = [math]::Abs($Act1.duration_minutes - $Act2.duration_minutes)
        if ($durationDiff -le 5) {
            return 1.0  # Same activity, similar duration
        } elseif ($durationDiff -le 15) {
            return 0.5  # Same activity, moderate difference
        }
    }

    return 0.0  # Different activity or very different duration
}
