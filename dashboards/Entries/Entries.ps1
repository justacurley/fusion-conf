New-UDApp -Content {
    New-UDContainer -Content {
        New-UDPaper -Children {
            New-UDGrid -Container -Content {
                New-UDTypography -Text "🏥 Health Recovery Entry Form" -Variant h4 -Style @{
                    textAlign    = "center"
                    marginBottom = "5px"
                    color        = "#1976d2"
                    fontWeight   = "bold"
                }
            }
            New-UDGrid -Container -Content {
                New-UDTypography -Text "Track your daily health metrics and recovery progress" -Variant subtitle1 -Style @{
                    textAlign    = "center"
                    marginBottom = "20px"
                    marginTop    = "8px"
                    color        = "#666"
                    fontStyle    = "italic"
                }
            }
        } -Style @{ padding = "20px"; marginBottom = "20px"; backgroundColor = "#f8f9fa" }
        New-UDForm -Content {
            # Date and Time fields
            New-UDCard -Title "📅 Date & Time" -Content {
                New-UDGrid -Container -Content {
                    $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time')
                    $currentDate = $MSTDate.ToString("yyyy-MM-dd")
                    $currentTime = $MSTDate.ToString("HH:mm")
                    
                    New-UDGrid -Item -ExtraSmallSize 6 -Content {
                        New-UDTextbox -Id "date" -Label "📅 Date" -Type "date" -FullWidth -Value $currentDate -Style @{
                            marginBottom = "10px"
                        }
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Content {
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
            # Medicatins Sectin
            # Medications Section - Visual Cards
            New-UDCard -Title "💊 Medications" -Content {
                New-UDGrid -Container -Content {
                    try {
                        $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/medications_lookup.json" | ConvertFrom-Json -AsHashtable
                        $Dosages = $MedData['Medications']
                        
                        # Create visual cards for each medication type
                        foreach ($medType in $Dosages.Keys | Sort-Object) {
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -MediumSize 4 -Content {
                                New-UDPaper -Children {
                                    New-UDTypography -Text "💊 $($medType.ToUpper())" -Variant subtitle1 -Style @{
                                        fontWeight   = "bold"
                                        marginBottom = "10px"
                                        color        = "#1976d2"
                                        textAlign    = "center"
                                    }
                                    
                                    # Create checkboxes for each dosage
                                    foreach ($dosage in $Dosages[$medType]) {
                                        New-UDCheckbox -Id "med_$($medType)_$($dosage -replace '\W', '_')" -Label $dosage -Style @{
                                            display         = "block"
                                            marginBottom    = "8px"
                                            padding         = "5px 10px"
                                            backgroundColor = "#f8f9fa"
                                            borderRadius    = "15px"
                                            border          = "1px solid #dee2e6"
                                            fontSize        = "14px"
                                        }
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
                        New-UDGrid -Item -ExtraSmallSize 12 -Content {
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
            } -Style @{ marginBottom = "20px" }


            # Add a section for activities that is comprised of a text box on the left for text data, the "Activity", and an text box next to it for integer data, the "Duration (minutes)", and another for "Note"
            # Activities Section - Enhanced UI
            New-UDCheckbox -Id "add_activitiy" -Label "🏃‍♂️ Add Activity Entry" -Style @{
                marginBottom = "15px"
                fontSize     = "16px"
                fontWeight   = "500"
            } -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show activities entry section
                    Set-UDElement -Id "activities_section" -Content {
                        New-UDCard -Title "🏃‍♂️ Physical Activities" -Content {
                            New-UDGrid -Container -Content {
                                # Initial activity entry with better styling
                                New-UDPaper -Children {
                                    New-UDTypography -Text "Activity #1" -Variant subtitle2 -Style @{
                                        marginBottom = "15px"
                                        color        = "#1976d2"
                                        fontWeight   = "500"
                                    }
                                    
                                    New-UDGrid -Container -Content {
                                        New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Content {
                                            New-UDTextBox -Id "activities_type_1" -Label "🏃‍♂️ Activity Type" -Type text -Placeholder "Walking, Running, Swimming, etc." -FullWidth -Style @{
                                                marginBottom = "10px"
                                            }
                                        }
                                        New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Content {
                                            New-UDTextbox -Id "activities_length_1" -Label "⏱️ Duration (min)" -Type number -Placeholder "20" -FullWidth -Style @{
                                                marginBottom = "10px"
                                            }
                                        }
                                        New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Content {
                                            New-UDTextbox -Id "activities_note_1" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth -Style @{
                                                marginBottom = "10px"
                                            }
                                        }
                                    }
                                } -Style @{
                                    padding         = "15px"
                                    margin          = "10px 0"
                                    backgroundColor = "#f8f9fa"
                                    borderLeft      = "4px solid #28a745"
                                    borderRadius    = "8px"
                                }
                                
                                # Add More Button - Styled
                                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                    New-UDButton -Text "➕ Add Another Activity" -Color primary -Variant outlined -OnClick {
                                        # Add another activities entry row
                                        $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                        
                                        Add-UDElement -ParentId "activities_section" -Content {
                                            New-UDPaper -Children {
                                                New-UDGrid -Container -Content {
                                                    New-UDGrid -Item -ExtraSmallSize 10 -Content {
                                                        New-UDTypography -Text "Activity #$entryCount" -Variant subtitle2 -Style @{
                                                            marginBottom = "15px"
                                                            color        = "#1976d2"
                                                            fontWeight   = "500"
                                                        }
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                                        New-UDButton -Text "🗑️" -Color secondary -Size small -OnClick {
                                                            # Remove this entry
                                                            Remove-UDElement -Id "activities_entry_$entryCount"
                                                        } -Style @{
                                                            minWidth = "40px"
                                                            padding  = "5px"
                                                        }
                                                    }
                                                    
                                                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Content {
                                                        New-UDTextBox -Id "activities_type_$entryCount" -Label "🏃‍♂️ Activity Type" -Type text -Placeholder "Walking, Running, Swimming, etc." -FullWidth -Style @{
                                                            marginBottom = "10px"
                                                        }
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Content {
                                                        New-UDTextbox -Id "activities_length_$entryCount" -Label "⏱️ Duration (min)" -Type number -Placeholder "20" -FullWidth -Style @{
                                                            marginBottom = "10px"
                                                        }
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Content {
                                                        New-UDTextbox -Id "activities_note_$entryCount" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth -Style @{
                                                            marginBottom = "10px"
                                                        }
                                                    }
                                                }
                                            } -Id "activities_entry_$entryCount" -Style @{
                                                padding         = "15px"
                                                margin          = "10px 0"
                                                backgroundColor = "#f8f9fa"
                                                borderLeft      = "4px solid #28a745"
                                                borderRadius    = "8px"
                                            }
                                        }
                                    } -Style @{
                                        marginTop = "15px"
                                        width     = "100%"
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
            # Dynamic activities section container
            New-UDElement -Id "activities_section" -Tag "div"
            # New-UDCheckbox -Id "add_activitiy" -Label "Add activitiy Entry" -OnChange {
            #     if ($EventData) {
            #         # Checkbox is checked - show activities entry section
            #         Set-UDElement -Id "activities_section" -Content {
            #             New-UDGrid -Container -Content {
            #                 New-UDGrid -Item -ExtraSmallSize 12 -Content {
            #                     New-UDTypography -Text "activities Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px" }
            #                 }                            
            #                 # Initial activities entry
            #                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                     New-UDTextBox -Id "activities_type_1" -Label "activities type" -Type text -Placeholder "Walking, Running, etc."
            #                 }
            #                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                     New-UDTextbox -Id "activities_length_1" -Label "Duration (min)" -Type number -Placeholder "20"
            #                 }
            #                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                     New-UDTextbox -Id "activities_note_1" -Label "Note" -Type text -Placeholder "Optional note"
            #                 }
            #                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                     New-UDButton -Text "Add More" -OnClick {
            #                         # Add another activities entry row
            #                         $currentContent = Get-UDElement -Id "activities_section"
            #                         $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
            #                         Add-UDElement -ParentId "activities_section" -Content {
            #                             New-UDGrid -Container -Content {
            #                                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                                     New-UDTextBox -Id "activities_type_$entryCount" -Label "activities type"  -Type text -Placeholder "Walking, Running, etc."
            #                                 }
            #                                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                                     New-UDTextbox -Id "activities_length_$entryCount"  -Label "Duration (min)" -Type number -Placeholder "20"
            #                                 }
            #                                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                                     New-UDTextbox -Id "activities_note_$entryCount" -Label "Note" -Type text -Placeholder "Optional note"
            #                                 }
            #                                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                                     New-UDButton -Text "Remove" -Color secondary -OnClick {
            #                                         # Remove this entry
            #                                         Remove-UDElement -Id "activities_entry_$entryCount"
            #                                     } -Id "remove_$entryCount"
            #                                 }
            #                             } -Id "activities_entry_$entryCount"
            #                         }
            #                     }
            #                 }
            #             }
            #         }
            #     }
            #     else {
            #         # Checkbox is unchecked - hide activities section
            #         Set-UDElement -Id "activities_section" -Content { }
            #     }
            # }           
            # # Dynamic activities section container
            # New-UDElement -Id "activities_section" -Tag "div"
            #pain sectionbb
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
                                New-UDTextbox -Id "pain_level_1" -Label "Pain Level (0-10)" -Type text -Placeholder "5"
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
                                                New-UDTextbox -Id "pain_level_$entryCount" -Label "Pain Level (0-10)" -Type text -Placeholder "5"
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

            # Upload an image 
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 12 -Content {
                    New-UDUpload -Id 'ImageFile' -Text 'Select Image to Upload' -Accept 'image/*'
                }
            }
        } -OnSubmit {
            Import-Module -Name fusion -Force
            Write-Information "=== EVENTDATA DEBUG === breakpoint"
            Write-Information "EventData Type: $($EventData.GetType().FullName)"
            Write-Information "EventData Count: $($EventData.Count)"
            Write-Information "EventData Content: $($EventData | ConvertTo-Json -Depth 99)"
            $Event = $EventData[0]
            $Event.timestamp = [datetime]::Parse($Event.timestamp).ToString("HHmm")
            $Event.date = [datetime]::Parse($Event.date).ToString("MMdd")
            Write-Information "Converting JSON to entries.json format..."
            Write-Information ( $Event | ConvertTo-Json -Depth 99)
            $entry = ConvertTo-EntriesFormat -Entry ( $Event | ConvertTo-Json -Depth 99 | ConvertFrom-Json)
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
            if ($EventData.ImageFile) {
                $imageFile = $EventData.ImageFile
                $imageFolderPath = "/home/data/fusion-data/img"
                $imageExt = $imageFile.Name.Split('.')[-1]
                $imageFileName = "$($EventData.date).$imageExt"
                $imagePath = Join-Path $imageFolderPath $imageFileName
                try {
                    # Save the uploaded image to the specified path
                    Copy-Item $EventData.ImageFile.FileName $imagePath
                    Write-Information "Image saved to: $imagePath"
                    Show-UDToast -Message "Image uploaded successfully!" -MessageColor Green -Duration 3000
                }
                catch {
                    Write-Error "Error saving image: $($_.Exception.Message)"
                    Show-UDToast -Message "Error uploading image: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                }
            }
        }
    }
}
