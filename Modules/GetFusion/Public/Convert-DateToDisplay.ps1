# Function to convert date format (unified schema uses YYYY-MM-DD, convert to MM/DD for display)
function Convert-DateToDisplay {
    param([string]$date)

    # Unified schema uses YYYY-MM-DD format, convert to MM/DD for display
    if ($date -match '^(\d{4})-(\d{2})-(\d{2})$') {
        return "$($matches[2])/$($matches[3])"
    }

    return $date
}
