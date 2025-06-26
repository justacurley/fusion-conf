$Dashboard = New-UDDashboard -Title "Pain Level Analysis" -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Max Daily Pain Level Tracker" -Variant h4 -Align center
        
        New-UDDynamic -Content {
            
            $EntriesPath = "/home/data/fusion-data/entries/entries.json"
            try {
                $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
                New-UDAlert -Severity success -Text "Loaded data from: $EntriesPath"
            
                # Extract max_pain_level data for each date
                $painData = @()
                $activityData = @()
                $dates = $entries.PSObject.Properties.Name | Sort-Object
                
                foreach ($date in $dates) {
                    $dateEntry = $entries.$date
                    if ($dateEntry.PSObject.Properties['max_pain_level']) {
                        $maxPain = [double]$dateEntry.max_pain_level
                        
                        # Convert MMDD to readable date
                        $month = $date.Substring(0, 2)
                        $day = $date.Substring(2, 2)
                        $dateStr = "$month/$day"
                        
                        # Calculate total daily activity duration
                        $totalActivityDuration = 0
                        $activityTypes = @{}
                        
                        # Check all timestamps for this date
                        foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
                            if ($timestamp -match '^\d{4}$') {  # This is a timestamp
                                $entry = $dateEntry.$timestamp
                                if ($entry.PSObject.Properties['Activities']) {
                                    foreach ($activity in $entry.Activities.PSObject.Properties.Name) {
                                        $activityInfo = $entry.Activities.$activity
                                        if ($activityInfo.PSObject.Properties['duration']) {
                                            $duration = [int]$activityInfo.duration
                                            $totalActivityDuration += $duration
                                            
                                            # Track individual activity types
                                            if ($activityTypes.ContainsKey($activity)) {
                                                $activityTypes[$activity] += $duration
                                            } else {
                                                $activityTypes[$activity] = $duration
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        $painData += [PSCustomObject]@{
                            Date         = $dateStr
                            MaxPainLevel = $maxPain
                            SortDate     = $date
                        }
                        
                        $activityData += [PSCustomObject]@{
                            Date = $dateStr
                            TotalDuration = $totalActivityDuration
                            Walking = if ($activityTypes['walking']) { $activityTypes['walking'] } else { 0 }
                            Stairs = if ($activityTypes['stairs']) { $activityTypes['stairs'] } else { 0 }
                            Standing = if ($activityTypes['standing']) { $activityTypes['standing'] } else { 0 }
                            SortDate = $date
                        }
                    }
                }
                
                if ($painData.Count -eq 0) {
                    New-UDAlert -Severity warning -Text "No pain level data found in entries"
                    return
                }
                
                # Sort by actual date
                $painData = $painData | Sort-Object SortDate
                $activityData = $activityData | Sort-Object SortDate
                
                # Remove SortDate property as it's only needed for sorting
                $painData = $painData | Select-Object Date, MaxPainLevel
                $activityData = $activityData | Select-Object Date, TotalDuration, Walking, Stairs, Standing
                
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Line chart for pain levels over time
                        $painSet = New-UDChartJSDataset -DataProperty MaxPainLevel -Label "Max Pain Level"  
                        New-UDChartJS -Type line -Data $painData -DataProperty MaxPainLevel -LabelProperty Date -Options @{
                            responsive = $true
                            scales = @{
                                y = @{
                                    beginAtZero = $true
                                    max = 10
                                    title = @{
                                        display = $true
                                        text = "Pain Level (0-10)"
                                    }
                                }
                                x = @{
                                    title = @{
                                        display = $true
                                        text = "Date"
                                    }
                                }
                            }
                            plugins = @{
                                title = @{
                                    display = $true
                                    text = "Daily Maximum Pain Levels"
                                }
                                legend = @{
                                    display = $true
                                }
                            }
                        }
                    }
                }
                
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Activity vs Pain correlation chart with dual datasets
                        New-UDChartJS -Type line -Data @{
                            labels = $painData.Date
                            datasets = @(
                                @{
                                    label = "Max Pain Level"
                                    data = $painData.MaxPainLevel
                                    borderColor = 'rgb(255, 99, 132)'
                                    backgroundColor = 'rgba(255, 99, 132, 0.2)'
                                    fill = $false
                                    tension = 0.1
                                    pointRadius = 4
                                    yAxisID = 'y'
                                    type = 'line'
                                },
                                @{
                                    label = "Total Activity Duration (min)"
                                    data = $activityData.TotalDuration
                                    borderColor = 'rgb(54, 162, 235)'
                                    backgroundColor = 'rgba(54, 162, 235, 0.2)'
                                    fill = $false
                                    tension = 0.1
                                    pointRadius = 4
                                    yAxisID = 'y1'
                                    type = 'line'
                                }
                            )
                        } -Options @{
                            responsive = $true
                            interaction = @{
                                mode = 'index'
                                intersect = $false
                            }
                            scales = @{
                                y = @{
                                    type = 'linear'
                                    display = $true
                                    position = 'left'
                                    beginAtZero = $true
                                    max = 10
                                    title = @{
                                        display = $true
                                        text = "Pain Level (0-10)"
                                    }
                                }
                                y1 = @{
                                    type = 'linear'
                                    display = $true
                                    position = 'right'
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Activity Duration (minutes)"
                                    }
                                    grid = @{
                                        drawOnChartArea = $false
                                    }
                                }
                                x = @{
                                    title = @{
                                        display = $true
                                        text = "Date"
                                    }
                                }
                            }
                            plugins = @{
                                title = @{
                                    display = $true
                                    text = "Pain Level vs Activity Duration Correlation"
                                }
                                legend = @{
                                    display = $true
                                }
                            }
                        }
                    }
                }
                
                New-UDRow -Columns {
                    New-UDColumn -Size 6 -Content {
                        # Pain Statistics card
                        $avgPain = [math]::Round(($painData.MaxPainLevel | Measure-Object -Average).Average, 1)
                        $maxPain = ($painData.MaxPainLevel | Measure-Object -Maximum).Maximum
                        $minPain = ($painData.MaxPainLevel | Measure-Object -Minimum).Minimum
                        $totalDays = $painData.Count
                        
                        New-UDCard -Title "Pain Statistics" -Content {
                            New-UDElement -Tag "div" -Content {
                                New-UDTypography -Text "Average Pain Level: $avgPain" -Variant h6
                                New-UDTypography -Text "Highest Pain Level: $maxPain" -Variant h6
                                New-UDTypography -Text "Lowest Pain Level: $minPain" -Variant h6
                                New-UDTypography -Text "Total Days Tracked: $totalDays" -Variant h6
                            }
                        }
                    }
                    
                    New-UDColumn -Size 6 -Content {
                        # Activity Statistics card
                        $avgActivity = [math]::Round(($activityData.TotalDuration | Measure-Object -Average).Average, 1)
                        $maxActivity = ($activityData.TotalDuration | Measure-Object -Maximum).Maximum
                        $totalActivity = ($activityData.TotalDuration | Measure-Object -Sum).Sum
                        $activeDays = ($activityData | Where-Object { $_.TotalDuration -gt 0 }).Count
                        
                        New-UDCard -Title "Activity Statistics" -Content {
                            New-UDElement -Tag "div" -Content {
                                New-UDTypography -Text "Average Daily Activity: $avgActivity min" -Variant h6
                                New-UDTypography -Text "Most Active Day: $maxActivity min" -Variant h6
                                New-UDTypography -Text "Total Activity Time: $totalActivity min" -Variant h6
                                New-UDTypography -Text "Days with Activity: $activeDays" -Variant h6
                            }
                        }
                    }
                }
                
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Data table
                        New-UDTable -Title "Daily Pain Data" -Data $painData -Columns @(
                            New-UDTableColumn -Property "Date" -Title "Date"
                            New-UDTableColumn -Property "MaxPainLevel" -Title "Max Pain Level"
                        ) -Sort -Filter -Search
                    }
                }
                
            } catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
            }
        } -Id "pain-data"
        
        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                New-UDButton -Text "Refresh Data" -OnClick {
                    Sync-UDElement -Id "pain-data"
                } -Color primary
            }
        }
    }
}

# Return the dashboard
$Dashboard


