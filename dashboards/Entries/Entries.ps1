New-UDApp -Content {
    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text "🏥 Health Recovery Entry Form" -Variant h4 -Style @{
                    textAlign    = "center"
                    marginBottom = "5px"
                    color        = "#1976d2"
                    fontWeight   = "bold"
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text "Track your daily health metrics and recovery progress" -Variant subtitle1 -Style @{
                    textAlign    = "center"
                    marginBottom = "20px"
                    marginTop    = "8px"
                    color        = "#666"
                    fontStyle    = "italic"
                }
            }
        } -Style @{ padding = "20px"; marginBottom = "20px"; backgroundColor = "#f8f9fa" }
        New-UDForm -Children {
            New-UDCard -Title "📅 Date & Time" -Content {
                New-UDGrid -Container -Children {
                    $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time')
                    $currentDate = $MSTDate.ToString("yyyy-MM-dd")
                    $currentTime = $MSTDate.ToString("HH:mm")
                    
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTextbox -Id "date" -Label "📅 Date" -Type "date" -FullWidth -Value $currentDate -Style @{
                            marginBottom = "10px"
                        }
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDTextbox -Id "timestamp" -Label "🕐 Time" -Type "time" -FullWidth -Value $currentTime -Style @{
                            marginBottom = "10px"
                        }
                    }
                }
                New-UDTypography -Text "💡 Automatically set to current Mountain Time - adjust if needed" -Variant caption -Style @{
                    marginTop = "5px"
                    color     = "#666"
                    fontStyle = "italic"
                    textAlign = "center"
                }
            } -Style @{ marginBottom = "20px" }
            New-UDCard -Title "💊 Medications" -Content {
                # Toggle button for collapsing/expanding medications
                New-UDContainer -Children {
                    New-UDButton -Text "🔽 Show Medications" -Id "medications_toggle" -Color primary -Variant outlined -OnClick {
                        # Toggle the transition state
                        $currentState = Get-UDElement -Id "medications_transition"
                        $newState = -not $currentState.in
                        
                        Set-UDElement -Id "medications_transition" -Properties @{
                            in = $newState
                        }
                        
                        # Update button text based on state
                        if ($newState) {
                            Set-UDElement -Id "medications_toggle" -Properties @{
                                text = "� Hide Medications"
                            }
                        } else {
                            Set-UDElement -Id "medications_toggle" -Properties @{
                                text = "🔽 Show Medications"
                            }
                        }
                    } -Style @{
                        marginBottom = "15px"
                        width = "100%"
                    }
                }
                
                # Collapsible medications content
                New-UDTransition -Id "medications_transition" -Content {
                    New-UDGrid -Container -Children {
                        try {
                            $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/medications_lookup.json" | ConvertFrom-Json -AsHashtable
                            $Dosages = $MedData['Medications']
                            
                            # Create visual cards for each medication type
                            foreach ($medType in $Dosages.Keys | Sort-Object) {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -MediumSize 4 -Children {
                                    New-UDPaper -Children {
                                        New-UDTypography -Text "💊 $($medType.ToUpper())" -Variant subtitle1 -Style @{
                                            fontWeight   = "bold"
                                            marginBottom = "10px"
                                            color        = "#1976d2"
                                            textAlign    = "center"
                                        }
                                        
                                        # Create checkboxes for each dosage
                                        foreach ($dosage in $Dosages[$medType]) {
                                            New-UDCheckbox -Id "med_$($medType)_$($dosage -replace '\W', '_')" -Label $dosage
                                        }
                                    } -Style @{
                                        padding         = "15px"
                                        margin          = "5px"
                                        backgroundColor = "#fafafa"
                                        borderLeft      = "4px solid #1976d2"
                                        borderRadius    = "8px"
                                        minHeight       = "120px"
                                    }
                                }
                            }
                        }
                        catch {
                            Write-Error "Failed to get or parse medication data: $_"
                            New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                New-UDAlert -Severity error -Text "Unable to load medication options. Please check the medications lookup file."
                            }
                        }
                    }
                    
                    New-UDTypography -Text "💡 Select all, if any, medications taken at the time of entry" -Variant caption -Style @{
                        marginTop = "15px"
                        color     = "#666"
                        fontStyle = "italic"
                        textAlign = "center"
                    }
                } -In:$false -Collapse -Timeout 500
            } -Style @{ marginBottom = "20px" }
            New-UDCheckBox -Id "add_activity" -Label "🏃‍♂️ Add Activity Entry" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show activities entry section
                    Set-UDElement -Id "activities_section" -Content {
                        New-UDCard -Title "🏃‍♂️ Physical Activities" -Content {
                            # Initial activity entry in its own Paper
                            New-UDPaper -Children {
                                New-UDGrid -Container -Children {
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        New-UDTypography -Text "Activity #1" -Variant subtitle2 -Style @{
                                            marginBottom = "15px"
                                            color        = "#1976d2"
                                            fontWeight   = "500"
                                        }
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                                        New-UDTextBox -Id "activities_type_1" -Label "🏃‍♂️ Activity Type" -Type text -Placeholder "Walking, Running, Swimming, etc." -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Children {
                                        New-UDTextbox -Id "activities_length_1" -Label "⏱️ Duration (min)" -Type number -Placeholder "20" -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Children {
                                        New-UDTextbox -Id "activities_note_1" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth
                                    }
                                }
                            } -Style @{
                                padding         = "15px"
                                margin          = "10px 0"
                                backgroundColor = "#f8f9fa"
                                borderLeft      = "4px solid #28a745"
                                borderRadius    = "8px"
                            }
                            
                            # Container for additional activities
                            New-UDElement -Id "additional_activities_container" -Tag "div"
                            
                            # Add More Button - Separate container
                            New-UDContainer -Children {
                                New-UDButton -Text "➕ Add Another Activity" -Color primary -Variant outlined -OnClick {
                                    # Generate unique ID for new activity
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    # Use Show-UDToast to debug
                                    Show-UDToast -Message "Adding Activity #$entryCount" -Duration 2000
                                    
                                    # Add the new activity using Add-UDElement with proper syntax
                                    Add-UDElement -ParentId "additional_activities_container" -Content {
                                        $currentEntryCount = $entryCount  # Capture the variable in local scope
                                        New-UDPaper -Id "activities_entry_$currentEntryCount" -Children {
                                            New-UDGrid -Container -Children {
                                                New-UDGrid -Item -ExtraSmallSize 10 -Children {
                                                    New-UDTypography -Text "Activity #$currentEntryCount" -Variant subtitle2 -Style @{
                                                        marginBottom = "15px"
                                                        color        = "#1976d2"
                                                        fontWeight   = "500"
                                                    }
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 2 -Children {
                                                    New-UDButton -Text "🗑️" -Color secondary -Size small -OnClick {
                                                        # Remove this specific activity Paper using Clear-UDElement
                                                        try {
                                                            Show-UDToast -Message "Removing Activity #$currentEntryCount" -Duration 2000
                                                            # Clear the content of this specific activity entry
                                                            Clear-UDElement -Id "activities_entry_$currentEntryCount"
                                                        }
                                                        catch {
                                                            Show-UDToast -Message "Error removing activity: $($_.Exception.Message)" -Duration 3000 -BackgroundColor red
                                                        }
                                                    } -Id "remove_btn_$currentEntryCount"
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                                                    New-UDTextBox -Id "activities_type_$currentEntryCount" -Label "🏃‍♂️ Activity Type" -Type text -Placeholder "Walking, Running, Swimming, etc." -FullWidth
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Children {
                                                    New-UDTextbox -Id "activities_length_$currentEntryCount" -Label "⏱️ Duration (min)" -Type number -Placeholder "20" -FullWidth
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Children {
                                                    New-UDTextbox -Id "activities_note_$currentEntryCount" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth
                                                }
                                            }
                                        } -Style @{
                                            padding         = "15px"
                                            margin          = "10px 0"
                                            backgroundColor = "#f8f9fa"
                                            borderLeft      = "4px solid #28a745"
                                            borderRadius    = "8px"
                                        }
                                    }
                                }
                            }
                            
                            New-UDTypography -Text "💡 Track your physical activities and exercise duration" -Variant caption -Style @{
                                marginTop = "15px"
                                color     = "#666"
                                fontStyle = "italic"
                                textAlign = "center"
                            }
                        } -Style @{
                            marginBottom = "20px"
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide activities section
                    Set-UDElement -Id "activities_section" -Content { }
                }
            }
            New-UDElement -Id "activities_section" -Tag "div"
            New-UDCheckbox -Id "add_pain" -Label "🩹 Add Pain Entry" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show pain entry section
                    Set-UDElement -Id "pain_section" -Content {
                        New-UDCard -Title "🩹 Pain Tracking" -Content {
                            # Initial pain entry in its own Paper
                            New-UDPaper -Children {
                                New-UDGrid -Container -Children {
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        New-UDTypography -Text "Pain Entry #1" -Variant subtitle2 -Style @{
                                            marginBottom = "15px"
                                            color        = "#1976d2"
                                            fontWeight   = "500"
                                        }
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                        New-UDSelect -Id "pain_location_1" -Label "🎯 Pain Location" -FullWidth -Option {
                                            New-UDSelectOption -Name "Back" -Value "back"
                                            New-UDSelectOption -Name "Right Glute" -Value "right_glute"
                                            New-UDSelectOption -Name "Left Glute" -Value "left_glute"
                                            New-UDSelectOption -Name "Glutes" -Value "glutes"
                                            New-UDSelectOption -Name "Right Hip" -Value "righthip"
                                            New-UDSelectOption -Name "Left Hip" -Value "lhip"
                                            New-UDSelectOption -Name "Hips" -Value "hips"
                                            New-UDSelectOption -Name "Right Quad" -Value "rquad"
                                            New-UDSelectOption -Name "Left Quad" -Value "lquad"
                                            New-UDSelectOption -Name "Quads" -Value "quads"
                                        }
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                        New-UDTextbox -Id "pain_level_1" -Label "📊 Level (0-10)" -Type number -Placeholder "5" -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 6 -Children {
                                        New-UDTextbox -Id "pain_note_1" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth
                                    }
                                }
                            } -Style @{
                                padding         = "15px"
                                margin          = "10px 0"
                                backgroundColor = "#fff5f5"
                                borderLeft      = "4px solid #dc3545"
                                borderRadius    = "8px"
                            }
                            
                            # Container for additional pain entries
                            New-UDElement -Id "additional_pain_container" -Tag "div"
                            
                            # Add More Button - Separate container
                            New-UDContainer -Children {
                                New-UDButton -Text "➕ Add Another Pain Entry" -Color primary -Variant outlined -OnClick {
                                    # Generate unique ID for new pain entry
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    # Use Show-UDToast to debug
                                    Show-UDToast -Message "Adding Pain Entry #$entryCount" -Duration 2000
                                    
                                    # Add the new pain entry using Add-UDElement with proper syntax
                                    Add-UDElement -ParentId "additional_pain_container" -Content {
                                        $currentEntryCount = $entryCount  # Capture the variable in local scope
                                        New-UDPaper -Id "pain_entry_$currentEntryCount" -Children {
                                            New-UDGrid -Container -Children {
                                                New-UDGrid -Item -ExtraSmallSize 10 -Children {
                                                    New-UDTypography -Text "Pain Entry #$currentEntryCount" -Variant subtitle2 -Style @{
                                                        marginBottom = "15px"
                                                        color        = "#1976d2"
                                                        fontWeight   = "500"
                                                    }
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 2 -Children {
                                                    New-UDButton -Text "🗑️" -Color secondary -Size small -OnClick {
                                                        # Remove this specific pain Paper using Clear-UDElement
                                                        try {
                                                            Show-UDToast -Message "Removing Pain Entry #$currentEntryCount" -Duration 2000
                                                            # Clear the content of this specific pain entry
                                                            Clear-UDElement -Id "pain_entry_$currentEntryCount"
                                                        }
                                                        catch {
                                                            Show-UDToast -Message "Error removing pain entry: $($_.Exception.Message)" -Duration 3000 -BackgroundColor red
                                                        }
                                                    } -Id "remove_pain_btn_$currentEntryCount"
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                                    New-UDSelect -Id "pain_location_$currentEntryCount" -Label "🎯 Pain Location" -FullWidth -Option {
                                                        New-UDSelectOption -Name "Back" -Value "back"
                                                        New-UDSelectOption -Name "Right Glute" -Value "right_glute"
                                                        New-UDSelectOption -Name "Left Glute" -Value "left_glute"
                                                        New-UDSelectOption -Name "Glutes" -Value "glutes"
                                                        New-UDSelectOption -Name "Right Hip" -Value "righthip"
                                                        New-UDSelectOption -Name "Left Hip" -Value "lhip"
                                                        New-UDSelectOption -Name "Hips" -Value "hips"
                                                        New-UDSelectOption -Name "Right Quad" -Value "rquad"
                                                        New-UDSelectOption -Name "Left Quad" -Value "lquad"
                                                        New-UDSelectOption -Name "Quads" -Value "quads"
                                                    }
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                                    New-UDTextbox -Id "pain_level_$currentEntryCount" -Label "📊 Level (0-10)" -Type number -Placeholder "5" -FullWidth
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 6 -Children {
                                                    New-UDTextbox -Id "pain_note_$currentEntryCount" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth
                                                }
                                            }
                                        } -Style @{
                                            padding         = "15px"
                                            margin          = "10px 0"
                                            backgroundColor = "#fff5f5"
                                            borderLeft      = "4px solid #dc3545"
                                            borderRadius    = "8px"
                                        }
                                    }
                                }
                            }
                            
                            New-UDTypography -Text "💡 Track pain levels and locations for better health monitoring" -Variant caption -Style @{
                                marginTop = "15px"
                                color     = "#666"
                                fontStyle = "italic"
                                textAlign = "center"
                            }
                        } -Style @{
                            marginBottom = "20px"
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide pain section
                    Set-UDElement -Id "pain_section" -Content { }
                }
            }
            New-UDElement -Id "pain_section" -Tag "div"
            New-UDCheckBox -Id "add_vitals" -Label "🩺 Add Vital Signs" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show vitals entry section
                    Set-UDElement -Id "vitals_section" -Content {
                        New-UDCard -Title "🩺 Vital Signs" -Content {
                            New-UDPaper -Children {
                                New-UDGrid -Container -Children {
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        New-UDTypography -Text "Vital Measurements" -Variant subtitle2 -Style @{
                                            marginBottom = "15px"
                                            color        = "#1976d2"
                                            fontWeight   = "500"
                                        }
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id "o2" -Label "🫁 Oxygen Saturation (%)" -Type number -Placeholder "95-100" -FullWidth
                                    }
                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                        New-UDTextbox -Id "bpr" -Label "❤️ Blood Pressure" -Type text -Placeholder "120/80" -FullWidth
                                    }
                                }
                            } -Style @{
                                padding         = "15px"
                                margin          = "10px 0"
                                backgroundColor = "#f0f8ff"
                                borderLeft      = "4px solid #007bff"
                                borderRadius    = "8px"
                            }
                            
                            New-UDTypography -Text "💡 Record oxygen saturation and blood pressure readings" -Variant caption -Style @{
                                marginTop = "15px"
                                color     = "#666"
                                fontStyle = "italic"
                                textAlign = "center"
                            }
                        } -Style @{
                            marginBottom = "20px"
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide vitals section
                    Set-UDElement -Id "vitals_section" -Content { }
                }
            }
            New-UDElement -Id "vitals_section" -Tag "div"
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTextbox -Id "notes" -Label "📝 Additional Notes" -Type text -Placeholder "Any additional information" -FullWidth
                }
            }
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDTextbox -Id "sleep" -Label "😴 Sleep Duration" -Type text -Placeholder "e.g., 7.5 hours, 8:30, 6h 45m" -FullWidth -Style @{
                        marginTop = "10px"
                    }
                }
            }
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDUpload -Id 'ImageFile' -Text 'Select Image to Upload' -Accept 'image/*'
                }
            }
        } -OnSubmit {
            try {
                Import-Module -Name fusion -Force
                $FormEvent = $EventData[0]
                
                # Comprehensive form validation before processing
                $validationErrors = @()
                
                # Validate required fields: Date and Time
                if ([string]::IsNullOrWhiteSpace($FormEvent.date)) {
                    $validationErrors += "❌ Date is required"
                } else {
                    try {
                        $parsedDate = [datetime]::Parse($FormEvent.date)
                        # Check if date is not in the future (allowing today)
                        if ($parsedDate.Date -gt (Get-Date).Date) {
                            $validationErrors += "❌ Date cannot be in the future"
                        }
                    } catch {
                        $validationErrors += "❌ Invalid date format"
                    }
                }
                
                if ([string]::IsNullOrWhiteSpace($FormEvent.timestamp)) {
                    $validationErrors += "❌ Time is required"
                } else {
                    try {
                        $parsedTime = [datetime]::Parse($FormEvent.timestamp)
                    } catch {
                        $validationErrors += "❌ Invalid time format"
                    }
                }
                
                # Check that at least one data category is provided
                $hasData = $false
                
                # Check for medications
                $medicationFields = $FormEvent.PSObject.Properties.Name | Where-Object { $_ -like "med_*" }
                $hasCheckedMedications = $false
                foreach ($field in $medicationFields) {
                    if ($FormEvent.$field -eq $true) {
                        $hasCheckedMedications = $true
                        break
                    }
                }
                if ($hasCheckedMedications) { $hasData = $true }
                
                # Check for activities
                if (-not [string]::IsNullOrWhiteSpace($FormEvent.activities_type_1)) {
                    $hasData = $true
                    
                    # Validate activity duration if provided
                    if (-not [string]::IsNullOrWhiteSpace($FormEvent.activities_length_1)) {
                        try {
                            $duration = [int]$FormEvent.activities_length_1
                            if ($duration -le 0 -or $duration -gt 1440) { # Max 24 hours in minutes
                                $validationErrors += "❌ Activity duration must be between 1 and 1440 minutes (24 hours)"
                            }
                        } catch {
                            $validationErrors += "❌ Activity duration must be a valid number"
                        }
                    }
                    
                    # Validate additional activities if they exist
                    $activityFields = $FormEvent.PSObject.Properties.Name | Where-Object { $_ -like "activities_type_*" -and $_ -ne "activities_type_1" }
                    foreach ($actField in $activityFields) {
                        if (-not [string]::IsNullOrWhiteSpace($FormEvent.$actField)) {
                            $entryNum = ($actField -split "_")[-1]
                            $lengthField = "activities_length_$entryNum"
                            if ($FormEvent.PSObject.Properties.Name -contains $lengthField -and -not [string]::IsNullOrWhiteSpace($FormEvent.$lengthField)) {
                                try {
                                    $duration = [int]$FormEvent.$lengthField
                                    if ($duration -le 0 -or $duration -gt 1440) {
                                        $validationErrors += "❌ Activity #$entryNum duration must be between 1 and 1440 minutes"
                                    }
                                } catch {
                                    $validationErrors += "❌ Activity #$entryNum duration must be a valid number"
                                }
                            }
                        }
                    }
                }
                
                # Check for pain entries
                if (-not [string]::IsNullOrWhiteSpace($FormEvent.pain_location_1) -or -not [string]::IsNullOrWhiteSpace($FormEvent.pain_level_1)) {
                    $hasData = $true
                    
                    # Validate pain level
                    if (-not [string]::IsNullOrWhiteSpace($FormEvent.pain_level_1)) {
                        try {
                            $painLevel = [int]$FormEvent.pain_level_1
                            if ($painLevel -lt 0 -or $painLevel -gt 10) {
                                $validationErrors += "❌ Pain level must be between 0 and 10"
                            }
                        } catch {
                            $validationErrors += "❌ Pain level must be a valid number"
                        }
                    }
                    
                    # If pain level is provided, location should also be provided
                    if (-not [string]::IsNullOrWhiteSpace($FormEvent.pain_level_1) -and [string]::IsNullOrWhiteSpace($FormEvent.pain_location_1)) {
                        $validationErrors += "❌ Pain location is required when pain level is specified"
                    }
                    
                    # Validate additional pain entries
                    $painLevelFields = $FormEvent.PSObject.Properties.Name | Where-Object { $_ -like "pain_level_*" -and $_ -ne "pain_level_1" }
                    foreach ($painField in $painLevelFields) {
                        if (-not [string]::IsNullOrWhiteSpace($FormEvent.$painField)) {
                            try {
                                $painLevel = [int]$FormEvent.$painField
                                if ($painLevel -lt 0 -or $painLevel -gt 10) {
                                    $entryNum = ($painField -split "_")[-1]
                                    $validationErrors += "❌ Pain level for entry #$entryNum must be between 0 and 10"
                                }
                            } catch {
                                $entryNum = ($painField -split "_")[-1]
                                $validationErrors += "❌ Pain level for entry #$entryNum must be a valid number"
                            }
                            
                            # Check corresponding location
                            $entryNum = ($painField -split "_")[-1]
                            $locationField = "pain_location_$entryNum"
                            if ($FormEvent.PSObject.Properties.Name -contains $locationField -and [string]::IsNullOrWhiteSpace($FormEvent.$locationField)) {
                                $validationErrors += "❌ Pain location is required for entry #$entryNum when pain level is specified"
                            }
                        }
                    }
                }
                
                # Check for vital signs
                if (-not [string]::IsNullOrWhiteSpace($FormEvent.o2) -or -not [string]::IsNullOrWhiteSpace($FormEvent.bpr)) {
                    $hasData = $true
                    
                    # Validate oxygen saturation
                    if (-not [string]::IsNullOrWhiteSpace($FormEvent.o2)) {
                        try {
                            $o2Level = [int]$FormEvent.o2
                            if ($o2Level -lt 70 -or $o2Level -gt 100) {
                                $validationErrors += "❌ Oxygen saturation must be between 70 and 100%"
                            }
                        } catch {
                            $validationErrors += "❌ Oxygen saturation must be a valid number"
                        }
                    }
                    
                    # Validate blood pressure format
                    if (-not [string]::IsNullOrWhiteSpace($FormEvent.bpr)) {
                        if ($FormEvent.bpr -notmatch '^\d{2,3}\/\d{2,3}$') {
                            $validationErrors += "❌ Blood pressure must be in format XXX/XX (e.g., 120/80)"
                        } else {
                            # Extract systolic and diastolic values for additional validation
                            $bpParts = $FormEvent.bpr -split '/'
                            $systolic = [int]$bpParts[0]
                            $diastolic = [int]$bpParts[1]
                            
                            if ($systolic -lt 60 -or $systolic -gt 250) {
                                $validationErrors += "❌ Systolic pressure must be between 60 and 250 mmHg"
                            }
                            if ($diastolic -lt 30 -or $diastolic -gt 150) {
                                $validationErrors += "❌ Diastolic pressure must be between 30 and 150 mmHg"
                            }
                            if ($systolic -le $diastolic) {
                                $validationErrors += "❌ Systolic pressure must be higher than diastolic pressure"
                            }
                        }
                    }
                }
                
                # Check if notes or sleep data is provided (these also count as valid data)
                if (-not [string]::IsNullOrWhiteSpace($FormEvent.notes) -or -not [string]::IsNullOrWhiteSpace($FormEvent.sleep)) {
                    $hasData = $true
                }
                
                # Require at least one type of health data
                if (-not $hasData) {
                    $validationErrors += "❌ Please provide at least one type of health data: medications, activities, pain levels, vital signs, notes, or sleep information"
                }
                
                # Validate sleep duration format if provided
                if (-not [string]::IsNullOrWhiteSpace($FormEvent.sleep)) {
                    # Accept various formats: "7.5 hours", "8:30", "6h 45m", "7", "7.5"
                    $sleepPattern = '^(\d+(\.\d+)?\s*(hours?|hrs?|h)?|\d{1,2}:\d{2}|\d+h\s*\d*m?)$'
                    if ($FormEvent.sleep -notmatch $sleepPattern) {
                        $validationErrors += "❌ Sleep duration format not recognized. Use formats like: '7.5 hours', '8:30', '6h 45m', or '7.5'"
                    }
                }
                
                # If there are validation errors, show them and stop processing
                if ($validationErrors.Count -gt 0) {
                    $errorMessage = "Please fix the following validation errors:`n`n" + ($validationErrors -join "`n")
                    Show-UDToast -Message $errorMessage -MessageColor Red -Duration 8000
                    return
                }
                
                # Convert date and time format
                try {
                    $FormEvent.timestamp = [datetime]::Parse($FormEvent.timestamp).ToString("HHmm")
                    $FormEvent.date = [datetime]::Parse($FormEvent.date).ToString("MMdd")
                } catch {
                    Show-UDToast -Message "❌ Invalid date or time format: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                    return
                }
                
                Write-Information ($FormEvent | ConvertTo-Json -Depth 99)
                
                # Convert the form event to entries format
                $entry = ConvertTo-EntriesFormat -Entry ( $FormEvent | ConvertTo-Json -Depth 99 | ConvertFrom-Json)
                
                if (-not $entry) {
                    Show-UDToast -Message "❌ Failed to convert form data to entry format" -MessageColor Red -Duration 5000
                    return
                }
                
                # Save the entry to the entries.json file
                $saveResult = Save-ConvertedEntry -ConvertedEntry $entry
                if ($saveResult) {
                    Write-Information "Successfully saved entry to entries.json"
                    Show-UDToast -Message "✅ Health entry saved successfully!" -MessageColor Green -Duration 4000
                } else {
                    Write-Warning "Failed to save entry - function returned false"
                    Show-UDToast -Message "❌ Failed to save entry - please check your data and try again" -MessageColor Red -Duration 5000
                    return
                }
            } catch {
                Write-Error "Error saving entry: $($_.Exception.Message)"
                Write-Error "Stack trace: $($_.ScriptStackTrace)"
                Show-UDToast -Message "❌ Error saving entry: $($_.Exception.Message)" -MessageColor Red -Duration 7000
                return
            }
            
            # Handle image upload if provided
            if ($EventData.ImageFile) {
                try {
                    $imageFile = $EventData.ImageFile
                    $imageFolderPath = "/home/data/fusion-data/img"
                    $imageExt = $imageFile.Name.Split('.')[-1]
                    $imageFileName = "$($EventData.date).$imageExt"
                    $imagePath = Join-Path $imageFolderPath $imageFileName
                    
                    # Ensure the image directory exists
                    if (-not (Test-Path $imageFolderPath)) {
                        New-Item -Path $imageFolderPath -ItemType Directory -Force
                    }
                    
                    # Save the uploaded image to the specified path
                    Copy-Item $EventData.ImageFile.FileName $imagePath
                    Write-Information "Image saved to: $imagePath"
                    Show-UDToast -Message "📷 Image uploaded successfully!" -MessageColor Green -Duration 3000
                } catch {
                    Write-Error "Error saving image: $($_.Exception.Message)"
                    Show-UDToast -Message "⚠️ Entry saved but image upload failed: $($_.Exception.Message)" -MessageColor Orange -Duration 5000
                }
            }
            
            # Update the cache with the new entry
            try {
                Import-Module -Name GetFusion -Force
                $EntriesPath = "/home/data/fusion-data/entries/entries.json"
                $Entries = Get-EntriesData -entriesPath $EntriesPath
                Set-PSUCache -Key "entriesData" -Value $Entries -AbsoluteExpiration (Get-Date).AddDays(1)
                Write-Information "Cache updated with new entries data"
                Show-UDToast -Message "📊 Data cache updated successfully" -MessageColor Blue -Duration 2000
            } catch {
                Write-Error "Error updating cache: $($_.Exception.Message)"
                Show-UDToast -Message "⚠️ Entry saved but cache update failed: $($_.Exception.Message)" -MessageColor Orange -Duration 5000
            }
        }
    }
}
