$global:EntriesPath = Join-Path $PSScriptRoot "entries.json"
$global:SchemaPath = Join-Path $PSScriptRoot "schema.json"
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
