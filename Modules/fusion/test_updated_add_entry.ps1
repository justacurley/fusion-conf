#!/usr/bin/env pwsh

# Test the updated Add-Entry function with new nested schema
Import-Module /home/alex/src/fusion-conf/Modules/fusion/fusion.psm1 -Force

# Create test entries directory if it doesn't exist
$testEntriesDir = "/home/alex/src/fusion-conf/fusion-data/entries"
if (-not (Test-Path $testEntriesDir)) {
    New-Item -ItemType Directory -Path $testEntriesDir -Force
}

# Initialize with empty entries file if it doesn't exist
$testEntriesFile = "$testEntriesDir/entries.json"
if (-not (Test-Path $testEntriesFile)) {
    "{}" | Out-File $testEntriesFile -Encoding UTF8
}

# Test data
$testDate = "0115"
$testTime = "1400"

Write-Host "Testing Add-Entry with new nested schema..."

# Test adding an entry with medications, pain, and activities
try {
    Add-Entry -Date $testDate -Time $testTime `
              -Medications @("tylenol1", "dilaudid4") `
              -PainLocation @("back", "shoulder") `
              -PainLevel @("3.5", "2.0") `
              -Activities @("walking", "stairs") `
              -ActivitiesDuration @(15, 5) `
              -o2 "98%" `
              -bpr "120/80" `
              -Note "Test entry with nested schema" `
              -Sleep "08:30"

    Write-Host "✓ Add-Entry completed successfully"
    
    # Check the created entry structure
    $entries = Get-Content -Path $testEntriesFile | ConvertFrom-Json
    $testEntry = $entries.$testDate.$testTime
    
    Write-Host "`nEntry structure:"
    Write-Host "Medications: $($testEntry.Medications | ConvertTo-Json -Compress)"
    Write-Host "Pain: $($testEntry.Pain | ConvertTo-Json -Compress)"
    Write-Host "Activities: $($testEntry.Activities | ConvertTo-Json -Compress)"
    Write-Host "medication_taken: '$($testEntry.medication_taken)'"
    Write-Host "Sleep at date level: '$($entries.$testDate.Sleep)'"
    Write-Host "max_pain_level: '$($entries.$testDate.max_pain_level)'"
    
    # Verify nested structure
    if ($testEntry.Pain.back.pain_level -eq 3.5 -and $testEntry.Pain.back.note -eq "") {
        Write-Host "✓ Pain nested structure is correct"
    } else {
        Write-Host "✗ Pain nested structure is incorrect"
        Write-Host "  Expected: pain_level=3.5, note=''"
        Write-Host "  Got: pain_level=$($testEntry.Pain.back.pain_level), note='$($testEntry.Pain.back.note)'"
    }
    
    if ($testEntry.Activities.walking.duration -eq 15 -and $testEntry.Activities.walking.note -eq "") {
        Write-Host "✓ Activities nested structure is correct"
    } else {
        Write-Host "✗ Activities nested structure is incorrect"
        Write-Host "  Expected: duration=15, note=''"
        Write-Host "  Got: duration=$($testEntry.Activities.walking.duration), note='$($testEntry.Activities.walking.note)'"
    }
    
    if ($testEntry.medication_taken -eq "tylenol,dilaudid") {
        Write-Host "✓ medication_taken field is correct"
    } else {
        Write-Host "✗ medication_taken field is incorrect: '$($testEntry.medication_taken)'"
    }
    
    # Check that max_pain_level was calculated correctly (should be 3.5)
    if ($entries.$testDate.max_pain_level -eq 3.5) {
        Write-Host "✓ max_pain_level calculated correctly: $($entries.$testDate.max_pain_level)"
    } else {
        Write-Host "✗ max_pain_level incorrect: expected 3.5, got $($entries.$testDate.max_pain_level)"
    }
    
} catch {
    Write-Host "✗ Error: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
}
