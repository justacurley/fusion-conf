New-UDApp -Content {
    $VerbosePreference = 'Continue'
    $DebugPreference = 'Continue'
    New-UDContainer -Children {
        New-UDForm -Children {
            # Checkbox to enable/disable activities section
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
                            New-UDElement -Id "additional_activities_container" -Tag "div" -Attributes @{
                                style = "width: 100%;"
                            }
                            
                            # Add More Button - Separate container
                            New-UDContainer -Children {
                                New-UDButton -Text "➕ Add Another Activity" -Color primary -Variant outlined -OnClick {
                                    # Add another activity entry in its own Paper
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "additional_activities_container" -Content {
                                        New-UDPaper -Children {
                                            New-UDGrid -Container -Children {
                                                New-UDGrid -Item -ExtraSmallSize 10 -Children {
                                                    New-UDTypography -Text "Activity #$entryCount" -Variant subtitle2 -Style @{
                                                        marginBottom = "15px"
                                                        color        = "#1976d2"
                                                        fontWeight   = "500"
                                                    }
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 2 -Children {
                                                    New-UDButton -Text "🗑️" -Color secondary -Size small -OnClick {
                                                        # Remove this specific activity Paper
                                                        Remove-UDElement -Id "activities_entry_$entryCount"
                                                    }
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 5 -Children {
                                                    New-UDTextBox -Id "activities_type_$entryCount" -Label "🏃‍♂️ Activity Type" -Type text -Placeholder "Walking, Running, Swimming, etc." -FullWidth
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 3 -Children {
                                                    New-UDTextbox -Id "activities_length_$entryCount" -Label "⏱️ Duration (min)" -Type number -Placeholder "20" -FullWidth
                                                }
                                                New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 4 -Children {
                                                    New-UDTextbox -Id "activities_note_$entryCount" -Label "📝 Note" -Type text -Placeholder "Optional note" -FullWidth
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
            
            # Activities section container (appears below checkbox when enabled)
            New-UDElement -Id "activities_section" -Tag "div"

            # Dynamic activities section container
            New-UDElement -Id "working_activities_section" -Tag "div"
            # New-UDCheckBox -Id "working_add_activitiy" -Label "Add activitiy Entry" -OnChange {
            #     if ($EventData) {
            #         # Checkbox is checked - show activities entry section
            #         Set-UDElement -Id "working_activities_section" -Content {
            #             New-UDGrid -Container -Content {
            #                 New-UDGrid -Item -ExtraSmallSize 12 -Content {
            #                     New-UDTypography -Text "activities Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px" }
            #                 }
            #                 # Initial activities entry
            #                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                     New-UDTextbox -Id "working_activities_type_1" -Label "activities type" -Type text -Placeholder "Walking, Running, etc."
            #                 }
            #                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                     New-UDTextbox -Id "working_activities_length_1" -Label "Duration (min)" -Type number -Placeholder "20"
            #                 }
            #                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                     New-UDTextbox -Id "working_activities_note_1" -Label "Note" -Type text -Placeholder "Optional note"
            #                 }
            #                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                     New-UDButton -Text "Add More" -OnClick {
            #                         # Add another activities entry row
            #                         $currentContent = Get-UDElement -Id "working_activities_section"
            #                         $entryCount = (Get-Random -Minimum 100 -Maximum 999)

            #                         Add-UDElement -ParentId "working_activities_section" -Content {
            #                             New-UDGrid -Container -Content {
            #                                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                                     New-UDTextbox -Id "working_activities_type_$entryCount" -Label "activities type"  -Type text -Placeholder "Walking, Running, etc."
            #                                 }
            #                                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                                     New-UDTextbox -Id "working_activities_length_$entryCount"  -Label "Duration (min)" -Type number -Placeholder "20"
            #                                 }
            #                                 New-UDGrid -Item -ExtraSmallSize 4 -Content {
            #                                     New-UDTextbox -Id "working_activities_note_$entryCount" -Label "Note" -Type text -Placeholder "Optional note"
            #                                 }
            #                                 New-UDGrid -Item -ExtraSmallSize 2 -Content {
            #                                     New-UDButton -Text "Remove" -Color secondary -OnClick {
            #                                         # Remove this entry
            #                                         Remove-UDElement -Id "working_activities_entry_$entryCount"
            #                                     } -Id "remove_$entryCount"
            #                                 }
            #                             } -Id "working_activities_entry_$entryCount"
            #                         }
            #                     }
            #                 }
            #             }
            #         }
            #     }
            #     else {
            #         # Checkbox is unchecked - hide activities section
            #         Set-UDElement -Id "working_activities_section" -Content { }
            #     }
            # }



        } -OnSubmit {
            Import-Module -Name fusion -Force
            Write-Information "=== EVENTDATA DEBUG === breakpoint"
            Write-Information "EventData Type: $($EventData.GetType().FullName)"
            Write-Information "EventData Count: $($EventData.Count)"
            Write-Information "EventData Content: $($EventData | ConvertTo-Json -Depth 99)"

        }
    }
}

