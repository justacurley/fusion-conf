# Fusion PowerShell Module

A robust PowerShell module for managing health recovery entries, converting form data to structured JSON format, and tracking medications, pain levels, activities, and vital signs.

## Overview

The Fusion module provides a complete solution for processing health data from various input sources (forms, manual entry) and converting them into a standardized JSON format for storage and analysis. It features comprehensive medication parsing, pain level tracking, activity logging, and vital signs recording.

## Philosophy

- **🔧 Robust**: Handles various input formats and edge cases gracefully
- **🎯 Structured**: Converts disparate data into consistent JSON schema
- **📦 Modular**: Each function has a single, clear responsibility
- **🔄 Tested**: Comprehensive test coverage with Pester framework
- **📊 Tracking**: Built-in pain level calculations and data aggregation

## Installation

Place the module in your PowerShell modules directory or import directly:

```powershell
Import-Module -Name "/path/to/fusion/fusion.psm1" -Force
```

Or install using the manifest:

```powershell
Import-Module -Name "/path/to/fusion/fusion.psd1" -Force
```

## Functions

### Core Functions

### Add-Entry
Creates a new health entry with comprehensive data structure.

**Parameters:**
- `date` (string): Date in MMDD format (e.g., "0523")
- `sleep` (string): Sleep duration (e.g., "7:30" or "8.5")
- `medications` (hashtable): Medication names and dosages
- `pain` (hashtable): Pain locations and levels (1-10)
- `activities` (hashtable): Activity names and durations
- `vitals` (hashtable): Vital signs measurements
- `notes` (string): Optional text notes

**Returns:** PSCustomObject representing the complete entry

**Example:**
```powershell
$entry = Add-Entry -date "0523" -sleep "7:30" `
    -medications @{ "Dilaudid" = "4mg"; "Ibuprofen" = "600mg" } `
    -pain @{ "back" = 6; "knee" = 3 } `
    -activities @{ "walking" = "30min"; "stretching" = "15min" } `
    -vitals @{ "blood_pressure" = "120/80"; "heart_rate" = "72" } `
    -notes "Feeling better today"
```

### ConvertTo-EntriesFormat
Converts form data (with boolean medication flags) into standardized entries format.

**Parameters:**
- `formData` (hashtable): Form data with medication flags, pain levels, activities, etc.

**Returns:** PSCustomObject with structured entry data ready for JSON conversion

**Key Features:**
- **Medication Parsing**: Converts boolean flags (e.g., `dilaudid_4mg = $true`) into structured arrays
- **Multiple Dosages**: Handles multiple doses of same medication (creates arrays)
- **Dynamic IDs**: Processes activities and pain with dynamic ID suffixes
- **Robust Validation**: Gracefully handles missing or invalid data

**Example:**
```powershell
$formData = @{
    'date' = '0523'
    'sleep' = '7:30'
    'dilaudid_4mg' = $true
    'dilaudid_2mg' = $true
    'ibuprofen_600mg' = $true
    'pain_back_1' = '6'
    'pain_knee_2' = '3'
    'activity_walking_1' = '30min'
    'activity_stretching_2' = '15min'
    'vital_blood_pressure' = '120/80'
    'notes' = 'Good day overall'
}

$result = ConvertTo-EntriesFormat -formData $formData
# Result includes properly structured medications, pain, activities arrays
```

### Save-ConvertedEntry
Saves a converted entry to the entries.json file and updates daily statistics.

**Parameters:**
- `convertedEntry` (PSObject): Entry object from ConvertTo-EntriesFormat
- `entriesPath` (string): Path to entries.json file (default: "./entries.json")

**Returns:** None (saves data to file)

**Features:**
- Creates new file if it doesn't exist
- Appends to existing entries file
- Automatically updates daily maximum pain levels
- Handles file locking and concurrent access gracefully

**Example:**
```powershell
$converted = ConvertTo-EntriesFormat -formData $formData
Save-ConvertedEntry -convertedEntry $converted -entriesPath "/path/to/entries.json"
```

### Update-DailyMaxPainLevel
Updates the maximum pain level for a specific date in the entries data.

**Parameters:**
- `entries` (PSObject): The full entries data structure
- `date` (string): Date in MMDD format
- `newEntry` (PSObject): New entry with pain data

**Returns:** Updated entries object with max_pain_level calculated

**Features:**
- Calculates maximum pain across all pain entries for the date
- Handles missing dates gracefully
- Preserves existing max_pain_level if no pain data exists
- Works with both single entries and multiple entries per date

**Example:**
```powershell
$entries = Get-Content "entries.json" | ConvertFrom-Json
$updatedEntries = Update-DailyMaxPainLevel -entries $entries -date "0523" -newEntry $newEntry
```

## Data Schema

### Entry Structure
```json
{
  "0523": {
    "max_pain_level": 6,
    "entries": [
      {
        "id": "12345",
        "timestamp": "2024-05-23T14:30:00Z",
        "sleep": "7:30",
        "medications": [
          { "name": "Dilaudid", "dosage": ["4mg", "2mg"] },
          { "name": "Ibuprofen", "dosage": "600mg" }
        ],
        "pain": [
          { "location": "back", "level": 6, "id": 1 },
          { "location": "knee", "level": 3, "id": 2 }
        ],
        "activities": [
          { "name": "walking", "duration": "30min", "id": 1 },
          { "name": "stretching", "duration": "15min", "id": 2 }
        ],
        "vitals": {
          "blood_pressure": "120/80",
          "heart_rate": "72"
        },
        "notes": "Good day overall",
        "medication_taken": true
      }
    ]
  }
}
```

## Testing

The module includes comprehensive Pester tests covering:

- **Unit Tests**: Each function tested individually
- **Integration Tests**: Full workflow testing
- **Edge Cases**: Multiple medications, missing data, empty entries
- **Data Validation**: Schema compliance and data integrity

Run tests:
```powershell
cd /path/to/fusion
Invoke-Pester tests/fusion.Tests.ps1 -Output Detailed
```

### Test Coverage
- ✅ Medication parsing with boolean flags
- ✅ Multiple dosages of same medication
- ✅ Dynamic activity and pain IDs
- ✅ Vital signs processing
- ✅ File operations and data persistence
- ✅ Pain level calculations
- ✅ Form-to-save workflow integration
- ✅ Error handling and edge cases

## File Structure

```
fusion/
├── fusion.psm1              # Main module file
├── fusion.psd1              # Module manifest
├── README.md                # This documentation
├── entries_schema.json      # Legacy JSON schema (v1.0)
├── entries_schema_v2.json   # Current JSON schema validation (v2.0)
├── ENTRIES-SCHEMA-v2.md     # Complete schema documentation
└── tests/
    └── fusion.Tests.ps1     # Comprehensive test suite
```

## Version History

### Version 1.0.0
- ✨ Initial release
- ✨ Add-Entry function for manual entry creation
- ✨ ConvertTo-EntriesFormat for form data conversion
- ✨ Update-DailyMaxPainLevel for pain level calculations
- ✨ Save-ConvertedEntry for data persistence
- ✨ Support for medications, pain tracking, activities, and vitals
- ✨ Comprehensive test coverage with Pester
- ✨ Robust medication parsing with multiple dosage support
- ✨ Dynamic ID handling for activities and pain entries

## Requirements

- **PowerShell**: 5.1 or later
- **Dependencies**: None (uses built-in PowerShell cmdlets)
- **Optional**: Pester 5.0+ for running tests

## Best Practices

### Medication Data
- Use boolean flags for form inputs: `dilaudid_4mg = $true`
- Multiple dosages automatically create arrays: `["4mg", "2mg"]`
- Medication names are normalized and case-insensitive

### Pain Tracking
- Use 1-10 scale for pain levels
- Include location and ID for multiple pain points
- System automatically calculates daily maximum pain level

### Activities
- Include duration with units (e.g., "30min", "1hr")
- Support multiple activities with unique IDs
- Flexible activity naming and categorization

### Data Persistence
- Always use Save-ConvertedEntry for data integrity
- Backup entries.json before major updates
- Monitor file size and implement rotation if needed

## Contributing

When contributing to this module:

1. **Tests First**: Add tests for new functionality
2. **Documentation**: Update README for new functions
3. **Schema**: Update schema files for data structure changes
4. **Versioning**: Follow semantic versioning (major.minor.patch)
5. **Best Practices**: Follow PowerShell best practices and conventions

## License

Copyright (c) Alex. All rights reserved.

## Support

For issues, questions, or contributions, please refer to the module maintainer or create appropriate documentation for your use case.
