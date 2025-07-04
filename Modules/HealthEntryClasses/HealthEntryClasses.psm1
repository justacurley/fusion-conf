# HealthEntry PowerShell Classes
# Defines the schema for health tracking entries with validation and type safety
# R now this is the only way to import the module: using module ./HealthEntryClasses.psm1

using namespace System.Collections.Generic
enum PainLocationEnum {
    Back
    RQuad
    LQuad
    Quads
    RHip
    LHip
    Hips
    RGlute
    LGlute
    Glutes
}

# Class for Mediation data
class MedicationValidator : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-Content (Join-Path $PSScriptRoot 'medications_lookup.json') | ConvertFrom-Json -AsHashtable)['Medications'].keys
    }

    [string[]] GetValidDosages([string]$medication) {
        $data = (Get-Content (Join-Path $PSScriptRoot 'medications_lookup.json') | ConvertFrom-Json -AsHashtable)
        if ($data['Medications'].ContainsKey($medication)) {
            return $data['Medications'][$medication]
        }
        return @()
    }
}

class MedicationTaken {
    # What properties do you think you need?
    # Try adding 2-3 basic properties here
    [string] $dosage = '4mg'    
    [string] $medication = 'dilaudid'

    # Valid Medication Names
    
    # Default constructor
    MedicationTaken() {}

    MedicationTaken([string]$dosage, [string]$medication) {
        $MedValidator = [MedicationValidator]::new()
        $ValidMeds = $MedValidator.GetValidValues()
        if ($ValidMeds -inotcontains $medication) {
            throw "Must provide valid medication, valid values:`n $($ValidMeds -join "`n")"
        }
        $ValidDosages = $MedValidator.GetValidDosages($medication)
        if ($ValidDosages -inotcontains $dosage) {
            throw "Must provide valid dosage for $medication, valid values:`n $($ValidDosages -join "`n")"
        }
        $this.dosage = $dosage
        $this.medication = $medication
    }

    # Validation method
    [bool] IsValid() {
        $MedValidator = [MedicationValidator]::new()
        $ValidMeds = $MedValidator.GetValidValues()
        $ValidDosages = $MedValidator.GetValidDosages($this.medication)
        
        return ($ValidMeds -icontains $this.medication) -and 
        ($ValidDosages -icontains $this.dosage) -and
        (-not [string]::IsNullOrWhiteSpace($this.medication))
    }

    [hashtable] ToHashtable() {
        return @{
            dosage     = $this.dosage 
            medication = $this.medication 
        }
    }
}

class Activity {
    [string] $ActivityName = 'Walking'
    [int] $ActivityDuration = 10
    [string] $Note = ''

    Activity() {}
    Activity([string]$ActivityName, [int]$ActivityDuration, [string]$Note) {
        $this.ActivityName = $ActivityName
        $this.ActivityDuration = $ActivityDuration
        $this.Note = $Note
    }
    [bool] IsValid() {
        return -not [string]::IsNullOrWhiteSpace($this.ActivityName) -and $this.ActivityDuration -gt 0 -and $null -ne $this.Note
    }
    [hashtable] ToHashtable() {
        return @{
            ActivityName     = $this.ActivityName
            ActivityDuration = $this.ActivityDuration
            Note             = $this.Note
        }
    }
}
# Class for pain location data
class PainLocation {
    [ValidateRange(0.0, 10.0)]
    [double] $pain_level = 0.0
    [PainLocationEnum] $location = 'Back'
    [string] $Note = ''
    
    # Default constructor
    PainLocation() {}

    # Parameterized constructor
    PainLocation([double]$level, [PainLocationEnum]$location, [string]$Note) {
        $this.pain_level = $level
        $this.location = $location
        $this.Note = $Note
    }
    
    # Validation method
    [bool] IsValid() {
        return $this.pain_level -ge 0.0 -and $this.pain_level -le 10.0 -and $null -ne $this.location
    }
    
    # Convert to hashtable for JSON serialization
    [hashtable] ToHashtable() {
        return @{
            pain_level = $this.pain_level
            location   = $this.location
            Note       = $this.Note
        }
    }
}

class Vitals {
    [int] $o2 = 95
    [string] $bpr = '120/80'

    Vitals() {}

    Vitals([int]$o2, [string]$bpr) {
        if ($o2 -gt 100 -or $o2 -lt 0) {
            throw "The provided value of o2: $o2, must be between 1-100"
        } 
        [int]$systolic, [int]$diastolic = $bpr -split '/'
        if ($systolic -gt 200 -or $systolic -lt 40) {
            throw "The provided systolic value of bpr: $bpr, valid values are between 40-200"
        }
        elseif ($diastolic -gt 200 -or $diastolic -lt 40) {
            throw "The provided diastolic $diastolic value of bpr: $bpr, valid values are between 40-200"
        }
        if ($bpr -notmatch '^\d{2,3}/\d{2,3}$' -or $bpr.Split('/').Count -ne 2) {
            throw "Invalid blood pressure format: $bpr. Expected format: XXX/XX (e.g., 120/80)"
        }
        $this.o2 = $o2 
        $this.bpr = $bpr 
    }

    [bool] IsValid() {
        $ValidO2 = $this.o2 -le 100 -and $this.o2 -ge 0 
        $ValidFormat = $this.bpr -match '^\d{2,3}/\d{2,3}$'
        if ($ValidFormat) {
            [int]$systolic, [int]$diastolic = $this.bpr -split '/'
            $validRanges = ($systolic -le 200 -and $systolic -ge 40) -and 
            ($diastolic -le 200 -and $diastolic -ge 40)
            return $ValidO2 -and $validRanges
        }
        return $false
    }

    [hashtable] ToHashtable() {
        return @{
            o2  = $this.o2
            bpr = $this.bpr
        }
    }
}
class HealthEntry {
    # Timestamp for when this entry was created
    [string] $Date = (Get-Date -f 'MMdd')
    [string] $Time = (Get-Date -f 'HHmm')
    
    # Individual health components (nullable - not every entry needs all components)
    [PainLocation[]] $Pain = @()
    [MedicationTaken[]] $Medication = @()  
    [Activity[]] $Activity = @()
    [Vitals] $Vitals = $null
    
    # Overall notes for this health entry
    [string] $Note = ''
    
    # # Constructors
    # HealthEntry([PainLocation[]] $Pain,[MedicationTaken[]] $Medication,[Activity[]] $Activity,[Vitals] $Vitals,[string] $Note) {

    # }

    # Constructor with parameters
    HealthEntry() {}
    
    # Validation method
    [bool] IsValid() {
        return $this.Pain.Length -gt 0 -or $this.Medication.Length -gt 0 -or $this.Activity.Length -gt 0 -or $null -ne $this.Vitals -or -not [string]::IsNullOrEmpty($this.Note)
    }
    
    
    # Serialization method  
    [hashtable] ToHashtable() {
        [hashtable]$Output = @{}
        
        [hashtable]$Medications = @{}
        [string[]]$MedicationsTaken = @()
        $this.Medication.ForEach({ 
            $Medications[$_.medication] = $_.dosage  # Use assignment instead of .add()
            if ($_.medication -notin $MedicationsTaken) {
                $MedicationsTaken = $MedicationsTaken + $_.medication
            }
        })
        
        $Output.Add('Medications',$Medications)        
        
        [hashtable]$Activities = @{}
        $this.Activity.ForEach({
            $ActivityName = $_.ActivityName
            $ActivityData = @{
                note = $_.Note
                duration = $_.ActivityDuration
            }
            $Activities.Add($ActivityName,$ActivityData)
        })
        
        $Output.Add('Activities',$Activities)
        
        $Pains = @{}
        $this.Pain.ForEach({
            $Location = $_.location.ToString()  # Convert enum to string
            $PainData = @{
                pain_level = $_.pain_level
                note = $_.Note
            }
            $Pains.Add($Location,$PainData)
        })

        $Output.Add('Pain',$Pains)

        if ($this.Vitals) {
            $Output.Add('o2',$this.Vitals.o2)
            $Output.Add('bpr',$this.Vitals.bpr)
        } else {
            $Output.Add('o2','')
            $Output.Add('bpr','')
        }

        if (-not [string]::IsNullOrEmpty($this.Note)) {
            $Output.Add('note',$this.Note)
        }

        if ($MedicationsTaken.length -gt 0) {
            $Output.Add('medication_taken', ($MedicationsTaken -join ','))
        } else { 
            $Output.Add('medication_taken','')
        }

        return $Output
    }
}
# Export the class
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *