# HealthEntry PowerShell Classes
# Defines the schema for health tracking entries with validation and type safety
# R now this is the only way to import the module: using module ./HealthEntryClasses.psm1

using namespace System.Collections.Generic

class Mood {
    [int] $MoodLevel = 3
    [string] $Note = ''

    Mood () {}

    Mood ([int]$MoodLevel, [string]$Note) {
        if ($MoodLevel -lt 1 -or $MoodLevel -gt 5) {
            throw "Mood level must be between 1 and 5, received: $MoodLevel"
        }
        $this.MoodLevel = $MoodLevel
        $this.Note = $Note
    }

    [bool] IsValid() {
        return $this.MoodLevel -ge 1 -and $this.MoodLevel -le 5
    }

    [hashtable] ToHashtable() {
        return @{
            mood_level = $this.MoodLevel
            mood_note = $this.Note
        }
    }
}

# Pain location validation - more flexible approach
class PainLocationValidator {
    static [string[]] $CommonLocations = @(
        'back', 'rquad', 'lquad', 'quads', 'rhip', 'lhip', 'hips',
        'rglute', 'lglute', 'glutes', 'righthip', 'lefthip',
        'right_glute', 'left_glute', 'right_hip', 'left_hip'
    )

    static [bool] IsValidLocation([string]$location) {
        # Allow any non-empty string for flexibility, but warn if not in common list
        if ([string]::IsNullOrWhiteSpace($location)) {
            return $false
        }
        return $true
    }

    static [string] NormalizeLocation([string]$location) {
        return $location.ToLower().Trim()
    }
}

# Class for Medication data - Updated for user-defined medications
class MedicationValidator : System.Management.Automation.IValidateSetValuesGenerator {
    # No longer uses medications_lookup.json - accepts any medication name
    [string[]] GetValidValues() {
        # Return empty array to allow any medication names
        # This maintains interface compatibility while removing validation constraints
        return @()
    }

    [string[]] GetValidDosages([string]$medication) {
        # Return empty array to allow any dosage values
        # Users can now define their own dosages in Settings
        return @()
    }

    # Static method for basic validation (non-empty strings)
    static [bool] IsValidMedicationName([string]$name) {
        return -not [string]::IsNullOrWhiteSpace($name)
    }

    static [bool] IsValidDosage([string]$dosage) {
        return -not [string]::IsNullOrWhiteSpace($dosage)
    }
}

class MedicationTaken {
    [string] $dosage = ''
    [string] $medication = ''

    # Default constructor with common medication example
    MedicationTaken() {
        $this.dosage = "325mg"
        $this.medication = "aspirin"
    }

    # Updated constructor - accepts any medication name and dosage
    MedicationTaken([string]$dosage, [string]$medication) {
        if (-not [MedicationValidator]::IsValidMedicationName($medication)) {
            throw "Medication name cannot be empty or null"
        }
        if (-not [MedicationValidator]::IsValidDosage($dosage)) {
            throw "Dosage cannot be empty or null"
        }
        $this.dosage = $dosage.Trim()
        $this.medication = $medication.Trim()
    }

    # Updated validation method - only checks for non-empty values
    [bool] IsValid() {
        return [MedicationValidator]::IsValidMedicationName($this.medication) -and
               [MedicationValidator]::IsValidDosage($this.dosage)
    }

    [hashtable] ToHashtable() {
        return @{
            name = $this.medication
            dosage = $this.dosage
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
        $output = @{
            name = $this.ActivityName
            duration_minutes = $this.ActivityDuration
        }
        if (-not [string]::IsNullOrEmpty($this.Note)) {
            $output.note = $this.Note
        }
        return $output
    }
}
# Class for pain location data
class PainLocation {
    [ValidateRange(0.0, 10.0)]
    [double] $pain_level = 0.0
    [string] $location = 'back'
    [string] $note = ''

    # Default constructor
    PainLocation() {}

    # Two-parameter constructor (location, level)
    PainLocation([string]$location, [double]$level) {
        $this.location = [PainLocationValidator]::NormalizeLocation($location)
        $this.pain_level = $level  # This will enforce the 0-10 range via ValidateRange
        $this.note = ''
    }

    # Three-parameter constructor (location, level, note)
    PainLocation([string]$location, [double]$level, [string]$note) {
        $this.location = [PainLocationValidator]::NormalizeLocation($location)
        $this.pain_level = $level  # This will enforce the 0-10 range via ValidateRange
        $this.note = $note
    }

    # Validation method
    [bool] IsValid() {
        return $this.pain_level -ge 0.0 -and $this.pain_level -le 10.0 -and
               [PainLocationValidator]::IsValidLocation($this.location)
    }

    [hashtable] ToHashtable() {
        $output = @{
            location = $this.location
            severity = $this.pain_level
        }
        if (-not [string]::IsNullOrEmpty($this.note)) {
            $output.note = $this.note
        }
        return $output
    }
}

class Vitals {
    [int] $o2 = 95
    [string] $bpr = '120/80'
    [int] $heart_rate = 70
    [double] $temperature = 98.6

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

    # Schema v2.0 compatible constructor
    Vitals([int]$o2, [string]$bpr, [int]$heart_rate, [double]$temperature) {
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
        if ($heart_rate -lt 40 -or $heart_rate -gt 220) {
            throw "The provided heart rate: $heart_rate, must be between 40-220"
        }
        if ($temperature -lt 95.0 -or $temperature -gt 110.0) {
            throw "The provided temperature: $temperature, must be between 95.0-110.0"
        }
        $this.o2 = $o2
        $this.bpr = $bpr
        $this.heart_rate = $heart_rate
        $this.temperature = $temperature
    }

    [bool] IsValid() {
        $ValidO2 = $this.o2 -le 100 -and $this.o2 -ge 0
        $ValidFormat = $this.bpr -match '^\d{2,3}/\d{2,3}$'
        $ValidHeartRate = $this.heart_rate -ge 40 -and $this.heart_rate -le 220
        $ValidTemperature = $this.temperature -ge 95.0 -and $this.temperature -le 110.0

        if ($ValidFormat) {
            [int]$systolic, [int]$diastolic = $this.bpr -split '/'
            $validRanges = ($systolic -le 200 -and $systolic -ge 40) -and
            ($diastolic -le 200 -and $diastolic -ge 40)
            return $ValidO2 -and $validRanges -and $ValidHeartRate -and $ValidTemperature
        }
        return $false
    }

    [hashtable] ToHashtable() {
        return @{
            blood_pressure = $this.bpr
            oxygen_saturation = $this.o2
            heart_rate = $this.heart_rate
            temperature = $this.temperature
        }
    }
}

class Weight {
    [double] $weight_lbs = 150.0
    [double] $weight_kg = 68.0

    Weight() {}

    Weight([double]$weight_lbs) {
        if ($weight_lbs -lt 50.0 -or $weight_lbs -gt 500.0) {
            throw "Weight in pounds must be between 50.0 and 500.0"
        }
        $this.weight_lbs = $weight_lbs
        $this.weight_kg = [math]::Round($weight_lbs * 0.453592, 1)
    }

    Weight([double]$weight_lbs, [double]$weight_kg) {
        if ($weight_lbs -lt 50.0 -or $weight_lbs -gt 500.0) {
            throw "Weight in pounds must be between 50.0 and 500.0"
        }
        if ($weight_kg -lt 20.0 -or $weight_kg -gt 250.0) {
            throw "Weight in kilograms must be between 20.0 and 250.0"
        }
        $this.weight_lbs = $weight_lbs
        $this.weight_kg = $weight_kg
    }

    [bool] IsValid() {
        return ($this.weight_lbs -ge 50.0 -and $this.weight_lbs -le 500.0) -and
               ($this.weight_kg -ge 20.0 -and $this.weight_kg -le 250.0)
    }

    [hashtable] ToHashtable() {
        return @{
            weight_lbs = $this.weight_lbs
            weight_kg = $this.weight_kg
        }
    }
}

class Sleep {
    [double] $sleep_hours = 8.0

    Sleep() {}

    Sleep([double]$sleep_hours) {
        if ($sleep_hours -lt 0.0 -or $sleep_hours -gt 24.0) {
            throw "Sleep hours must be between 0.0 and 24.0"
        }
        $this.sleep_hours = $sleep_hours
    }

    [bool] IsValid() {
        return $this.sleep_hours -ge 0.0 -and $this.sleep_hours -le 24.0
    }

    [hashtable] ToHashtable() {
        return @{
            sleep_hours = $this.sleep_hours
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
    [Mood] $Mood = $null
    [Weight] $Weight = $null
    [Sleep] $Sleep = $null

    # Overall notes for this health entry
    [string] $Note = ''

    # # Constructors
    # HealthEntry([PainLocation[]] $Pain,[MedicationTaken[]] $Medication,[Activity[]] $Activity,[Vitals] $Vitals,[string] $Note) {

    # }

    # Constructor with parameters
    HealthEntry() {}

    # Validation method - allow empty entries
    [bool] IsValid() {
        # Always return true - allow empty entries
        # Individual components have their own validation
        return $true
    }


    # Serialization method - Schema v2.0 format
    [hashtable] ToHashtable() {
        [hashtable]$Output = @{}

        # Basic entry metadata
        $now = Get-Date
        $Output.Add('date', $now.ToString('yyyy-MM-dd'))
        $Output.Add('time', $now.ToString('HH:mm'))

        # Build data section based on what's present
        [hashtable]$Data = @{}

        # Handle medications as array
        if ($this.Medication.Count -gt 0) {
            [array]$MedicationsArray = @()
            $this.Medication.ForEach({
                $MedicationsArray += $_.ToHashtable()
            })
            $Data.Add('medications', [array]$MedicationsArray)
        }

        # Handle activities as array
        if ($this.Activity.Count -gt 0) {
            [array]$ActivitiesArray = @()
            $this.Activity.ForEach({
                $ActivitiesArray += $_.ToHashtable()
            })
            $Data.Add('activities', [array]$ActivitiesArray)
        }

        # Handle pain as array
        if ($this.Pain.Count -gt 0) {
            [array]$PainArray = @()
            $this.Pain.ForEach({
                $PainArray += $_.ToHashtable()
            })
            $Data.Add('pain', [array]$PainArray)
        }

        # Handle vitals
        if ($this.Vitals) {
            $Data.Add('vitals', $this.Vitals.ToHashtable())
        }

        # Handle mood
        if ($this.Mood) {
            $Data.Add('mood', $this.Mood.ToHashtable())
        }

        # Handle weight
        if ($this.Weight) {
            $Data.Add('weight', $this.Weight.ToHashtable())
        }

        # Handle sleep
        if ($this.Sleep) {
            $Data.Add('sleep', $this.Sleep.ToHashtable())
        }

        $Output.Add('data', $Data)

        # Add notes field
        if (-not [string]::IsNullOrEmpty($this.Note)) {
            $Output.Add('notes', $this.Note)
        } else {
            $Output.Add('notes', '')
        }

        return $Output
    }
}
# Export the class
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *