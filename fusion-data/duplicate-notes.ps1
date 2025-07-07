# Script to find duplicate notes within each date in entries copy.json
param(
    [string]$EntriesPath = "$PSScriptRoot\entries copy.json",
    [switch]$ShowDetails
)

function Find-DuplicateNotes {
    param(
        [string]$FilePath,
        [switch]$Detailed
    )
    
    try {
        # Check if file exists
        if (-not (Test-Path $FilePath)) {
            Write-Error "File not found: $FilePath"
            return
        }
        
        # Read the entries file
        $entries = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        $duplicatesFound = 0
        $totalDatesProcessed = 0
        
        Write-Host "Searching for duplicate notes in: $FilePath" -ForegroundColor Green
        Write-Host "=" * 60
        
        # Process each date in entries
        foreach ($dateKey in $entries.PSObject.Properties.Name | Sort-Object) {
            # Skip non-date entries (like max_pain_level)
            if ($dateKey -notmatch '^\d{4}$') { continue }
            
            $totalDatesProcessed++
            $dateEntry = $entries.$dateKey
            
            # Collect all notes for this date
            $timestampNotes = @()
            
            # Process each timestamp in the date entry
            foreach ($timestampKey in $dateEntry.PSObject.Properties.Name) {
                # Skip non-timestamp entries (like max_pain_level)
                if ($timestampKey -notmatch '^\d{4}$') { continue }
                
                $timestampEntry = $dateEntry.$timestampKey
                
                # Check main note field
                if ($timestampEntry.PSObject.Properties['note'] -and 
                    $timestampEntry.note -and 
                    $timestampEntry.note.Trim() -ne "") {
                    
                    $noteText = $timestampEntry.note.Trim()
                    $timestampNotes += [PSCustomObject]@{
                        Timestamp = $timestampKey
                        NoteType = "main"
                        NoteText = $noteText
                        Location = "note"
                    }
                }
                
                # Check pain notes
                if ($timestampEntry.PSObject.Properties['Pain']) {
                    foreach ($painLocation in $timestampEntry.Pain.PSObject.Properties.Name) {
                        $painEntry = $timestampEntry.Pain.$painLocation
                        if ($painEntry.PSObject.Properties['note'] -and 
                            $painEntry.note -and 
                            $painEntry.note.Trim() -ne "") {
                            
                            $noteText = $painEntry.note.Trim()
                            $timestampNotes += [PSCustomObject]@{
                                Timestamp = $timestampKey
                                NoteType = "pain"
                                NoteText = $noteText
                                Location = "Pain.$painLocation.note"
                            }
                        }
                    }
                }
                
                # Check activity notes
                if ($timestampEntry.PSObject.Properties['Activities']) {
                    foreach ($activityName in $timestampEntry.Activities.PSObject.Properties.Name) {
                        $activityEntry = $timestampEntry.Activities.$activityName
                        if ($activityEntry.PSObject.Properties['note'] -and 
                            $activityEntry.note -and 
                            $activityEntry.note.Trim() -ne "") {
                            
                            $noteText = $activityEntry.note.Trim()
                            $timestampNotes += [PSCustomObject]@{
                                Timestamp = $timestampKey
                                NoteType = "activity"
                                NoteText = $noteText
                                Location = "Activities.$activityName.note"
                            }
                        }
                    }
                }
            }
            
            # Find duplicates for this date
            $duplicateGroups = $timestampNotes | 
                Group-Object -Property NoteText | 
                Where-Object { $_.Count -gt 1 }
            
            if ($duplicateGroups.Count -gt 0) {
                Write-Host "Date $dateKey - Found $($duplicateGroups.Count) duplicate note(s):" -ForegroundColor Yellow
                
                foreach ($duplicateGroup in $duplicateGroups) {
                    $duplicatesFound++
                    $noteText = $duplicateGroup.Name
                    $occurrences = $duplicateGroup.Group
                    
                    Write-Host "  Duplicate Note: `"$noteText`"" -ForegroundColor Red
                    Write-Host "  Found in $($occurrences.Count) locations:" -ForegroundColor Cyan
                    
                    foreach ($occurrence in $occurrences) {
                        Write-Host "    - $($occurrence.Timestamp) ($($occurrence.NoteType)): $($occurrence.Location)" -ForegroundColor White
                    }
                    
                    if ($Detailed) {
                        Write-Host "    Suggested action: Keep in earliest timestamp, remove from others" -ForegroundColor Gray
                    }
                    Write-Host ""
                }
                Write-Host ""
            } else {
                if ($Detailed) {
                    Write-Host "Date $dateKey - No duplicate notes found" -ForegroundColor Green
                }
            }
        }
        
        # Summary
        Write-Host "=" * 60
        Write-Host "Summary:" -ForegroundColor Green
        Write-Host "  Total dates processed: $totalDatesProcessed"
        Write-Host "  Total duplicate note groups found: $duplicatesFound"
        
        if ($duplicatesFound -eq 0) {
            Write-Host "  No duplicate notes found! 🎉" -ForegroundColor Green
        } else {
            Write-Host "  Consider cleaning up duplicate notes to improve data quality." -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Error "Error processing file: $($_.Exception.Message)"
    }
}

# Function to remove duplicate notes (dry run mode)
function Remove-DuplicateNotes {
    param(
        [string]$FilePath,
        [switch]$DryRun,
        [string]$OutputPath = "$PSScriptRoot\entries-cleaned.json"
    )
    
    $isDryRun = $DryRun -or -not $PSBoundParameters.ContainsKey('DryRun')
    
    if ($isDryRun) {
        Write-Host "DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
        Write-Host "Use -DryRun:`$false to actually clean the file" -ForegroundColor Yellow
        Write-Host ""
    }
    
    try {
        # Check if file exists
        if (-not (Test-Path $FilePath)) {
            Write-Error "File not found: $FilePath"
            return
        }
        
        # Read the entries file
        $entries = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        $duplicatesRemoved = 0
        $totalDatesProcessed = 0
        
        Write-Host "Processing duplicate note removal..." -ForegroundColor Green
        Write-Host "=" * 60
        
        # Process each date in entries
        foreach ($dateKey in $entries.PSObject.Properties.Name | Sort-Object) {
            # Skip non-date entries (like max_pain_level)
            if ($dateKey -notmatch '^\d{4}$') { continue }
            
            $totalDatesProcessed++
            $dateEntry = $entries.$dateKey
            
            # Collect all notes for this date with their references
            $timestampNotes = @()
            
            # Process each timestamp in the date entry
            foreach ($timestampKey in $dateEntry.PSObject.Properties.Name) {
                # Skip non-timestamp entries (like max_pain_level)
                if ($timestampKey -notmatch '^\d{4}$') { continue }
                
                $timestampEntry = $dateEntry.$timestampKey
                
                # Check main note field
                if ($timestampEntry.PSObject.Properties['note'] -and 
                    $timestampEntry.note -and 
                    $timestampEntry.note.Trim() -ne "") {
                    
                    $noteText = $timestampEntry.note.Trim()
                    $timestampNotes += [PSCustomObject]@{
                        Timestamp = $timestampKey
                        NoteType = "main"
                        NoteText = $noteText
                        Location = "note"
                        Reference = $timestampEntry
                        Property = "note"
                    }
                }
                
                # Check pain notes
                if ($timestampEntry.PSObject.Properties['Pain']) {
                    foreach ($painLocation in $timestampEntry.Pain.PSObject.Properties.Name) {
                        $painEntry = $timestampEntry.Pain.$painLocation
                        if ($painEntry.PSObject.Properties['note'] -and 
                            $painEntry.note -and 
                            $painEntry.note.Trim() -ne "") {
                            
                            $noteText = $painEntry.note.Trim()
                            $timestampNotes += [PSCustomObject]@{
                                Timestamp = $timestampKey
                                NoteType = "pain"
                                NoteText = $noteText
                                Location = "Pain.$painLocation.note"
                                Reference = $painEntry
                                Property = "note"
                            }
                        }
                    }
                }
                
                # Check activity notes
                if ($timestampEntry.PSObject.Properties['Activities']) {
                    foreach ($activityName in $timestampEntry.Activities.PSObject.Properties.Name) {
                        $activityEntry = $timestampEntry.Activities.$activityName
                        if ($activityEntry.PSObject.Properties['note'] -and 
                            $activityEntry.note -and 
                            $activityEntry.note.Trim() -ne "") {
                            
                            $noteText = $activityEntry.note.Trim()
                            $timestampNotes += [PSCustomObject]@{
                                Timestamp = $timestampKey
                                NoteType = "activity"
                                NoteText = $noteText
                                Location = "Activities.$activityName.note"
                                Reference = $activityEntry
                                Property = "note"
                            }
                        }
                    }
                }
            }
            
            # Find duplicates for this date
            $duplicateGroups = $timestampNotes | 
                Group-Object -Property NoteText | 
                Where-Object { $_.Count -gt 1 }
            
            if ($duplicateGroups.Count -gt 0) {
                Write-Host "Date $dateKey - Processing $($duplicateGroups.Count) duplicate note group(s):" -ForegroundColor Yellow
                
                foreach ($duplicateGroup in $duplicateGroups) {
                    $noteText = $duplicateGroup.Name
                    $occurrences = $duplicateGroup.Group | Sort-Object Timestamp
                    
                    Write-Host "  Duplicate Note: `"$noteText`"" -ForegroundColor Red
                    Write-Host "  Found in $($occurrences.Count) locations:" -ForegroundColor Cyan
                    
                    # Keep the first occurrence, remove the rest
                    for ($i = 0; $i -lt $occurrences.Count; $i++) {
                        $occurrence = $occurrences[$i]
                        
                        if ($i -eq 0) {
                            # Keep the first occurrence
                            Write-Host "    ✓ KEEPING: $($occurrence.Timestamp) ($($occurrence.NoteType)): $($occurrence.Location)" -ForegroundColor Green
                        } else {
                            # Remove subsequent occurrences
                            Write-Host "    ✗ REMOVING: $($occurrence.Timestamp) ($($occurrence.NoteType)): $($occurrence.Location)" -ForegroundColor Red
                            
                            if (-not $isDryRun) {
                                # Actually remove the duplicate note
                                $occurrence.Reference.($occurrence.Property) = ""
                                $duplicatesRemoved++
                            } else {
                                $duplicatesRemoved++
                            }
                        }
                    }
                    Write-Host ""
                }
            }
        }
        
        # Save the cleaned file if not dry run
        if (-not $isDryRun -and $duplicatesRemoved -gt 0) {
            $entries | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Host "Cleaned file saved to: $OutputPath" -ForegroundColor Green
        }
        
        # Summary
        Write-Host "=" * 60
        Write-Host "Duplicate Removal Summary:" -ForegroundColor Green
        Write-Host "  Total dates processed: $totalDatesProcessed"
        Write-Host "  Total duplicate notes removed: $duplicatesRemoved"
        
        if ($isDryRun) {
            Write-Host "  This was a DRY RUN - no actual changes were made" -ForegroundColor Yellow
            if ($duplicatesRemoved -gt 0) {
                Write-Host "  Run with -DryRun:`$false to actually remove duplicates" -ForegroundColor Yellow
            }
        } else {
            if ($duplicatesRemoved -gt 0) {
                Write-Host "  Duplicate notes have been removed! ✨" -ForegroundColor Green
            } else {
                Write-Host "  No duplicate notes were found to remove." -ForegroundColor Green
            }
        }
        
    }
    catch {
        Write-Error "Error processing file: $($_.Exception.Message)"
    }
}

# Main execution
Write-Host "Duplicate Notes Finder & Cleaner" -ForegroundColor Magenta
Write-Host "=================================" -ForegroundColor Magenta
Write-Host ""

# First, find and display duplicates
Find-DuplicateNotes -FilePath $EntriesPath -Detailed:$ShowDetails

Write-Host ""
Write-Host "=" * 60
Write-Host ""

# Then offer to clean them
Write-Host "Cleaning duplicate notes..." -ForegroundColor Magenta
Write-Host ""

# Run the cleaner in dry-run mode by default
Remove-DuplicateNotes -FilePath $EntriesPath

Write-Host ""
Write-Host "To actually remove duplicates, run:" -ForegroundColor Yellow
Write-Host "Remove-DuplicateNotes -FilePath '$EntriesPath' -DryRun:`$false" -ForegroundColor Cyan
Remove-DuplicateNotes -FilePath $EntriesPath -DryRun:$false