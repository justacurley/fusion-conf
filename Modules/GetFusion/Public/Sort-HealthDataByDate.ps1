# Function to sort health data by date
function Sort-HealthDataByDate {
    param($healthData)

    # For unified schema v2.0, detect date format and sort accordingly
    if ($healthData.Count -gt 0) {
        $sampleDate = $healthData[0].Date
        if ($sampleDate -match '^\d{4}-\d{2}-\d{2}$') {
            # YYYY-MM-DD format
            return $healthData | Sort-Object { [datetime]::ParseExact($_.Date, 'yyyy-MM-dd', $null) }
        } elseif ($sampleDate -match '^\d{2}/\d{2}$') {
            # MM/dd format
            return $healthData | Sort-Object { [datetime]::ParseExact($_.Date, 'MM/dd', $null) }
        }
    }

    # Fallback to string sort if date format is unrecognized
    return $healthData | Sort-Object Date
}
