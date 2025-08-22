# Test script for HealthEntryClasses Schema v2.0 compliance
# This script tests the updated module against the new schema requirements

# Import the module
using module ./HealthEntryClasses.psm1

Write-Host "Testing HealthEntryClasses Schema v2.0 Support" -ForegroundColor Green
Write-Host "=" * 50

# Test 1: Create a basic entry with required fields
Write-Host "`nTest 1: Creating basic entry..." -ForegroundColor Yellow

$entry = [HealthEntry]::new("user@example.com")
$entry.Note = "Test entry for schema validation"

# Add some sample data
$entry.Mood = [Mood]::new(4, "Feeling great today")
$entry.Vitals = [Vitals]::new(98, "125/82", 75, 98.6)

# Update entry types after adding data
$entry.UpdateEntryTypes()

Write-Host "Entry ID: $($entry.EntryId)"
Write-Host "User Email: $($entry.UserEmail)"
Write-Host "Date: $($entry.Date)"
Write-Host "Time: $($entry.Time)"
Write-Host "Entry Types: $($entry.EntryTypes -join ', ')"

# Test 2: Validate the entry
Write-Host "`nTest 2: Validating entry..." -ForegroundColor Yellow
$isValid = $entry.IsValid()
Write-Host "Entry is valid: $isValid"

if (-not $isValid) {
    Write-Host "Validation failed!" -ForegroundColor Red
} else {
    Write-Host "Validation passed!" -ForegroundColor Green
}

# Test 3: Schema v2.0 validation
Write-Host "`nTest 3: Schema v2.0 validation..." -ForegroundColor Yellow
$schemaValid = $entry.ValidateSchemaV2()
Write-Host "Schema v2.0 compliant: $schemaValid"

# Test 4: Convert to hashtable (JSON-ready format)
Write-Host "`nTest 4: Converting to hashtable..." -ForegroundColor Yellow
$hashtable = $entry.ToHashtable()

Write-Host "Generated hashtable structure:"
Write-Host "- entry_id: $($hashtable.entry_id)"
Write-Host "- user_email: $($hashtable.user_email)"
Write-Host "- date: $($hashtable.date)"
Write-Host "- time: $($hashtable.time)"
Write-Host "- entry_types: $($hashtable.entry_types -join ', ')"
Write-Host "- data keys: $($hashtable.data.Keys -join ', ')"
Write-Host "- notes: $($hashtable.notes)"

# Test 5: Create entry with multiple data types (no limits per updated schema)
Write-Host "`nTest 5: Creating complex entry..." -ForegroundColor Yellow

$complexEntry = [HealthEntry]::new("alex@example.com")
$complexEntry.Note = "Complex entry with multiple data types"

# Add all available data types (no longer limited by schema)
$complexEntry.Mood = [Mood]::new(3, "Feeling okay")
$complexEntry.Vitals = [Vitals]::new(95, "120/80", 70, 98.2)
$complexEntry.Medication += [MedicationTaken]::new("4mg", "dilaudid")
$complexEntry.Medication += [MedicationTaken]::new("1g", "tylenol")
$complexEntry.Activity += [Activity]::new("Walking", 20, "Slow pace")
$complexEntry.Pain += [PainLocation]::new("back", 3.5, "Lower back ache")
$complexEntry.Weight = [Weight]::new(150.0)
$complexEntry.Sleep = [Sleep]::new(7.5)

# Update entry types after adding all data
$complexEntry.UpdateEntryTypes()

Write-Host "Complex entry types: $($complexEntry.EntryTypes -join ', ')"
Write-Host "Complex entry valid: $($complexEntry.IsValid())"
Write-Host "Complex entry schema v2.0 compliant: $($complexEntry.ValidateSchemaV2())"

# Test 6: Round-trip test (create from hashtable)
Write-Host "`nTest 6: Round-trip test..." -ForegroundColor Yellow
$complexHashtable = $complexEntry.ToHashtable()
$recreatedEntry = [HealthEntry]::FromHashtable($complexHashtable)

Write-Host "Original entry types: $($complexEntry.EntryTypes -join ', ')"
Write-Host "Recreated entry types: $($recreatedEntry.EntryTypes -join ', ')"
Write-Host "Round-trip successful: $($recreatedEntry.IsValid())"

Write-Host "`nAll tests completed!" -ForegroundColor Green
