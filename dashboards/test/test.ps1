New-UDApp -Content {
    New-UDContainer -Content {
        New-UDForm -Content {



            # Add a section for activities that is comprised of a text box on the left for text data, the "Activity", and an text box next to it for integer data, the "Duration (minutes)", and another for "Note"
            # Activities Section - Enhanced UI
            New-UDCheckbox -Id "add_activity" -Label "🏃‍♂️ Add Activity Entry" -Style @{
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
                                                            Show-UDToast -Message (Get-UDElement -Id "activities_entry_$entryCount" | ConvertTo-Json) -MessageColor Red -Duration 10000    
                                                            # Remove-UDElement -Id "activities_entry_$entryCount"
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
            New-UDElement -Id "activities_section" -Tag "div"

            New-UDCheckbox -Id "working_add_activitiy" -Label "Add activitiy Entry" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show activities entry section
                    Set-UDElement -Id "working_activities_section" -Content {
                        New-UDGrid -Container -Content {
                            New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                New-UDTypography -Text "activities Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px" }
                            }                            
                            # Initial activities entry
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextBox -Id "working_activities_type_1" -Label "activities type" -Type text -Placeholder "Walking, Running, etc."
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDTextbox -Id "working_activities_length_1" -Label "Duration (min)" -Type number -Placeholder "20"
                            }
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextbox -Id "working_activities_note_1" -Label "Note" -Type text -Placeholder "Optional note"
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDButton -Text "Add More" -OnClick {
                                    # Add another activities entry row
                                    $currentContent = Get-UDElement -Id "working_activities_section"
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "activities_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextBox -Id "working_activities_type_$entryCount" -Label "activities type"  -Type text -Placeholder "Walking, Running, etc."
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                                New-UDTextbox -Id "working_activities_length_$entryCount"  -Label "Duration (min)" -Type number -Placeholder "20"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "working_activities_note_$entryCount" -Label "Note" -Type text -Placeholder "Optional note"
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                                New-UDButton -Text "Remove" -Color secondary -OnClick {
                                                    # Remove this entry
                                                    Remove-UDElement -Id "working_activities_entry_$entryCount"
                                                } -Id "remove_$entryCount"
                                            }
                                        } -Id "working_activities_entry_$entryCount"
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    # Checkbox is unchecked - hide activities section
                    Set-UDElement -Id "working_activities_section" -Content { }
                }
            }           
            # Dynamic activities section container
            New-UDElement -Id "working_activities_section" -Tag "div"
  

        } -OnSubmit {
            Import-Module -Name fusion -Force
            Write-Information "=== EVENTDATA DEBUG === breakpoint"
            Write-Information "EventData Type: $($EventData.GetType().FullName)"
            Write-Information "EventData Count: $($EventData.Count)"
            Write-Information "EventData Content: $($EventData | ConvertTo-Json -Depth 99)"
            
        }
    }
}

