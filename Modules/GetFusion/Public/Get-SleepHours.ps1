# Function to parse sleep data from various formats
function Get-SleepHours {
    param([string]$sleepValue)

    if ([string]::IsNullOrEmpty($sleepValue)) {
        return $null
    }

    # Parse "HH:MM" format like "7:39", "9:10", "6:03"
    if ($sleepValue -match '^(\d+):(\d+)$') {
        $hours = [int]$matches[1]
        $minutes = [int]$matches[2]
        return [math]::Round($hours + ($minutes / 60.0), 2)
    }
    # Handle decimal format like "7.5"
    elseif ($sleepValue -match '^(\d+(?:\.\d+)?)$') {
        return [double]$matches[1]
    }

    return $null
}
