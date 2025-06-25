# $global:EntriesPath = Join-Path $PSScriptRoot "entries.json"
# $global:SchemaPath = Join-Path $PSScriptRoot "schema.json"
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
        # Add activities
        $AllActivities = @{}
        for ($i = 0; $i -lt $Activities.Count; $i++) {
            $AllActivities.Add($Activities[$i], $ActivitiesDuration[$i])
        }
        $CurrentEntry["Activities"] = $AllActivities
        # Add pain
        $AllPain = @{}
        for ($i = 0; $i -lt $PainLocation.Count; $i++) {
            $AllPain.Add($PainLocation[$i], $PainLevel[$i])
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
    }

    # Create the full structure for entries.json
    $FullEntry = @{
        $Date = @{
            $Timestamp = $EntryStructure
        }
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