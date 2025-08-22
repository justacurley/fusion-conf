# Function to compare vital signs (unified schema v2.0)
function Compare-Vitals {
    param($Entry1, $Entry2)

    if (-not $Entry1.data.vitals -and -not $Entry2.data.vitals) { return 1.0 }
    if (-not $Entry1.data.vitals -or -not $Entry2.data.vitals) { return 0.0 }

    $vitals1 = $Entry1.data.vitals
    $vitals2 = $Entry2.data.vitals
    $matchCount = 0
    $total = 0

    # Compare each vital sign
    if ($vitals1.blood_pressure -or $vitals2.blood_pressure) {
        $total++
        if ($vitals1.blood_pressure -eq $vitals2.blood_pressure) { $matchCount++ }
    }

    if ($vitals1.oxygen_saturation -or $vitals2.oxygen_saturation) {
        $total++
        if ($vitals1.oxygen_saturation -eq $vitals2.oxygen_saturation) { $matchCount++ }
    }

    if ($vitals1.heart_rate -or $vitals2.heart_rate) {
        $total++
        if ($vitals1.heart_rate -eq $vitals2.heart_rate) { $matchCount++ }
    }

    if ($vitals1.temperature -or $vitals2.temperature) {
        $total++
        if ($vitals1.temperature -eq $vitals2.temperature) { $matchCount++ }
    }

    if ($total -gt 0) {
        return $matchCount / $total
    } else {
        return 1.0
    }
}
