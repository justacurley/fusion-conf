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
    # Schema v2.0 fields
    [string] $EntryId = ''
    [string] $UserEmail = ''
    [string] $Date = ''
    [string] $Time = ''
    [string[]] $EntryTypes = @()

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

    # Default constructor
    HealthEntry() {
        $this.InitializeDefaults()
    }

    # Constructor with user email
    HealthEntry([string]$UserEmail) {
        $this.UserEmail = $UserEmail
        $this.InitializeDefaults()
    }

    # Initialize default values
    [void] InitializeDefaults() {
        $now = Get-Date
        $this.Date = $now.ToString('yyyy-MM-dd')
        $this.Time = $now.ToString('HH:mm')
        $this.EntryId = $now.ToString('yyMMddHHmm')
        $this.EntryTypes = @()
        # Don't call UpdateEntryTypes here - it should be called when data is added
    }

    # Validation method - Schema v2.0 compliance
    [bool] IsValid() {
        # Check required fields
        if ([string]::IsNullOrWhiteSpace($this.EntryId) -or $this.EntryId.Length -ne 10) {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($this.UserEmail) -or $this.UserEmail -notmatch '^[^@]+@[^@]+\.[^@]+$') {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($this.Date) -or $this.Date -notmatch '^\d{4}-\d{2}-\d{2}$') {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($this.Time) -or $this.Time -notmatch '^\d{2}:\d{2}$') {
            return $false
        }
        if ($this.EntryTypes.Count -eq 0) {
            return $false
        }

        # Validate individual components if present
        if ($this.Vitals -and -not $this.Vitals.IsValid()) { return $false }
        if ($this.Mood -and -not $this.Mood.IsValid()) { return $false }
        if ($this.Weight -and -not $this.Weight.IsValid()) { return $false }
        if ($this.Sleep -and -not $this.Sleep.IsValid()) { return $false }

        # Validate arrays
        foreach ($pain in $this.Pain) {
            if (-not $pain.IsValid()) { return $false }
        }
        foreach ($med in $this.Medication) {
            if (-not $med.IsValid()) { return $false }
        }
        foreach ($activity in $this.Activity) {
            if (-not $activity.IsValid()) { return $false }
        }

        return $true
    }

    # Automatically determine entry types based on populated data
    [void] UpdateEntryTypes() {
        $this.EntryTypes = @()

        if ($this.Mood) { $this.EntryTypes += 'mood' }
        if ($this.Vitals) { $this.EntryTypes += 'vitals' }
        if ($this.Medication.Count -gt 0) { $this.EntryTypes += 'medications' }
        if ($this.Activity.Count -gt 0) { $this.EntryTypes += 'activities' }
        if ($this.Pain.Count -gt 0) { $this.EntryTypes += 'pain' }
        if ($this.Weight) { $this.EntryTypes += 'weight' }
        if ($this.Sleep) { $this.EntryTypes += 'sleep' }
    }


    # Serialization method - Schema v2.0 format
    [hashtable] ToHashtable() {
        # Update entry types before serialization
        $this.UpdateEntryTypes()

        [hashtable]$Output = @{}

        # Required fields per schema v2.0
        $Output.Add('entry_id', $this.EntryId)
        $Output.Add('user_email', $this.UserEmail)
        $Output.Add('date', $this.Date)
        $Output.Add('time', $this.Time)
        $Output.Add('entry_types', [array]$this.EntryTypes)

        # Build data section based on what's present
        [hashtable]$Data = @{}

        # Handle mood
        if ($this.Mood) {
            $Data.Add('mood', $this.Mood.ToHashtable())
        }

        # Handle vitals
        if ($this.Vitals) {
            $Data.Add('vitals', $this.Vitals.ToHashtable())
        }

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

        # Handle weight
        if ($this.Weight) {
            $Data.Add('weight', $this.Weight.ToHashtable())
        }

        # Handle sleep
        if ($this.Sleep) {
            $Data.Add('sleep', $this.Sleep.ToHashtable())
        }

        $Output.Add('data', $Data)

        # Add notes field (required per schema)
        $Output.Add('notes', $this.Note)

        return $Output
    }

    # Static method to create HealthEntry from schema v2.0 JSON
    static [HealthEntry] FromHashtable([hashtable]$data) {
        # Create entry without calling InitializeDefaults() to avoid auto-generating fields
        $entry = [HealthEntry]::new()
        $entry.EntryId = ''  # Reset the auto-generated EntryId
        $entry.Date = ''     # Reset the auto-generated Date
        $entry.Time = ''     # Reset the auto-generated Time

        # Set required fields
        if ($data.ContainsKey('entry_id')) { $entry.EntryId = $data.entry_id }
        if ($data.ContainsKey('user_email')) { $entry.UserEmail = $data.user_email }
        if ($data.ContainsKey('date')) { $entry.Date = $data.date }
        if ($data.ContainsKey('time')) { $entry.Time = $data.time }
        if ($data.ContainsKey('entry_types')) { $entry.EntryTypes = $data.entry_types }
        if ($data.ContainsKey('notes')) { $entry.Note = $data.notes }

        # Process data section
        if ($data.ContainsKey('data') -and $data.data) {
            $entryData = $data.data

            # Handle mood
            if ($entryData.ContainsKey('mood')) {
                $moodData = $entryData.mood
                $entry.Mood = [Mood]::new($moodData.mood_level, $moodData.mood_note)
            }

            # Handle vitals
            if ($entryData.ContainsKey('vitals')) {
                $vitalsData = $entryData.vitals
                $entry.Vitals = [Vitals]::new(
                    $vitalsData.oxygen_saturation,
                    $vitalsData.blood_pressure,
                    $vitalsData.heart_rate,
                    $vitalsData.temperature
                )
            }

            # Handle medications
            if ($entryData.ContainsKey('medications')) {
                $entry.Medication = @()
                foreach ($med in $entryData.medications) {
                    $entry.Medication += [MedicationTaken]::new($med.dosage, $med.name)
                }
            }

            # Handle activities
            if ($entryData.ContainsKey('activities')) {
                $entry.Activity = @()
                foreach ($act in $entryData.activities) {
                    $actNote = if ($act.ContainsKey('note')) { $act.note } else { '' }
                    $entry.Activity += [Activity]::new($act.name, $act.duration_minutes, $actNote)
                }
            }

            # Handle pain
            if ($entryData.ContainsKey('pain')) {
                $entry.Pain = @()
                foreach ($pain in $entryData.pain) {
                    $painNote = if ($pain.ContainsKey('note')) { $pain.note } else { '' }
                    $entry.Pain += [PainLocation]::new($pain.location, $pain.severity, $painNote)
                }
            }

            # Handle weight
            if ($entryData.ContainsKey('weight')) {
                $weightData = $entryData.weight
                $entry.Weight = [Weight]::new($weightData.weight_lbs, $weightData.weight_kg)
            }

            # Handle sleep
            if ($entryData.ContainsKey('sleep')) {
                $sleepData = $entryData.sleep
                $entry.Sleep = [Sleep]::new($sleepData.sleep_hours)
            }
        }

        return $entry
    }

    # Helper method to validate schema v2.0 compliance
    [bool] ValidateSchemaV2() {
        try {
            # Check entry_id format (yyMMddHHmm)
            if ([string]::IsNullOrEmpty($this.EntryId) -or $this.EntryId -notmatch '^\d{10}$') {
                Write-Warning "Invalid entry_id format: $($this.EntryId). Expected yyMMddHHmm format."
                return $false
            }

            # Check entry_types are valid
            $validTypes = @('mood', 'vitals', 'medications', 'activities', 'pain', 'weight', 'sleep')
            foreach ($type in $this.EntryTypes) {
                if ($type -cnotin $validTypes) {  # Use -cnotin for case-sensitive comparison
                    Write-Warning "Invalid entry_type: $type. Valid types are: $($validTypes -join ', ')"
                    return $false
                }
            }

            return $this.IsValid()
        }
        catch {
            Write-Warning "Schema validation error: $($_.Exception.Message)"
            return $false
        }
    }
}
# Export the class
Export-ModuleMember -Function * -Cmdlet * -Variable * -Alias *