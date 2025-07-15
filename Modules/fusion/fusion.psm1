using module ../HealthEntryClasses/HealthEntryClasses.psm1
$Remote = Get-ChildItem Env:HOSTNAME -ErrorAction Ignore
if ($Remote -and $Remote.Value -like '*us-west-2*') {
    $global:EntriesPath = '/home/data/fusion-data/entries/entries.json'
    $global:SchemaPath = Join-Path $PSScriptRoot 'entries_schema.json'
    $global:MedicationsPath = Join-Path $PSScriptRoot 'medications_lookup.json'
    $global:ImagePath = '/home/data/fusion-data/img'
}
else {
    $global:EntriesPath = '/home/alex/src/fusion-conf/fusion-data/entries/entries.json'
    $global:SchemaPath = Join-Path $PSScriptRoot 'entries_schema.json'
    $global:MedicationsPath = Join-Path $PSScriptRoot 'medications_lookup.json'
    $global:ImagePath = '/home/alex/src/fusion-conf/fusion-data/img'
}

function ConvertTo-EntriesFormat {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )

    # Validate input type
    if ($Entry -isnot [PSCustomObject]) {
        throw 'Entry parameter must be a PSCustomObject'
    }

    # Convert to entries.json format
    Write-Host 'Converting entry to entries.json format...'

    # Create new HealthEntry instance
    $healthEntry = [HealthEntry]::new()

    # Set Date and Time
    $healthEntry.Date = if ($Entry.date) { $Entry.date } else { '' }
    $healthEntry.Time = if ($Entry.timestamp) { $Entry.timestamp } else { '' }

    # Process medications using MedicationTaken class
    $medProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'med_*' -and ($_.Value -eq $true -or $_.Value -eq 'true') }
    foreach ($medProp in $medProperties) {
        # Parse "med_dilaudid_4mg" format
        if ($medProp.Name -match '^med_(.+?)_(.+)$') {
            $medName = $matches[1]
            $dosage = $matches[2]

            try {
                $medication = [MedicationTaken]::new($dosage, $medName)
                $healthEntry.Medication += $medication
                Write-Information "Added medication: $medName $dosage"
            }
            catch {
                Write-Warning "Invalid medication: $medName $dosage - $($_.Exception.Message)"
            }
        }
    }

    # Process pain using PainLocation class with flexible location names
    # Handle boolean strings as well as boolean values
    $shouldProcessPain = ($Entry.add_pain -eq $true -or $Entry.add_pain -eq 'true') -or
    ($Entry.PSObject.Properties | Where-Object { $_.Name -like 'pain_location_*' })

    if ($shouldProcessPain) {
        $painProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'pain_location_*' }
        foreach ($painProp in $painProperties) {
            $id = $painProp.Name -replace 'pain_location_', ''
            $location = $painProp.Value
            $levelProp = "pain_level_$id"
            $noteProp = "pain_note_$id"

            if ($Entry.PSObject.Properties[$levelProp] -and $location) {
                try {
                    $level = [double]$Entry.PSObject.Properties[$levelProp].Value
                    $note = if ($Entry.PSObject.Properties[$noteProp]) { $Entry.PSObject.Properties[$noteProp].Value } else { '' }

                    # Use the new constructor signature: location, level, note
                    $pain = [PainLocation]::new($location, $level, $note)
                    $healthEntry.Pain += $pain
                    Write-Information "Added pain: $location level $level"
                }
                catch {
                    Write-Warning "Invalid pain entry: $location $level - $($_.Exception.Message)"
                }
            }
        }
    }

    # Process activities using Activity class
    # Handle boolean strings as well as boolean values
    $shouldProcessActivity = ($Entry.add_activity -eq $true -or $Entry.add_activity -eq 'true') -or
    ($Entry.PSObject.Properties | Where-Object { $_.Name -like 'activities_type_*' })

    if ($shouldProcessActivity) {
        $activityProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like 'activities_type_*' }
        Write-Information "Found $($activityProperties.Count) activity type properties"

        foreach ($activityProp in $activityProperties) {
            $id = $activityProp.Name -replace 'activities_type_', ''
            $activityType = $activityProp.Value
            $lengthProp = "activities_length_$id"
            $noteProp = "activities_note_$id"

            Write-Information "Processing activity ID $id, Type: $activityType"

            if ($Entry.PSObject.Properties[$lengthProp] -and $activityType) {
                try {
                    $duration = [int]$Entry.PSObject.Properties[$lengthProp].Value
                    $note = if ($Entry.PSObject.Properties[$noteProp]) { $Entry.PSObject.Properties[$noteProp].Value } else { '' }

                    $activity = [Activity]::new($activityType, $duration, $note)
                    $healthEntry.Activity += $activity
                    Write-Information "Added activity: $activityType duration $duration"
                }
                catch {
                    Write-Warning "Invalid activity entry: $activityType - $($_.Exception.Message)"
                }
            }
        }
    }

    # Process vitals using Vitals class
    if ($Entry.o2 -or $Entry.bpr) {
        try {
            $o2 = if ($Entry.o2) { [int]$Entry.o2 } else { 95 }
            $bpr = if ($Entry.bpr) { $Entry.bpr } else { '120/80' }

            $healthEntry.Vitals = [Vitals]::new($o2, $bpr)
            Write-Information "Added vitals: o2=$o2 bpr=$bpr"
        }
        catch {
            Write-Warning "Invalid vitals: o2=$($Entry.o2) bpr=$($Entry.bpr) - $($_.Exception.Message)"
        }
    }

    # Set notes
    if ($Entry.notes) {
        $healthEntry.Note = $Entry.notes
    }

    if ($Entry.mood) {
        try {
            $moodLevel = [int]$Entry.mood
            $moodNote = if ($Entry.mood_note) { $Entry.mood_note } else { '' }

            $healthEntry.Mood = [Mood]::new($moodLevel, $moodNote)
            Write-Information "Added mood: level $moodLevel"
        }
        catch {
            Write-Warning "Invalid mood entry: level=$($Entry.mood) note=$($Entry.mood_note) - $($_.Exception.Message)"
        }
    }
    # No need for strict validation - allow empty entries
    # The individual classes handle their own validation

    # Use the class's ToHashtable() method for consistent serialization
    $entryStructure = $healthEntry.ToHashtable()

    # Create the full structure for entries.json
    $fullEntry = @{
        $healthEntry.Date = @{
            $healthEntry.Time = $entryStructure
        }
    }

    # Add date-level fields like Sleep if present
    if ($Entry.sleep) {
        $fullEntry[$healthEntry.Date]['Sleep'] = $Entry.sleep
    }

    # Return the result
    return @{
        FullEntry      = $fullEntry
        EntryStructure = $entryStructure
        Date           = $healthEntry.Date
        Timestamp      = $healthEntry.Time
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
                if ($entry -is [hashtable] -and $entry.ContainsKey('Pain') -and $entry.Pain) {
                    if ($entry.Pain -is [hashtable]) {
                        foreach ($location in $entry.Pain.Keys) {
                            $painData = $entry.Pain[$location]
                            if ($painData -is [hashtable] -and $painData.ContainsKey('pain_level')) {
                                try {
                                    $level = [double]$painData['pain_level']
                                    if ($level -gt $maxPainForDay) {
                                        $maxPainForDay = $level
                                    }
                                }
                                catch {
                                    Write-Warning "Invalid pain level data for $Date/$timestamp/$location - skipping"
                                }
                            }
                        }
                    }
                }
            }
        }

        # Set the daily max pain level at the date level
        $Entries[$Date]['max_pain_level'] = $maxPainForDay
    }

    Write-Information "Updated daily max pain level for $Date : $maxPainForDay"
    return $maxPainForDay
}

Export-ModuleMember -Function Update-DailyMaxPainLevel

function Save-ConvertedEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                # Check for both possible key names (Date/Timestamp or date/timestamp)
                $hasDate = $_.ContainsKey('Date') -or $_.ContainsKey('date')
                $hasTimestamp = $_.ContainsKey('Timestamp') -or $_.ContainsKey('timestamp')

                if (-not $hasDate -or -not $hasTimestamp) {
                    throw 'ConvertedEntry must contain Date/date and Timestamp/timestamp properties'
                }

                $dateValue = if ($_.ContainsKey('Date')) { $_.Date } else { $_.date }
                $timestampValue = if ($_.ContainsKey('Timestamp')) { $_.Timestamp } else { $_.timestamp }

                if ([string]::IsNullOrWhiteSpace($dateValue) -or [string]::IsNullOrWhiteSpace($timestampValue)) {
                    throw 'Date and Timestamp values cannot be null or empty'
                }
                return $true
            })]
        [hashtable]$ConvertedEntry,

        [Parameter(Mandatory = $false)]
        [string]$EntriesPath = $global:EntriesPath
    )

    Write-Information 'Starting Save-ConvertedEntry'

    # Load existing entries
    $Entries = @{}
    if (Test-Path $EntriesPath) {
        $Entries = Get-Content -Path $EntriesPath | ConvertFrom-Json -AsHashtable
    }

    # Extract date and timestamp from the converted entry (handle both naming conventions)
    $Date = if ($ConvertedEntry.ContainsKey('Date')) { $ConvertedEntry.Date } else { $ConvertedEntry.date }
    $Timestamp = if ($ConvertedEntry.ContainsKey('Timestamp')) { $ConvertedEntry.Timestamp } else { $ConvertedEntry.timestamp }
    $EntryStructure = $ConvertedEntry.EntryStructure

    Write-Information "Saving entry for Date: $Date, Timestamp: $Timestamp"

    # Add to entries structure
    if (-not $Entries.ContainsKey($Date)) {
        $Entries[$Date] = @{}
    }

    $Entries[$Date][$Timestamp] = $EntryStructure

    # Add all date-level fields from FullEntry if present
    if ($ConvertedEntry.FullEntry[$Date]) {
        $dateLevelFields = @('Sleep', 'ScarImage')  # Could be expanded
        foreach ($field in $dateLevelFields) {
            if ($ConvertedEntry.FullEntry[$Date].ContainsKey($field)) {
                $Entries[$Date][$field] = $ConvertedEntry.FullEntry[$Date][$field]
            }
        }
    }

    # Update the daily max pain level
    Write-Information "Updating daily max pain level for $Date"
    $null = Update-DailyMaxPainLevel -Entries $Entries -Date $Date

    # Save the entries
    Write-Information "Saving entries to $EntriesPath"
    $Entries | ConvertTo-Json -Depth 99 -Compress | Out-File $EntriesPath -Encoding UTF8

    Write-Information 'Entry saved successfully'
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
            }
            catch {
                Write-Information "PSU cache not available or failed: $($_.Exception.Message)"
            }
        }

        if (-not $AllEntries -or $ForceReload) {
            # Fallback to loading from file if cache is empty or force reload requested
            Write-Information 'Loading entries from file (cache empty or force reload)'

            try {
                Import-Module -Name GetFusion -Force
                $EntriesPath = Get-PSUVariable -Name $EntriesPathVariableName -ValueOnly
                Write-Information "Got entries path from PSU variable: $EntriesPath"
            }
            catch {
                # Fallback to global variable if PSU variable not available
                Write-Information 'PSU variable not available, using global variable'
                $EntriesPath = $global:EntriesPath
            }

            if (-not $EntriesPath) {
                throw 'Could not determine entries file path from PSU variable or global variable'
            }

            $AllEntries = Get-EntriesData -entriesPath $EntriesPath

            # Update cache for next time (only if PSU cache is available)
            try {
                Set-PSUCache -Key $CacheKey -Value $AllEntries -AbsoluteExpiration (Get-Date).AddDays(1)
                Write-Information "Updated PSU cache with key: $CacheKey"
            }
            catch {
                Write-Information "Could not update PSU cache: $($_.Exception.Message)"
            }
        }
        else {
            Write-Information 'Loaded entries from PSU cache'

            # Convert PSCustomObject to hashtable if needed
            if ($AllEntries -is [System.Management.Automation.PSCustomObject]) {
                Write-Information 'Converting cached PSCustomObject to hashtable'
                $AllEntries = $AllEntries | ConvertTo-Json -Depth 20 | ConvertFrom-Json -AsHashtable
            }
        }

        return $AllEntries

    }
    catch {
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
                $EntriesPath = Get-PSUVariable -Name 'EntriesPath' -ValueOnly
                Write-Information "Got entries path from PSU variable: $EntriesPath"
            }
            catch {
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
        if (-not $PSCmdlet.ShouldProcess($shouldProcessMessage, 'Remove-TimeEntry')) {
            Write-Information 'Operation cancelled by user'
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
            }
            else {
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
                Write-Information 'Updating PSU cache'
                Set-PSUCache -Key 'entriesData' -Value $Entries -AbsoluteExpiration (Get-Date).AddDays(1)
            }
            catch {
                Write-Information "Could not update PSU cache (not in PSU environment): $($_.Exception.Message)"
            }
        }

        Write-Information "Successfully removed timestamp '$NormalizedTime' from date '$Date'"
        return $true

    }
    catch {
        Write-Error "Error in Remove-TimeEntry: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Remove-TimeEntry