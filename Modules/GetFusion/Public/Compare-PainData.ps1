# Function to compare pain data (unified schema v2.0)
function Compare-PainData {
    param($Pain1, $Pain2)

    if (-not $Pain1 -and -not $Pain2) { return 1.0 }
    if (-not $Pain1 -or -not $Pain2) { return 0.0 }

    # Compare pain location and severity
    if ($Pain1.location -eq $Pain2.location) {
        $severityDiff = [math]::Abs($Pain1.severity - $Pain2.severity)
        if ($severityDiff -le 1.0) {
            return 1.0  # Same location, similar severity
        } elseif ($severityDiff -le 2.0) {
            return 0.5  # Same location, moderate difference
        }
    }

    return 0.0  # Different location or very different severity
}
