# Function to compare note text
function Compare-NoteText {
    param([string]$Note1, [string]$Note2)

    if ([string]::IsNullOrEmpty($Note1) -and [string]::IsNullOrEmpty($Note2)) { return 1.0 }
    if ([string]::IsNullOrEmpty($Note1) -or [string]::IsNullOrEmpty($Note2)) { return 0.0 }

    $Note1 = $Note1.ToLower().Trim()
    $Note2 = $Note2.ToLower().Trim()

    if ($Note1 -eq $Note2) { return 1.0 }

    # Check if one note contains the other
    if ($Note1.Contains($Note2) -or $Note2.Contains($Note1)) { return 0.8 }

    # Calculate word overlap
    $words1 = $Note1 -split '\s+' | Where-Object { $_.Length -gt 2 }
    $words2 = $Note2 -split '\s+' | Where-Object { $_.Length -gt 2 }

    if ($words1.Count -eq 0 -and $words2.Count -eq 0) { return 1.0 }
    if ($words1.Count -eq 0 -or $words2.Count -eq 0) { return 0.0 }

    $commonWords = $words1 | Where-Object { $words2 -contains $_ }
    $totalWords = ($words1 + $words2) | Sort-Object -Unique

    if ($totalWords.Count -gt 0) {
        return $commonWords.Count / $totalWords.Count
    } else {
        return 0.0
    }
}
