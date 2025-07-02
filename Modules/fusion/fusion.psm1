$Remote = Get-ChildItem Env:HOSTNAME -ErrorAction Ignore
if ($Remote -and $Remote.Value -like "*us-west-2*") {
    $global:EntriesPath =  "/home/data/fusion-data/entries/entries.json"
    $global:SchemaPath = Join-Path $PSScriptRoot "entries_schema.json"
    $global:MedicationsPath = Join-Path $PSScriptRoot "medications_lookup.json"
    $global:ImagePath =  "/home/data/fusion-data/img"
} else {
    $global:EntriesPath =  "/home/alex/src/fusion-conf/fusion-data/entries/entries.json"
    $global:SchemaPath = Join-Path $PSScriptRoot "entries_schema.json"
    $global:MedicationsPath = Join-Path $PSScriptRoot "medications_lookup.json"
    $global:ImagePath =  "/home/alex/src/fusion-conf/fusion-data/img"  
} 
function Add-Entry {
    [CmdletBinding()]
    param (
        [string]$Date = (Get-Date -f "MMdd"),
        [string]$Time = (Get-Date -f "HHmm"),
        [parameter()]
        [ValidateSet("tylenol1", "dilaudid4", "valium5", "vitaminD5", "lexapro2", "lexapro1", "journavx", "oxycodone")]
        [string[]]$Medications,
        [string]$ScarImage,
        [parameter(Mandatory = $false)]
        [ValidateSet('walking', 'standing', 'stairs')]
        [string[]]$Activities,
        [parameter()]
        # [ValidateScript({ $_.Count -eq $Activities.Count })]
        [int[]]$ActivitiesDuration,
        [string[]]$PainLocation,
        [string[]]$PainLevel,
        [string]$o2,
        [string]$bpr,
        [string]$Note,
        [string]$Sleep
    )    
    begin {
        # Do some param validation we cant do in ValidateScript
        if (($Activities -and $ActivitiesDuration) -and ($Activities.Count -ne $ActivitiesDuration.Count)) {
            throw "Activities Count ne ActivitiesDuration $Activities : $($ActivitiesDuration -join ",")"
        }
        if (($PainLocation -and $PainLevel) -and ($PainLocation.Count -ne $PainLevel.Count)) {
            write-host $PainLevel
            throw "PainLocation Count ne PainLevel $PainLocation : $($PainLevel -join ",")"
        }
    }
    end {
        $Schema = Get-Content -Path $SchemaPath | ConvertFrom-Json -AsHashtable
        $Entries = Get-Content -Path $Entriespath | ConvertFrom-Json -AsHashtable
        # Add Date and Time keys
        if ($Date -notin $Entries.keys) {
            $Entries.add($Date,@{})
        }
        if ($Time -notin $Entries[$Date].keys) {
            $Entries[$Date].add($Time,@{})           
        }
        $Entries[$Date][$Time]=$Schema["EmptyEntry"]
        $CurrentEntry = $Entries[$Date][$Time]
        # Add medications
        $Medications.ForEach({
                $MedName = ($_ -replace '\d', '')
                $CurrentEntry["Medications"][$MedName] = $schema["Medications"][$_]
            })
        
        # Set medication_taken field for DynamoDB GSI
        if ($Medications) {
            $MedNames = $Medications | ForEach-Object { $_ -replace '\d', '' }
            $CurrentEntry["medication_taken"] = ($MedNames -join ',')
        } else {
            $CurrentEntry["medication_taken"] = ""
        }
        
        # Add activities with nested structure per schema
        $AllActivities = @{}
        for ($i = 0; $i -lt $Activities.Count; $i++) {
            $AllActivities[$Activities[$i]] = @{
                "duration" = $ActivitiesDuration[$i]
                "note" = ""
            }
        }
        $CurrentEntry["Activities"] = $AllActivities
        
        # Add pain with nested structure per schema
        $AllPain = @{}
        for ($i = 0; $i -lt $PainLocation.Count; $i++) {
            $AllPain[$PainLocation[$i]] = @{
                "pain_level" = [double]$PainLevel[$i]
                "note" = ""
            }
        }
        $CurrentEntry["Pain"] = $AllPain
        # Add o2, bpr, notes
        $CurrentEntry["o2"] = $o2
        $CurrentEntry["bpr"] = $bpr
        $CurrentEntry["note"] = $Note
        if ($Sleep -and ('Sleep' -notin $Entries[$Date].keys)) {
            $Entries[$Date]['Sleep'] = $Sleep
        }
        if ($ScarImage -and ('ScarImage' -notin $Entries[$Date].keys)) {
            $Entries[$Date]['ScarImage'] = $ScarImage
        }
        
        $Entries[$Date][$Time] = $CurrentEntry
        
        # Update the daily max pain level
        Update-DailyMaxPainLevel -Entries $Entries -Date $Date
        
        Out-File $EntriesPath -InputObject ($Entries | convertto-json -depth 99)
    }
}
Set-Alias -Name ae -Value Add-Entry
Export-ModuleMember -Function Add-Entry -Alias ae
# Add-Entry -Time 1300 -Medications dilaudid4 -PainLocation back -PainLevel 5-6 -o2 90 -bpr 120/80 -Note "short walk this morning, didn't increase pain"

function ConvertTo-EntriesFormat {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )
    
    # Validate input type
    if ($Entry -isnot [PSCustomObject]) {
        throw "Entry parameter must be a PSCustomObject"
    }
    
    # Convert to entries.json format
    Write-Host "Converting entry to entries.json format..."

    # Extract basic info
    $Date = if ($Entry.date) { $Entry.date } else { "" }
    $Timestamp = if ($Entry.timestamp) { $Entry.timestamp } else { "" }

    # Build Medications object - New format uses boolean flags like med_dilaudid_4mg: true
    $Medications = @{}
    $medProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like "med_*" -and $_.Value -eq $true }
    
    foreach ($medProp in $medProperties) {
        # Parse "med_dilaudid_4mg" format
        if ($medProp.Name -match "^med_(.+?)_(.+)$") {
            $medName = $matches[1]
            $dosage = $matches[2]
            
            # Validate that this looks like a valid medication name (known medication names)
            $validMedicationNames = @("tylenol", "dilaudid", "valium", "vitaminD", "lexapro", "journavx", "oxycodone")
            if ($medName -in $validMedicationNames) {
                # Handle multiple doses of same medication
                if ($Medications.ContainsKey($medName)) {
                    # Convert to array if not already
                    if ($Medications[$medName] -is [string]) {
                        $Medications[$medName] = @($Medications[$medName], $dosage)
                    } else {
                        # Already an array, add new element
                        $Medications[$medName] = $Medications[$medName] + @($dosage)
                    }
                } else {
                    $Medications[$medName] = $dosage
                }
            }
        }
    }

    # Build Pain object - New Schema: { "location": { "pain_level": 0.0, "note": "" } }
    $Pain = @{}
    # Only process pain data if add_pain flag is true or pain properties exist
    if ($Entry.add_pain -eq $true -or ($Entry.PSObject.Properties | Where-Object { $_.Name -like "pain_location_*" })) {
        # Get all pain location/level pairs
        $painProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like "pain_location_*" }
        foreach ($painProp in $painProperties) {
            $id = $painProp.Name -replace "pain_location_", ""
            $location = $painProp.Value
            $levelProp = "pain_level_$id"
            $noteProp = "pain_note_$id"
            
            if ($Entry.PSObject.Properties[$levelProp]) {
                $level = $Entry.PSObject.Properties[$levelProp].Value
                $note = if ($Entry.PSObject.Properties[$noteProp]) { 
                    $Entry.PSObject.Properties[$noteProp].Value 
                } else { "" }
                
                if ($location -and $level) {
                    # Try to convert level to double with error handling
                    try {
                        $levelDouble = [double]$level
                        # New schema format: nested object with pain_level as decimal number and note
                        $Pain[$location] = @{
                            "pain_level" = $levelDouble
                            "note" = $note
                        }
                    } catch {
                        Write-Warning "Invalid pain level '$level' for location '$location' - skipping entry"
                    }
                }
            }
        }
    }

    # Build Activities object - New Schema: { "activity_name": { "duration": 0, "note": "" } }
    $Activities = @{}
    Write-Information "Looking for activity properties..."

    # Only process activity data if add_activity flag is true or activity properties exist
    if ($Entry.add_activity -eq $true -or ($Entry.PSObject.Properties | Where-Object { $_.Name -like "activities_type_*" })) {
        # Get all activity type/length pairs
        $activityProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like "activities_type_*" }
        Write-Information "Found $($activityProperties.Count) activity type properties"

        foreach ($activityProp in $activityProperties) {
            $id = $activityProp.Name -replace "activities_type_", ""
            $activityType = $activityProp.Value
            $lengthProp = "activities_length_$id"
            $noteProp = "activities_note_$id"
            
            Write-Information "Processing activity ID $id, Type: $activityType"
            Write-Information "Looking for $lengthProp"
            
            # Check for corresponding length and note properties
            $duration = $null
            $note = ""
            if ($Entry.PSObject.Properties[$lengthProp]) {
                try {
                    $duration = [int]$Entry.PSObject.Properties[$lengthProp].Value
                    Write-Information "Found length property with value: $duration"
                } catch {
                    Write-Warning "Invalid activity duration '$($Entry.PSObject.Properties[$lengthProp].Value)' for activity '$activityType' - skipping"
                    continue
                }
            } else {
                Write-Information "No matching duration property found for ID $id"
                # List all available properties for debugging
                $availableProps = $Entry.PSObject.Properties | Where-Object { $_.Name -like "*$id*" } | Select-Object -ExpandProperty Name
                Write-Information "Available properties with ID $id : $($availableProps -join ', ')"
            }
            
            if ($Entry.PSObject.Properties[$noteProp]) {
                $note = $Entry.PSObject.Properties[$noteProp].Value
            }
            
            if ($activityType -and $null -ne $duration) {
                # New schema format: nested object with duration and note
                $Activities[$activityType] = @{
                    "duration" = $duration
                    "note" = $note
                }
                Write-Information "Added activity: $activityType = {duration: $duration, note: '$note'}"
            } else {
                Write-Information "Skipping activity - Type: '$activityType', Duration: '$duration'"
            }
        }
    }
    
    # Create the entry structure
    $EntryStructure = @{
        "Medications" = $Medications
        "Pain"        = $Pain
        "Activities"  = $Activities
        "o2"          = if ($Entry.o2) { $Entry.o2 } else { "" }
        "bpr"         = if ($Entry.bpr) { $Entry.bpr } else { "" }
        "note"        = if ($Entry.notes) { $Entry.notes } else { "" }
        
        # DynamoDB GSI fields - Updated for new schema
        "medication_taken" = if ($Medications.Keys.Count -gt 0) { ($Medications.Keys -join ",") } else { "" }
    }

    # Create the full structure for entries.json
    $FullEntry = @{
        $Date = @{
            $Timestamp = $EntryStructure
        }
    }
    
    # Add date-level fields like Sleep if present
    if ($Entry.sleep) {
        $FullEntry[$Date]["Sleep"] = $Entry.sleep
    }

    # Return the result
    return @{
        FullEntry = $FullEntry
        EntryStructure = $EntryStructure
        Date = $Date
        Timestamp = $Timestamp
    }
}
Export-ModuleMember -Function ConvertTo-EntriesFormat

function Update-DailyMaxPainLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Entries,
        
        [Parameter(Mandatory = $true)]
        [string]$Date
    )
    
    # Calculate the maximum pain level for all timestamps in the given date
    $maxPainForDay = 0.0
    
    if ($Entries.ContainsKey($Date)) {
        foreach ($timestamp in $Entries[$Date].Keys) {
            # Skip non-timestamp entries like "Sleep", "ScarImage", "max_pain_level"
            if ($timestamp -match '^\d{4}$') {
                $entry = $Entries[$Date][$timestamp]
                if ($entry -is [hashtable] -and $entry.ContainsKey("Pain") -and $entry.Pain) {
                    if ($entry.Pain -is [hashtable]) {
                        foreach ($location in $entry.Pain.Keys) {
                            $painData = $entry.Pain[$location]
                            if ($painData -is [hashtable] -and $painData.ContainsKey("pain_level")) {
                                try {
                                    $level = [double]$painData["pain_level"]
                                    if ($level -gt $maxPainForDay) { 
                                        $maxPainForDay = $level 
                                    }
                                } catch {
                                    Write-Warning "Invalid pain level data for $Date/$timestamp/$location - skipping"
                                }
                            }
                        }
                    }
                }
            }
        }
        
        # Set the daily max pain level at the date level
        $Entries[$Date]["max_pain_level"] = $maxPainForDay
    }
    
    Write-Information "Updated daily max pain level for $Date : $maxPainForDay"
    return $maxPainForDay
}

Export-ModuleMember -Function Update-DailyMaxPainLevel

function Save-ConvertedEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ConvertedEntry,
        
        [Parameter(Mandatory = $false)]
        [string]$EntriesPath = $global:EntriesPath
    )
    
    Write-Information "Starting Save-ConvertedEntry"
    
    # Load existing entries
    $Entries = @{}
    if (Test-Path $EntriesPath) {
        $Entries = Get-Content -Path $EntriesPath | ConvertFrom-Json -AsHashtable
    }
    
    # Extract date and timestamp from the converted entry
    $Date = $ConvertedEntry.Date
    $Timestamp = $ConvertedEntry.Timestamp
    $EntryStructure = $ConvertedEntry.EntryStructure
    
    Write-Information "Saving entry for Date: $Date, Timestamp: $Timestamp"
    
    # Add to entries structure
    if (-not $Entries.ContainsKey($Date)) {
        $Entries[$Date] = @{}
    }
    
    $Entries[$Date][$Timestamp] = $EntryStructure
    
    # Add date-level fields from FullEntry if present
    if ($ConvertedEntry.FullEntry[$Date] -and $ConvertedEntry.FullEntry[$Date].ContainsKey("Sleep")) {
        $Entries[$Date]["Sleep"] = $ConvertedEntry.FullEntry[$Date]["Sleep"]
    }
    
    # Update the daily max pain level
    Write-Information "Updating daily max pain level for $Date"
    $null = Update-DailyMaxPainLevel -Entries $Entries -Date $Date
    
    # Save the entries
    Write-Information "Saving entries to $EntriesPath"
    $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8
    
    Write-Information "Entry saved successfully"
    return $true
}

Export-ModuleMember -Function Save-ConvertedEntry

function Get-CachedEntriesData {
    <#
    .SYNOPSIS
    Gets entries data from PSU cache or file with automatic cache management
    
    .DESCRIPTION
    This function attempts to load entries data from PSU cache first, falling back to file if cache is empty.
    It handles PSCustomObject to hashtable conversion and updates the cache when loading from file.
    
    .PARAMETER CacheKey
    The PSU cache key to use. Defaults to 'entriesData'
    
    .PARAMETER EntriesPathVariableName
    The PSU variable name that contains the entries file path. Defaults to 'EntriesPath'
    
    .PARAMETER ForceReload
    If true, bypasses cache and loads directly from file, then updates cache
    
    .EXAMPLE
    $entries = Get-CachedEntriesData
    
    .EXAMPLE
    $entries = Get-CachedEntriesData -ForceReload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CacheKey = 'entriesData',
        
        [Parameter(Mandatory = $false)]
        [string]$EntriesPathVariableName = 'EntriesPath',
        
        [Parameter(Mandatory = $false)]
        [switch]$ForceReload
    )
    
    try {
        $AllEntries = $null
        
        # Try to get from cache unless force reload is requested
        if (-not $ForceReload) {
            try {
                $AllEntries = Get-PSUCache -Key $CacheKey
                Write-Information "Attempted to load from PSU cache with key: $CacheKey"
            } catch {
                Write-Information "PSU cache not available or failed: $($_.Exception.Message)"
            }
        }
        
        if (-not $AllEntries -or $ForceReload) {
            # Fallback to loading from file if cache is empty or force reload requested
            Write-Information "Loading entries from file (cache empty or force reload)"
            
            try {
                Import-Module -Name GetFusion -Force
                $EntriesPath = Get-PSUVariable -Name $EntriesPathVariableName -ValueOnly
                Write-Information "Got entries path from PSU variable: $EntriesPath"
            } catch {
                # Fallback to global variable if PSU variable not available
                Write-Information "PSU variable not available, using global variable"
                $EntriesPath = $global:EntriesPath
            }
            
            if (-not $EntriesPath) {
                throw "Could not determine entries file path from PSU variable or global variable"
            }
            
            $AllEntries = Get-EntriesData -entriesPath $EntriesPath
            
            # Update cache for next time (only if PSU cache is available)
            try {
                Set-PSUCache -Key $CacheKey -Value $AllEntries -AbsoluteExpiration (Get-Date).AddDays(1)
                Write-Information "Updated PSU cache with key: $CacheKey"
            } catch {
                Write-Information "Could not update PSU cache: $($_.Exception.Message)"
            }
        } else {
            Write-Information "Loaded entries from PSU cache"
            
            # Convert PSCustomObject to hashtable if needed
            if ($AllEntries -is [System.Management.Automation.PSCustomObject]) {
                Write-Information "Converting cached PSCustomObject to hashtable"
                $AllEntries = $AllEntries | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
            }
        }
        
        return $AllEntries
        
    } catch {
        Write-Error "Error in Get-CachedEntriesData: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Get-CachedEntriesData

function Remove-TimeEntry {
    <#
    .SYNOPSIS
    Removes a timestamped entry from a specific date in the entries data
    
    .DESCRIPTION
    This function safely removes a timestamped entry (e.g., "1430", "0800") from a specific date (MMDD format)
    in the entries.json file. It includes validation, backup options, and automatic cache updates.
    
    .PARAMETER Date
    The date in MMDD format (e.g., "0701", "1225") from which to remove the entry
    
    .PARAMETER Time
    The timestamp in HHMM format (e.g., "1430", "0800") to remove from the specified date
    
    .PARAMETER EntriesPath
    Optional. The path to the entries.json file. If not provided, uses global variable or PSU variable
    
    .PARAMETER CreateBackup
    Optional. If true, creates a backup of the entries file before making changes. Default is true
    
    .PARAMETER UpdateCache
    Optional. If true, updates the PSU cache after successful removal. Default is true
    
    .EXAMPLE
    Remove-TimeEntry -Date "0701" -Time "1430"
    
    .EXAMPLE
    Remove-TimeEntry -Date "1225" -Time "0800" -WhatIf
    
    .EXAMPLE
    Remove-TimeEntry -Date "0615" -Time "2130" -CreateBackup:$false
    
    .OUTPUTS
    Returns $true if the entry was successfully removed, $false otherwise
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d{4}$')]
        [string]$Date,
        
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^\d{3,4}$')]
        [string]$Time,
        
        [Parameter(Mandatory = $false)]
        [string]$EntriesPath,
        
        [Parameter(Mandatory = $false)]
        [bool]$CreateBackup = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$UpdateCache = $true
    )
    
    try {
        Write-Information "Starting Remove-TimeEntry for Date: $Date, Time: $Time"
        
        # Determine entries file path
        if (-not $EntriesPath) {
            try {
                $EntriesPath = Get-PSUVariable -Name "EntriesPath" -ValueOnly
                Write-Information "Got entries path from PSU variable: $EntriesPath"
            } catch {
                $EntriesPath = $global:EntriesPath
                Write-Information "Using global entries path: $EntriesPath"
            }
        }
        
        if (-not $EntriesPath -or -not (Test-Path $EntriesPath)) {
            throw "Entries file not found at path: $EntriesPath"
        }
        
        # Load existing entries
        Write-Information "Loading entries from: $EntriesPath"
        $Entries = Get-Content -Path $EntriesPath | ConvertFrom-Json -AsHashtable
        
        # Validate that the date exists
        if (-not $Entries.ContainsKey($Date)) {
            Write-Warning "Date '$Date' not found in entries data"
            return $false
        }
        
        # Normalize time format (ensure 4 digits)
        $NormalizedTime = if ($Time.Length -eq 3) { "0$Time" } else { $Time }
        
        # Validate that the timestamp exists
        if (-not $Entries[$Date].ContainsKey($NormalizedTime)) {
            Write-Warning "Timestamp '$NormalizedTime' not found in date '$Date'"
            return $false
        }
        
        # Get the entry details for logging
        $EntryToRemove = $Entries[$Date][$NormalizedTime]
        $EntryJson = $EntryToRemove | ConvertTo-Json -Depth 5 -Compress
        
        Write-Information "Found entry to remove: $EntryJson"
        
        # WhatIf processing (using built-in SupportsShouldProcess)
        if ($WhatIfPreference) {
            Write-Host "WhatIf: Would remove timestamp '$NormalizedTime' from date '$Date'" -ForegroundColor Yellow
            Write-Host "Entry content: $EntryJson" -ForegroundColor Cyan
            return $true
        }
        
        # ShouldProcess check for -Confirm parameter
        $shouldProcessMessage = "Remove timestamp '$NormalizedTime' from date '$Date'"
        if (-not $PSCmdlet.ShouldProcess($shouldProcessMessage, "Remove-TimeEntry")) {
            Write-Information "Operation cancelled by user"
            return $false
        }
        
        # Create backup if requested
        if ($CreateBackup) {
            $BackupPath = "$EntriesPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Write-Information "Creating backup at: $BackupPath"
            Copy-Item -Path $EntriesPath -Destination $BackupPath -Force
        }
        
        # Remove the timestamp entry
        Write-Information "Removing timestamp '$NormalizedTime' from date '$Date'"
        $Entries[$Date].Remove($NormalizedTime)
        
        # If this was the last timestamp for the date, optionally remove the entire date
        $remainingTimeEntries = $Entries[$Date].Keys | Where-Object { $_ -match '^\d{3,4}$' }
        if ($remainingTimeEntries.Count -eq 0) {
            # Check if there are any non-timestamp entries (Sleep, max_pain_level, ScarImage)
            $nonTimeEntries = $Entries[$Date].Keys | Where-Object { $_ -notmatch '^\d{3,4}$' }
            if ($nonTimeEntries.Count -eq 0) {
                Write-Information "No remaining entries for date '$Date', removing entire date entry"
                $Entries.Remove($Date)
            } else {
                Write-Information "Date '$Date' still has non-timestamp entries: $($nonTimeEntries -join ', ')"
            }
        }
        
        # Recalculate daily max pain level if there are still time entries for this date
        if ($Entries.ContainsKey($Date)) {
            Write-Information "Recalculating daily max pain level for date '$Date'"
            $null = Update-DailyMaxPainLevel -Entries $Entries -Date $Date
        }
        
        # Save the updated entries
        Write-Information "Saving updated entries to: $EntriesPath"
        $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8
        
        # Update cache if requested and PSU is available
        if ($UpdateCache) {
            try {
                Write-Information "Updating PSU cache"
                Set-PSUCache -Key "entriesData" -Value $Entries -AbsoluteExpiration (Get-Date).AddDays(1)
            } catch {
                Write-Information "Could not update PSU cache (not in PSU environment): $($_.Exception.Message)"
            }
        }
        
        Write-Information "Successfully removed timestamp '$NormalizedTime' from date '$Date'"
        return $true
        
    } catch {
        Write-Error "Error in Remove-TimeEntry: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Remove-TimeEntry