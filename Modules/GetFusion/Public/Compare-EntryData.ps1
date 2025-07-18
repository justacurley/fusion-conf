# Function to compare two entries and return similarity score (unified schema v2.0)
function Compare-EntryData {
    param(
        [Parameter(Mandatory)]
        $Entry1,
        [Parameter(Mandatory)]
        $Entry2,
        [bool]$IncludeNotes = $true,
        [bool]$IncludeVitals = $true
    )

    $totalWeight = 0
    $matchingWeight = 0
    $reasons = @()

    # Compare entry types (20% weight)
    $entryTypesWeight = 20
    $totalWeight += $entryTypesWeight
    $commonTypes = $Entry1.entry_types | Where-Object { $Entry2.entry_types -contains $_ }
    $allTypes = ($Entry1.entry_types + $Entry2.entry_types) | Sort-Object -Unique
    if ($allTypes.Count -gt 0) {
        $typesSimilarity = $commonTypes.Count / $allTypes.Count
        $matchingWeight += $typesSimilarity * $entryTypesWeight
        if ($typesSimilarity -eq 1.0) { $reasons += "Entry types match exactly" }
        elseif ($typesSimilarity -gt 0.5) { $reasons += "Entry types partially match" }
    }

    # Compare each data type that exists in both entries
    foreach ($entryType in $commonTypes) {
        switch ($entryType) {
            "medications" {
                if ($Entry1.data.medications -and $Entry2.data.medications) {
                    $medWeight = 15
                    $totalWeight += $medWeight
                    # Compare medications arrays
                    $medSimilarity = 0
                    if ($Entry1.data.medications.Count -eq $Entry2.data.medications.Count) {
                        $matchCount = 0
                        foreach ($med1 in $Entry1.data.medications) {
                            foreach ($med2 in $Entry2.data.medications) {
                                if ((Compare-Medications -Med1 $med1 -Med2 $med2) -gt 0.8) {
                                    $matchCount++
                                    break
                                }
                            }
                        }
                        $medSimilarity = $matchCount / $Entry1.data.medications.Count
                    }
                    $matchingWeight += $medSimilarity * $medWeight
                    if ($medSimilarity -eq 1.0) { $reasons += "Medications match exactly" }
                }
            }
            "pain" {
                if ($Entry1.data.pain -and $Entry2.data.pain) {
                    $painWeight = 15
                    $totalWeight += $painWeight
                    # Compare pain arrays
                    $painSimilarity = 0
                    if ($Entry1.data.pain.Count -eq $Entry2.data.pain.Count) {
                        $matchCount = 0
                        foreach ($pain1 in $Entry1.data.pain) {
                            foreach ($pain2 in $Entry2.data.pain) {
                                if ((Compare-PainData -Pain1 $pain1 -Pain2 $pain2) -gt 0.8) {
                                    $matchCount++
                                    break
                                }
                            }
                        }
                        $painSimilarity = $matchCount / $Entry1.data.pain.Count
                    }
                    $matchingWeight += $painSimilarity * $painWeight
                    if ($painSimilarity -eq 1.0) { $reasons += "Pain data matches exactly" }
                }
            }
            "activities" {
                if ($Entry1.data.activities -and $Entry2.data.activities) {
                    $actWeight = 15
                    $totalWeight += $actWeight
                    # Compare activities arrays
                    $actSimilarity = 0
                    if ($Entry1.data.activities.Count -eq $Entry2.data.activities.Count) {
                        $matchCount = 0
                        foreach ($act1 in $Entry1.data.activities) {
                            foreach ($act2 in $Entry2.data.activities) {
                                if ((Compare-Activities -Act1 $act1 -Act2 $act2) -gt 0.8) {
                                    $matchCount++
                                    break
                                }
                            }
                        }
                        $actSimilarity = $matchCount / $Entry1.data.activities.Count
                    }
                    $matchingWeight += $actSimilarity * $actWeight
                    if ($actSimilarity -eq 1.0) { $reasons += "Activities match exactly" }
                }
            }
            "vitals" {
                if ($IncludeVitals -and $Entry1.data.vitals -and $Entry2.data.vitals) {
                    $vitalsWeight = 15
                    $totalWeight += $vitalsWeight
                    $vitalsSimilarity = Compare-Vitals -Entry1 $Entry1 -Entry2 $Entry2
                    $matchingWeight += $vitalsSimilarity * $vitalsWeight
                    if ($vitalsSimilarity -eq 1.0) { $reasons += "Vitals match exactly" }
                }
            }
            "mood" {
                if ($Entry1.data.mood -and $Entry2.data.mood) {
                    $moodWeight = 10
                    $totalWeight += $moodWeight
                    $moodSimilarity = if ($Entry1.data.mood.mood_level -eq $Entry2.data.mood.mood_level) { 1.0 } else { 0.0 }
                    $matchingWeight += $moodSimilarity * $moodWeight
                    if ($moodSimilarity -eq 1.0) { $reasons += "Mood levels match exactly" }
                }
            }
        }
    }

    # Compare notes if requested (15% weight)
    if ($IncludeNotes) {
        $notesWeight = 15
        $totalWeight += $notesWeight
        $notesSimilarity = Compare-NoteText -Note1 $Entry1.notes -Note2 $Entry2.notes
        $matchingWeight += $notesSimilarity * $notesWeight
        if ($notesSimilarity -eq 1.0) { $reasons += "Notes match exactly" }
    }

    # Calculate final similarity score
    $similarityScore = if ($totalWeight -gt 0) {
        [math]::Round(($matchingWeight / $totalWeight) * 100, 1)
    } else {
        0
    }

    return [PSCustomObject]@{
        Score = $similarityScore
        Reason = if ($reasons.Count -gt 0) { $reasons -join "; " } else { "No significant matches found" }
    }
}
