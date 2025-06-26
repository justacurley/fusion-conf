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
                $medicationData = @()
                $backPainData = @()
                $dates = $entries.PSObject.Properties.Name | Sort-Object
                
                foreach ($date in $dates) {
                    $dateEntry = $entries.$date
                    if ($dateEntry.PSObject.Properties['max_pain_level']) {
                        $maxPain = [double]$dateEntry.max_pain_level
                        
                        # Convert MMDD to readable date
                        $month = $date.Substring(0, 2)
                        $day = $date.Substring(2, 2)
                        $dateStr = "$month/$day"
                        
                        # Calculate total daily activity duration and medication amounts
                        $totalActivityDuration = 0
                        $activityTypes = @{}
                        $totalDilaudid = 0
                        $totalValium = 0
                        $backPainLevels = @()
                        
                        # Check all timestamps for this date
                        foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
                            if ($timestamp -match '^\d{4}$') {
                                # This is a timestamp
                                $entry = $dateEntry.$timestamp
                                
                                # Process Pain data - specifically back pain
                                if ($entry.PSObject.Properties['Pain']) {
                                    if ($entry.Pain.PSObject.Properties['back']) {
                                        $backPainLevel = [double]$entry.Pain.back.pain_level
                                        $backPainLevels += $backPainLevel
                                    }
                                }
                                
                                # Process Activities
                                if ($entry.PSObject.Properties['Activities']) {
                                    foreach ($activity in $entry.Activities.PSObject.Properties.Name) {
                                        $activityInfo = $entry.Activities.$activity
                                        if ($activityInfo.PSObject.Properties['duration']) {
                                            $duration = [int]$activityInfo.duration
                                            $totalActivityDuration += $duration
                                            
                                            # Track individual activity types
                                            if ($activityTypes.ContainsKey($activity)) {
                                                $activityTypes[$activity] += $duration
                                            }
                                            else {
                                                $activityTypes[$activity] = $duration
                                            }
                                        }
                                    }
                                }
                                
                                # Process Medications - dilaudid and valium
                                if ($entry.PSObject.Properties['Medications']) {
                                    foreach ($medication in $entry.Medications.PSObject.Properties.Name) {
                                        if ($medication -eq 'dilaudid') {
                                            $dose = $entry.Medications.$medication
                                            # Extract numeric value from dose (e.g., "4mg" -> 4)
                                            if ($dose -match '(\d+(?:\.\d+)?)') {
                                                $dilaudidAmount = [double]$matches[1]
                                                $totalDilaudid += $dilaudidAmount
                                            }
                                        }
                                        elseif ($medication -eq 'valium') {
                                            $dose = $entry.Medications.$medication
                                            # Extract numeric value from dose (e.g., "5mg" -> 5)
                                            if ($dose -match '(\d+(?:\.\d+)?)') {
                                                $valiumAmount = [double]$matches[1]
                                                $totalValium += $valiumAmount
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
                            Date          = $dateStr
                            TotalDuration = $totalActivityDuration
                            Walking       = if ($activityTypes['walking']) { $activityTypes['walking'] } else { 0 }
                            Stairs        = if ($activityTypes['stairs']) { $activityTypes['stairs'] } else { 0 }
                            Standing      = if ($activityTypes['standing']) { $activityTypes['standing'] } else { 0 }
                            SortDate      = $date
                        }
                        
                        $medicationData += [PSCustomObject]@{
                            Date          = $dateStr
                            TotalDilaudid = $totalDilaudid
                            TotalValium   = $totalValium
                            SortDate      = $date
                        }
                        
                        # Calculate average back pain for the day
                        if ($backPainLevels.Count -gt 0) {
                            $avgBackPain = [math]::Round(($backPainLevels | Measure-Object -Average).Average, 1)
                            $backPainData += [PSCustomObject]@{
                                Date        = $dateStr
                                AvgBackPain = $avgBackPain
                                SortDate    = $date
                            }
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
                $medicationData = $medicationData | Sort-Object SortDate
                $backPainData = $backPainData | Sort-Object SortDate
                
                # Remove SortDate property as it's only needed for sorting
                $painData = $painData | Select-Object Date, MaxPainLevel
                $activityData = $activityData | Select-Object Date, TotalDuration, Walking, Stairs, Standing
                $medicationData = $medicationData | Select-Object Date, TotalDilaudid, TotalValium
                $backPainData = $backPainData | Select-Object Date, AvgBackPain
                $combinedPainData = $painData + $backPainData
                $painDataSets = @()
                $painDataSets += New-UDChartJSDataset -Data $painData -DataProperty MaxPainLevel -Label Date -BackgroundColor '#729ECE' -BorderColor '#729ECE' -YAxisId 'y'
                $painDataSets += New-UDChartJSDataset -Data $backPainData -DataProperty AvgBackPain -Label Date -BackgroundColor '#FF9E4A' -BorderColor '#FF7F0E' -YAxisId 'y1'
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Line chart for pain levels over time - using explicit dataset syntax
                        New-UDChartJS -Type line -Data $combinedPainData -LabelProperty Date -Options @{   
                            responsive          = $true
                            maintainAspectRatio = $false
                            plugins             = @{
                                legend = @{
                                    display = $false
                                }
                            }
                            scales              = @{
                                xAxis  = @{
                                    display = $true
                                    ticks   = @{
                                        display = $false
                                    }
                                }
                                y  = @{
                                    display  = $true
                                    position = 'left'
                                }
                                y1 = @{
                                    display  = $true
                                    position = 'right'
                                    grid     = @{
                                        drawOnChartArea = $false # only want the grid lines for one axis to show up
                                    }
                                }
                            }
                        }
                    }
                }
                
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Line chart for daily dilaudid consumption
                        New-UDChartJS -Type line -Data $medicationData -DataProperty TotalDilaudid -LabelProperty Date -Options @{
                            responsive = $true
                            scales     = @{
                                y = @{
                                    beginAtZero = $true
                                    title       = @{
                                        display = $true
                                        text    = "Dilaudid Amount (mg)"
                                    }
                                }
                                x = @{
                                    title = @{
                                        display = $true
                                        text    = "Date"
                                    }
                                }
                            }
                            plugins    = @{
                                title  = @{
                                    display = $true
                                    text    = "Daily Total Dilaudid Consumption"
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
                        # Line chart for daily valium consumption
                        New-UDChartJS -Type line -Data $medicationData -DataProperty TotalValium -LabelProperty Date -Options @{
                            responsive = $true
                            scales     = @{
                                y = @{
                                    beginAtZero = $true
                                    title       = @{
                                        display = $true
                                        text    = "Valium Amount (mg)"
                                    }
                                }
                                x = @{
                                    title = @{
                                        display = $true
                                        text    = "Date"
                                    }
                                }
                            }
                            plugins    = @{
                                title  = @{
                                    display = $true
                                    text    = "Daily Total Valium Consumption"
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
                        # Line chart for average back pain levels
                        New-UDChartJS -Type line -Data $backPainData -DataProperty AvgBackPain -LabelProperty Date -Options @{
                            responsive = $true
                            scales     = @{
                                y = @{
                                    beginAtZero = $true
                                    max         = 10
                                    title       = @{
                                        display = $true
                                        text    = "Average Back Pain Level (0-10)"
                                    }
                                }
                                x = @{
                                    title = @{
                                        display = $true
                                        text    = "Date"
                                    }
                                }
                            }
                            plugins    = @{
                                title  = @{
                                    display = $true
                                    text    = "Daily Average Back Pain Levels"
                                }
                                legend = @{
                                    display = $true
                                }
                            }
                        }
                    }
                }
                
                
                New-UDRow -Columns {
                    New-UDColumn -Size 2 -Content {
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
                    
                    New-UDColumn -Size 2 -Content {
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
                    
                    New-UDColumn -Size 3 -Content {
                        # Dilaudid Statistics card
                        $avgDilaudid = [math]::Round(($medicationData.TotalDilaudid | Measure-Object -Average).Average, 1)
                        $maxDilaudid = ($medicationData.TotalDilaudid | Measure-Object -Maximum).Maximum
                        $totalDilaudid = ($medicationData.TotalDilaudid | Measure-Object -Sum).Sum
                        $dilaudidDays = ($medicationData | Where-Object { $_.TotalDilaudid -gt 0 }).Count
                        
                        New-UDCard -Title "Dilaudid Statistics" -Content {
                            New-UDElement -Tag "div" -Content {
                                New-UDTypography -Text "Average Daily Dose: $avgDilaudid mg" -Variant h6
                                New-UDTypography -Text "Highest Daily Dose: $maxDilaudid mg" -Variant h6
                                New-UDTypography -Text "Total Consumed: $totalDilaudid mg" -Variant h6
                                New-UDTypography -Text "Days with Dilaudid: $dilaudidDays" -Variant h6
                            }
                        }
                    }
                    
                    New-UDColumn -Size 3 -Content {
                        # Valium Statistics card
                        $avgValium = [math]::Round(($medicationData.TotalValium | Measure-Object -Average).Average, 1)
                        $maxValium = ($medicationData.TotalValium | Measure-Object -Maximum).Maximum
                        $totalValium = ($medicationData.TotalValium | Measure-Object -Sum).Sum
                        $valiumDays = ($medicationData | Where-Object { $_.TotalValium -gt 0 }).Count
                        
                        New-UDCard -Title "Valium Statistics" -Content {
                            New-UDElement -Tag "div" -Content {
                                New-UDTypography -Text "Average Daily Dose: $avgValium mg" -Variant h6
                                New-UDTypography -Text "Highest Daily Dose: $maxValium mg" -Variant h6
                                New-UDTypography -Text "Total Consumed: $totalValium mg" -Variant h6
                                New-UDTypography -Text "Days with Valium: $valiumDays" -Variant h6
                            }
                        }
                    }
                    
                    New-UDColumn -Size 2 -Content {
                        # Back Pain Statistics card
                        if ($backPainData.Count -gt 0) {
                            $avgBackPain = [math]::Round(($backPainData.AvgBackPain | Measure-Object -Average).Average, 1)
                            $maxBackPain = ($backPainData.AvgBackPain | Measure-Object -Maximum).Maximum
                            $minBackPain = ($backPainData.AvgBackPain | Measure-Object -Minimum).Minimum
                            $backPainDays = $backPainData.Count
                            
                            New-UDCard -Title "Back Pain Statistics" -Content {
                                New-UDElement -Tag "div" -Content {
                                    New-UDTypography -Text "Average Back Pain: $avgBackPain" -Variant h6
                                    New-UDTypography -Text "Highest Daily Avg: $maxBackPain" -Variant h6
                                    New-UDTypography -Text "Lowest Daily Avg: $minBackPain" -Variant h6
                                    New-UDTypography -Text "Days with Back Pain: $backPainDays" -Variant h6
                                }
                            }
                        }
                        else {
                            New-UDCard -Title "Back Pain Statistics" -Content {
                                New-UDElement -Tag "div" -Content {
                                    New-UDTypography -Text "No back pain data available" -Variant h6
                                }
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
                
            }
            catch {
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


