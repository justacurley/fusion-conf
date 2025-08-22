# Function to compare medication data (unified schema v2.0)
function Compare-Medications {
    param($Med1, $Med2)

    if (-not $Med1 -and -not $Med2) { return 1.0 }
    if (-not $Med1 -or -not $Med2) { return 0.0 }

    # Compare medication name and dosage - updated for schema v2.0
    if ($Med1.name -eq $Med2.name) {
        if ($Med1.dosage -eq $Med2.dosage) {
            return 1.0  # Perfect match
        } else {
            return 0.5  # Same medication, different dose
        }
    }

    return 0.0  # Different medications
}
