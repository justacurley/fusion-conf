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
                    $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/medications_lookup.json" | ConvertFrom-Json -AsHashtable
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
            # Add a section for activities that is comprised of a text box on the left for text data, the "Activity", and an text box next to it for integer data, the "Duration (minutes)", and another for "Note"
            New-UDCheckbox -Id "add_activitiy" -Label "Add activitiy Entry" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show activities entry section
                    Set-UDElement -Id "activities_section" -Content {
                        New-UDGrid -Container -Content {
                            New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                New-UDTypography -Text "activities Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px" }
                            }                            
                            # Initial activities entry
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextBox -Id "activities_type_1" -Label "activities type" -Type text -Placeholder "Walking, Running, etc."
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDTextbox -Id "activities_length_1" -Label "Duration (min)" -Type number -Placeholder "20"
                            }
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextbox -Id "activities_note_1" -Label "Note" -Type text -Placeholder "Optional note"
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDButton -Text "Add More" -OnClick {
                                    # Add another activities entry row
                                    $currentContent = Get-UDElement -Id "activities_section"
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "activities_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextBox -Id "activities_type_$entryCount" -Label "activities type"  -Type text -Placeholder "Walking, Running, etc."
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                                New-UDTextbox -Id "activities_length_$entryCount"  -Label "Duration (min)" -Type number -Placeholder "20"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "activities_note_$entryCount" -Label "Note" -Type text -Placeholder "Optional note"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
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
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDSelect -Id "pain_location_1" -Label "Pain Location" -Option $SelectOptions
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDTextbox -Id "pain_level_1" -Label "Pain Level (0-10)" -Type number -Placeholder "5.5" -Step "0.1"
                            }
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextbox -Id "pain_note_1" -Label "Note" -Type text -Placeholder "Optional note"
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDButton -Text "Add More" -OnClick {
                                    # Add another pain entry row
                                    $currentContent = Get-UDElement -Id "pain_section"
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "pain_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDSelect -Id "pain_location_$entryCount" -Label "Pain Location" -Option $SelectOptions
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                                New-UDTextbox -Id "pain_level_$entryCount" -Label "Pain Level (0-10)" -Type number -Placeholder "5.5" -Step "0.1"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "pain_note_$entryCount" -Label "Note" -Type text -Placeholder "Optional note"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
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
            Import-Module -Name fusion -Force
            # Handle form submission logic here
            Write-Information ($EventData | ConvertTo-Json -Depth 99)
            Write-Information ($EventData.Gettype().FullName)
            Write-Host "Converting JSON to entries.json format..."
            $entry = ConvertTo-EntriesFormat -Entry ( $EventData | ConvertTo-Json -Depth 99 | ConvertFrom-Json)
            # Output results
            Write-Information "`nFull Entry JSON (ready for entries.json):"
            Write-Information "=========================================="
            Write-Information ($entry | ConvertTo-Json -Depth 99)
            # Save the entry to the entries.json file
            try {
                $saveResult = Save-ConvertedEntry -ConvertedEntry $entry
                if ($saveResult) {
                    Write-Information "Successfully saved entry to entries.json"
                    Show-UDToast -Message "Entry saved successfully!" -MessageColor Green -Duration 3000
                }
                else {
                    Write-Warning "Failed to save entry - function returned false"
                    Show-UDToast -Message "Failed to save entry" -MessageColor Red -Duration 5000
                }
            }
            catch {
                Write-Error "Error saving entry: $($_.Exception.Message)"
                Write-Error "Stack trace: $($_.ScriptStackTrace)"
                Show-UDToast -Message "Error saving entry: $($_.Exception.Message)" -MessageColor Red -Duration 5000
            }
        }
    }
}
