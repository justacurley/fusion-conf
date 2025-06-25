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
            #pain section
            New-UDCheckbox -Id "add_pain" -Label "Add Pain Entry" -OnChange {
                if ($EventData) {
                    Write-Debug "Pain Entry Checkbox is checked"
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

        } -OnSubmit {
            Write-Information "Date: $MSTMMDD, Time: $MSTHHMM"
            # Handle form submission logic here
            $painLocations = Get-UDElement -Id "pain_section" | Select-Object -ExpandProperty Content | Where-Object { $_.Id -like "pain_location_*" }
            $painLevels = Get-UDElement -Id "pain_section" | Select-Object -ExpandProperty Content | Where-Object { $_.Id -like "pain_level_*" }
            Write-Information $painEntries | ConvertTo-Json | Out-String
            Write-Information $painLevels | ConvertTo-Json | Out-String
            $painEntries = for ($i = 0; $i -lt $painLocations.Count; $i++) {
                $location = $painLocations[$i].Value
                $level = $painLevels[$i].Value
                if ($location -and $level) {
                    $painEntries += @{
                        Location = $location
                        Level    = $level
                    }
                }
            }            
            # Here you can save the painEntries to a database or file as needed
            Write-Information "Pain Entries: $($painEntries | ConvertTo-Json)"
        }
    }
}
