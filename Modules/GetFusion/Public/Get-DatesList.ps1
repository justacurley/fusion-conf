# Function to get sorted list of dates from entries (unified schema v2.0)
function Get-DatesList {
    param($entries)

    # Return cached dates if available
    if ($null -ne $global:DatesList) {
        return $global:DatesList
    }

    # Extract and sort unique dates from unified schema v2.0
    $dates = $entries | ForEach-Object { $_.date } | Sort-Object -Unique
    $global:DatesList = $dates
    return $global:DatesList
}
