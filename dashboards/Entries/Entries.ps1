# Helper function to create pain entry elements (reduces code duplication)
function New-PainEntryElement {
    param(
        [int]$EntryNumber,
        [bool]$IncludeRemoveButton = $false,
        [string[]]$ConfiguredLocations
    )

    $paperId = if ($EntryNumber -eq 1) { $null } else { "pain_entry_$EntryNumber" }

    return New-UDPaper -Id $paperId -Children {
        New-UDGrid -Container -Children {
            if ($IncludeRemoveButton) {
                New-UDGrid -Item -ExtraSmallSize 10 -Children {
                    New-UDTypography -Text "Pain Entry #$EntryNumber" -Variant subtitle2 -Style @{
                        marginBottom = '15px'
                        color        = 'var(--theme-palette-primary-main)'
                        fontWeight   = '500'
                    }
                }
                New-UDGrid -Item -ExtraSmallSize 2 -Children {
                    New-UDButton -Text '🗑️' -Color secondary -Size small -OnClick {
                        # Remove this specific pain Paper using Clear-UDElement
                        try {
                            Show-UDToast -Message "Removing Pain Entry #$EntryNumber" -Duration 2000
                            # Clear the content of this specific pain entry
                            Clear-UDElement -Id "pain_entry_$EntryNumber"
                        }
                        catch {
                            Show-UDToast -Message "Error removing pain entry: $($_.Exception.Message)" -Duration 3000 -BackgroundColor red
                        }
                    } -Id "remove_pain_btn_$EntryNumber"
                }
            }
            else {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTypography -Text "Pain Entry #$EntryNumber" -Variant subtitle2 -Style @{
                        marginBottom = '15px'
                        color        = 'var(--theme-palette-primary-main)'
                        fontWeight   = '500'
                    }
                }
            }
            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                New-UDSelect -Id "pain_location_$EntryNumber" -Label '🎯 Pain Location' -FullWidth -Option {
                    if ($ConfiguredLocations.Count -gt 0) {
                        $ConfiguredLocations.ForEach({
                                $DisplayName = if ($_ -like "*_*") {
                                    $_.split('_').foreach({ $_.Substring(0, 1).ToUpper() + $_.Substring(1) }) -join ' '
                                }
                                New-UDSelectOption -Name $DisplayName -Value $_
                            })
                        New-UDSelectOption -Name "Other (specify below)" -Value "other"
                    }
                    else {
                        New-UDSelectOption -Name 'Back' -Value 'back'
                        New-UDSelectOption -Name 'Right Glute' -Value 'right_glute'
                        New-UDSelectOption -Name 'Left Glute' -Value 'left_glute'
                        New-UDSelectOption -Name 'Glutes' -Value 'glutes'
                        New-UDSelectOption -Name 'Right Hip' -Value 'righthip'
                        New-UDSelectOption -Name 'Left Hip' -Value 'lhip'
                        New-UDSelectOption -Name 'Hips' -Value 'hips'
                        New-UDSelectOption -Name 'Right Quad' -Value 'rquad'
                        New-UDSelectOption -Name 'Left Quad' -Value 'lquad'
                        New-UDSelectOption -Name 'Quads' -Value 'quads'
                        New-UDSelectOption -Name "Other (specify below)" -Value "other"
                    }
                } -OnChange {
                    if ($EventData -eq 'other') {
                        Write-Information "other was selected from select options"
                        Set-UDElement -Id "custom_location_container_$EntryNumber" -Content {
                            New-UDTextbox -Id "custom_pain_location_$EntryNumber" -Label "Other Location" -Placeholder "Enter Location..."
                        }
                    }
                    else {
                        Set-UDElement -Id "custom_location_container_$EntryNumber" -Content {}
                    }
                }
            }
            New-UDGrid -Item -ExtraSmallSize 12 -Children {
                New-UDElement -Id "custom_location_container_$EntryNumber" -Tag 'div'
            }
            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                New-UDTextbox -Id "pain_level_$EntryNumber" -Label '📊 Level (0-10)' -Type number -Minimum 0.0 -Maximum 10.0 -Placeholder 5.0 -FullWidth
            }
            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 6 -Children {
                New-UDTextbox -Id "pain_note_$EntryNumber" -Label '📝 Note' -Type text -Placeholder 'Optional note' -FullWidth
            }
        }
    } -Style @{
        padding         = '15px'
        margin          = '10px 0'
        backgroundColor = 'var(--theme-palette-background-paper)'
        borderLeft      = '4px solid var(--theme-palette-error-main)'
        borderRadius    = '8px'
        border          = '1px solid var(--theme-palette-divider)'
        boxShadow       = '0 2px 4px rgba(0,0,0,0.1)'
    }
}
# Helper function to reset mood button states and highlight selected
function Set-MoodButtonState {
    param(
        [int]$SelectedMood
    )

    @(1, 2, 3, 4, 5) | ForEach-Object {
        $color = if ($_ -eq $SelectedMood) { 'primary' } else { 'default' }
        $variant = if ($_ -eq $SelectedMood) { 'contained' } else { 'outlined' }
        Set-UDElement -Id "mood_$_" -Properties @{ color = $color; variant = $variant }
    }
}

# Helper function to create activity entry elements (reduces code duplication)
function New-ActivityEntryElement {
    param(
        [int]$EntryNumber,
        [bool]$IncludeRemoveButton = $false
    )

    $paperId = if ($EntryNumber -eq 1) { $null } else { "activities_entry_$EntryNumber" }

    return New-UDPaper -Id $paperId -Children {
        New-UDGrid -Container -Children {
            if ($IncludeRemoveButton) {
                New-UDGrid -Item -ExtraSmallSize 10 -Children {
                    New-UDTypography -Text "Activity #$EntryNumber" -Variant subtitle2 -Style @{
                        marginBottom = '15px'
                        color        = 'var(--theme-palette-primary-main)'
                        fontWeight   = '500'
                    }
                }
                New-UDGrid -Item -ExtraSmallSize 2 -Children {
                    New-UDButton -Text '🗑️' -Color secondary -Size small -OnClick {
                        # Remove this specific activity Paper using Clear-UDElement
                        try {
                            Show-UDToast -Message "Removing Activity #$EntryNumber" -Duration 2000
                            # Clear the content of this specific activity entry
                            Clear-UDElement -Id "activities_entry_$EntryNumber"
                        }
                        catch {
                            Show-UDToast -Message "Error removing activity: $($_.Exception.Message)" -Duration 3000 -BackgroundColor red
                        }
                    } -Id "remove_btn_$EntryNumber"
                }
            }
            else {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTypography -Text "Activity #$EntryNumber" -Variant subtitle2 -Style @{
                        marginBottom = '15px'
                        color        = 'var(--theme-palette-primary-main)'
                        fontWeight   = '500'
                    }
                }
            }
            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                New-UDTextbox -Id "activities_type_$EntryNumber" -Label '🏃‍♂️ Activity Type' -Type text -Placeholder 'Walking, Running, Swimming, etc.' -FullWidth
            }
            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Children {
                New-UDTextbox -Id "activities_length_$EntryNumber" -Label '⏱️ Duration (min)' -Type number -Placeholder '20' -FullWidth
            }
            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Children {
                New-UDTextbox -Id "activities_note_$EntryNumber" -Label '📝 Note' -Type text -Placeholder 'Optional note' -FullWidth
            }
        }
    } -Style @{
        padding         = '15px'
        margin          = '10px 0'
        backgroundColor = 'var(--theme-palette-background-paper)'
        borderLeft      = '4px solid var(--theme-palette-success-main)'
        borderRadius    = '8px'
        border          = '1px solid var(--theme-palette-divider)'
    }
}
# Helper function to update the mood element


New-UDApp -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    Write-Information ($UserData.Preferences.tracking.pain.locations.name.location)
    $Session:Pain = $UserData.Preferences.tracking.pain
    $Session:PreferredPainLocations = $Session:Pain.enabled ? $Session:Pain.locations.name.location : @()
    $Session:Mood = $UserData.Preferences.tracking.mood
    $Session:MoodEnabled = $Session:Mood.enabled ? $true : $false
    $Session:MoodScaleType = $Session:Mood.scale_type ? $Session:Mood.scale_type : "numeric_5"
    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text '🏥 Health Recovery Entry Form' -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = 'var(--theme-palette-primary-main)'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Track your daily health metrics and recovery progress' -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = 'var(--theme-palette-text-secondary)'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '20px'; backgroundColor = 'var(--theme-palette-background-paper)' }
        New-UDForm -Children {
            # Date and Time fields
            New-UDCard -Title '📅 Date & Time' -Content {
                New-UDGrid -Container -Children {
                    $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time')
                    $currentDate = $MSTDate.ToString('yyyy-MM-dd')
                    $currentTime = $MSTDate.ToString('HH:mm')

                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTextbox -Id 'date' -Label '📅 Date' -Type 'date' -FullWidth -Value $currentDate
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTextbox -Id 'timestamp' -Label '🕐 Time' -Type 'time' -FullWidth -Value $currentTime
                    }
                }
                New-UDTypography -Text '💡 Automatically set to current Mountain Time - adjust if needed' -Variant caption -Style @{
                    marginTop = '5px'
                    color     = 'var(--theme-palette-text-secondary)'
                    fontStyle = 'italic'
                    textAlign = 'center'
                }
            } -Style @{ marginBottom = '20px' }
            # Medicatins Sectin
            # Medications Section - Collapsible with Enhanced UI
            New-UDCard -Title '💊 Medications' -Content {
                # Toggle button for collapsing/expanding medications
                New-UDContainer -Children {
                    New-UDButton -Text '🔽 Show Medications' -Id 'medications_toggle' -Color primary -Variant outlined -OnClick {
                        # Toggle the transition state
                        $currentState = Get-UDElement -Id 'medications_transition'
                        $newState = -not $currentState.in

                        Set-UDElement -Id 'medications_transition' -Properties @{
                            in = $newState
                        }

                        # Update button text based on state
                        if ($newState) {
                            Set-UDElement -Id 'medications_toggle' -Properties @{
                                text = '� Hide Medications'
                            }
                        }
                        else {
                            Set-UDElement -Id 'medications_toggle' -Properties @{
                                text = '🔽 Show Medications'
                            }
                        }
                    } -Style @{
                        marginBottom = '15px'
                        width        = '100%'
                    }
                }

                # Collapsible medications content
                New-UDTransition -Id 'medications_transition' -Content {
                    New-UDGrid -Container -Children {
                        try {
                            # Load user-defined medications from preferences instead of lookup file
                            Import-Module UserManagement -Force
                            $CurrentUserResult = Get-CurrentUser

                            if ($CurrentUserResult.Success -and $CurrentUserResult.Data.Preferences.Medications) {
                                $UserMedications = $CurrentUserResult.Data.Preferences.Medications

                                # Create visual cards for each user-defined medication
                                foreach ($medication in $UserMedications) {
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -MediumSize 4 -Children {
                                        New-UDPaper -Children {
                                            New-UDTypography -Text "💊 $($medication.name.ToUpper())" -Variant subtitle1 -Style @{
                                                fontWeight   = 'bold'
                                                marginBottom = '10px'
                                                color        = 'var(--theme-palette-primary-main)'
                                                textAlign    = 'center'
                                            }

                                            # Create checkbox for the user's medication with their dosage
                                            New-UDCheckBox -Id "med_$($medication.name -replace '\W', '_')_$($medication.dosage -replace '\W', '_')" -Label "$($medication.dosage)"
                                        } -Style @{
                                            padding         = '15px'
                                            margin          = '5px'
                                            backgroundColor = 'var(--theme-palette-background-default)'
                                            borderLeft      = '4px solid var(--theme-palette-primary-main)'
                                            borderRadius    = '8px'
                                            minHeight       = '120px'
                                            border          = '1px solid var(--theme-palette-divider)'
                                        }
                                    }
                                }
                            } else {
                                # No user medications defined yet
                                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                    New-UDAlert -Severity info -Text 'No medications configured. Add your medications in Settings to track them here.'
                                }
                            }
                        }
                        catch {
                            Write-Error "Failed to load user medications: $_"
                            New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                New-UDAlert -Severity error -Text 'Unable to load your medication preferences. Please check your Settings.'
                            }
                        }
                    }

                    New-UDTypography -Text '💡 Select all, if any, medications taken at the time of entry' -Variant caption -Style @{
                        marginTop = '15px'
                        color     = 'var(--theme-palette-text-secondary)'
                        fontStyle = 'italic'
                        textAlign = 'center'
                    }
                } -In:$false -Collapse -Timeout 500
            } -Style @{ marginBottom = '20px' }

            # Add a section for activities that is comprised of a text box on the left for text data, the "Activity", and an text box next to it for integer data, the "Duration (minutes)", and another for "Note"
            New-UDCheckBox -Id 'add_activity' -Label '🏃‍♂️ Add Activity Entry' -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show activities entry section
                    Set-UDElement -Id 'activities_section' -Content {
                        New-UDCard -Title '🏃‍♂️ Physical Activities' -Content {
                            # Initial activity entry using reusable function
                            New-ActivityEntryElement -EntryNumber 1 -IncludeRemoveButton $false

                            # Container for additional activities
                            New-UDElement -Id 'additional_activities_container' -Tag 'div'

                            # Add More Button - Separate container
                            New-UDContainer -Children {
                                New-UDButton -Text '➕ Add Another Activity' -Color primary -Variant outlined -OnClick {
                                    if (-not $Session:ActivityEntryCounter) { $Session:ActivityEntryCounter = 2 }
                                    $entryCount = $Session:ActivityEntryCounter
                                    $Session:ActivityEntryCounter++

                                    # Use Show-UDToast to debug
                                    Show-UDToast -Message "Adding Activity #$entryCount" -Duration 2000

                                    # Add the new activity using Add-UDElement with proper syntax
                                    Add-UDElement -ParentId 'additional_activities_container' -Content {
                                        $currentEntryCount = $entryCount  # Capture the variable in local scope
                                        New-ActivityEntryElement -EntryNumber $currentEntryCount -IncludeRemoveButton $true
                                    }
                                }
                            }

                            New-UDTypography -Text '💡 Track your physical activities and exercise duration' -Variant caption -Style @{
                                marginTop = '15px'
                                color     = 'var(--theme-palette-text-secondary)'
                                fontStyle = 'italic'
                                textAlign = 'center'
                            }
                        } -Style @{
                            marginBottom = '20px'
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide activities section
                    Set-UDElement -Id 'activities_section' -Content { }
                }
            }
            # Activities section container (appears below checkbox when enabled)
            New-UDElement -Id 'activities_section' -Tag 'div'

            #pain section
            New-UDCheckBox -Id 'add_pain' -Label '🩹 Add Pain Entry' -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show pain entry section
                    Set-UDElement -Id 'pain_section' -Content {
                        New-UDCard -Title '🩹 Pain Tracking' -Content {
                            # Initial pain entry using reusable function
                            New-PainEntryElement -EntryNumber 1 -ConfiguredLocations $Session:PreferredPainLocations

                            # Container for additional pain entries
                            New-UDElement -Id 'additional_pain_container' -Tag 'div'

                            # Add More Button - Separate container
                            New-UDContainer -Children {
                                New-UDButton -Text '➕ Add Another Pain Entry' -Color primary -Variant outlined -OnClick {
                                    # Use PowerShell Universal Session scope for persistent counters
                                    if (-not $Session:PainEntryCounter) { $Session:PainEntryCounter = 2 }
                                    $entryCount = $Session:PainEntryCounter
                                    $Session:PainEntryCounter++

                                    # Use Show-UDToast to debug
                                    Show-UDToast -Message "Adding Pain Entry #$entryCount" -Duration 2000

                                    # Add the new pain entry using Add-UDElement with proper syntax
                                    Add-UDElement -ParentId 'additional_pain_container' -Content {
                                        $currentEntryCount = $entryCount  # Capture the variable in local scope
                                        New-PainEntryElement -EntryNumber $currentEntryCount -IncludeRemoveButton $true -ConfiguredLocations $Session:PreferredPainLocations
                                    }
                                }
                            }

                            New-UDTypography -Text '💡 Track pain levels and locations for better health monitoring' -Variant caption -Style @{
                                marginTop = '15px'
                                color     = 'var(--theme-palette-text-secondary)'
                                fontStyle = 'italic'
                                textAlign = 'center'
                            }
                        } -Style @{
                            marginBottom = '20px'
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide pain section
                    Set-UDElement -Id 'pain_section' -Content { }
                }
            }
            # Pain section container (appears below checkbox when enabled)
            New-UDElement -Id 'pain_section' -Tag 'div'

            # Vitals Section - Enhanced UI
            New-UDCheckBox -Id 'add_vitals' -Label '🩺 Add Vital Signs' -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show vitals entry section
                    Set-UDElement -Id 'vitals_section' -Content {
                        New-UDCard -Title '🩺 Vital Signs' -Content {
                            New-UDPaper -Children {
                                New-UDGrid -Container -Children {
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        New-UDTypography -Text 'Vital Measurements' -Variant subtitle2 -Style @{
                                            marginBottom = '15px'
                                            color        = 'var(--theme-palette-primary-main)'
                                            fontWeight   = '500'
                                        }
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id 'o2' -Label '🫁 Oxygen Saturation (%)' -Type number -Placeholder '95-100' -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id 'bpr' -Label '❤️ Blood Pressure' -Type text -Placeholder '120/80' -FullWidth
                                    }
                                }
                            } -Style @{
                                padding         = '15px'
                                margin          = '10px 0'
                                backgroundColor = 'var(--theme-palette-background-paper)'
                                borderLeft      = '4px solid var(--theme-palette-info-main)'
                                borderRadius    = '8px'
                                border          = '1px solid var(--theme-palette-divider)'
                            }

                            New-UDTypography -Text '💡 Record oxygen saturation and blood pressure readings' -Variant caption -Style @{
                                marginTop = '15px'
                                color     = 'var(--theme-palette-text-secondary)'
                                fontStyle = 'italic'
                                textAlign = 'center'
                            }
                        } -Style @{
                            marginBottom = '20px'
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide vitals section
                    Set-UDElement -Id 'vitals_section' -Content { }
                }
            }
            # Vitals section container (appears below checkbox when enabled)
            New-UDElement -Id 'vitals_section' -Tag 'div'

            # Add a text field for additional notes
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTextbox -Id 'notes' -Label '📝 Additional Notes' -Type text -Placeholder 'Any additional information' -FullWidth
                }
            }

            # Sleep tracking section
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTextbox -Id 'sleep' -Label '😴 Sleep Duration' -Type text -Placeholder 'e.g., 7.5 hours, 8:30, 6h 45m' -FullWidth
                }
            }
            # Mood Tracking Section
            if ($Session:MoodEnabled) {
                New-UDCard -Title '😊 Mood Tracking' -Content {
                    New-UDPaper -Children {
                        New-UDStack -Direction Column -Children {
                            New-UDTypography -Text 'How are you feeling?' -Variant subtitle2 -Style @{
                                marginBottom = '20px'
                                color        = 'var(--theme-palette-primary-main)'
                                fontWeight   = '500'
                                textAlign    = 'center'
                            }
                            # Hidden input to store mood value for form submission
                            New-UDTextbox -Id 'mood' -Type 'text' -Value ($Session:SelectedMood ? $Session:SelectedMood : '') -Style @{ display = 'none' }



                            New-UDStack -Direction Row -JustifyContent center -Spacing 2 -Children {
                                # Rad 5
                                New-UDButton -Id 'mood_5' -Text '😃' -Variant outlined -Size large -OnClick {
                                    $Session:SelectedMood = 5
                                    Set-UDElement -Id 'mood_display' -Content {
                                        New-UDTypography -Text 'Feeling: Rad! 😃' -Variant body1 -Style @{
                                            color      = 'var(--theme-palette-success-main)'
                                            fontWeight = 'bold'
                                            textAlign  = 'center'
                                        }
                                    }
                                    # Reset other buttons and highlight selected
                                    Set-MoodButtonState -SelectedMood 5
                                } -Style @{ fontSize = '2rem'; minWidth = '60px'; minHeight = '60px' }
                                New-UDTypography -Text 'rad' -Variant caption -Style @{ textAlign = 'center'; marginTop = '5px' }

                                # Good (4)
                                New-UDButton -Id 'mood_4' -Text '🙂' -Variant outlined -Size large -OnClick {
                                    $Session:SelectedMood = 4
                                    Set-UDElement -Id 'mood_display' -Content {
                                        New-UDTypography -Text 'Feeling: Good 🙂' -Variant body1 -Style @{
                                            color      = 'var(--theme-palette-success-main)'
                                            fontWeight = 'bold'
                                            textAlign  = 'center'
                                        }
                                    }
                                    Set-MoodButtonState -SelectedMood 4
                                } -Style @{ fontSize = '2rem'; minWidth = '60px'; minHeight = '60px' }
                                New-UDTypography -Text 'good' -Variant caption -Style @{ textAlign = 'center'; marginTop = '5px' }

                                # Meh (3)
                                New-UDButton -Id 'mood_3' -Text '😐' -Variant outlined -Size large -OnClick {
                                    $Session:SelectedMood = 3
                                    Set-UDElement -Id 'mood_display' -Content {
                                        New-UDTypography -Text 'Feeling: Meh 😐' -Variant body1 -Style @{
                                            color      = 'var(--theme-palette-warning-main)'
                                            fontWeight = 'bold'
                                            textAlign  = 'center'
                                        }
                                    }
                                    Set-MoodButtonState -SelectedMood 3
                                } -Style @{ fontSize = '2rem'; minWidth = '60px'; minHeight = '60px' }
                                New-UDTypography -Text 'meh' -Variant caption -Style @{ textAlign = 'center'; marginTop = '5px' }

                                # Bad (2)
                                New-UDButton -Id 'mood_2' -Text '🙁' -Variant outlined -Size large -OnClick {
                                    $Session:SelectedMood = 2
                                    Set-UDElement -Id 'mood_display' -Content {
                                        New-UDTypography -Text 'Feeling: Bad 🙁' -Variant body1 -Style @{
                                            color      = 'var(--theme-palette-error-main)'
                                            fontWeight = 'bold'
                                            textAlign  = 'center'
                                        }
                                    }
                                    Set-MoodButtonState -SelectedMood 2
                                } -Style @{ fontSize = '2rem'; minWidth = '60px'; minHeight = '60px' }
                                New-UDTypography -Text 'bad' -Variant caption -Style @{ textAlign = 'center'; marginTop = '5px' }

                                # Awful (1)
                                New-UDButton -Id 'mood_1' -Text '😞' -Variant outlined -Size large -OnClick {
                                    $Session:SelectedMood = 1
                                    Set-UDElement -Id 'mood_display' -Content {
                                        New-UDTypography -Text 'Feeling: Awful 😞' -Variant body1 -Style @{
                                            color      = 'var(--theme-palette-error-main)'
                                            fontWeight = 'bold'
                                            textAlign  = 'center'
                                        }
                                    }
                                    Set-MoodButtonState -SelectedMood 1
                                } -Style @{ fontSize = '2rem'; minWidth = '60px'; minHeight = '60px' }
                                New-UDTypography -Text 'awful' -Variant caption -Style @{ textAlign = 'center'; marginTop = '5px' }


                            }
                            # Display selected mood
                            New-UDElement -Id 'mood_display' -Tag 'div' -Content {
                                New-UDTypography -Text 'Select your mood above' -Variant body2 -Style @{
                                    textAlign = 'center'
                                    color     = 'var(--theme-palette-text-secondary)'
                                    marginTop = '15px'
                                }
                            }
                            New-UDTextbox -Id 'mood_note' -Label '💭 Mood Note (Optional)' -Type text -Placeholder 'How are you feeling?' -FullWidth -Multiline -Rows 2
                        }
                    }
                    New-UDTypography -Text '💡 Track your daily mood to identify patterns and trends' -Variant caption -Style @{
                        marginTop = '15px'
                        color     = 'var(--theme-palette-text-secondary)'
                        fontStyle = 'italic'
                        textAlign = 'center'
                    } #-Style @{ marginBottom = '20px' }
                } -Style @{
                    padding         = '20px'
                    margin          = '10px 0'
                    backgroundColor = 'var(--theme-palette-background-paper)'
                    borderLeft      = '4px solid var(--theme-palette-warning-main)'
                    borderRadius    = '8px'
                    border          = '1px solid var(--theme-palette-divider)'
                }
            }
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDUpload -Id 'ImageFile' -Text 'Select Image to Upload' -Accept 'image/*'
                }
            }
        } -OnSubmit {
            Import-Module -Name fusion -Force
            $FormEvent = $EventData[0]
            $FormEvent.timestamp = [datetime]::Parse($FormEvent.timestamp).ToString('HHmm')
            $FormEvent.date = [datetime]::Parse($FormEvent.date).ToString('MMdd')
            Write-Information ($FormEvent | ConvertTo-Json -Depth 99)
            $entry = ConvertTo-EntriesFormat -Entry ( $FormEvent | ConvertTo-Json -Depth 99 | ConvertFrom-Json)
            # Save the entry to the entries.json file
            try {
                $saveResult = Save-ConvertedEntry -ConvertedEntry $entry
                if ($saveResult) {
                    Write-Information 'Successfully saved entry to entries.json'
                    Show-UDToast -Message 'Entry saved successfully!' -MessageColor Green -Duration 3000
                }
                else {
                    Write-Warning 'Failed to save entry - function returned false'
                    Show-UDToast -Message 'Failed to save entry' -MessageColor Red -Duration 5000
                }
            }
            catch {
                Write-Error "Error saving entry: $($_.Exception.Message)"
                Write-Error "Stack trace: $($_.ScriptStackTrace)"
                Show-UDToast -Message "Error saving entry: $($_.Exception.Message)" -MessageColor Red -Duration 5000
            }
            if ($EventData.ImageFile) {
                $imageFile = $EventData.ImageFile
                $imageFolderPath = '/home/data/fusion-data/img'
                $imageExt = $imageFile.Name.Split('.')[-1]
                $imageFileName = "$($EventData.date).$imageExt"
                $imagePath = Join-Path $imageFolderPath $imageFileName
                try {
                    # Save the uploaded image to the specified path
                    Copy-Item $EventData.ImageFile.FileName $imagePath
                    Write-Information "Image saved to: $imagePath"
                    Show-UDToast -Message 'Image uploaded successfully!' -MessageColor Green -Duration 3000
                }
                catch {
                    Write-Error "Error saving image: $($_.Exception.Message)"
                    Show-UDToast -Message "Error uploading image: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                }
            }
            # Update the cache with the new entry
            try {
                Import-Module -Name GetFusion -Force
                $EntriesPath = '/home/data/fusion-data/entries/entries.json'
                $Entries = Get-EntriesData -entriesPath $EntriesPath
                Set-PSUCache -Key 'entriesData' -Value $Entries -AbsoluteExpiration (Get-Date).AddDays(1)
                Write-Information 'Cache updated with new entries data'
            }
            catch {
                Write-Error "Error updating cache: $($_.Exception.Message)"
                Show-UDToast -Message "Error updating cache: $($_.Exception.Message)" -MessageColor Red -Duration 5000
            }
        }
    }
}
