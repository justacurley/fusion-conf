$global:EntriesPath =  "/home/data/fusion-data/entries/entries.json"



function ConvertTo-EntriesFormat {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Entry
    )
    
    # Save and set InformationAction
    $CurrentInformationAction = $InformationPreference
    $InformationPreference = 'Continue'
    
    # Convert to entries.json format
    Write-Host "Converting entry to entries.json format..."

    # Extract basic info
    $Date = $Entry.date
    $Timestamp = $Entry.timestamp

    # Build Medications object
    $Medications = @{}
    if ($Entry.meds -and $Entry.meds.Count -gt 0) {
        foreach ($med in $Entry.meds) {
            # Parse "oxycodone - 2.5mg" format (note the spaces)
            if ($med -match "^(.+?)\s*-\s*(.+)$") {
                $medName = $matches[1].Trim()
                $dosage = $matches[2].Trim()
                
                # Handle multiple doses of same medication
                if ($Medications.ContainsKey($medName)) {
                    # Convert to array if not already
                    if ($Medications[$medName] -is [string]) {
                        $Medications[$medName] = @($Medications[$medName])
                    }
                    $Medications[$medName] += $dosage
                } else {
                    $Medications[$medName] = $dosage
                }
            }
        }
    }

    # Build Pain object
    $Pain = @{}
    # Get all pain location/level pairs
    $painProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like "pain_location_*" }
    foreach ($painProp in $painProperties) {
        $id = $painProp.Name -replace "pain_location_", ""
        $location = $painProp.Value
        $levelProp = "pain_level_$id"
        if ($Entry.PSObject.Properties[$levelProp]) {
            $level = $Entry.PSObject.Properties[$levelProp].Value
            if ($location -and $level) {
                $Pain[$location] = $level
            }
        }
    }

    # Build Activities object
    $Activities = @{}
    Write-Information "Looking for activity properties..."

    # Get all activity type/length pairs
    $activityProperties = $Entry.PSObject.Properties | Where-Object { $_.Name -like "activities_type_*" }
    Write-Information "Found $($activityProperties.Count) activity type properties"

    foreach ($activityProp in $activityProperties) {
        $id = $activityProp.Name -replace "activities_type_", ""
        $activityType = $activityProp.Value
        $lengthProp = "activities_length_$id"
        
        Write-Information "Processing activity ID $id, Type: $activityType"
        Write-Information "Looking for $lengthProp"
        
        # Check for corresponding length property
        $duration = $null
        if ($Entry.PSObject.Properties[$lengthProp]) {
            $duration = [int]$Entry.PSObject.Properties[$lengthProp].Value
            Write-Information "Found length property with value: $duration"
        } else {
            Write-Information "No matching duration property found for ID $id"
            # List all available properties for debugging
            $availableProps = $Entry.PSObject.Properties | Where-Object { $_.Name -like "*$id*" } | Select-Object -ExpandProperty Name
            Write-Information "Available properties with ID $id : $($availableProps -join ', ')"
        }
        
        if ($activityType -and $duration) {
            # Convert activity type to lowercase key
            $activityKey = $activityType.ToLower()
            $Activities[$activityKey] = $duration
            Write-Information "Added activity: $activityKey = $duration"
        } else {
            Write-Information "Skipping activity - Type: '$activityType', Duration: '$duration'"
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
        
        # DynamoDB GSI fields
        "medication_taken" = if ($Medications.Keys.Count -gt 0) { ($Medications.Keys -join ",") } else { "" }
        "max_pain_level"   = if ($Pain.Values.Count -gt 0) { 
            # Extract highest number from pain level strings like "6-7-8"
            $maxPain = 0
            foreach ($level in $Pain.Values) {
                $numbers = $level -split '[-,\s]' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
                if ($numbers) {
                    $levelMax = ($numbers | Measure-Object -Maximum).Maximum
                    if ($levelMax -gt $maxPain) { $maxPain = $levelMax }
                }
            }
            $maxPain
        } else { 0 }
    }

    # Create the full structure for entries.json
    $FullEntry = @{
        $Date = @{
            $Timestamp = $EntryStructure
        }
    }

    # Return the result
    $Result = @{
        FullEntry = $FullEntry
        EntryStructure = $EntryStructure
        Date = $Date
        Timestamp = $Timestamp
    }
    
    # Restore InformationAction
    $InformationPreference = $CurrentInformationAction
    
    return $Result
}
Export-ModuleMember -Function ConvertTo-EntriesFormat

function Save-ConvertedEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ConvertedEntry,
        
        [Parameter(Mandatory = $false)]
        [string]$EntriesFilePath = $global:EntriesPath
    )
    
    begin {
        # Save and set InformationAction
        $CurrentInformationAction = $InformationPreference
        $InformationPreference = 'Continue'
        
        Write-Information "Starting Save-ConvertedEntry"
        
        # Validate the ConvertedEntry structure
        if (-not $ConvertedEntry.ContainsKey("Date") -or 
            -not $ConvertedEntry.ContainsKey("Timestamp") -or 
            -not $ConvertedEntry.ContainsKey("EntryStructure")) {
            throw "ConvertedEntry must contain Date, Timestamp, and EntryStructure keys"
        }
        
        $Date = $ConvertedEntry.Date
        $Timestamp = $ConvertedEntry.Timestamp
        $EntryData = $ConvertedEntry.EntryStructure
        
        Write-Information "Processing entry for Date: $Date, Timestamp: $Timestamp"
    }
    
    process {
        try {
            # Load existing entries or create new structure
            $Entries = @{}
            if (Test-Path $EntriesFilePath) {
                $Entries = Get-Content $EntriesFilePath | ConvertFrom-Json -AsHashtable
                Write-Information "Loaded existing entries file with $($Entries.Keys.Count) dates"
            } else {
                Write-Information "Creating new entries file"
                # Ensure directory exists
                $Directory = Split-Path $EntriesFilePath -Parent
                if (-not (Test-Path $Directory)) {
                    New-Item -ItemType Directory -Path $Directory -Force
                    Write-Information "Created directory: $Directory"
                }
            }
            
            # Auto-determine action based on what exists
            if (-not $Entries.ContainsKey($Date)) {
                # Date doesn't exist - add entire date entry
                $Entries[$Date] = @{
                    $Timestamp = $EntryData
                }
                Write-Information "Added new date entry for: $Date with timestamp: $Timestamp"
            } elseif (-not $Entries[$Date].ContainsKey($Timestamp)) {
                # Date exists but timestamp doesn't - add timestamp entry
                $Entries[$Date][$Timestamp] = $EntryData
                Write-Information "Added new timestamp entry for existing date $Date at timestamp: $Timestamp"
            } else {
                # Both date and timestamp exist - overwrite
                $Entries[$Date][$Timestamp] = $EntryData
                Write-Information "Overwrote existing entry for $Date at timestamp: $Timestamp"
            }
            
            # Create backup before saving
            if (Test-Path $EntriesFilePath) {
                $BackupTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $BackupPath = $EntriesFilePath -replace '\.json$', "_backup_$BackupTimestamp.json"
                Copy-Item -Path $EntriesFilePath -Destination $BackupPath -Force
                Write-Information "Created backup: $BackupPath"
            }
            
            # Save back to file
            $JsonOutput = $Entries | ConvertTo-Json -Depth 10
            $JsonOutput | Out-File $EntriesFilePath -Encoding UTF8
            Write-Information "Successfully saved entries to: $EntriesFilePath"
            
            # Restore InformationAction
            $InformationPreference = $CurrentInformationAction
            
            return $true
            
        } catch {
            Write-Error "Error saving entry: $($_.Exception.Message)"
            Write-Error "Stack trace: $($_.ScriptStackTrace)"
            
            # Restore InformationAction even on error
            $InformationPreference = $CurrentInformationAction
            
            return $false
        }
    }
}
Export-ModuleMember -Function Save-ConvertedEntry

function Sync-EntriesToDynamoDB {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$EntriesFilePath = $global:EntriesPath,
        
        [Parameter(Mandatory = $false)]
        [string]$TableName = "fusion-health-entries",
        
        [Parameter(Mandatory = $false)]
        [string]$Region = "us-west-2",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    begin {
        # Save and set InformationAction
        $CurrentInformationAction = $InformationPreference
        $InformationPreference = 'Continue'
        
        Write-Information "Starting Sync-EntriesToDynamoDB"
        Write-Information "Table: $TableName, Region: $Region"
        Write-Information "Source file: $EntriesFilePath"
        
        if ($WhatIf) {
            Write-Information "WhatIf mode - no actual changes will be made"
        }
        
        # Verify entries file exists
        if (-not (Test-Path $EntriesFilePath)) {
            throw "Entries file not found: $EntriesFilePath"
        }
        
        # Check if AWS CLI is available
        try {
            $awsVersion = aws --version 2>$null
            Write-Information "AWS CLI detected: $awsVersion"
        } catch {
            throw "AWS CLI not found. Please install AWS CLI and configure credentials."
        }
    }
    
    process {
        try {
            # Load entries from JSON file
            $entries = Get-Content $EntriesFilePath | ConvertFrom-Json -AsHashtable
            Write-Information "Loaded entries file with $($entries.Keys.Count) dates"
            
            $totalItems = 0
            $processedItems = 0
            
            # Count total items for progress tracking
            foreach ($date in $entries.Keys) {
                $timestampKeys = $entries[$date].Keys | Where-Object { $_ -match '^\d{4}$' }
                $totalItems += $timestampKeys.Count
            }
            Write-Information "Total items to process: $totalItems"
            
            if (-not $WhatIf) {
                # Clear existing table data (scan and delete all items)
                Write-Information "Clearing existing table data..."
                $scanCommand = "aws dynamodb scan --table-name $TableName --region $Region --select ALL_ATTRIBUTES --output json"
                $existingItems = Invoke-Expression $scanCommand | ConvertFrom-Json
                
                if ($existingItems.Items -and $existingItems.Items.Count -gt 0) {
                    Write-Information "Found $($existingItems.Items.Count) existing items to delete"
                    
                    # Delete existing items in batches
                    $batchSize = 25
                    for ($i = 0; $i -lt $existingItems.Items.Count; $i += $batchSize) {
                        $batch = $existingItems.Items[$i..([Math]::Min($i + $batchSize - 1, $existingItems.Items.Count - 1))]
                        
                        $deleteRequests = @()
                        foreach ($item in $batch) {
                            $deleteRequests += @{
                                DeleteRequest = @{
                                    Key = @{
                                        date = $item.date
                                        timestamp = $item.timestamp
                                    }
                                }
                            }
                        }
                        
                        $batchDeleteRequest = @{
                            RequestItems = @{
                                $TableName = $deleteRequests
                            }
                        } | ConvertTo-Json -Depth 10 -Compress
                        
                        $deleteCommand = "aws dynamodb batch-write-item --region $Region --request-items '$batchDeleteRequest'"
                        Invoke-Expression $deleteCommand | Out-Null
                        Write-Information "Deleted batch of $($batch.Count) items"
                    }
                }
            }
            
            # Process each date and timestamp
            foreach ($date in $entries.Keys) {
                Write-Information "Processing date: $date"
                
                # Skip non-timestamp keys like "Sleep", "ScarImage"
                $timestampKeys = $entries[$date].Keys | Where-Object { $_ -match '^\d{4}$' }
                
                foreach ($timestamp in $timestampKeys) {
                    $entry = $entries[$date][$timestamp]
                    $processedItems++
                    
                    # Calculate GSI fields if they don't exist
                    if (-not $entry.ContainsKey("medication_taken")) {
                        $entry["medication_taken"] = if ($entry.Medications -and $entry.Medications.Count -gt 0) { 
                            ($entry.Medications.Keys -join ",") 
                        } else { "" }
                    }
                    
                    if (-not $entry.ContainsKey("max_pain_level")) {
                        $maxPain = 0
                        if ($entry.Pain -and $entry.Pain.Count -gt 0) {
                            foreach ($level in $entry.Pain.Values) {
                                $numbers = $level -split '[-,\s]' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
                                if ($numbers) {
                                    $levelMax = ($numbers | Measure-Object -Maximum).Maximum
                                    if ($levelMax -gt $maxPain) { $maxPain = $levelMax }
                                }
                            }
                        }
                        $entry["max_pain_level"] = $maxPain
                    }
                    
                    # Build DynamoDB item
                    $dynamoItem = @{
                        date = @{ S = $date }
                        timestamp = @{ S = $timestamp }
                        medication_taken = @{ S = $entry.medication_taken }
                        max_pain_level = @{ N = $entry.max_pain_level.ToString() }
                        medications = @{ S = ($entry.Medications | ConvertTo-Json -Compress) }
                        pain = @{ S = ($entry.Pain | ConvertTo-Json -Compress) }
                        activities = @{ S = ($entry.Activities | ConvertTo-Json -Compress) }
                        o2 = @{ S = $entry.o2 }
                        bpr = @{ S = $entry.bpr }
                        note = @{ S = $entry.note }
                    }
                    
                    if ($WhatIf) {
                        Write-Information "Would insert: $date[$timestamp] - Meds: '$($entry.medication_taken)', Max Pain: $($entry.max_pain_level)"
                    } else {
                        # Insert item into DynamoDB
                        $itemJson = $dynamoItem | ConvertTo-Json -Depth 10 -Compress
                        $putCommand = "aws dynamodb put-item --table-name $TableName --region $Region --item '$itemJson'"
                        
                        try {
                            Invoke-Expression $putCommand | Out-Null
                            Write-Information "[$processedItems/$totalItems] Inserted: $date[$timestamp]"
                        } catch {
                            Write-Error "Failed to insert $date[$timestamp]: $($_.Exception.Message)"
                        }
                    }
                }
            }
            
            Write-Information "Sync completed. Processed $processedItems items."
            
            # Restore InformationAction
            $InformationPreference = $CurrentInformationAction
            
            return $true
            
        } catch {
            Write-Error "Error syncing to DynamoDB: $($_.Exception.Message)"
            Write-Error "Stack trace: $($_.ScriptStackTrace)"
            
            # Restore InformationAction even on error
            $InformationPreference = $CurrentInformationAction
            
            return $false
        }
    }
}
Export-ModuleMember -Function Sync-EntriesToDynamoDB

function New-EntryObject {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Date,
        
        [Parameter(Mandatory = $true)]
        [string]$Timestamp,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Medications = @{},
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Pain = @{},
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Activities = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$O2 = "",
        
        [Parameter(Mandatory = $false)]
        [string]$BPR = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Note = ""
    )
    
    begin {
        # Save and set InformationAction
        $CurrentInformationAction = $InformationPreference
        $InformationPreference = 'Continue'
        
        Write-Information "Creating new entry object for $Date at $Timestamp"
        
        # Validate date format (MMDD)
        if ($Date -notmatch '^\d{4}$') {
            throw "Date must be in MMDD format (e.g., '0624')"
        }
        
        # Validate timestamp format (HHMM)
        if ($Timestamp -notmatch '^\d{4}$') {
            throw "Timestamp must be in HHMM format (e.g., '1430')"
        }
    }
    
    process {
        try {
            # Calculate GSI fields
            $medicationTaken = if ($Medications.Keys.Count -gt 0) { 
                ($Medications.Keys -join ",") 
            } else { "" }
            
            $maxPainLevel = 0
            if ($Pain.Values.Count -gt 0) {
                foreach ($level in $Pain.Values) {
                    $numbers = $level -split '[-,\s]' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
                    if ($numbers) {
                        $levelMax = ($numbers | Measure-Object -Maximum).Maximum
                        if ($levelMax -gt $maxPainLevel) { $maxPainLevel = $levelMax }
                    }
                }
            }
            
            # Create the entry structure with DynamoDB GSI fields
            $EntryStructure = @{
                "Medications" = $Medications
                "Pain" = $Pain
                "Activities" = $Activities
                "o2" = $O2
                "bpr" = $BPR
                "note" = $Note
                "medication_taken" = $medicationTaken
                "max_pain_level" = $maxPainLevel
            }
            
            # Create the full structure for entries.json
            $FullEntry = @{
                $Date = @{
                    $Timestamp = $EntryStructure
                }
            }
            
            # Create the result object compatible with Save-ConvertedEntry
            $Result = @{
                FullEntry = $FullEntry
                EntryStructure = $EntryStructure
                Date = $Date
                Timestamp = $Timestamp
            }
            
            Write-Information "Created entry object - Meds: '$medicationTaken', Max Pain: $maxPainLevel"
            
            # Restore InformationAction
            $InformationPreference = $CurrentInformationAction
            
            return $Result
            
        } catch {
            Write-Error "Error creating entry object: $($_.Exception.Message)"
            
            # Restore InformationAction even on error
            $InformationPreference = $CurrentInformationAction
            
            throw
        }
    }
}
Export-ModuleMember -Function New-EntryObject