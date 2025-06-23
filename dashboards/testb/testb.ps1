New-UDApp -Content { 
    
    New-UDContainer -Content {
        New-UDTypography -Text "Dynamic Pain Entry Form" -Variant h4 -Style @{marginBottom = "20px" }
        
        New-UDForm -Content {
            # Add Pain checkbox
            New-UDCheckbox -Id "add_pain" -Label "Add Pain Entry" -OnChange {
                Write-PSULog -Level Information -Message "Add Pain checkbox changed. EventData: $EventData"
                if ($EventData) {
                    Write-PSULog -Level Information -Message "Pain entry section being displayed"
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
                            }                            New-UDGrid -Item -ExtraSmallSize 3 -Content {                                New-UDButton -Text "Add More" -OnClick {
                                    Write-PSULog -Level Information -Message "Add More button clicked"
                                    # Add another pain entry row
                                    $entryCount = (Get-Random -Minimum 100 -Maximum 999)
                                    Write-PSULog -Level Information -Message "Creating new pain entry with ID: $entryCount"
                                    
                                    Add-UDElement -ParentId "pain_section" -Content {
                                        New-UDGrid -Container -Content {
                                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                                New-UDSelect -Id "pain_location_$entryCount" -Label "Pain Location" -Option $SelectOptions
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 4 -Content {
                                                New-UDTextbox -Id "pain_level_$entryCount" -Label "Pain Level (0-10)" -Type number -Placeholder "0-10"
                                            }                                            New-UDGrid -Item -ExtraSmallSize 3 -Content {
                                                New-UDButton -Text "Remove" -Color secondary -OnClick {
                                                    Write-PSULog -Level Information -Message "Remove button clicked for entry ID: $entryCount"
                                                    # Remove this entry
                                                    Remove-UDElement -Id "pain_entry_$entryCount"
                                                    Write-PSULog -Level Information -Message "Pain entry $entryCount removed successfully"
                                                } -Id "remove_$entryCount"
                                            }
                                        } -Id "pain_entry_$entryCount"
                                    }
                                    Write-PSULog -Level Information -Message "New pain entry $entryCount added successfully"
                                }
                            }
                        }
                    }                }
                else {
                    Write-PSULog -Level Information -Message "Pain entry section being hidden"
                    # Checkbox is unchecked - hide pain section
                    Set-UDElement -Id "pain_section" -Content { }
                    Write-PSULog -Level Information -Message "Pain entry section hidden successfully"
                }
            }
            
            # Dynamic pain section container
            New-UDElement -Id "pain_section" -Tag "div"
              # Submit button
            New-UDButton -Text "Submit Form" -OnClick {
                Write-PSULog -Level Information -Message "Submit Form button clicked"
                Show-UDToast -Message "Form submitted successfully!" -MessageColor Success
                Write-PSULog -Level Information -Message "Success toast message displayed"
            } -Style @{marginTop = "20px" }        } -OnSubmit {
            Write-PSULog -Level Information -Message "Form submission started"
            try {
                # Handle form submission logic here
                $painEntries = @()
                Write-PSULog -Level Information -Message "Collecting pain entries from form data"
                
                $painLocations = Get-UDElement -Id "pain_section" | Select-Object -ExpandProperty Content | Where-Object { $_.Id -like "pain_location_*" }
                $painLevels = Get-UDElement -Id "pain_section" | Select-Object -ExpandProperty Content | Where-Object { $_.Id -like "pain_level_*" }
                
                Write-PSULog -Level Information -Message "Found $($painLocations.Count) pain locations and $($painLevels.Count) pain levels"
                
                for ($i = 0; $i -lt $painLocations.Count; $i++) {
                    $location = $painLocations[$i].Value
                    $level = $painLevels[$i].Value
                    Write-PSULog -Level Debug -Message "Processing entry $i - Location: $location, Level: $level"
                    
                    if ($location -and $level) {
                        $painEntry = @{
                            Location = $location
                            Level    = [int]$level
                        }
                        $painEntries += $painEntry
                        Write-PSULog -Level Information -Message "Added pain entry: Location=$location, Level=$level"
                    } else {
                        Write-PSULog -Level Warning -Message "Skipping incomplete entry $i - Location: $location, Level: $level"
                    }
                }
                
                Write-PSULog -Level Information -Message "Total pain entries collected: $($painEntries.Count)"
                
                # Here you can save the painEntries to a database or file as needed
                $jsonOutput = $painEntries | ConvertTo-Json -Depth 2
                Write-PSULog -Level Information -Message "Pain entries JSON: $jsonOutput"
                Write-Output "Pain Entries: $jsonOutput"
                
                Write-PSULog -Level Information -Message "Form submission completed successfully"
                
            } catch {                Write-PSULog -Level Error -Message "Error during form submission: $($_.Exception.Message)"
                Write-PSULog -Level Error -Message "Stack trace: $($_.ScriptStackTrace)"
                throw
            }
        }
    }
}


