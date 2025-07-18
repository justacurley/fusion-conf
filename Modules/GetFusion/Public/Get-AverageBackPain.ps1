# Function to calculate average back pain for unified entries schema v2.0
function Get-AverageBackPain {
    param($entries)

    $backPainLevels = @()

    # Process unified schema v2.0 (array of entries)
    foreach ($entry in $entries) {
        if ($entry.entry_types -contains "pain" -and $entry.data.pain) {
            # Handle pain as array in schema v2.0
            foreach ($painEntry in $entry.data.pain) {
                if ($painEntry.location -eq "back") {
                    $backPainLevels += [double]$painEntry.severity
                }
            }
        }
    }

    # Calculate average back pain (null if no back pain data)
    if ($backPainLevels.Count -gt 0) {
        return [math]::Round(($backPainLevels | Measure-Object -Average).Average, 1)
    }

    return $null
}
