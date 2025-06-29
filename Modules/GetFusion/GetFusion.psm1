# GetFusion PowerShell Module
# Contains reusable functions for processing health data from entries.json

# Global variable to track distinct data values found during processing
$global:DistinctDataValues = @{}

# Global variable to cache the dates list for performance optimization
$global:DatesList = $null

# Function to parse sleep data from various formats
function Get-SleepHours {
    param([string]$sleepValue)
    
    if ([string]::IsNullOrEmpty($sleepValue)) {
        return $null
    }
    
    # Parse "HH:MM" format like "7:39", "9:10", "6:03"
    if ($sleepValue -match '^(\d+):(\d+)$') {
        $hours = [int]$matches[1]
        $minutes = [int]$matches[2]
        return [math]::Round($hours + ($minutes / 60.0), 2)
    }
    # Handle decimal format like "7.5"
    elseif ($sleepValue -match '^(\d+(?:\.\d+)?)$') {
        return [double]$matches[1]
    }
    
    return $null
}

# Function to calculate average back pain for a given date entry
function Get-AverageBackPain {
    param($dateEntry)
    
    $backPainLevels = @()
    
    # Check all timestamps for this date
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {  # This is a timestamp
            $entry = $dateEntry.$timestamp
            
            # Process Pain data - specifically back pain
            if ($entry.PSObject.Properties['Pain']) {
                if ($entry.Pain.PSObject.Properties['back']) {
                    $backPainLevel = [double]$entry.Pain.back.pain_level
                    $backPainLevels += $backPainLevel
                }
            }
        }
    }
    
    # Calculate average back pain for the day (null if no back pain data)
    if ($backPainLevels.Count -gt 0) {
        return [math]::Round(($backPainLevels | Measure-Object -Average).Average, 1)
    }
    
    return $null
}

# Function to convert MMDD date format to MM/DD display format
function Convert-DateToDisplay {
    param([string]$date)
    
    if ($date.Length -eq 4) {
        $month = $date.Substring(0, 2)
        $day = $date.Substring(2, 2)
        return "$month/$day"
    }
    
    return $date
}

# Function to load and parse entries.json file
function Get-EntriesData {
    param([string]$entriesPath)
    
    return Get-Content -Path $entriesPath | ConvertFrom-Json
}

# Function to get sorted list of dates from entries
function Get-DatesList {
    param($entries)
    
    # Return cached dates if available
    if ($null -ne $global:DatesList) {
        return $global:DatesList
    }
    
    # Calculate and cache the dates list
    $global:DatesList = $entries.PSObject.Properties.Name | Sort-Object
    return $global:DatesList
}

# Function to add additional data to a combined data object
function Set-CombinedData {
    param(
        [PSCustomObject]$combinedData,
        [string]$name,
        $data
    )
    
    # Validate that the property name doesn't already exist
    if ($combinedData.PSObject.Properties[$name]) {
        Show-UDToast "Property '$name' already exists in the combined data object. This is overwriting the existing values." -MessageType Warning
    }
    
    # Add the new property to the existing object
    $combinedData | Add-Member -MemberType NoteProperty -Name $name -Value $data -Force
    
    return $combinedData
}

# Function to extract medication data from all entries
function Get-MedicationData {
    param($entries)
    
    $allMedications = @()
    
    # Use cached dates if available, otherwise call Get-DatesList
    $dates = if ($null -ne $global:DatesList) { $global:DatesList } else { Get-DatesList -entries $entries }
    
    # Initialize Medications array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Medications')) {
        $global:DistinctDataValues['Medications'] = @()
    }
    
    foreach ($date in $dates) {
        $dateEntry = $entries.$date
        foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
            if ($timestamp -match '^\d{4}$') {
                $entry = $dateEntry.$timestamp
                if ($entry.PSObject.Properties['Medications']) {
                    $medications = $entry.Medications
                    # Add date and timestamp context to each medication entry
                    foreach ($medication in $medications) {
                        # Track unique medications in global variable
                        if ($global:DistinctDataValues['Medications'] -notcontains $medication) {
                            $global:DistinctDataValues['Medications'] += $medication
                        }
                        
                        $medicationWithContext = [PSCustomObject]@{
                            Date = Convert-DateToDisplay -date $date
                            Timestamp = $timestamp
                            Medication = $medication
                        }
                        $allMedications += $medicationWithContext
                    }
                }
            }
        }
    }
    
    return $allMedications
}

# Function to extract activity data from all entries
function Get-ActivityData {
    param($entries)
    
    $allActivities = @()
    
    # Use cached dates if available, otherwise call Get-DatesList
    $dates = if ($null -ne $global:DatesList) { $global:DatesList } else { Get-DatesList -entries $entries }
    
    # Initialize Activities array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Activities')) {
        $global:DistinctDataValues['Activities'] = @()
    }
    
    foreach ($date in $dates) {
        $dateEntry = $entries.$date
        foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
            if ($timestamp -match '^\d{4}$') {
                $entry = $dateEntry.$timestamp
                if ($entry.PSObject.Properties['Activities']) {
                    $activities = $entry.Activities
                    # Add date and timestamp context to each activity entry
                    foreach ($activity in $activities) {
                        # Track unique activities in global variable
                        if ($global:DistinctDataValues['Activities'] -notcontains $activity) {
                            $global:DistinctDataValues['Activities'] += $activity
                        }
                        
                        $activityWithContext = [PSCustomObject]@{
                            Date = Convert-DateToDisplay -date $date
                            Timestamp = $timestamp
                            Activity = $activity
                        }
                        $allActivities += $activityWithContext
                    }
                }
            }
        }
    }
    
    return $allActivities
}

# Function to extract vitals data from all entries
function Get-VitalsData {
    param($entries)
    
    $allVitals = @()
    
    # Use cached dates if available, otherwise call Get-DatesList
    $dates = if ($null -ne $global:DatesList) { $global:DatesList } else { Get-DatesList -entries $entries }
    
    foreach ($date in $dates) {
        $dateEntry = $entries.$date
        foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
            if ($timestamp -match '^\d{4}$') {
                $entry = $dateEntry.$timestamp
                if ($entry.PSObject.Properties['Vitals']) {
                    $vitals = $entry.Vitals
                    # Add date and timestamp context to each vitals entry
                    foreach ($vital in $vitals) {
                        $vitalWithContext = [PSCustomObject]@{
                            Date = Convert-DateToDisplay -date $date
                            Timestamp = $timestamp
                            Vital = $vital
                        }
                        $allVitals += $vitalWithContext
                    }
                }
            }
        }
    }
    
    return $allVitals
}

# Function to extract medication data from a single date entry
function Get-DateMedicationData {
    param([string]$date, $dateEntry)
    
    $medications = @()
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {
            $entry = $dateEntry.$timestamp
            if ($entry.PSObject.Properties['Medications']) {
                foreach ($medication in $entry.Medications) {
                    $medicationWithContext = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                        Timestamp = $timestamp
                        Medication = $medication
                    }
                    $medications += $medicationWithContext
                }
            }
        }
    }
    return $medications
}

# Function to extract activity data from a single date entry
function Get-DateActivityData {
    param([string]$date, $dateEntry)
    
    $activities = @()
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {
            $entry = $dateEntry.$timestamp
            if ($entry.PSObject.Properties['Activities']) {
                foreach ($activity in $entry.Activities) {
                    $activityWithContext = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                        Timestamp = $timestamp
                        Activity = $activity
                    }
                    $activities += $activityWithContext
                }
            }
        }
    }
    return $activities
}

# Function to extract vitals data from a single date entry
function Get-DateVitalsData {
    param([string]$date, $dateEntry)
    
    $vitals = @()
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {
            $entry = $dateEntry.$timestamp
            if ($entry.PSObject.Properties['Vitals']) {
                foreach ($vital in $entry.Vitals) {
                    $vitalWithContext = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                        Timestamp = $timestamp
                        Vital = $vital
                    }
                    $vitals += $vitalWithContext
                }
            }
        }
    }
    return $vitals
}

# Function to sort health data by date
function Sort-HealthDataByDate {
    param($healthData)
    
    return $healthData | Sort-Object { [datetime]::ParseExact($_.Date, "MM/dd", $null) }
}

# Function to clear cached data (useful when entries data changes)
function Clear-CachedData {
    $global:DatesList = $null
    $global:DistinctDataValues = @{}
}

# Export the functions so they can be used when the module is imported
Export-ModuleMember -Function Get-SleepHours, Get-AverageBackPain, Convert-DateToDisplay, Get-EntriesData, Get-DatesList, Sort-HealthDataByDate, Set-CombinedData, Get-MedicationData, Get-ActivityData, Get-VitalsData, Get-DateMedicationData, Get-DateActivityData, Get-DateVitalsData, Clear-CachedData, Clear-CachedData