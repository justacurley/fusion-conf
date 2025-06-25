New-UDApp -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Health Recovery Entry Form" -Variant h4 -Style @{marginBottom = "20px" }
        New-UDTypography -Text "Entry Date and Time" -Variant h6 -Style  @{marginTop = "20px"; marginBottom = "10px" }
        New-UDForm -Content {
            # Date and Time fields
            New-UDGrid -Container -Content {
                $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time') | ForEach-Object { $_.ToString("MMdd HHmm") }
                $MSTMMDD = $MSTDate.split(" ")[0]
                $MSTHHMM = $MSTDate.split(" ")[1]
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "date" -Label "Date (MMDD)" -Placeholder $MSTMMDD -FullWidth -Value $MSTMMDD
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "timestamp" -Label "Time (HHMM)" -Placeholder $MMSTHHMM -FullWidth -Value $MSTHHMM
                }
            }
            # Medicatins Sectin
            New-UDTypography -Text "Medications" -Variant h6 -Style @{marginTop = "20px" }
            New-UDSelect -Id "meds" -Option {
                try {
                    $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/schema.json" | ConvertFrom-Json -AsHashtable
                    $Dosages = $MedData['Medications']
                }
                catch {
                    Write-Error "Failed to get or parse data $_"
                }
                foreach ($key in $Dosages.keys) {
                    $Dosages[$key].foreach({
                            New-UDSelectOption -Name "$key - $_" -Value "$key - $_"
                        })
                }
            } -Multiple
            # Add a section for activities that is comprised of a text box on the left for text data, the "Activity", and an text box next to it for integer data, the "Duration (minutes)"
            New-UDCheckbox -Id "add_activitiy" -Label "Add activitiy Entry" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show activities entry section
                    Set-UDElement -Id "activities_section" -Content {
                        New-UDGrid -Container -Content {
                            New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                New-UDTypography -Text "activities Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px" }
                            }                            
                            # Initial activities entry
                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                New-UDTextBox -Id "activities_type_1" -Label "activities type" -Type text -Placeholder "Walking, Running, etc."
                            }
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextbox -Id "activities_length_1" -Label "activities length" -Type number -Placeholder "20"
                            }
                            New-UDGrid -Item -ExtraSmallSize 3 -Content {
                                New-UDButton -Text "Add More" -OnClick {
                                    # Add another activities entry row
                                    $currentContent = Get-UDElement -Id "activities_section"
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "activities_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                                New-UDTextBox -Id "activities_type_$entryCount" -Label "activities type"  -Type text -Placeholder "Walking, Running, etc."
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "activities_length_$entryCount"  -Label "activities length" -Type number -Placeholder "20"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 3 -Content {
                                                New-UDButton -Text "Remove" -Color secondary -OnClick {
                                                    # Remove this entry
                                                    Remove-UDElement -Id "activities_entry_$entryCount"
                                                } -Id "remove_$entryCount"
                                            }
                                        } -Id "activities_entry_$entryCount"
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide activities section
                    Set-UDElement -Id "activities_section" -Content { }
                }
            }           
            # Dynamic activities section container
            New-UDElement -Id "activities_section" -Tag "div"
            #pain section
            New-UDCheckbox -Id "add_pain" -Label "Add Pain Entry" -OnChange {
                if ($EventData) {
                    $SelectOptions = {
                        New-UDSelectOption -Name "Back" -Value "back"
                        New-UDSelectOption -Name "RQuad" -Value "rquads"
                        New-UDSelectOption -Name "LQuad" -Value "lquad"
                        New-UDSelectOption -Name "Glutes" -Value "glutes"
                        New-UDSelectOption -Name "Right Hip" -Value "righthip"
                        New-UDSelectOption -Name "LHip" -Value "lhip"
                    }
                    # Checkbox is checked - show pain entry section
                    Set-UDElement -Id "pain_section" -Content {
                        New-UDGrid -Container -Content {
                            New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                New-UDTypography -Text "Pain Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px" }
                            }                            
                            # Initial pain entry
                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                New-UDSelect -Id "pain_location_1" -Label "Pain Location" -Option $SelectOptions
                            }
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextbox -Id "pain_level_1" -Label "Pain Level (0-10)" -Type text -Placeholder "3-4"
                            }
                            New-UDGrid -Item -ExtraSmallSize 3 -Content {
                                New-UDButton -Text "Add More" -OnClick {
                                    # Add another pain entry row
                                    $currentContent = Get-UDElement -Id "pain_section"
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "pain_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                                New-UDSelect -Id "pain_location_$entryCount" -Label "Pain Location" -Option $SelectOptions
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "pain_level_$entryCount" -Label "Pain Level (0-10)" -Type text -Placeholder "0-10"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 3 -Content {
                                                New-UDButton -Text "Remove" -Color secondary -OnClick {
                                                    # Remove this entry
                                                    Remove-UDElement -Id "pain_entry_$entryCount"
                                                } -Id "remove_$entryCount"
                                            }
                                        } -Id "pain_entry_$entryCount"
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide pain section
                    Set-UDElement -Id "pain_section" -Content { }
                }
            }           
            # Dynamic pain section container
            New-UDElement -Id "pain_section" -Tag "div"
            # Making a new ud-grid for the o2 and bpr input sections
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "o2" -Label "Oxygen Saturation (%)" -Type number -Placeholder "95-100" -FullWidth
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "bpr" -Label "Blood Pressure (Systolic/Diastolic)" -Type text -Placeholder "120/80" -FullWidth
                }
            }

            # Add a text field for additional notes
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                    New-UDTextbox -Id "notes" -Label "Additional Notes" -Type text -Placeholder "Any additional information" -FullWidth
                }
            }
        } -OnSubmit {
            # Handle form submission logic here
            $entry = $EventData

            # Convert to entries.json format
            Write-Host "Converting PSCustomObject to entries.json format..."

            # Extract basic info
            $Date = $entry.date
            $Timestamp = $entry.timestamp

            # Build Medications object
            $Medications = @{}
            if ($entry.meds -and $entry.meds.Count -gt 0) {
                foreach ($med in $entry.meds) {
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
                        }
                        else {
                            $Medications[$medName] = $dosage
                        }
                    }
                }
            }

            # Build Pain object
            $Pain = @{}
            # Get all pain location/level pairs
            $painProperties = $entry.PSObject.Properties | Where-Object { $_.Name -like "pain_location_*" }
            foreach ($painProp in $painProperties) {
                $id = $painProp.Name -replace "pain_location_", ""
                $location = $painProp.Value
                $levelProp = "pain_level_$id"
                if ($entry.PSObject.Properties[$levelProp]) {
                    $level = $entry.PSObject.Properties[$levelProp].Value
                    if ($location -and $level) {
                        $Pain[$location] = $level
                    }
                }
            }

            # Build Activities object
            $Activities = @{}
            Write-Information "Looking for activity properties..."

            # Get all activity type/length pairs
            $activityProperties = $entry.PSObject.Properties | Where-Object { $_.Name -like "activities_type_*" }
            Write-Information "Found $($activityProperties.Count) activity type properties"

            foreach ($activityProp in $activityProperties) {
                $id = $activityProp.Name -replace "activities_type_", ""
                $activityType = $activityProp.Value
                $lengthProp = "activities_length_$id"
    
                Write-Information "Processing activity ID $id, Type: $activityType"
                Write-Information "Looking for $lengthProp"
    
                # Check for corresponding length property
                $duration = $null
                if ($entry.PSObject.Properties[$lengthProp]) {
                    $duration = [int]$entry.PSObject.Properties[$lengthProp].Value
                    Write-Information "Found length property with value: $duration"
                }
                else {
                    Write-Information "No matching duration property found for ID $id"
                    # List all available properties for debugging
                    $availableProps = $entry.PSObject.Properties | Where-Object { $_.Name -like "*$id*" } | Select-Object -ExpandProperty Name
                    Write-Information "Available properties with ID $id : $($availableProps -join ', ')"
                }
    
                if ($activityType -and $duration) {
                    # Convert activity type to lowercase key
                    $activityKey = $activityType.ToLower()
                    $Activities[$activityKey] = $duration
                    Write-Information "Added activity: $activityKey = $duration"
                }
                else {
                    Write-Information "Skipping activity - Type: '$activityType', Duration: '$duration'"
                }
            }
            # Create the entry structure
            $EntryStructure = @{
                "Medications" = $Medications
                "Pain"        = $Pain
                "Activities"  = $Activities
                "o2"          = if ($entry.o2) { $entry.o2 } else { "" }
                "bpr"         = if ($entry.bpr) { $entry.bpr } else { "" }
                "note"        = if ($entry.notes) { $entry.notes } else { "" }
            }

            # Create the full structure for entries.json
            $FullEntry = @{
                $Date = @{
                    $Timestamp = $EntryStructure
                }
            }

            # Output results
            Write-Information "`nFull Entry JSON (ready for entries.json):"
            Write-Information "=========================================="
            Write-Information ($FullEntry | ConvertTo-Json -Depth 5)

            Write-Information "`nJust the entry data (for manual insertion under $Date -> $Timestamp):"
            Write-Information "=================================================================="
            Write-Information ($EntryStructure | ConvertTo-Json -Depth 4)

        }
    }
}
