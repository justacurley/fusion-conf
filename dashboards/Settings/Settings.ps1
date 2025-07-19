function gpf {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Preference,
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$JsonPreferences
    )

    try {
        # Split the preference path by dots
        $pathParts = $Preference -split '\.'
        $current = $JsonPreferences

        # Navigate through each part of the path
        foreach ($part in $pathParts) {
            if ($current -is [PSCustomObject]) {
                if ($current.PSObject.Properties.Name -contains $part) {
                    $current = $current.$part
                }
                else {
                    return @{
                        success = $false
                        message = "Preference path '$Preference' not found - missing key '$part'"
                        data    = $null
                    }
                }
            }
            elseif ($current -is [hashtable]) {
                if ($current.ContainsKey($part)) {
                    $current = $current[$part]
                }
                else {
                    return @{
                        success = $false
                        message = "Preference path '$Preference' not found - missing key '$part'"
                        data    = $null
                    }
                }
            }
            elseif ($current -is [array]) {
                # Handle array index access
                if ($part -match '^\d+$') {
                    $index = [int]$part
                    if ($index -ge 0 -and $index -lt $current.Count) {
                        $current = $current[$index]
                    }
                    else {
                        return @{
                            success = $false
                            message = "Preference path '$Preference' not found - array index '$part' out of bounds"
                            data    = $null
                        }
                    }
                }
                else {
                    return @{
                        success = $false
                        message = "Preference path '$Preference' not found - cannot access property '$part' on array"
                        data    = $null
                    }
                }
            }
            else {
                return @{
                    success = $false
                    message = "Preference path '$Preference' not found - cannot navigate further from '$part'"
                    data    = $null
                }
            }
        }

        return @{
            success = $true
            message = "Preference '$Preference' found"
            data    = $current
        }
    }
    catch {
        return @{
            success = $false
            message = "Error accessing preference '$Preference': $($_.Exception.Message)"
            data    = $null
        }
    }
}

$SettingsPage = New-UDApp -Content {
    Import-Module UserManagement -Force
    $Session:UserData = Initialize-UserContext -UserEmail $User
    if (!$Session:UserData) {
        sleep 6
        Show-UDToast -Message "Redirecting to login page." -MessageColor Green -Duration 1000
        Invoke-UDRedirect -Url /login -Native
    } else {
    #   Write-Information ($Session:UserData | Select U*, P* | ConvertTo-Json -Depth 99)
        Write-Information ($Session:UserData.Preferences | Convertto-json -depth 99)
      $PSDefaultParameterValues["gpf:JsonPreferences"] = $Session:UserData.Preferences
    #   Show-UDToast -Message (gpf 'tracking.vitals.heart_rate.enabled' | Convertto-Json) -Duration 10000 -Persistent
    }
    # Add custom CSS for settings form styling
    New-UDElement -Tag 'style' -Content {
        @'
        .settings-form {
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
        }

        .settings-section {
            margin-bottom: 30px;
            background: var(--theme-palette-background-paper);
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .settings-section h5 {
            color: var(--theme-palette-primary-main);
            font-weight: 600;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--theme-palette-primary-light);
        }

        .settings-form .MuiFormControl-root {
            margin-bottom: 16px;
            width: 100%;
        }

        .settings-form .MuiButton-contained {
            background-color: var(--theme-palette-primary-main);
            color: white;
            padding: 12px 32px;
            font-size: 16px;
            font-weight: 600;
            border-radius: 8px;
            text-transform: none;
            margin-top: 20px;
        }

        .settings-form .MuiButton-contained:hover {
            background-color: var(--theme-palette-primary-dark);
            box-shadow: 0 6px 16px rgba(0,0,0,0.2);
        }

        .tracking-toggle {
            background: var(--theme-palette-background-default);
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
            border-left: 4px solid var(--theme-palette-primary-main);
            border: 1px solid var(--theme-palette-divider);
        }

        .medication-item, .activity-item, .pain-location-item {
            background: var(--theme-palette-background-paper);
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 12px;
            border: 1px solid var(--theme-palette-divider);
        }

        .remove-btn {
            background-color: var(--theme-palette-error-main) !important;
            color: var(--theme-palette-error-contrastText) !important;
            min-width: 40px !important;
            padding: 8px !important;
        }

        .add-btn {
            background-color: var(--theme-palette-success-main) !important;
            color: var(--theme-palette-success-contrastText) !important;
            margin-top: 12px !important;
        }

        .section-description {
            color: var(--theme-palette-text-secondary);
            font-size: 14px;
            margin-bottom: 20px;
            font-style: italic;
        }
'@
    }

    New-UDContainer -Children {
        # Header Section
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text '⚙️ Health Tracking Settings' -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = 'var(--theme-palette-primary-main)'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Configure your personalized health tracking preferences' -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = 'var(--theme-palette-text-secondary)'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '30px'; backgroundColor = 'var(--theme-palette-background-paper)' }
        New-UDForm -Id 'settings-form' -Children {
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-form' } -Content {

                # Basic Profile Settings Section
                New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                    New-UDTypography -Text '👤 Profile Preferences' -Variant h5
                    New-UDTypography -Text 'Basic settings for your health dashboard experience' -Style @{ class = 'section-description' }

                    New-UDStack -Id 'profile_preferences' -Content {
                            New-UDSelect -Id 'timezone' -Label '🌍 Timezone' -FullWidth -Option {
                                New-UDSelectOption -Name 'UTC' -Value 'UTC'
                                New-UDSelectOption -Name 'Eastern Time' -Value 'America/New_York'
                                New-UDSelectOption -Name 'Central Time' -Value 'America/Chicago'
                                New-UDSelectOption -Name 'Mountain Time' -Value 'America/Denver'
                                New-UDSelectOption -Name 'Pacific Time' -Value 'America/Los_Angeles'
                            } -DefaultValue ((($r=gpf 'profile.timezone').success) ? $r.data : 'UTC')
                            New-UDSelect -Id 'temperature_unit' -Label '🌡️ Temperature Unit' -FullWidth -Option {
                                New-UDSelectOption -Name 'Fahrenheit' -Value 'fahrenheit'
                                New-UDSelectOption -Name 'Celsius' -Value 'celsius'
                            } -DefaultValue ((($r=gpf 'profile.units.temperature').success) ? $r.data : 'fahrenheit')
                            New-UDSelect -Id 'weight_unit' -Label '⚖️ Weight Unit' -FullWidth -Option {
                                New-UDSelectOption -Name 'Pounds' -Value 'pounds'
                                New-UDSelectOption -Name 'Kilograms' -Value 'kilograms'
                            } -DefaultValue ((($r=gpf 'profile.units.weight').success) ? $r.data : 'pounds')
                    } -Direction Column
                }

                # Optional Tracking Section
                New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                    New-UDTypography -Text '📊 Optional Tracking' -Variant h5
                    New-UDTypography -Text 'Choose which optional health metrics you want to track' -Style @{ class = 'section-description' }

                    # Vital Signs and Health Metrics
                    New-UDElement -Tag 'div' -Attributes @{ class = 'tracking-toggle' } -Content {
                        New-UDGrid -Container -Children {
                            New-UDStack -Id 'optional_tracks' -Children {
                                New-UDCheckbox -Id 'track_weight' -Label '⚖️ Track Weight (Daily)' -Checked ((($r=gpf 'tracking.vitals.weight.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_sleep' -Label '😴 Track Sleep (Daily)' -Checked ((($r=gpf 'tracking.sleep.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_temperature' -Label '🌡️ Track Temperature (As Needed)' -Checked ((($r=gpf 'tracking.vitals.weight.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_blood_pressure' -Label '🩸 Track Blood Pressure (As Needed)' -OnChange {
                                    $Session:track_blood_pressure = (Get-UDElement -Id 'track_blood_pressure').Checked
                                    Sync-UDElement -Id 'tracking_devices'
                                } -Checked ((($r=gpf 'tracking.vitals.blood_pressure.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_oxygen' -Label '🫁 Track Oxygen Saturation (As Needed)' -OnChange {
                                    $Session:track_oxygen = (Get-UDElement -Id 'track_oxygen').Checked
                                    Sync-UDElement -Id 'tracking_devices'
                                } -Checked ((($r=gpf 'tracking.vitals.oxygen_saturation.enabled').success) ? $r.data : $false)
                            } -Direction Column -Divider {New-UDDivider -Variant 'inset'}
                            New-UDStack -Id 'optional_tracks' -Children {
                                New-UDCheckbox -Id 'track_heart_rate' -Label '💗 Track Heart Rate (As Needed)' -OnChange {
                                    $Session:track_heart_rate = (Get-UDElement -Id 'track_heart_rate').Checked
                                    Sync-UDElement -Id 'tracking_devices'
                                } -Checked ((($r=gpf 'tracking.vitals.heart_rate.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_glucose' -Label '🩸 Track Blood Glucose (As Needed)' -OnChange {
                                    $Session:track_glucose = (Get-UDElement -Id 'track_glucose').Checked
                                    Sync-UDElement -Id 'tracking_devices'
                                } -Checked ((($r=gpf 'tracking.vitals.blood_glucose.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_mood' -Label '😊 Track Mood (As Needed)' -Checked ((($r=gpf 'tracking.mood.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_steps' -Label '👟 Track Steps (Daily)' -OnChange {
                                    $Session:track_steps = (Get-UDElement -Id 'track_steps').Checked
                                    Sync-UDElement -Id 'tracking_devices'
                                } -Checked ((($r=gpf 'tracking.steps.enabled').success) ? $r.data : $false)
                                New-UDCheckbox -Id 'track_activities' -Label '🏃 Track Activities & Exercise' -Checked ((($r=gpf 'tracking.vitals.activities.enabled').success) ? $r.data : $false)
                            } -Direction Column -Divider {New-UDDivider -Variant 'inset'}
                        }
                    }
                }

                # Medications Section
                New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                    New-UDTypography -Text '💊 Medications' -Variant h5
                    New-UDTypography -Text 'Add medications you are currently taking' -Style @{ class = 'section-description' }

                    New-UDElement -Id 'medications-container' -Tag 'div' -Content {
                        # Get existing medications from preferences
                        $existingMedications = @()
                        $medicationsResult = gpf 'tracking.medications.medications_list'
                        if ($medicationsResult.success -and $medicationsResult.data) {
                            $existingMedications = $medicationsResult.data | Where-Object { $_.name -and $_.dosage }
                        }

                        # If no existing medications, create one empty entry
                        if ($existingMedications.Count -eq 0) {
                            New-UDElement -Tag 'div' -Attributes @{ class = 'medication-item' } -Content {
                                New-UDGrid -Container -Children {
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id 'med_name_1' -Label 'Medication Name' -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id 'med_dosage_1' -Label 'Dosage (e.g., 10mg)' -FullWidth
                                    }
                                }
                            }
                            # Initialize counter for adding new meds
                            $Session:MedicationCounter = 2
                        }
                        else {
                            # Create entries for existing medications
                            for ($i = 0; $i -lt $existingMedications.Count; $i++) {
                                $medIndex = $i + 1
                                $med = $existingMedications[$i]

                                New-UDElement -Id "medication-item-$medIndex" -Tag 'div' -Attributes @{ class = 'medication-item' } -Content {
                                    New-UDGrid -Container -Children {
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                                            New-UDTextbox -Id "med_name_$medIndex" -Label 'Medication Name' -FullWidth -Value $med.name
                                        }
                                        New-UDGrid -Item -ExtraSmallSize 10 -SmallSize 5 -Children {
                                            New-UDTextbox -Id "med_dosage_$medIndex" -Label 'Dosage (e.g., 10mg)' -FullWidth -Value $med.dosage
                                        }
                                        if ($i -gt 0) {  # Don't show remove button for first medication
                                            New-UDGrid -Item -ExtraSmallSize 2 -SmallSize 2 -Children {
                                                New-UDButton -Text '🗑️' -Color secondary -Size small -OnClick {
                                                    $currentMedIndex = $medIndex  # Capture in local scope
                                                    try {
                                                        Show-UDToast -Message "Removing Medication #$currentMedIndex" -Duration 2000
                                                        Clear-UDElement -Id "medication-item-$currentMedIndex"
                                                    }
                                                    catch {
                                                        Show-UDToast -Message "Error removing medication: $($_.Exception.Message)" -Duration 3000 -BackgroundColor red
                                                    }
                                                } -Style @{ class = 'remove-btn' }
                                            }
                                        }
                                    }
                                }
                            }
                            # Set counter for adding new medications
                            $Session:MedicationCounter = $existingMedications.Count + 1
                        }
                    }

                    New-UDButton -Text '+ Add Another Medication' -Color success -OnClick {
                        # Use session variable to track medication count
                        if (-not $Session:MedicationCounter) { $Session:MedicationCounter = 2 }
                        $medCount = $Session:MedicationCounter
                        $Session:MedicationCounter++

                        Show-UDToast -Message "Adding Medication #$medCount" -Duration 2000

                        # Add new medication entry to the container
                        Add-UDElement -ParentId 'medications-container' -Content {
                            $currentMedCount = $medCount  # Capture in local scope
                            New-UDElement -Id "medication-item-$currentMedCount" -Tag 'div' -Attributes @{ class = 'medication-item' } -Content {
                                New-UDGrid -Container -Children {
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                                        New-UDTextbox -Id "med_name_$currentMedCount" -Label 'Medication Name' -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 10 -SmallSize 5 -Children {
                                        New-UDTextbox -Id "med_dosage_$currentMedCount" -Label 'Dosage (e.g., 10mg)' -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 2 -SmallSize 2 -Children {
                                        New-UDButton -Text '🗑️' -Color secondary -Size small -OnClick {
                                            try {
                                                Show-UDToast -Message "Removing Medication #$currentMedCount" -Duration 2000
                                                Clear-UDElement -Id "medication-item-$currentMedCount"
                                            }
                                            catch {
                                                Show-UDToast -Message "Error removing medication: $($_.Exception.Message)" -Duration 3000 -BackgroundColor red
                                            }
                                        } -Style @{ class = 'remove-btn' }
                                    }
                                }
                            }
                        }
                    } -Style @{ class = 'add-btn' }
                }

                # Pain Locations Section
                New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                    New-UDTypography -Text '🩹 Pain Tracking Locations' -Variant h5
                    New-UDTypography -Text 'Select all body areas where you experience pain (multi-select)' -Style @{ class = 'section-description' }

                    New-UDGrid -Container -Children {
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            # Get existing pain locations from preferences
                            $existingPainLocations = @()
                            $painLocationsResult = gpf 'tracking.pain.locations'
                            if ($painLocationsResult.success -and $painLocationsResult.data) {
                                $existingPainLocations = $painLocationsResult.data | ForEach-Object {
                                    if ($_.name -and $_.name.location) {
                                        $_.name.location
                                    }
                                }
                            }

                            New-UDSelect -Id 'pain_locations' -Label 'Pain Locations' -Multiple -FullWidth -Checkbox -DefaultValue $existingPainLocations -Option {
                                New-UDSelectOption -Name 'Lower Back' -Value 'lower_back'
                                New-UDSelectOption -Name 'Upper Back' -Value 'upper_back'
                                New-UDSelectOption -Name 'Neck' -Value 'neck'
                                New-UDSelectOption -Name 'Right Hip' -Value 'right_hip'
                                New-UDSelectOption -Name 'Left Hip' -Value 'left_hip'
                                New-UDSelectOption -Name 'Right Knee' -Value 'right_knee'
                                New-UDSelectOption -Name 'Left Knee' -Value 'left_knee'
                                New-UDSelectOption -Name 'Right Shoulder' -Value 'right_shoulder'
                                New-UDSelectOption -Name 'Left Shoulder' -Value 'left_shoulder'
                                New-UDSelectOption -Name 'Head/Headache' -Value 'head'
                                New-UDSelectOption -Name 'Right Ankle' -Value 'right_ankle'
                                New-UDSelectOption -Name 'Left Ankle' -Value 'left_ankle'
                                New-UDSelectOption -Name 'Right Wrist' -Value 'right_wrist'
                                New-UDSelectOption -Name 'Left Wrist' -Value 'left_wrist'
                                New-UDSelectOption -Name 'Chest' -Value 'chest'
                                New-UDSelectOption -Name 'Abdomen' -Value 'abdomen'
                                New-UDSelectOption -Name 'Other' -Value 'other'
                            }
                        }
                    }
                }

                # Activities Section
                New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                    New-UDTypography -Text '🏃 Activities & Exercise' -Variant h5
                    New-UDTypography -Text 'Enter the names of activities and exercises you expect to perform during your recovery, separated by commas' -Style @{ class = 'section-description' }

                    New-UDGrid -Container -Children {
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            # Get existing activities from preferences
                            $existingActivities = ""
                            $activitiesResult = gpf 'tracking.activities.activities_list'
                            if ($activitiesResult.success -and $activitiesResult.data) {
                                $activityNames = $activitiesResult.data | ForEach-Object {
                                    if ($_.name) {
                                        $_.name
                                    }
                                } | Where-Object { -not [string]::IsNullOrEmpty($_) }
                                $existingActivities = $activityNames -join ', '
                            }

                            New-UDTextbox -Id 'activities_list' -Label 'Activities (comma-separated)' -Placeholder 'e.g., Walking, Physical Therapy, Swimming, Stretching, Yoga' -Multiline -Rows 3 -FullWidth -Value $existingActivities
                        }
                    }
                }

                # Device Settings Section
                New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                    New-UDDynamic -Id 'tracking_devices' -Content {
                        New-UDTypography -Text '📱 Device Configuration' -Variant h5
                        New-UDTypography -Text 'Configure your medical devices for tracking (optional)' -Style @{ class = 'section-description' }

                        New-UDGrid -Container -Children {
                            if ($Session:track_blood_pressure) {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                    New-UDTextbox -Id 'blood_pressure_device' -Label 'Blood Pressure Monitor' -Placeholder 'e.g., Omron BP742N' -FullWidth
                                }
                            }
                            if ($Session:track_oxygen) {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                    New-UDTextbox -Id 'oxygen_saturation_device' -Label 'Pulse Oximeter' -Placeholder 'e.g., Zacurate Pro Series 500DL' -FullWidth
                                }
                            }
                            if ($Session:track_glucose) {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                    New-UDTextbox -Id 'blood_glucose_device' -Label 'Blood Glucose Meter' -Placeholder 'e.g., FreeStyle Lite' -FullWidth
                                }
                            }
                            if ($Session:track_heart_rate) {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                    New-UDTextbox -Id 'heart_rate_device' -Label 'Heart Rate Monitor' -Placeholder 'e.g., Polar H10, Apple Watch, Fitbit' -FullWidth
                                }
                            }
                            if ($Session:track_steps) {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                    New-UDTextbox -Id 'steps_device' -Label 'Step Counter / Fitness Tracker' -Placeholder 'e.g., Fitbit Charge 5, Apple Watch, Garmin' -FullWidth
                                }
                            }
                        }
                    }
                }
            }
        } -OnSubmit {
            try {
                Import-Module UserManagement -Force
                $FormData = $EventData[0]
                $PSKeys = ( $FormData | Get-Member -MemberType NoteProperty ).Name
                Write-Information "Settings form data received: $($FormData | ConvertTo-Json -Depth 3)"

                # Collect medications (dynamic entries)
                $Medications = @()
                $PSKeys.Where({$_ -match "^med_name_"}).ForEach({
                    $dosage = $_ -replace 'name','dosage'
                    if ($dosage -in $PSKeys -and ( -not [string]::IsNullOrEmpty($FormData.$dosage))) {
                        $Medications += @{
                            name = $FormData.$_
                            dosage = $FormData.$dosage
                        }
                    } else { Show-UDToast -Message "Missing dosage for $($FormData.$_)" -Duration 5000 -BackgroundColor '#f44336' }
                })

                # Collect pain locations (multi-select)
                $PainLocations = @()
                if ($FormData.pain_locations) {
                    # Handle both single value and array
                    $selectedLocations = if ($FormData.pain_locations -is [array]) {
                        $FormData.pain_locations
                    }
                    else {
                        @($FormData.pain_locations)
                    }
                    foreach ($location in $selectedLocations) {
                        $PainLocations += @{
                            location = $location
                        }
                    }
                }

                # Collect activities (comma-separated list)
                $Activities = @()
                if (-not [string]::IsNullOrEmpty($FormData.activities_list)) {
                    $activityNames = $FormData.activities_list -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
                    foreach ($activityName in $activityNames) {
                        $Activities += @{
                            name = $activityName
                        }
                    }
                }

                # Call New-UserHealthPreferences with collected data
                $PreferencesResult = New-UserHealthPreferences -Email $User -Timezone $FormData.timezone -TemperatureUnit $FormData.temperature_unit `
                    -Medications $Medications -PainLocations $PainLocations -Activities $Activities `
                    -WeightUnit $FormData.weight_unit -TrackBloodPressure:($FormData.track_blood_pressure -eq $true) `
                    -TrackOxygen:($FormData.track_oxygen -eq $true) -TrackHeartRate:($FormData.track_heart_rate -eq $true) `
                    -TrackTemperature:($FormData.track_temperature -eq $true) -TrackWeight:($FormData.track_weight -eq $true) `
                    -TrackGlucose:($FormData.track_glucose -eq $true) -TrackMedications:$true -TrackPain:$true `
                    -TrackActivities:($FormData.track_activities -eq $true) -TrackSleep:($FormData.track_sleep -eq $true) `
                    -TrackMood:($FormData.track_mood -eq $true) -TrackSteps:($FormData.track_steps -eq $true) `
                    -BloodPressureDevice $FormData.blood_pressure_device -OxygenSaturationDevice $FormData.oxygen_saturation_device `
                    -BloodGlucoseDevice $FormData.blood_glucose_device -HeartRateDevice $FormData.heart_rate_device `
                    -StepsDevice $FormData.steps_device

                if ($PreferencesResult.Success) {
                    Show-UDToast -Message 'Health tracking settings saved successfully!' -Duration 3000 -BackgroundColor '#4caf50'
                    Write-Information "Preferences saved successfully: $($PreferencesResult.Message)"
                    Write-Information ($PreferencesResult | Convertto-Json -depth 99)
                }
                else {
                    Show-UDToast -Message "Error saving settings: $($PreferencesResult.Message)" -Duration 5000 -BackgroundColor '#f44336'
                    Write-Error "Failed to save preferences: $($PreferencesResult.Message)"
                }

            }
            catch {
                $errorMsg = "Error processing settings: $($_.Exception.Message)"
                Write-Error $errorMsg
                Show-UDToast -Message $errorMsg -Duration 5000 -BackgroundColor '#f44336'
            }
        }
    }
}

# Return the settings app
$SettingsPage
