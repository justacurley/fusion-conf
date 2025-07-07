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
        if ($timestamp -match '^\d{4}$') {
            # This is a timestamp
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
        # Check if Show-UDToast is available and functional (PowerShell Universal environment)
        try {
            if (Get-Command Show-UDToast -ErrorAction SilentlyContinue) {
                Show-UDToast "Property '$name' already exists in the combined data object. This is overwriting the existing values." -MessageType Warning
            } else {
                Write-Warning "Property '$name' already exists in the combined data object. This is overwriting the existing values."
            }
        } catch {
            # Fallback to Write-Warning if Show-UDToast fails
            Write-Warning "Property '$name' already exists in the combined data object. This is overwriting the existing values."
        }
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
                $baseObject = Set-CombinedData -combinedData $baseObject -name 'MaxPain' -data ([double]$dateEntry.max_pain_level)
            }
            
            if ($DataPoints -contains 'BackPain') {
                $avgBackPain = Get-AverageBackPain -dateEntry $dateEntry
                if ($null -ne $avgBackPain) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'BackPain' -data $avgBackPain
                }
            }
            
            if ($DataPoints -contains 'Sleep' -and $dateEntry.PSObject.Properties['Sleep']) {
                $sleepHours = Get-SleepHours -sleepValue $dateEntry.Sleep
                if ($null -ne $sleepHours) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'Sleep' -data $sleepHours
                }
            }
            
            if ($DataPoints -contains 'ActivityDuration') {
                $totalDuration = Get-TotalActivityDuration -dateEntry $dateEntry
                if ($null -ne $totalDuration) {
                    $baseObject = Set-CombinedData -combinedData $baseObject -name 'ActivityDuration' -data $totalDuration
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
        if ($timestamp -match '^\d{4}$') {
            # This is a timestamp
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
                        Date       = Convert-DateToDisplay -date $date
                        Timestamp  = $timestamp
                        Medication = $medicationName
                        Dose       = $medicationDose
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
                        Date      = Convert-DateToDisplay -date $date
                        Timestamp = $timestamp
                        Activity  = $activityName
                        Note      = $activityData.note
                        Duration  = $activityData.duration
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
                    Date      = Convert-DateToDisplay -date $date
                    Timestamp = $timestamp
                    VitalType = 'Blood Pressure'
                    Vital     = $entry.bpr
                }
                $vitals += $bprWithContext
            }
            
            # Check for oxygen (o2) data
            if ($entry.PSObject.Properties['o2'] -and -not [string]::IsNullOrEmpty($entry.o2)) {
                $o2WithContext = [PSCustomObject]@{
                    Date      = Convert-DateToDisplay -date $date
                    Timestamp = $timestamp
                    VitalType = 'Oxygen Level'
                    Vital     = $entry.o2
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
    
    return $healthData | Sort-Object { [datetime]::ParseExact($_.Date, 'MM/dd', $null) }
}

# Function to clear cached data (useful when entries data changes)
function Clear-CachedData {
    $global:DatesList = $null
    $global:DistinctDataValues = @{}
}

Function Get-PSUCachedEntries {
    $Entries = (Get-PSUCache -Key 'entriesData' -OutVariable TempEntry) ? $TempEntry : (& {
            Write-Information 'Could not find entriesData cache'
            $EntriesPath = '/home/data/fusion-data/entries/entries.json'
            Get-EntriesData -Path $EntriesPath
            Set-PSUCache -Key 'Entries' -Value $Entries -Expiration (New-TimeSpan -Days 1) | Out-Null
        })
    $TempEntry ? (Remove-Variable -Name TempEntry -ErrorAction Ignore) : $null
    $Entries
}
# Export the functions so they can be used when the module is imported

function Find-DuplicateEntries {
    <#
    .SYNOPSIS
    Finds potentially duplicate entries across timestamps within dates
    
    .DESCRIPTION
    This function analyzes health entries to identify potential duplicates by comparing
    medications, activities, pain levels, vitals, and notes across different timestamps.
    Uses a weighted scoring system to determine similarity percentage.
    
    .PARAMETER Entries
    The entries data object (output from Get-EntriesData)
    
    .PARAMETER SimilarityThreshold
    Minimum similarity percentage to flag as duplicate (default: 80)
    
    .PARAMETER IncludeVitals
    Whether to include vitals (O2, blood pressure) in comparison (default: true)
    
    .PARAMETER IncludeNotes
    Whether to include note text in comparison (default: false - can be noisy)
    
    .EXAMPLE
    $duplicates = Find-DuplicateEntries -Entries $AllEntries
    
    .EXAMPLE
    $duplicates = Find-DuplicateEntries -Entries $AllEntries -SimilarityThreshold 90 -IncludeNotes
    
    .OUTPUTS
    Returns array of PSCustomObject with duplicate information including similarity score and reasons
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Entries,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(50, 100)]
        [int]$SimilarityThreshold = 80,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeVitals = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeNotes = $false
    )
    
    $duplicates = @()
    
    # Get all dates
    $dates = $Entries.PSObject.Properties.Name | Sort-Object
    
    foreach ($date in $dates) {
        $dateEntry = $Entries.$date
        
        # Get all timestamps for this date
        $timestamps = $dateEntry.PSObject.Properties.Name | Where-Object { $_ -match '^\d{3,4}$' } | Sort-Object
        
        # Compare each timestamp with every other timestamp
        for ($i = 0; $i -lt $timestamps.Count; $i++) {
            for ($j = $i + 1; $j -lt $timestamps.Count; $j++) {
                $entry1 = $dateEntry.($timestamps[$i])
                $entry2 = $dateEntry.($timestamps[$j])
                
                # Calculate similarity between the two entries
                $similarity = Compare-EntryData -Entry1 $entry1 -Entry2 $entry2 -IncludeVitals $IncludeVitals -IncludeNotes $IncludeNotes
                
                if ($similarity.Score -ge $SimilarityThreshold) {
                    $duplicate = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                        SimilarityScore = $similarity.Score
                        Reason = $similarity.Reason
                        Entry1 = @{
                            Timestamp = $timestamps[$i]
                            Data = $entry1
                        }
                        Entry2 = @{
                            Timestamp = $timestamps[$j]
                            Data = $entry2
                        }
                    }
                    $duplicates += $duplicate
                }
            }
        }
    }
    
    return $duplicates
}

# Helper function to compare two entry data objects
function Compare-EntryData {
    param(
        $Entry1,
        $Entry2,
        [bool]$IncludeVitals = $true,
        [bool]$IncludeNotes = $false
    )
    
    $totalWeight = 0
    $matchedWeight = 0
    $reasons = @()
    
    # Compare Medications (40% weight)
    $medicationWeight = 40
    $totalWeight += $medicationWeight
    
    $med1 = if ($Entry1.PSObject.Properties['Medications']) { $Entry1.Medications } else { $null }
    $med2 = if ($Entry2.PSObject.Properties['Medications']) { $Entry2.Medications } else { $null }
    
    if ($med1 -and $med2) {
        $medMatch = Compare-Medications -Med1 $med1 -Med2 $med2
        $matchedWeight += $medicationWeight * $medMatch
        if ($medMatch -gt 0.7) { $reasons += "Medications match" }
    } elseif (-not $med1 -and -not $med2) {
        $matchedWeight += $medicationWeight * 1.0  # Both empty = perfect match
        $reasons += "Both have no medications"
    }
    
    # Compare Pain data (30% weight)
    $painWeight = 30
    $totalWeight += $painWeight
    
    $pain1 = if ($Entry1.PSObject.Properties['Pain']) { $Entry1.Pain } else { $null }
    $pain2 = if ($Entry2.PSObject.Properties['Pain']) { $Entry2.Pain } else { $null }
    
    if ($pain1 -and $pain2) {
        $painMatch = Compare-PainData -Pain1 $pain1 -Pain2 $pain2
        $matchedWeight += $painWeight * $painMatch
        if ($painMatch -gt 0.7) { $reasons += "Pain data match" }
    } elseif (-not $pain1 -and -not $pain2) {
        $matchedWeight += $painWeight * 1.0  # Both empty = perfect match
        $reasons += "Both have no pain data"
    }
    
    # Compare Activities (20% weight)
    $activityWeight = 20
    $totalWeight += $activityWeight
    
    $act1 = if ($Entry1.PSObject.Properties['Activities']) { $Entry1.Activities } else { $null }
    $act2 = if ($Entry2.PSObject.Properties['Activities']) { $Entry2.Activities } else { $null }
    
    if ($act1 -and $act2) {
        $actMatch = Compare-Activities -Act1 $act1 -Act2 $act2
        $matchedWeight += $activityWeight * $actMatch
        if ($actMatch -gt 0.7) { $reasons += "Activities match" }
    } elseif (-not $act1 -and -not $act2) {
        $matchedWeight += $activityWeight * 1.0  # Both empty = perfect match
        $reasons += "Both have no activities"
    }
    
    # Compare Vitals (10% weight) - if enabled
    if ($IncludeVitals) {
        $vitalWeight = 10
        $totalWeight += $vitalWeight
        
        $vitalMatch = Compare-Vitals -Entry1 $Entry1 -Entry2 $Entry2
        $matchedWeight += $vitalWeight * $vitalMatch
        if ($vitalMatch -gt 0.7) { $reasons += "Vitals match" }
    }
    
    # Compare Notes (variable weight) - if enabled
    if ($IncludeNotes) {
        $noteWeight = 15
        $totalWeight += $noteWeight
        
        $note1 = if ($Entry1.PSObject.Properties['note']) { $Entry1.note } else { "" }
        $note2 = if ($Entry2.PSObject.Properties['note']) { $Entry2.note } else { "" }
        
        $noteMatch = Compare-NoteText -Note1 $note1 -Note2 $note2
        $matchedWeight += $noteWeight * $noteMatch
        if ($noteMatch -gt 0.7) { $reasons += "Notes are similar" }
    }
    
    # Calculate final score
    $score = if ($totalWeight -gt 0) { [math]::Round(($matchedWeight / $totalWeight) * 100, 1) } else { 0 }
    $reasonText = if ($reasons.Count -gt 0) { $reasons -join " and " } else { "Low similarity across all fields" }
    
    return @{
        Score = $score
        Reason = $reasonText
    }
}

# Helper function to compare medications
function Compare-Medications {
    param($Med1, $Med2)
    
    $med1Names = $Med1.PSObject.Properties.Name
    $med2Names = $Med2.PSObject.Properties.Name
    
    if ($med1Names.Count -eq 0 -and $med2Names.Count -eq 0) { return 1.0 }
    if ($med1Names.Count -eq 0 -or $med2Names.Count -eq 0) { return 0.0 }
    
    $matchCount = 0
    $total = [math]::Max($med1Names.Count, $med2Names.Count)
    
    foreach ($medName in $med1Names) {
        if ($medName -in $med2Names) {
            # Check if doses also match
            $dose1 = $Med1.$medName
            $dose2 = $Med2.$medName
            if ($dose1 -eq $dose2) {
                $matchCount += 1.0  # Perfect match
            } else {
                $matchCount += 0.5  # Medication same, dose different
            }
        }
    }
    
    return [math]::Min(1.0, $matchCount / $total)
}

# Helper function to compare pain data
function Compare-PainData {
    param($Pain1, $Pain2)
    
    $pain1Locations = $Pain1.PSObject.Properties.Name
    $pain2Locations = $Pain2.PSObject.Properties.Name
    
    if ($pain1Locations.Count -eq 0 -and $pain2Locations.Count -eq 0) { return 1.0 }
    if ($pain1Locations.Count -eq 0 -or $pain2Locations.Count -eq 0) { return 0.0 }
    
    $matchCount = 0
    $total = [math]::Max($pain1Locations.Count, $pain2Locations.Count)
    
    foreach ($location in $pain1Locations) {
        if ($location -in $pain2Locations) {
            $level1 = [double]$Pain1.$location.pain_level
            $level2 = [double]$Pain2.$location.pain_level
            
            # Consider pain levels within 1.0 point as similar
            $levelDiff = [math]::Abs($level1 - $level2)
            if ($levelDiff -le 1.0) {
                $matchCount += 1.0
            } elseif ($levelDiff -le 2.0) {
                $matchCount += 0.5
            }
        }
    }
    
    return [math]::Min(1.0, $matchCount / $total)
}

# Helper function to compare activities
function Compare-Activities {
    param($Act1, $Act2)
    
    $act1Names = $Act1.PSObject.Properties.Name
    $act2Names = $Act2.PSObject.Properties.Name
    
    if ($act1Names.Count -eq 0 -and $act2Names.Count -eq 0) { return 1.0 }
    if ($act1Names.Count -eq 0 -or $act2Names.Count -eq 0) { return 0.0 }
    
    $matchCount = 0
    $total = [math]::Max($act1Names.Count, $act2Names.Count)
    
    foreach ($actName in $act1Names) {
        if ($actName -in $act2Names) {
            $duration1 = [int]$Act1.$actName.duration
            $duration2 = [int]$Act2.$actName.duration
            
            # Consider durations within 5 minutes as similar
            $durationDiff = [math]::Abs($duration1 - $duration2)
            if ($durationDiff -le 5) {
                $matchCount += 1.0
            } elseif ($durationDiff -le 15) {
                $matchCount += 0.5
            }
        }
    }
    
    return [math]::Min(1.0, $matchCount / $total)
}

# Helper function to compare vitals
function Compare-Vitals {
    param($Entry1, $Entry2)
    
    $matchCount = 0
    $total = 0
    
    # Compare O2 levels
    $o21 = if ($Entry1.PSObject.Properties['o2']) { $Entry1.o2 } else { "" }
    $o22 = if ($Entry2.PSObject.Properties['o2']) { $Entry2.o2 } else { "" }
    
    if ($o21 -or $o22) {
        $total += 1
        if ($o21 -eq $o22) { $matchCount += 1 }
    }
    
    # Compare blood pressure
    $bpr1 = if ($Entry1.PSObject.Properties['bpr']) { $Entry1.bpr } else { "" }
    $bpr2 = if ($Entry2.PSObject.Properties['bpr']) { $Entry2.bpr } else { "" }
    
    if ($bpr1 -or $bpr2) {
        $total += 1
        if ($bpr1 -eq $bpr2) { $matchCount += 1 }
    }
    
    if ($total -gt 0) { 
        return $matchCount / $total 
    } else { 
        return 1.0 
    }
}

# Helper function to compare note text
function Compare-NoteText {
    param([string]$Note1, [string]$Note2)
    
    if ([string]::IsNullOrWhiteSpace($Note1) -and [string]::IsNullOrWhiteSpace($Note2)) { return 1.0 }
    if ([string]::IsNullOrWhiteSpace($Note1) -or [string]::IsNullOrWhiteSpace($Note2)) { return 0.0 }
    
    # Simple text similarity - could be enhanced with more sophisticated algorithms
    $Note1 = $Note1.ToLower().Trim()
    $Note2 = $Note2.ToLower().Trim()
    
    if ($Note1 -eq $Note2) { return 1.0 }
    
    # Check if one note contains the other
    if ($Note1.Contains($Note2) -or $Note2.Contains($Note1)) { return 0.8 }
    
    # Basic word overlap calculation
    $words1 = $Note1 -split '\s+' | Where-Object { $_.Length -gt 2 }
    $words2 = $Note2 -split '\s+' | Where-Object { $_.Length -gt 2 }
    
    if ($words1.Count -eq 0 -and $words2.Count -eq 0) { return 1.0 }
    if ($words1.Count -eq 0 -or $words2.Count -eq 0) { return 0.0 }
    
    $commonWords = $words1 | Where-Object { $_ -in $words2 }
    $totalWords = [math]::Max($words1.Count, $words2.Count)
    
    return $commonWords.Count / $totalWords
}

# Export all functions at the end to ensure they're all defined
Export-ModuleMember -Function Get-PSUCachedEntries, Get-HealthMetrics, Get-SleepHours, Get-AverageBackPain, Get-TotalActivityDuration, Convert-DateToDisplay, Get-EntriesData, Get-DatesList, Sort-HealthDataByDate, Set-CombinedData, Get-DateMedicationData, Get-DateActivityData, Get-DateVitalsData, Clear-CachedData, Find-DuplicateEntries, Compare-EntryData, Compare-Medications, Compare-PainData, Compare-Activities, Compare-Vitals, Compare-NoteText