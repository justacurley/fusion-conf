using module ../HealthEntryClasses/HealthEntryClasses.psm1

# Legacy global path support for backward compatibility
# New functions should use the EntriesPath parameter instead
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

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path (Split-Path $_ -Parent))) {
                    throw "Parent directory does not exist: $(Split-Path $_ -Parent)"
                }
                return $true
            })]
        [string]$EntriesPath
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

    .PARAMETER EntriesPath
    The full path to the user's entries.json file (required for multi-user support)

    .PARAMETER CacheKey
    The PSU cache key to use. Defaults to 'entriesData'

    .PARAMETER ForceReload
    If true, bypasses cache and loads directly from file, then updates cache

    .EXAMPLE
    $entries = Get-CachedEntriesData -EntriesPath "/home/alex/data/users/user@example.com/health-data/entries.json"

    .EXAMPLE
    $entries = Get-CachedEntriesData -EntriesPath $userEntriesPath -ForceReload
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                $parentDir = Split-Path $_ -Parent
                if (-not (Test-Path $parentDir)) {
                    throw "Parent directory does not exist: $parentDir"
                }
                $true
            })]
        [string]$EntriesPath,

        [Parameter(Mandatory = $false)]
        [string]$CacheKey = 'entriesData',

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

            if (-not (Test-Path $EntriesPath)) {
            Write-Information "Entries file does not exist, creating empty structure: $EntriesPath"
            # Create directory if it doesn't exist
            $parentDir = Split-Path $EntriesPath -Parent
            if (-not (Test-Path $parentDir)) {
                New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
            }
            # Create empty entries file
            @{} | ConvertTo-Json -Depth 1 | Out-File $EntriesPath -Encoding UTF8
            # Initialize with empty hashtable - ensure it's not null
            $AllEntries = @{}
        } else {
            $content = Get-Content -Path $EntriesPath -Raw
            if ([string]::IsNullOrWhiteSpace($content)) {
                # Handle empty file
                $AllEntries = @{}
            } else {
                $AllEntries = $content | ConvertFrom-Json -AsHashtable
            }
        }

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
    The full path to the user's entries.json file (required for multi-user support)

    .PARAMETER CreateBackup
    Optional. If true, creates a backup of the entries file before making changes. Default is true

    .PARAMETER UpdateCache
    Optional. If true, updates the PSU cache after successful removal. Default is true

    .EXAMPLE
    Remove-TimeEntry -Date "0701" -Time "1430" -EntriesPath "/home/alex/data/users/user@example.com/health-data/entries.json"

    .EXAMPLE
    Remove-TimeEntry -Date "1225" -Time "0800" -EntriesPath $userEntriesPath -WhatIf

    .EXAMPLE
    Remove-TimeEntry -Date "0615" -Time "2130" -EntriesPath $userEntriesPath -CreateBackup:$false

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

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if (-not (Test-Path (Split-Path $_ -Parent))) {
                    throw "Parent directory does not exist: $(Split-Path $_ -Parent)"
                }
                return $true
            })]
        [string]$EntriesPath,

        [Parameter(Mandatory = $false)]
        [bool]$CreateBackup = $true,

        [Parameter(Mandatory = $false)]
        [bool]$UpdateCache = $true
    )

    try {
        Write-Information "Starting Remove-TimeEntry for Date: $Date, Time: $Time"

        # Validate entries file exists
        if (-not (Test-Path $EntriesPath)) {
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

function Get-UserEntriesPath {
    <#
    .SYNOPSIS
    Gets the entries.json file path for a specific user

    .DESCRIPTION
    Constructs the full path to a user's entries.json file based on their email address.
    The email is base64 encoded for safe filesystem usage.

    .PARAMETER UserEmail
    The user's email address

    .PARAMETER BaseDataPath
    Optional. The base data directory path. Defaults to appropriate path based on environment

    .EXAMPLE
    $entriesPath = Get-UserEntriesPath -UserEmail "user@example.com"

    .EXAMPLE
    $entriesPath = Get-UserEntriesPath -UserEmail "alex@domain.com" -BaseDataPath "/custom/data/path"

    .OUTPUTS
    Returns the full path to the user's entries.json file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[^@]+@[^@]+\.[^@]+$')]
        [string]$UserEmail,

        [Parameter(Mandatory = $false)]
        [string]$BaseDataPath
    )

    try {
        # Determine base data path if not provided
        if (-not $BaseDataPath) {
            $Remote = Get-ChildItem Env:HOSTNAME -ErrorAction Ignore
            if ($Remote -and $Remote.Value -like '*us-west-2*') {
                $BaseDataPath = '/home/data'
            }
            else {
                $BaseDataPath = '/home/alex/src/fusion-local/data'
            }
        }

        # Encode email address for safe filesystem usage
        $EncodedEmail = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserEmail))

        # Construct full path
        $UserEntriesPath = Join-Path $BaseDataPath "users" $EncodedEmail "health-data" "entries.json"

        Write-Information "Generated entries path for user '$UserEmail': $UserEntriesPath"
        return $UserEntriesPath
    }
    catch {
        Write-Error "Error generating user entries path: $($_.Exception.Message)"
        throw
    }
}

Export-ModuleMember -Function Get-UserEntriesPath

function New-SampleHealthEntries {
    <#
    .SYNOPSIS
    Generates sample health entries using the unified schema format

    .DESCRIPTION
    Creates sample health entries using the new unified schema with composite keys (yyMMddHHmm),
    multiple entry types, and structured data sections. Used for testing and development.

    .PARAMETER Count
    Number of sample entries to generate (default: 5)

    .PARAMETER UserEmail
    User email for the sample entries (default: "sample.user@example.com")

    .EXAMPLE
    $samples = New-SampleHealthEntries -Count 10

    .EXAMPLE
    $samples = New-SampleHealthEntries -Count 3 -UserEmail "test@domain.com"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Count = 5,

        [Parameter(Mandatory = $false)]
        [string]$UserEmail = "sample.user@example.com"
    )

    try {
        # Handle zero count case
        if ($Count -eq 0) {
            Write-Information "Count is 0, returning empty hashtable"
            $emptyResult = @{}
            return $emptyResult
        }

        $entries = @{}
        $entryTypes = @("mood", "pain", "vitals", "medication", "activity", "sleep")
        $painLocations = @("back", "neck", "shoulder", "hip", "knee", "head", "chest", "abdomen")
        $activities = @("Walking", "Stretching", "Exercise", "Physical Therapy", "Swimming", "Yoga", "Running")
        $medications = @("tylenol", "dilaudid", "lexapro", "vitaminD", "oxycodone", "valium")
        $moodNotes = @("Feeling good today", "A bit tired", "Energetic morning", "Relaxed evening", "Productive day", "Need more rest")

        for ($i = 0; $i -lt $Count; $i++) {
            # Generate random date/time within last 30 days
            $baseDate = (Get-Date).AddDays(-30)
            $randomDate = $baseDate.AddDays((Get-Random -Minimum 0 -Maximum 30))
            $randomHour = Get-Random -Minimum 6 -Maximum 22
            $randomMinute = Get-Random -Minimum 0 -Maximum 59

            # Create composite key (yyMMddHHmm)
            $compositeKey = "{0:yy}{0:MM}{0:dd}{1:D2}{2:D2}" -f $randomDate, $randomHour, $randomMinute

            # Ensure unique keys
            while ($entries.ContainsKey($compositeKey)) {
                $randomMinute = ($randomMinute + 1) % 60
                if ($randomMinute -eq 0) { $randomHour = ($randomHour + 1) % 24 }
                $compositeKey = "{0:yy}{0:MM}{0:dd}{1:D2}{2:D2}" -f $randomDate, $randomHour, $randomMinute
            }

            # Select random entry types (1-3 types per entry)
            $typeCount = Get-Random -Minimum 1 -Maximum 4
            $selectedTypes = $entryTypes | Get-Random -Count $typeCount

            # Ensure entry_types is always an array by using explicit array creation
            # PowerShell can unwrap single-item arrays, so we force array type
            if ($typeCount -eq 1) {
                $selectedTypes = [string[]]@($selectedTypes)
            } else {
                $selectedTypes = [string[]]$selectedTypes
            }

            # Build data section based on selected types
            $data = @{}

            foreach ($type in $selectedTypes) {
                switch ($type) {
                    "mood" {
                        $data.mood = @{
                            mood_level = Get-Random -Minimum 1 -Maximum 10
                            mood_note = $moodNotes | Get-Random
                        }
                    }
                    "pain" {
                        $data.pain = @{
                            pain_level = Get-Random -Minimum 0 -Maximum 10
                            location = $painLocations | Get-Random
                            pain_note = "Sample pain entry"
                        }
                    }
                    "vitals" {
                        $systolic = Get-Random -Minimum 110 -Maximum 140
                        $diastolic = Get-Random -Minimum 70 -Maximum 90
                        $data.vitals = @{
                            blood_pressure = "$systolic/$diastolic"
                            heart_rate = Get-Random -Minimum 60 -Maximum 100
                            oxygen_saturation = Get-Random -Minimum 95 -Maximum 100
                            temperature = [math]::Round((Get-Random -Minimum 97.0 -Maximum 99.5), 1)
                        }
                    }
                    "medication" {
                        $med = $medications | Get-Random
                        $dosages = @("500mg", "1g", "2mg", "4mg", "5mg", "10mg", "20mg")
                        $data.medication = @{
                            name = $med
                            dosage = $dosages | Get-Random
                            time_taken = "{0:HH:mm}" -f $randomDate.AddHours($randomHour).AddMinutes($randomMinute)
                        }
                    }
                    "activity" {
                        $data.activity = @{
                            type = $activities | Get-Random
                            duration_minutes = Get-Random -Minimum 5 -Maximum 120
                            intensity = @("Low", "Medium", "High") | Get-Random
                            activity_note = "Sample activity"
                        }
                    }
                    "sleep" {
                        $data.sleep = @{
                            hours_slept = [math]::Round((Get-Random -Minimum 4.0 -Maximum 10.0), 1)
                            sleep_quality = Get-Random -Minimum 1 -Maximum 10
                            sleep_note = "Sleep tracking entry"
                        }
                    }
                }
            }

            # Create the entry
            $entry = @{
                entry_id = $compositeKey
                user_email = $UserEmail
                date = "{0:yyyy-MM-dd}" -f $randomDate
                time = "{0:D2}:{1:D2}" -f $randomHour, $randomMinute
                entry_types = [string[]]$selectedTypes  # Explicit string array type
                data = $data
                notes = if ((Get-Random -Minimum 1 -Maximum 4) -eq 1) { "Sample general note for entry" } else { "" }
                created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }

            $entries[$compositeKey] = $entry
        }

        Write-Information "Generated $Count sample health entries using unified schema"
        return $entries

    }
    catch {
        Write-Error "Error generating sample health entries: $($_.Exception.Message)"
        throw
    }
}
Export-ModuleMember -Function New-SampleHealthEntries