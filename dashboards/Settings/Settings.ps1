$SettingsPage = New-UDApp -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    if (!$UserData) {
        sleep 6
        Show-UDToast -Message "Redirecting to login page." -MessageColor Green -Duration 1000
        Invoke-UDRedirect -Url /login -Native
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
            background: #f8f9fa;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
            border-left: 4px solid var(--theme-palette-primary-main);
        }

        .medication-item, .activity-item, .pain-location-item {
            background: #f0f7ff;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 12px;
            border: 1px solid #e3f2fd;
        }

        .remove-btn {
            background-color: #f44336 !important;
            color: white !important;
            min-width: 40px !important;
            padding: 8px !important;
        }

        .add-btn {
            background-color: #4caf50 !important;
            color: white !important;
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

        New-UDElement -Tag 'div' -Attributes @{ class = 'settings-form' } -Content {

            # Basic Profile Settings Section
            # TODO: Make these rows so they stack on top of each other
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '👤 Profile Preferences' -Variant h5
                New-UDTypography -Text 'Basic settings for your health dashboard experience' -Style @{ class = 'section-description' }

                New-UDGrid -Container -Children {
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'timezone' -Label '🌍 Timezone' -FullWidth -Option {
                            New-UDSelectOption -Name 'UTC' -Value 'UTC'
                            New-UDSelectOption -Name 'Eastern Time' -Value 'America/New_York'
                            New-UDSelectOption -Name 'Central Time' -Value 'America/Chicago'
                            New-UDSelectOption -Name 'Mountain Time' -Value 'America/Denver'
                            New-UDSelectOption -Name 'Pacific Time' -Value 'America/Los_Angeles'
                        } -DefaultValue 'America/Denver'
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'temperature_unit' -Label '🌡️ Temperature Unit' -FullWidth -Option {
                            New-UDSelectOption -Name 'Fahrenheit' -Value 'fahrenheit'
                            New-UDSelectOption -Name 'Celsius' -Value 'celsius'
                        } -DefaultValue 'fahrenheit'
                    }

                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'weight_unit' -Label '⚖️ Weight Unit' -FullWidth -Option {
                            New-UDSelectOption -Name 'Pounds' -Value 'pounds'
                            New-UDSelectOption -Name 'Kilograms' -Value 'kilograms'
                        } -DefaultValue 'pounds'
                    }
                }
            }

            # Optional Tracking Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '� Optional Tracking' -Variant h5
                New-UDTypography -Text 'Choose which optional health metrics you want to track' -Style @{ class = 'section-description' }

                # Vital Signs and Health Metrics
                New-UDElement -Tag 'div' -Attributes @{ class = 'tracking-toggle' } -Content {
                    New-UDGrid -Container -Children {
                        # TODO: Align these properly, they look sloppy right now
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            New-UDCheckbox -Id 'track_temperature' -Label '🌡️ Track Temperature (As Needed)'
                            New-UDCheckbox -Id 'track_blood_pressure' -Label '🩸 Track Blood Pressure (As Needed)'
                            New-UDCheckbox -Id 'track_weight' -Label '⚖️ Track Weight (Daily)'
                            New-UDCheckbox -Id 'track_oxygen' -Label '🫁 Track Oxygen Saturation (As Needed)'
                            New-UDCheckbox -Id 'track_heart_rate' -Label '💗 Track Heart Rate (As Needed)'
                            New-UDCheckbox -Id 'track_glucose' -Label '🩸 Track Blood Glucose (As Needed)'
                            New-UDCheckbox -Id 'track_activities' -Label '🏃 Track Activities & Exercise'
                            New-UDCheckbox -Id 'track_sleep' -Label '😴 Track Sleep'
                            New-UDCheckbox -Id 'track_mood' -Label '😊 Track Mood'
                        }
                    }
                }
            }

            # Mandatory Tracking Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '📋 Required Tracking' -Variant h5
                New-UDTypography -Text 'These health metrics are always tracked and cannot be disabled' -Style @{ class = 'section-description' }

                # Mandatory tracking items (always enabled)
                New-UDGrid -Container -Children {
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTypography -Text '🩹 Pain Levels (Required)' -Variant body1 -Style @{
                            color = 'var(--theme-palette-text-primary)'
                            fontWeight = '500'
                            padding = '8px 0'
                        }
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTypography -Text '💊 Medications (Required)' -Variant body1 -Style @{
                            color = 'var(--theme-palette-text-primary)'
                            fontWeight = '500'
                            padding = '8px 0'
                        }
                    }
                }
            }

            # Medications Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '💊 Medications' -Variant h5
                New-UDTypography -Text 'Add medications you are currently taking' -Style @{ class = 'section-description' }

                New-UDElement -Id 'medications-container' -Tag 'div' -Content {
                    # Initial medication entry
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
                                        } catch {
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
                        New-UDSelect -Id 'pain_locations' -Label 'Pain Locations' -Multiple -FullWidth -Option {
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
                        New-UDTextbox -Id 'activities_list' -Label 'Activities (comma-separated)' -Placeholder 'e.g., Walking, Physical Therapy, Swimming, Stretching, Yoga' -Multiline -Rows 3 -FullWidth
                    }
                }
            }

            # Save Settings Button - Wrapped in Form for data collection
            New-UDForm -Id 'settings-form' -Children {
                # Hidden submit button (we'll trigger this programmatically)
                New-UDElement -Tag 'button' -Attributes @{
                    type = 'submit'
                    style = 'display: none;'
                    id = 'hidden-submit-btn'
                }
            } -OnSubmit {
                try {
                    Import-Module UserManagement -Force
                    $FormData = $EventData[0]

                    Write-Information "Settings form data received: $($FormData | ConvertTo-Json -Depth 3)"

                    # Collect medications (dynamic entries)
                    $Medications = @()
                    for ($i = 1; $i -le 10; $i++) {  # Check up to 10 medication entries
                        $medName = $FormData["med_name_$i"]
                        if (-not [string]::IsNullOrEmpty($medName)) {
                            $Medications += @{
                                name = $medName
                                dosage = $FormData["med_dosage_$i"]
                            }
                        }
                    }

                    # Collect pain locations (multi-select)
                    $PainLocations = @()
                    if ($FormData.pain_locations) {
                        # Handle both single value and array
                        $selectedLocations = if ($FormData.pain_locations -is [array]) {
                            $FormData.pain_locations
                        } else {
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
                    $PreferencesResult = New-UserHealthPreferences -Email $User -Timezone $FormData.timezone -TemperatureUnit $FormData.temperature_unit -WeightUnit $FormData.weight_unit -TrackBloodPressure:($FormData.track_blood_pressure -eq $true) -TrackOxygen:($FormData.track_oxygen -eq $true) -TrackHeartRate:($FormData.track_heart_rate -eq $true) -TrackTemperature:($FormData.track_temperature -eq $true) -TrackWeight:($FormData.track_weight -eq $true) -TrackGlucose:($FormData.track_glucose -eq $true) -TrackMedications:$true -TrackPain:$true -TrackActivities:($FormData.track_activities -eq $true) -TrackSleep:($FormData.track_sleep -eq $true) -TrackMood:($FormData.track_mood -eq $true) -Medications $Medications -PainLocations $PainLocations -Activities $Activities

                    if ($PreferencesResult.Success) {
                        Show-UDToast -Message 'Health tracking settings saved successfully!' -Duration 3000 -BackgroundColor '#4caf50'
                        Write-Information "Preferences saved successfully: $($PreferencesResult.Message)"
                    } else {
                        Show-UDToast -Message "Error saving settings: $($PreferencesResult.Message)" -Duration 5000 -BackgroundColor '#f44336'
                        Write-Error "Failed to save preferences: $($PreferencesResult.Message)"
                    }

                } catch {
                    $errorMsg = "Error processing settings: $($_.Exception.Message)"
                    Write-Error $errorMsg
                    Show-UDToast -Message $errorMsg -Duration 5000 -BackgroundColor '#f44336'
                }
            }

            # Visible Save Button
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDButton -Text '💾 Save Health Tracking Settings' -Color primary -Size large -FullWidth -OnClick {
                        # Trigger the hidden form submit to collect all data
                        Invoke-UDJavaScript -JavaScript "document.getElementById('hidden-submit-btn').click();"
                    } -Style @{
                        marginTop = '30px'
                        padding = '16px 0'
                        fontSize = '18px'
                        fontWeight = 'bold'
                    }
                }
            }
        }
    }
}
# Return the settings app
$SettingsPage
