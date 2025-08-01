$Pages += New-UDPage -Name 'entry' -url '/entry:entryid' -content {

    Import-Module UserManagement -Force
    Import-Module GetFusion -Force

    $UserData = Initialize-UserContext -UserEmail $User

    # Ensure EntriesPath is available
    if (-not $UserData.EntriesPath -and $UserData.UserDataPath) {
        $UserData | Add-Member -MemberType NoteProperty -Name 'EntriesPath' -Value (Join-Path $UserData.UserDataPath 'health-data/entries.json') -Force
    }

    # Load existing entry if entryid is provided
    $ExistingEntry = $null
    $IsEditMode = $false
    if ($entryid -and $entryid -ne 'new') {
        try {
            if ($UserData.EntriesPath -and (Test-Path $UserData.EntriesPath)) {
                $AllEntries = Get-Content $UserData.EntriesPath -Raw | ConvertFrom-Json
                $ExistingEntry = $AllEntries | Where-Object { $_.entry_id -eq $entryid }
                if ($ExistingEntry) {
                    $IsEditMode = $true
                    Write-Information "Found existing entry for editing: $entryid"
                }
                else {
                    Write-Warning "Entry ID $entryid not found in user's data"
                }
            }
        }
        catch {
            Write-Error "Error loading existing entry: $($_.Exception.Message)"
        }
    }

    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                $titleText = if ($IsEditMode) { "✏️ Edit Health Entry" } else { "🏥 Create Health Entry" }
                New-UDTypography -Text $titleText -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = 'var(--theme-palette-primary-main)'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                $subtitleText = if ($IsEditMode) { "Update your health entry data" } else { "Track your daily health metrics and recovery progress" }
                New-UDTypography -Text $subtitleText -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = 'var(--theme-palette-text-secondary)'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '20px'; backgroundColor = 'var(--theme-palette-background-paper)' }

        New-UDForm -Children {
            # Date and Time fields - prepopulated if editing
            New-UDCard -Title '📅 Date & Time' -Content {
                New-UDGrid -Container -Children {
                    # Determine initial values
                    if ($IsEditMode -and $ExistingEntry) {
                        $initialDate = $ExistingEntry.date
                        $initialTime = $ExistingEntry.time
                    }
                    else {
                        $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time')
                        $initialDate = $MSTDate.ToString('yyyy-MM-dd')
                        $initialTime = $MSTDate.ToString('HH:mm')
                    }

                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTextbox -Id 'date' -Label '📅 Date' -Type 'date' -FullWidth -Value $initialDate
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTextbox -Id 'timestamp' -Label '🕐 Time' -Type 'time' -FullWidth -Value $initialTime
                    }
                }
                $helpText = if ($IsEditMode) { "💡 Editing entry from $initialDate at $initialTime" } else { "💡 Automatically set to current Mountain Time - adjust if needed" }
                New-UDTypography -Text $helpText -Variant caption -Style @{
                    marginTop = '5px'
                    color     = 'var(--theme-palette-text-secondary)'
                    fontStyle = 'italic'
                    textAlign = 'center'
                }
            } -Style @{ marginBottom = '20px' }

            # Medications Section - Enhanced with prepopulation
            New-UDCard -Title '💊 Medications' -Content {
                New-UDContainer -Children {
                    $medButtonText = if ($IsEditMode -and $ExistingEntry.entry_types -contains 'medications') { '🔽 Hide Medications' } else { '🔽 Show Medications' }
                    $medInitialState = $IsEditMode -and $ExistingEntry.entry_types -contains 'medications'

                    New-UDButton -Text $medButtonText -Id 'medications_toggle' -Color primary -Variant outlined -OnClick {
                        $currentState = Get-UDElement -Id 'medications_transition'
                        $newState = -not $currentState.in

                        Set-UDElement -Id 'medications_transition' -Properties @{
                            in = $newState
                        }

                        if ($newState) {
                            Set-UDElement -Id 'medications_toggle' -Properties @{
                                text = '🔺 Hide Medications'
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

                New-UDTransition -Id 'medications_transition' -Content {
                    New-UDGrid -Container -Children {
                        try {
                            Import-Module UserManagement -Force
                            $CurrentUserResult = Get-CurrentUser

                            if ($CurrentUserResult.Success -and $CurrentUserResult.Data.Preferences.Tracking.Medications) {
                                $UserMedications = $CurrentUserResult.Data.Preferences.Tracking.Medications.medications_list

                                # Get existing medications if in edit mode
                                $ExistingMedications = @()
                                if ($IsEditMode -and $ExistingEntry.data.medications) {
                                    $ExistingMedications = $ExistingEntry.data.medications
                                }

                                foreach ($medication in $UserMedications) {
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -MediumSize 4 -Children {
                                        New-UDPaper -Children {
                                            New-UDTypography -Text "💊 $($medication.name.ToUpper())" -Variant subtitle1 -Style @{
                                                fontWeight   = 'bold'
                                                marginBottom = '10px'
                                                color        = 'var(--theme-palette-primary-main)'
                                                textAlign    = 'center'
                                            }

                                            # Check if this medication was taken in the existing entry
                                            $isChecked = $false
                                            if ($IsEditMode) {
                                                $isChecked = $ExistingMedications | Where-Object {
                                                    $_.name -eq $medication.name -and $_.dosage -eq $medication.dosage
                                                }
                                            }

                                            New-UDCheckBox -Id "med_$($medication.name -replace '\W', '_')_$($medication.dosage -replace '\W', '_')" -Label "$($medication.dosage)" -Checked:$isChecked
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
                            }
                            else {
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

                    New-UDTypography -Text '💡 Select all medications taken at the time of entry' -Variant caption -Style @{
                        marginTop = '15px'
                        color     = 'var(--theme-palette-text-secondary)'
                        fontStyle = 'italic'
                        textAlign = 'center'
                    }
                } -In:$medInitialState -Collapse -Timeout 500
            } -Style @{ marginBottom = '20px' }

            # Activities Section - Enhanced with prepopulation
            $activityInitialChecked = $IsEditMode -and $ExistingEntry.entry_types -contains 'activities'
            New-UDCheckBox -Id 'add_activity' -Label '🏃‍♂️ Add Activity Entry' -Checked:$activityInitialChecked -OnChange {
                if ($EventData) {
                    Set-UDElement -Id 'activities_section' -Content {
                        New-UDCard -Title '🏃‍♂️ Physical Activities' -Content {
                            # Prepopulate activities if editing
                            if ($IsEditMode -and $ExistingEntry.data.activities) {
                                $existingActivities = $ExistingEntry.data.activities
                                for ($i = 0; $i -lt $existingActivities.Count; $i++) {
                                    $activity = $existingActivities[$i]
                                    $entryNum = $i + 1

                                    New-UDPaper -Id $(if ($entryNum -eq 1) { $null } else { "activities_entry_$entryNum" }) -Children {
                                        New-UDGrid -Container -Children {
                                            New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                New-UDTypography -Text "Activity #$entryNum" -Variant subtitle2 -Style @{
                                                    marginBottom = '15px'
                                                    color        = 'var(--theme-palette-primary-main)'
                                                    fontWeight   = '500'
                                                }
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                                                New-UDTextbox -Id "activities_type_$entryNum" -Label '🏃‍♂️ Activity Type' -Type text -Placeholder 'Walking, Running, Swimming, etc.' -FullWidth -Value $activity.name
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Children {
                                                New-UDTextbox -Id "activities_length_$entryNum" -Label '⏱️ Duration (min)' -Type number -Placeholder '20' -FullWidth -Value $activity.duration_minutes
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Children {
                                                New-UDTextbox -Id "activities_note_$entryNum" -Label '📝 Note' -Type text -Placeholder 'Optional note' -FullWidth -Value $activity.note
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
                            }
                            else {
                                # Default single activity entry
                                New-ActivityEntryElement -EntryNumber 1 -IncludeRemoveButton $false
                            }

                            New-UDElement -Id 'additional_activities_container' -Tag 'div'

                            New-UDContainer -Children {
                                New-UDButton -Text '➕ Add Another Activity' -Color primary -Variant outlined -OnClick {
                                    if (-not $Session:ActivityEntryCounter) { $Session:ActivityEntryCounter = 2 }
                                    $entryCount = $Session:ActivityEntryCounter
                                    $Session:ActivityEntryCounter++

                                    Show-UDToast -Message "Adding Activity #$entryCount" -Duration 2000

                                    Add-UDElement -ParentId 'additional_activities_container' -Content {
                                        $currentEntryCount = $entryCount
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
                        } -Style @{ marginBottom = '20px' }
                    }
                }
                else {
                    Set-UDElement -Id 'activities_section' -Content { }
                }
            }
            New-UDElement -Id 'activities_section' -Tag 'div'

            # Pain Section - Enhanced with prepopulation
            $painInitialChecked = $IsEditMode -and $ExistingEntry.entry_types -contains 'pain'
            New-UDCheckBox -Id 'add_pain' -Label '🩹 Add Pain Entry' -Checked:$painInitialChecked -OnChange {
                if ($EventData) {
                    Set-UDElement -Id 'pain_section' -Content {
                        New-UDCard -Title '🩹 Pain Tracking' -Content {
                            # Prepopulate pain entries if editing
                            if ($IsEditMode -and $ExistingEntry.data.pain) {
                                $existingPain = $ExistingEntry.data.pain
                                for ($i = 0; $i -lt $existingPain.Count; $i++) {
                                    $pain = $existingPain[$i]
                                    $entryNum = $i + 1

                                    New-UDPaper -Id $(if ($entryNum -eq 1) { $null } else { "pain_entry_$entryNum" }) -Children {
                                        New-UDGrid -Container -Children {
                                            New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                New-UDTypography -Text "Pain Entry #$entryNum" -Variant subtitle2 -Style @{
                                                    marginBottom = '15px'
                                                    color        = 'var(--theme-palette-primary-main)'
                                                    fontWeight   = '500'
                                                }
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                                New-UDSelect -Id "pain_location_$entryNum" -Label '🎯 Pain Location' -FullWidth -Value $pain.location -Option {
                                                    # Add options based on user preferences
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
                                                    New-UDSelectOption -Name "Other" -Value "other"
                                                }
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                                New-UDTextbox -Id "pain_level_$entryNum" -Label '📊 Level (0-10)' -Type number -Minimum 0.0 -Maximum 10.0 -FullWidth -Value $pain.severity
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 6 -Children {
                                                New-UDTextbox -Id "pain_note_$entryNum" -Label '📝 Note' -Type text -Placeholder 'Optional note' -FullWidth -Value $pain.note
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
                            }
                            else {
                                # Default single pain entry
                                New-PainEntryElement -EntryNumber 1 -ConfiguredLocations @()
                            }

                            New-UDElement -Id 'additional_pain_container' -Tag 'div'

                            New-UDContainer -Children {
                                New-UDButton -Text '➕ Add Another Pain Entry' -Color primary -Variant outlined -OnClick {
                                    if (-not $Session:PainEntryCounter) { $Session:PainEntryCounter = 2 }
                                    $entryCount = $Session:PainEntryCounter
                                    $Session:PainEntryCounter++

                                    Show-UDToast -Message "Adding Pain Entry #$entryCount" -Duration 2000

                                    Add-UDElement -ParentId 'additional_pain_container' -Content {
                                        $currentEntryCount = $entryCount
                                        New-PainEntryElement -EntryNumber $currentEntryCount -IncludeRemoveButton $true -ConfiguredLocations @()
                                    }
                                }
                            }

                            New-UDTypography -Text '💡 Track pain levels and locations for better health monitoring' -Variant caption -Style @{
                                marginTop = '15px'
                                color     = 'var(--theme-palette-text-secondary)'
                                fontStyle = 'italic'
                                textAlign = 'center'
                            }
                        } -Style @{ marginBottom = '20px' }
                    }
                }
                else {
                    Set-UDElement -Id 'pain_section' -Content { }
                }
            }
            New-UDElement -Id 'pain_section' -Tag 'div'

            # Vitals Section - Enhanced with prepopulation
            $vitalsInitialChecked = $IsEditMode -and $ExistingEntry.entry_types -contains 'vitals'
            New-UDCheckBox -Id 'add_vitals' -Label '🩺 Add Vital Signs' -Checked:$vitalsInitialChecked -OnChange {
                if ($EventData) {
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

                                    # Prepopulate vitals if editing
                                    $o2Value = if ($IsEditMode -and $ExistingEntry.data.vitals) { $ExistingEntry.data.vitals.oxygen_saturation } else { '' }
                                    $bpValue = if ($IsEditMode -and $ExistingEntry.data.vitals) { $ExistingEntry.data.vitals.blood_pressure } else { '' }

                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id 'o2' -Label '🫁 Oxygen Saturation (%)' -Type number -Placeholder '95-100' -FullWidth -Value $o2Value
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id 'bpr' -Label '❤️ Blood Pressure' -Type text -Placeholder '120/80' -FullWidth -Value $bpValue
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
                        } -Style @{ marginBottom = '20px' }
                    }
                }
                else {
                    Set-UDElement -Id 'vitals_section' -Content { }
                }
            }
            New-UDElement -Id 'vitals_section' -Tag 'div'

            # Notes and Sleep - prepopulated if editing
            $notesValue = if ($IsEditMode) { $ExistingEntry.notes } else { '' }
            $sleepValue = if ($IsEditMode -and $ExistingEntry.data.sleep) { $ExistingEntry.data.sleep.sleep_hours } else { '' }

            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTextbox -Id 'notes' -Label '📝 Additional Notes' -Type text -Placeholder 'Any additional information' -FullWidth -Value $notesValue
                }
            }

            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTextbox -Id 'sleep' -Label '😴 Sleep Duration' -Type text -Placeholder 'e.g., 7.5 hours, 8:30, 6h 45m' -FullWidth -Value $sleepValue
                }
            }

            # Mood Section - Enhanced with prepopulation
            $moodValue = if ($IsEditMode -and $ExistingEntry.data.mood) { $ExistingEntry.data.mood.level } else { '' }
            $moodNoteValue = if ($IsEditMode -and $ExistingEntry.data.mood) { $ExistingEntry.data.mood.note } else { '' }

            New-UDCard -Title '😊 Mood Tracking' -Content {
                New-UDPaper -Children {
                    New-UDStack -Direction Column -Children {
                        New-UDTypography -Text 'How are you feeling?' -Variant subtitle2 -Style @{
                            marginBottom = '20px'
                            color        = 'var(--theme-palette-primary-main)'
                            fontWeight   = '500'
                            textAlign    = 'center'
                        }

                        New-UDTextbox -Id 'mood' -Type 'text' -Value $moodValue -Style @{ display = 'none' }

                        New-UDStack -Direction Row -JustifyContent center -Spacing 2 -Children {
                            # Mood buttons with prepopulation
                            @(1, 2, 3, 4, 5) | ForEach-Object {
                                $moodLevel = $_
                                $emoji = switch ($_) {
                                    1 { '😞' }
                                    2 { '🙁' }
                                    3 { '😐' }
                                    4 { '🙂' }
                                    5 { '😃' }
                                }
                                $label = switch ($_) {
                                    1 { 'awful' }
                                    2 { 'bad' }
                                    3 { 'meh' }
                                    4 { 'good' }
                                    5 { 'rad' }
                                }

                                $isSelected = $IsEditMode -and $moodValue -eq $moodLevel
                                $buttonColor = if ($isSelected) { 'primary' } else { 'default' }
                                $buttonVariant = if ($isSelected) { 'contained' } else { 'outlined' }

                                New-UDButton -Id "mood_$moodLevel" -Text $emoji -Variant $buttonVariant -Color $buttonColor -Size large -OnClick {
                                    $Session:SelectedMood = $moodLevel
                                    Set-UDElement -Id 'mood_display' -Content {
                                        New-UDTypography -Text "Feeling: $label $emoji" -Variant body1 -Style @{
                                            color      = 'var(--theme-palette-success-main)'
                                            fontWeight = 'bold'
                                            textAlign  = 'center'
                                        }
                                    }
                                    Set-MoodButtonState -SelectedMood $moodLevel
                                } -Style @{ fontSize = '2rem'; minWidth = '60px'; minHeight = '60px' }
                                New-UDTypography -Text $label -Variant caption -Style @{ textAlign = 'center'; marginTop = '5px' }
                            }
                        }

                        # Display selected mood
                        New-UDElement -Id 'mood_display' -Tag 'div' -Content {
                            if ($IsEditMode -and $moodValue) {
                                $moodText = switch ($moodValue) {
                                    1 { "Feeling: Awful 😞" }
                                    2 { "Feeling: Bad 🙁" }
                                    3 { "Feeling: Meh 😐" }
                                    4 { "Feeling: Good 🙂" }
                                    5 { "Feeling: Rad! 😃" }
                                    default { "Select your mood above" }
                                }
                                New-UDTypography -Text $moodText -Variant body1 -Style @{
                                    textAlign  = 'center'
                                    color      = 'var(--theme-palette-success-main)'
                                    fontWeight = 'bold'
                                    marginTop  = '15px'
                                }
                            }
                            else {
                                New-UDTypography -Text 'Select your mood above' -Variant body2 -Style @{
                                    textAlign = 'center'
                                    color     = 'var(--theme-palette-text-secondary)'
                                    marginTop = '15px'
                                }
                            }
                        }

                        New-UDTextbox -Id 'mood_note' -Label '💭 Mood Note (Optional)' -Type text -Placeholder 'How are you feeling?' -FullWidth -Multiline -Rows 2 -Value $moodNoteValue
                    }
                }

                New-UDTypography -Text '💡 Track your daily mood to identify patterns and trends' -Variant caption -Style @{
                    marginTop = '15px'
                    color     = 'var(--theme-palette-text-secondary)'
                    fontStyle = 'italic'
                    textAlign = 'center'
                }
            } -Style @{
                padding         = '20px'
                margin          = '10px 0'
                backgroundColor = 'var(--theme-palette-background-paper)'
                borderLeft      = '4px solid var(--theme-palette-warning-main)'
                borderRadius    = '8px'
                border          = '1px solid var(--theme-palette-divider)'
            }

            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDUpload -Id 'ImageFile' -Text 'Select Image to Upload' -Accept 'image/*'
                }
            }

        } -OnSubmit {
            # Enhanced form submission to handle both create and edit modes
            Import-Module -Name fusion -Force
            $FormEvent = $EventData[0]
            $FormEvent.timestamp = [datetime]::Parse($FormEvent.timestamp).ToString('HHmm')
            $FormEvent.date = [datetime]::Parse($FormEvent.date).ToString('MMdd')
            $FormEvent.mood = $Session:SelectedMood

            Write-Information "Form input (Edit Mode: $IsEditMode)"
            Write-Information ($FormEvent | ConvertTo-Json -Depth 99)

            if ($IsEditMode) {
                # Update existing entry
                try {
                    # Convert form data to v2 format
                    $UpdatedEntry = ConvertTo-EntriesFormat -Entry ($FormEvent | ConvertTo-Json -Depth 99 | ConvertFrom-Json) -UserEmail $User

                    # Preserve the original entry_id
                    $UpdatedEntry.entry_id = $ExistingEntry.entry_id

                    Write-Information "Updated entry converted"
                    Write-Information ($UpdatedEntry | ConvertTo-Json -Depth 99)

                    # Load all entries
                    $AllEntries = Get-Content $UserData.EntriesPath -Raw | ConvertFrom-Json

                    # Find and replace the existing entry
                    $entryIndex = $AllEntries | ForEach-Object { $i = 0 } { if ($_.entry_id -eq $ExistingEntry.entry_id) { $i }; $i++ }

                    if ($entryIndex -ne $null) {
                        $AllEntries[$entryIndex] = $UpdatedEntry

                        # Save back to file
                        $AllEntries | ConvertTo-Json -Depth 10 | Set-Content -Path $UserData.EntriesPath -Encoding UTF8

                        Write-Information 'Successfully updated existing entry'
                        Show-UDToast -Message 'Entry updated successfully!' -MessageColor Green -Duration 3000
                    }
                    else {
                        throw "Entry not found for update"
                    }
                }
                catch {
                    Write-Error "Error updating entry: $($_.Exception.Message)"
                    Show-UDToast -Message "Error updating entry: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                }
            }
            else {
                # Create new entry (existing logic)
                $Entry = ConvertTo-EntriesFormat -Entry ($FormEvent | ConvertTo-Json -Depth 99 | ConvertFrom-Json) -UserEmail $User
                Write-Information "New entry converted"
                Write-Information ($Entry | ConvertTo-Json -Depth 99)

                try {
                    $saveResult = Save-ConvertedEntry -ConvertedEntry $Entry -EntriesPath $UserData.EntriesPath
                    if ($saveResult) {
                        Write-Information 'Successfully saved new entry to entries.json'
                        Show-UDToast -Message 'Entry saved successfully!' -MessageColor Green -Duration 3000
                    }
                    else {
                        Write-Warning 'Failed to save entry - function returned false'
                        Show-UDToast -Message 'Failed to save entry' -MessageColor Red -Duration 5000
                    }
                }
                catch {
                    Write-Error "Error saving entry: $($_.Exception.Message)"
                    Show-UDToast -Message "Error saving entry: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                }
            }

            # Handle image upload (same for both modes)
            if ($EventData.ImageFile) {
                $imageFile = $EventData.ImageFile
                $imageFolderPath = if ($env:FUSION_DATA_PATH) {
                    Join-Path $env:FUSION_DATA_PATH 'img'
                }
                else {
                    '/home/data/fusion-data/img'
                }
                $imageExt = $imageFile.Name.Split('.')[-1]
                $imageFileName = "$($EventData.date).$imageExt"
                $imagePath = Join-Path $imageFolderPath $imageFileName

                try {
                    if (-not (Test-Path $imageFolderPath)) {
                        New-Item -ItemType Directory -Path $imageFolderPath -Force
                    }
                    Copy-Item $EventData.ImageFile.FileName $imagePath
                    Write-Information "Image saved to: $imagePath"
                    Show-UDToast -Message 'Image uploaded successfully!' -MessageColor Green -Duration 3000
                }
                catch {
                    Write-Error "Error saving image: $($_.Exception.Message)"
                    Show-UDToast -Message "Error uploading image: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                }
            }

            # Update cache (same for both modes)
            try {
                Import-Module -Name GetFusion -Force
                if (Test-Path $UserData.EntriesPath) {
                    try {
                        $Entries = Get-EntriesData -entriesPath $UserData.EntriesPath
                        Set-PSUCache -Key 'entriesData' -Value $Entries -AbsoluteExpiration (Get-Date).AddDays(1)
                        Write-Information 'Cache updated with entries data'
                    }
                    catch {
                        Write-Warning "Error updating cache: $($_.Exception.Message)"
                        Remove-PSUCache -Key 'entriesData'
                    }
                }
            }
            catch {
                Write-Error "Error updating cache: $($_.Exception.Message)"
                Show-UDToast -Message "Warning: Cache update failed, but entry was saved" -MessageColor Orange -Duration 3000
            }
        }
    }
}

New-UDApp -Title 'Health Entry Form' -Pages $Pages