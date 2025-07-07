# GetFusion PowerShell Module

A flexible PowerShell module for extracting and processing health data from fusion entries.json files, designed for use with PowerShell Universal dashboards.

## Overview

The GetFusion module provides composable functions for extracting specific data types from JSON health data files. Unlike opinionated frameworks, this module gives you building blocks to create exactly the datasets you need for your specific use cases.

## Philosophy

- **🔧 Composable**: Mix and match functions to build custom datasets
- **🎯 Flexible**: No predefined data structures - build what you need
- **📦 Modular**: Each function has a single, clear responsibility
- **🔄 Reusable**: Functions work across different dashboard and analysis scenarios

## Installation

Place the module files in your PowerShell modules directory or import directly:

```powershell
Import-Module -Name "/path/to/GetFusion/GetFusion.psm1" -Force
```

## Functions

### Core Functions

### Get-HealthData
Main function that extracts and processes comprehensive health data from entries.json.

**Parameters:**
- `entriesPath` (string): Path to the entries.json file

**Returns:** Array of PSCustomObject with Date, MaxPain, BackPain, and Sleep properties

**Example:**
```powershell
$healthData = Get-HealthData -entriesPath "/path/to/entries.json"
$healthData | Format-Table -AutoSize
```

### Get-SleepHours
Parses sleep data from various formats (HH:MM or decimal).

**Parameters:**
- `sleepValue` (string): Sleep value in "HH:MM" format (e.g., "7:39") or decimal (e.g., "8.5")

**Returns:** Double representing hours, or null if invalid

**Example:**
```powershell
$hours1 = Get-SleepHours -sleepValue "7:39"  # Returns 7.65
$hours2 = Get-SleepHours -sleepValue "8.5"   # Returns 8.5
```

### Get-AverageBackPain
Calculates the average back pain level for a given date entry.

**Parameters:**
- `dateEntry` (PSObject): A date entry object from the entries.json structure

**Returns:** Double representing average back pain level, or null if no data

**Example:**
```powershell
$entries = Get-Content "entries.json" | ConvertFrom-Json
$avgPain = Get-AverageBackPain -dateEntry $entries.0523
```

### Convert-DateToDisplay
Converts MMDD date format to MM/DD display format.

**Parameters:**
- `date` (string): Date in MMDD format (e.g., "0523")

**Returns:** String in MM/DD format (e.g., "05/23")

**Example:**
```powershell
$displayDate = Convert-DateToDisplay -date "0523"  # Returns "05/23"
```

### Modular Helper Functions

### Get-EntriesData
Loads and parses the entries.json file.

**Parameters:**
- `entriesPath` (string): Path to the entries.json file

**Returns:** PSObject representing the parsed JSON data

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
```

### Get-DatesList
Gets a sorted list of dates from the entries data.

**Parameters:**
- `entries` (PSObject): Parsed entries data from Get-EntriesData

**Returns:** Array of date strings sorted chronologically

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$dates = Get-DatesList -entries $entries
```

### Get-DateHealthMetrics
Processes a single date entry and extracts health metrics.

**Parameters:**
- `date` (string): Date in MMDD format
- `dateEntry` (PSObject): The date entry object from entries data

**Returns:** PSCustomObject with Date, MaxPain, BackPain, and Sleep properties, or null if no max_pain_level

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$metrics = Get-DateHealthMetrics -date "0523" -dateEntry $entries.0523
```

### Sort-HealthDataByDate
Sorts health data chronologically by date.

**Parameters:**
- `healthData` (Array): Array of health data objects with Date property

**Returns:** Array sorted by date

**Example:**
```powershell
$sortedData = Sort-HealthDataByDate -healthData $unsortedHealthData
```

## Building Custom Datasets

The module's flexible design makes it easy to build exactly the dataset you need for your specific use case.

### Basic Pattern

```powershell
# 1. Load the data
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$dates = Get-DatesList -entries $entries

# 2. Build your custom dataset
$customData = @()
foreach ($date in $dates) {
    $dateEntry = $entries.$date
    
    # Start with a base object
    $baseObject = [PSCustomObject]@{
        Date = Convert-DateToDisplay -date $date
    }
    
    # Add whatever data you need using Set-CombinedData
    if ($dateEntry.PSObject.Properties['max_pain_level']) {
        $baseObject = Set-CombinedData -combinedData $baseObject -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
    }
    
    if ($dateEntry.PSObject.Properties['Sleep']) {
        $sleepHours = Get-SleepHours -sleepValue $dateEntry.Sleep
        $baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data $sleepHours
    }
    
    $customData += $baseObject
}

# 3. Sort if needed
$customData = Sort-HealthDataByDate -healthData $customData
```

### Example Custom Datasets

#### Pain & Sleep Tracking
```powershell
$painSleepData = @()
foreach ($date in $dates) {
    $baseObject = [PSCustomObject]@{ Date = Convert-DateToDisplay -date $date }
    
    # Add pain metrics
    if ($entries.$date.PSObject.Properties['max_pain_level']) {
        $baseObject = Set-CombinedData -combinedData $baseObject -name "MaxPain" -data ([double]$entries.$date.max_pain_level)
    }
    
    $avgBackPain = Get-AverageBackPain -dateEntry $entries.$date
    if ($avgBackPain) {
        $baseObject = Set-CombinedData -combinedData $baseObject -name "BackPain" -data $avgBackPain
    }
    
    # Add sleep data
    if ($entries.$date.PSObject.Properties['Sleep']) {
        $sleepHours = Get-SleepHours -sleepValue $entries.$date.Sleep
        $baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data $sleepHours
    }
    
    $painSleepData += $baseObject
}
```

#### Medication Correlation Analysis
```powershell
$medicationData = Get-MedicationData -entries $entries
$medicationsByDate = $medicationData | Group-Object Date

$correlationData = @()
foreach ($dateGroup in $medicationsByDate) {
    $summary = [PSCustomObject]@{
        Date = $dateGroup.Name
        MedicationCount = $dateGroup.Count
    }
    
    # Add pain correlation
    $dateKey = $dateGroup.Name -replace "/", ""
    if ($entries.PSObject.Properties[$dateKey]) {
        if ($entries.$dateKey.PSObject.Properties['max_pain_level']) {
            $summary = Set-CombinedData -combinedData $summary -name "MaxPain" -data ([double]$entries.$dateKey.max_pain_level)
        }
    }
    
    $correlationData += $summary
}
```
```

### Benefits of This Approach

- **🔧 Modular**: Each function handles one specific data type
- **🔄 Reusable**: Functions can be combined and reused across dashboards
- **🧪 Testable**: Easy to test individual data extractors
- **📈 Scalable**: Add new data types without modifying existing code
- **🎯 Focused**: Each function has a single, clear responsibility

### New Data Extraction Functions

### Get-MedicationData
Extracts all medication data from all entries.

**Parameters:**
- `entries` (PSObject): Parsed entries data from Get-EntriesData

**Returns:** Array of medication objects with Date, Timestamp, and Medication properties

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$allMedications = Get-MedicationData -entries $entries
```

### Get-ActivityData
Extracts all activity data from all entries.

**Parameters:**
- `entries` (PSObject): Parsed entries data from Get-EntriesData

**Returns:** Array of activity objects with Date, Timestamp, and Activity properties

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$allActivities = Get-ActivityData -entries $entries
```

### Get-VitalsData
Extracts all vital signs data from all entries.

**Parameters:**
- `entries` (PSObject): Parsed entries data from Get-EntriesData

**Returns:** Array of vitals objects with Date, Timestamp, and Vital properties

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$allVitals = Get-VitalsData -entries $entries
```

### Single-Date Data Extraction Functions

### Get-DateMedicationData
Extracts medication data from a single date entry.

**Parameters:**
- `date` (string): Date in MMDD format
- `dateEntry` (PSObject): The date entry object from entries data

**Returns:** Array of medication objects with Date, Timestamp, and Medication properties

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$medications = Get-DateMedicationData -date "0523" -dateEntry $entries.0523
```

### Get-DateActivityData
Extracts activity data from a single date entry.

**Parameters:**
- `date` (string): Date in MMDD format
- `dateEntry` (PSObject): The date entry object from entries data

**Returns:** Array of activity objects with Date, Timestamp, and Activity properties

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$activities = Get-DateActivityData -date "0523" -dateEntry $entries.0523
```

### Get-DateVitalsData
Extracts vital signs data from a single date entry.

**Parameters:**
- `date` (string): Date in MMDD format
- `dateEntry` (PSObject): The date entry object from entries data

**Returns:** Array of vitals objects with Date, Timestamp, and Vital properties

**Example:**
```powershell
$entries = Get-EntriesData -entriesPath "/path/to/entries.json"
$vitals = Get-DateVitalsData -date "0523" -dateEntry $entries.0523
```

### Set-CombinedData
Adds additional data to an existing combined data object with validation to prevent overwriting existing properties.

**Parameters:**
- `combinedData` (PSCustomObject): The existing combined data object
- `name` (string): The name of the property to add
- `data` (any): The data to add to the object

**Returns:** The updated PSCustomObject with the new property added

**Validation:** Throws an error if the property name already exists in the object.

**Example:**
```powershell
# Create a base object
$baseObject = [PSCustomObject]@{ Date = "06/29" }

# Add sleep data
$baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data 7.5

# Add pain data
$baseObject = Set-CombinedData -combinedData $baseObject -name "MaxPain" -data 4

# This would throw an error (property already exists):
# $baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data 8.0
```
