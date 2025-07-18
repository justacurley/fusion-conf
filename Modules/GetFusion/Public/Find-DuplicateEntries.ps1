# Function to find duplicate entries based on similarity analysis (unified schema v2.0)
function Find-DuplicateEntries {
    param(
        [Parameter(Mandatory)]
        [Array]$Entries,
        [int]$SimilarityThreshold = 80,
        [bool]$IncludeNotes = $true,
        [bool]$IncludeVitals = $true
    )

    $duplicates = @()
    $processedPairs = @{}

    # Group entries by date for efficiency
    $entriesByDate = $Entries | Group-Object -Property date

    foreach ($dateGroup in $entriesByDate) {
        $dateEntries = $dateGroup.Group

        # Compare each entry with every other entry for the same date
        for ($i = 0; $i -lt $dateEntries.Count; $i++) {
            for ($j = $i + 1; $j -lt $dateEntries.Count; $j++) {
                $entry1 = $dateEntries[$i]
                $entry2 = $dateEntries[$j]

                # Create a unique key for this pair to avoid duplicate comparisons
                $pairKey = "$($entry1.entry_id)-$($entry2.entry_id)"
                $reversePairKey = "$($entry2.entry_id)-$($entry1.entry_id)"

                if ($processedPairs.ContainsKey($pairKey) -or $processedPairs.ContainsKey($reversePairKey)) {
                    continue
                }

                $processedPairs[$pairKey] = $true

                # Compare the entries
                $comparison = Compare-EntryData -Entry1 $entry1 -Entry2 $entry2 -IncludeNotes $IncludeNotes -IncludeVitals $IncludeVitals

                if ($comparison.Score -ge $SimilarityThreshold) {
                    $duplicate = [PSCustomObject]@{
                        Date = $entry1.date
                        SimilarityScore = $comparison.Score
                        Entry1 = [PSCustomObject]@{
                            EntryId = $entry1.entry_id
                            Timestamp = $entry1.time
                            EntryTypes = $entry1.entry_types -join ', '
                            Notes = $entry1.notes
                        }
                        Entry2 = [PSCustomObject]@{
                            EntryId = $entry2.entry_id
                            Timestamp = $entry2.time
                            EntryTypes = $entry2.entry_types -join ', '
                            Notes = $entry2.notes
                        }
                        Reason = $comparison.Reason
                    }
                    $duplicates += $duplicate
                }
            }
        }
    }

    return $duplicates
}
