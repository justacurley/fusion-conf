New-UDApp -Content {
    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text "✏️ Update Health Entries" -Variant h4 -Style @{
                    textAlign    = "center"
                    marginBottom = "5px"
                    color        = "#1976d2"
                    fontWeight   = "bold"
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text "Select a date to view and edit all time entries for that day" -Variant subtitle1 -Style @{
                    textAlign    = "center"
                    marginBottom = "20px"
                    marginTop    = "8px"
                    color        = "#666"
                    fontStyle    = "italic"
                }
            }
        } -Style @{ padding = "20px"; marginBottom = "20px"; backgroundColor = "#f8f9fa" }

        # Date Selection Section
        New-UDCard -Title "📅 Select Date" -Content {
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                    # Current date in Mountain Time
                    $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time')
                    $currentDate = $MSTDate.ToString("yyyy-MM-dd")
                    
                    New-UDTextbox -Id "selectedDate" -Label "📅 Date" -Type "date" -FullWidth -Value $currentDate -OnChange {
                        # Load entries for selected date
                        $selectedDateValue = $EventData
                        if (-not [string]::IsNullOrWhiteSpace($selectedDateValue)) {
                            try {
                                # Parse the date and convert to MMDD format
                                $parsedDate = [datetime]::Parse($selectedDateValue)
                                $dateKey = $parsedDate.ToString("MMdd")
                                
                                # Import modules and load data
                                Import-Module -Name fusion -Force
                                
                                # Use the new cached entries function
                                $AllEntries = Get-CachedEntriesData
                                
                                if ($AllEntries.ContainsKey($dateKey)) {
                                    $dayEntries = $AllEntries[$dateKey]
                                    
                                    # Build the time entries display
                                    $timeEntriesContent = @()
                                    
                                    # Get all time entries (exclude non-time keys like "Sleep", "max_pain_level", "ScarImage")
                                    $timeKeys = $dayEntries.Keys | Where-Object { $_ -match '^\d{4}$' -or $_ -match '^\d{3}$' } | Sort-Object
                                    
                                    if ($timeKeys.Count -gt 0) {
                                        foreach ($timeKey in $timeKeys) {
                                            $timeEntry = $dayEntries[$timeKey]
                                            $timeEntryJson = $timeEntry | ConvertTo-Json -Depth 10 -Compress:$false
                                            
                                            # Format time for display
                                            $displayTime = if ($timeKey.Length -eq 3) { "0$timeKey" } else { $timeKey }
                                            $formattedTime = "$($displayTime.Substring(0,2)):$($displayTime.Substring(2,2))"
                                            
                                            $timeEntriesContent += New-UDPaper -Children {
                                                New-UDGrid -Container -Children {
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDTypography -Text "🕐 $formattedTime ($timeKey)" -Variant h6 -Style @{
                                                            marginBottom = "15px"
                                                            color        = "#1976d2"
                                                            fontWeight   = "600"
                                                        }
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDTextbox -Id "timeEntry_$timeKey" -Label "JSON Data" -Multiline -Rows 15 -FullWidth -Value $timeEntryJson -Style @{
                                                            fontFamily = "monospace"
                                                            fontSize   = "12px"
                                                        }
                                                    }
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDButton -Text "💾 Update $formattedTime Entry" -Color primary -FullWidth -OnClick {
                                                            try {
                                                                # Get the updated JSON data
                                                                $updatedJson = (Get-UDElement -Id "timeEntry_$timeKey").value
                                                                $updatedData = $updatedJson | ConvertFrom-Json
                                                                
                                                                # Import modules
                                                                Import-Module -Name fusion -Force
                                                                
                                                                # Use the new cached entries function
                                                                $AllEntries = Get-CachedEntriesData
                                                                
                                                                # Update the specific time entry
                                                                if (-not $AllEntries.ContainsKey($dateKey)) {
                                                                    $AllEntries[$dateKey] = @{}
                                                                }
                                                                $AllEntries[$dateKey][$timeKey] = $updatedData
                                                                
                                                                # Save back to file
                                                                $EntriesPath = Get-PSUVariable -Name "EntriesPath" -ValueOnly
                                                                $AllEntries | ConvertTo-Json -Depth 10 | Set-Content -Path $EntriesPath -Encoding UTF8
                                                                
                                                                Show-UDToast -Message "✅ Successfully updated $formattedTime entry for $($parsedDate.ToString('MM/dd'))" -MessageColor Green -Duration 4000
                                                                
                                                                # Update cache using the new function
                                                                try {
                                                                    $null = Get-CachedEntriesData -ForceReload
                                                                } catch {
                                                                    Write-Warning "Failed to update cache: $($_.Exception.Message)"
                                                                }
                                                            }
                                                            catch {
                                                                Show-UDToast -Message "❌ Error updating entry: $($_.Exception.Message)" -MessageColor Red -Duration 6000
                                                                Write-Error "Error updating time entry: $($_.Exception.Message)"
                                                            }
                                                        }
                                                    }
                                                }
                                            } -Style @{
                                                padding         = "20px"
                                                margin          = "10px 0"
                                                backgroundColor = "#f8f9fa"
                                                borderLeft      = "4px solid #007bff"
                                                borderRadius    = "8px"
                                            }
                                        }
                                        
                                        # Update the time entries container
                                        Set-UDElement -Id "timeEntriesContainer" -Content {
                                            $timeEntriesContent
                                        }
                                        
                                        # Show summary info
                                        $summaryInfo = @()
                                        if ($dayEntries.ContainsKey("Sleep")) {
                                            $summaryInfo += "😴 Sleep: $($dayEntries.Sleep)"
                                        }
                                        if ($dayEntries.ContainsKey("max_pain_level")) {
                                            $summaryInfo += "🩹 Max Pain: $($dayEntries.max_pain_level)"
                                        }
                                        if ($dayEntries.ContainsKey("ScarImage")) {
                                            $summaryInfo += "📷 Image: $($dayEntries.ScarImage)"
                                        }
                                        
                                        if ($summaryInfo.Count -gt 0) {
                                            Set-UDElement -Id "summaryContainer" -Content {
                                                New-UDAlert -Severity info -Text "📊 Day Summary: $($summaryInfo -join ' | ')"
                                            }
                                        } else {
                                            Set-UDElement -Id "summaryContainer" -Content { }
                                        }
                                        
                                        Show-UDToast -Message "📋 Loaded $($timeKeys.Count) time entries for $($parsedDate.ToString('MM/dd/yyyy'))" -MessageColor Blue -Duration 3000
                                    } else {
                                        Set-UDElement -Id "timeEntriesContainer" -Content {
                                            New-UDAlert -Severity warning -Text "No time entries found for $($parsedDate.ToString('MM/dd/yyyy')). This date exists but has no timed health data."
                                        }
                                        Set-UDElement -Id "summaryContainer" -Content { }
                                    }
                                } else {
                                    Set-UDElement -Id "timeEntriesContainer" -Content {
                                        New-UDAlert -Severity error -Text "No entries found for $($parsedDate.ToString('MM/dd/yyyy')). Please select a date that has existing health data."
                                    }
                                    Set-UDElement -Id "summaryContainer" -Content { }
                                }
                            }
                            catch {
                                Show-UDToast -Message "❌ Error loading entries: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                                Write-Error "Error loading entries for date: $($_.Exception.Message)"
                                Set-UDElement -Id "timeEntriesContainer" -Content {
                                    New-UDAlert -Severity error -Text "Error loading entries: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                    New-UDButton -Text "🔄 Refresh Data" -Color secondary -FullWidth -OnClick {
                        # Trigger the date change event to reload data
                        $currentSelectedDate = (Get-UDElement -Id "selectedDate").value
                        if (-not [string]::IsNullOrWhiteSpace($currentSelectedDate)) {
                            Invoke-UDJavaScript -JavaScript @"
                                document.getElementById('selectedDate').dispatchEvent(new Event('change'));
"@
                        }
                    }
                }
            }
            
            New-UDTypography -Text "💡 Select a date above to load all time entries for editing" -Variant caption -Style @{
                marginTop = "15px"
                color     = "#666"
                fontStyle = "italic"
                textAlign = "center"
            }
        } -Style @{ marginBottom = "20px" }

        # Summary Information Container
        New-UDElement -Id "summaryContainer" -Tag "div"

        # Time Entries Container
        New-UDElement -Id "timeEntriesContainer" -Tag "div" -Content {
            New-UDTypography -Text "👆 Please select a date above to view and edit time entries" -Variant body1 -Style @{
                textAlign = "center"
                color     = "#999"
                margin    = "40px 0"
                fontStyle = "italic"
            }
        }

        # Help Section
        New-UDCard -Title "ℹ️ Help & Tips" -Content {
            New-UDList -Children {
                New-UDListItem -Label "📝 Each time entry shows its JSON data which you can edit directly"
                New-UDListItem -Label "⚠️ Be careful with JSON syntax - invalid JSON will cause save errors"
                New-UDListItem -Label "🔄 Use the Refresh button if data seems outdated"
                New-UDListItem -Label "💾 Click 'Update Entry' button for each time slot you modify"
                New-UDListItem -Label "📊 Summary information (Sleep, Max Pain, Images) is shown at the top"
            }
        } -Style @{ marginTop = "30px"; backgroundColor = "#f0f8ff" }
    }
}