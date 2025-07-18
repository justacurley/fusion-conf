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
            "medication" {
                if ($Entry1.data.medication -and $Entry2.data.medication) {
                    $medWeight = 15
                    $totalWeight += $medWeight
                    $medSimilarity = Compare-Medications -Med1 $Entry1.data.medication -Med2 $Entry2.data.medication
                    $matchingWeight += $medSimilarity * $medWeight
                    if ($medSimilarity -eq 1.0) { $reasons += "Medications match exactly" }
                }
            }
            "pain" {
                if ($Entry1.data.pain -and $Entry2.data.pain) {
                    $painWeight = 15
                    $totalWeight += $painWeight
                    $painSimilarity = Compare-PainData -Pain1 $Entry1.data.pain -Pain2 $Entry2.data.pain
                    $matchingWeight += $painSimilarity * $painWeight
                    if ($painSimilarity -eq 1.0) { $reasons += "Pain data matches exactly" }
                }
            }
            "activity" {
                if ($Entry1.data.activity -and $Entry2.data.activity) {
                    $actWeight = 15
                    $totalWeight += $actWeight
                    $actSimilarity = Compare-Activities -Act1 $Entry1.data.activity -Act2 $Entry2.data.activity
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
