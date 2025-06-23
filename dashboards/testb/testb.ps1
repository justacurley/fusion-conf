New-UDApp -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Dynamic Pain Entry Form" -Variant h4 -Style @{marginBottom = "20px"}
        
        New-UDForm -Content {
            # Add Pain checkbox
            New-UDCheckbox -Id "add_pain" -Label "Add Pain Entry" -OnChange {
                if ($EventData) {
                    # Checkbox is checked - show pain entry section
                    Set-UDElement -Id "pain_section" -Content {
                        New-UDGrid -Container -Content {
                            New-UDGrid -Item -ExtraSmallSize 12 -Content {
                                New-UDTypography -Text "Pain Entries" -Variant h6 -Style @{marginTop = "10px"; marginBottom = "10px"}
                            }
                            
                            # Initial pain entry
                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                New-UDSelect -Id "pain_location_1" -Label "Pain Location" -Option @(
                                    New-UDSelectOption -Name "Back" -Value "back"
                                    New-UDSelectOption -Name "Legs" -Value "legs"
                                    New-UDSelectOption -Name "Quads" -Value "quads"
                                    New-UDSelectOption -Name "Glutes" -Value "glutes"
                                    New-UDSelectOption -Name "Right Hip" -Value "righthip"
                                    New-UDSelectOption -Name "Left Hip" -Value "lefthip"
                                    New-UDSelectOption -Name "Neck" -Value "neck"
                                    New-UDSelectOption -Name "Shoulders" -Value "shoulders"
                                    New-UDSelectOption -Name "Arms" -Value "arms"
                                    New-UDSelectOption -Name "Other" -Value "other"
                                )
                            }
                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                New-UDTextbox -Id "pain_level_1" -Label "Pain Level (0-10)" -Type number -Placeholder "0-10"
                            }
                            New-UDGrid -Item -ExtraSmallSize 3 -Content {
                                New-UDButton -Text "Add More" -OnClick {
                                    # Add another pain entry row
                                    $currentContent = Get-UDElement -Id "pain_section"
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    
                                    Add-UDElement -ParentId "pain_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                                New-UDSelect -Id "pain_location_$entryCount" -Label "Pain Location" -Option @(
                                                    New-UDSelectOption -Name "Back" -Value "back"
                                                    New-UDSelectOption -Name "Legs" -Value "legs"
                                                    New-UDSelectOption -Name "Quads" -Value "quads"
                                                    New-UDSelectOption -Name "Glutes" -Value "glutes"
                                                    New-UDSelectOption -Name "Right Hip" -Value "righthip"
                                                    New-UDSelectOption -Name "Left Hip" -Value "lefthip"
                                                    New-UDSelectOption -Name "Neck" -Value "neck"
                                                    New-UDSelectOption -Name "Shoulders" -Value "shoulders"
                                                    New-UDSelectOption -Name "Arms" -Value "arms"
                                                    New-UDSelectOption -Name "Other" -Value "other"
                                                )
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "pain_level_$entryCount" -Label "Pain Level (0-10)" -Type number -Placeholder "0-10"
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
                } else {
                    # Checkbox is unchecked - hide pain section
                    Set-UDElement -Id "pain_section" -Content { }
                }
            }
            
            # Dynamic pain section container
            New-UDElement -Id "pain_section" -Tag "div"
            
            # Submit button
            New-UDButton -Text "Submit Form" -OnClick {
                Show-UDToast -Message "Form submitted successfully!" -MessageColor Success
            } -Style @{marginTop = "20px"}
        } -OnSubmit {
            # Handle form submission logic here
            $painEntries = @()
            $painLocations = Get-UDElement -Id "pain_section" | Select-Object -ExpandProperty Content | Where-Object { $_.Id -like "pain_location_*" }
            $painLevels = Get-UDElement -Id "pain_section" | Select-Object -ExpandProperty Content | Where-Object { $_.Id -like "pain_level_*" }
            
            for ($i = 0; $i -lt $painLocations.Count; $i++) {
                $location = $painLocations[$i].Value
                $level = $painLevels[$i].Value
                if ($location -and $level) {
                    $painEntries += @{
                        Location = $location
                        Level = [int]$level
                    }
                }
            }
            
            # Here you can save the painEntries to a database or file as needed
            Write-Output "Pain Entries: $($painEntries | ConvertTo-Json)"
        }
    }
}


