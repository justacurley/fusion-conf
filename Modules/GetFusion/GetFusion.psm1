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

# Function to extract health metrics for one or more datapoints and return a combined data object
function Get-HealthMetrics {
    param(
        # Output of Get-EntriesData
        [Parameter(Mandatory)]
        [PSCustomObject]$Entries,        
        [Parameter(Mandatory)]
        [ValidateSet('MaxPain', 'BackPain', 'Sleep', 'Medications', 'Activities', 'Vitals', 'ActivityDuration')]
        [string[]]$DataPoints
    )
    
    # Get cached dates if available, otherwise call Get-DatesList
    $dates = if ($null -ne $global:DatesList) { $global:DatesList } else { Get-DatesList -entries $Entries }
    
    # Initialize result hashtable
    $results = @{}
    
    # Initialize arrays for each requested data point
    if ($DataPoints -contains 'Medications') { $results['Medications'] = @() }
    if ($DataPoints -contains 'Activities') { $results['Activities'] = @() }
    if ($DataPoints -contains 'Vitals') { $results['Vitals'] = @() }
    if ($DataPoints -contains 'MaxPain' -or $DataPoints -contains 'BackPain' -or $DataPoints -contains 'Sleep' -or $DataPoints -contains 'ActivityDuration') { 
        $results['CombinedHealthData'] = @() 
    }
    
    foreach ($date in $dates) {
        $dateEntry = $Entries.$date
        
        # Handle combined health data (MaxPain, BackPain, Sleep, ActivityDuration)
        if ($DataPoints -contains 'MaxPain' -or $DataPoints -contains 'BackPain' -or $DataPoints -contains 'Sleep' -or $DataPoints -contains 'ActivityDuration') {
            $baseObject = [PSCustomObject]@{
                Date = Convert-DateToDisplay -date $date
            }
            
            if ($DataPoints -contains 'MaxPain' -and $dateEntry.PSObject.Properties['max_pain_level']) {
                $baseObject = Set-CombinedData -combinedData $baseObject -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
            }
            
            if ($DataPoints -contains 'BackPain') {
                $avgBackPain = Get-AverageBackPain -dateEntry $dateEntry
                if ($null -ne $avgBackPain) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name "BackPain" -data $avgBackPain
                }
            }
            
            if ($DataPoints -contains 'Sleep' -and $dateEntry.PSObject.Properties['Sleep']) {
                $sleepHours = Get-SleepHours -sleepValue $dateEntry.Sleep
                if ($null -ne $sleepHours) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data $sleepHours
                }
            }
            
            if ($DataPoints -contains 'ActivityDuration') {
                $totalDuration = Get-TotalActivityDuration -dateEntry $dateEntry
                if ($null -ne $totalDuration) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name "ActivityDuration" -data $totalDuration
                }
            }
            
            $results['CombinedHealthData'] += $baseObject
        }
        
        # Handle individual data types
        if ($DataPoints -contains 'Medications') {
            $medications = Get-DateMedicationData -date $date -dateEntry $dateEntry
            $results['Medications'] += $medications
        }
        
        if ($DataPoints -contains 'Activities') {
            $activities = Get-DateActivityData -date $date -dateEntry $dateEntry
            $results['Activities'] += $activities
        }
        
        if ($DataPoints -contains 'Vitals') {
            $vitals = Get-DateVitalsData -date $date -dateEntry $dateEntry
            $results['Vitals'] += $vitals
        }
    }
    
    return $results
}

# Function to calculate total activity duration for a given date entry
function Get-TotalActivityDuration {
    param($dateEntry)
    
    $totalDuration = 0
    
    # Check all timestamps for this date
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {  # This is a timestamp
            $entry = $dateEntry.$timestamp
            
            # Process Activities data
            if ($entry.PSObject.Properties['Activities'] -and $entry.Activities.PSObject.Properties.Count -gt 0) {
                foreach ($activityName in $entry.Activities.PSObject.Properties.Name) {
                    $activityData = $entry.Activities.$activityName
                    
                    # Try to parse duration as a number (assuming it's in minutes)
                    if ($activityData.duration -and $activityData.duration -match '^(\d+(?:\.\d+)?)') {
                        $totalDuration += [double]$matches[1]
                    }
                }
            }
        }
    }
    
    # Return total duration in minutes, or null if no activities found
    if ($totalDuration -gt 0) {
        return $totalDuration
    }
    
    return $null
}

# Function to extract medication data from a single date entry
function Get-DateMedicationData {
    param([string]$date, $dateEntry)
    
    # Initialize Medications array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Medications')) {
        $global:DistinctDataValues['Medications'] = @()
    }
    
    $medications = @()
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {
            $entry = $dateEntry.$timestamp
            if ($entry.PSObject.Properties['Medications'] -and $entry.Medications.PSObject.Properties.Count -gt 0) {
                # Medications are stored as key-value pairs within the Medications object
                foreach ($medicationName in $entry.Medications.PSObject.Properties.Name) {
                    $medicationDose = $entry.Medications.$medicationName
                    
                    # Track unique medications in global variable
                    if ($global:DistinctDataValues['Medications'] -notcontains $medicationName) {
                        $global:DistinctDataValues['Medications'] += $medicationName
                    }
                    
                    $medicationWithContext = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                        Timestamp = $timestamp
                        Medication = $medicationName
                        Dose = $medicationDose
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
    
    # Initialize Activities array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Activities')) {
        $global:DistinctDataValues['Activities'] = @()
    }

    $activities = @()
    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
        if ($timestamp -match '^\d{4}$') {
            $entry = $dateEntry.$timestamp
            if ($entry.PSObject.Properties['Activities'] -and $entry.Activities.PSObject.Properties.Count -gt 0) {
                # Activities are stored as properties of the Activities object
                foreach ($activityName in $entry.Activities.PSObject.Properties.Name) {
                    $activityData = $entry.Activities.$activityName
                    
                    # Track unique activities in global variable
                    if ($global:DistinctDataValues['Activities'] -notcontains $activityName) {
                        $global:DistinctDataValues['Activities'] += $activityName
                    }
                    
                    $activityWithContext = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                        Timestamp = $timestamp
                        Activity = $activityName
                        Note = $activityData.note
                        Duration = $activityData.duration
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
            
            # Check for blood pressure (bpr) data
            if ($entry.PSObject.Properties['bpr'] -and -not [string]::IsNullOrEmpty($entry.bpr)) {
                $bprWithContext = [PSCustomObject]@{
                    Date = Convert-DateToDisplay -date $date
                    Timestamp = $timestamp
                    VitalType = 'Blood Pressure'
                    Vital = $entry.bpr
                }
                $vitals += $bprWithContext
            }
            
            # Check for oxygen (o2) data
            if ($entry.PSObject.Properties['o2'] -and -not [string]::IsNullOrEmpty($entry.o2)) {
                $o2WithContext = [PSCustomObject]@{
                    Date = Convert-DateToDisplay -date $date
                    Timestamp = $timestamp
                    VitalType = 'Oxygen Level'
                    Vital = $entry.o2
                }
                $vitals += $o2WithContext
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
Export-ModuleMember -Function Get-HealthMetrics, Get-SleepHours, Get-AverageBackPain, Get-TotalActivityDuration, Convert-DateToDisplay, Get-EntriesData, Get-DatesList, Sort-HealthDataByDate, Set-CombinedData, Get-DateMedicationData, Get-DateActivityData, Get-DateVitalsData, Clear-CachedData