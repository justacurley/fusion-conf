$Dashboard = New-UDDashboard -Title "Simple Interactive Chart" -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Interactive Chart with Toggleable Data Series" -Variant h4 -Align center
        
        New-UDDynamic -Content {
            $EntriesPath = "/home/data/fusion-data/entries/entries.json"
            try {
                $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
                
                # Extract combined pain data for each date
                $combinedPainData = @()
                $dates = $entries.PSObject.Properties.Name | Sort-Object
                
                foreach ($date in $dates) {
                    $dateEntry = $entries.$date
                    if ($dateEntry.PSObject.Properties['max_pain_level']) {
                        $maxPain = [double]$dateEntry.max_pain_level
                        
                        # Convert MMDD to readable date
                        $month = $date.Substring(0, 2)
                        $day = $date.Substring(2, 2)
                        $dateStr = "$month/$day"
                        
                        # Calculate average back pain for the day
                        $backPainLevels = @()
                        
                        # Check for sleep data
                        $sleepHours = $null
                        if ($dateEntry.PSObject.Properties['Sleep']) {
                            $sleepValue = $dateEntry.Sleep
                            # Parse different sleep formats: "7:39", "9:10", "6:03", etc.
                            if ($sleepValue -match '^(\d+):(\d+)$') {
                                $hours = [int]$matches[1]
                                $minutes = [int]$matches[2]
                                $sleepHours = [math]::Round($hours + ($minutes / 60.0), 2)
                            }
                            # Handle decimal format like "7.5"
                            elseif ($sleepValue -match '^(\d+(?:\.\d+)?)$') {
                                $sleepHours = [double]$matches[1]
                            }
                        }
                        
                        # Check all timestamps for this date
                        foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
                            if ($timestamp -match '^\d{4}$') {  # This is a timestamp
                                $entry = $dateEntry.$timestamp
                                
                                # Process Pain data - specifically back pain
                                if ($entry.PSObject.Properties['Pain']) {
                                    if ($entry.Pain.PSObject.Properties['back']) {
                                        $backPainLevel = [double]$entry.Pain.back.pain_level
                                        $backPainLevels += $backPainLevel
                                    }
                                }
                            }
                        }
                        
                        # Calculate average back pain for the day (null if no back pain data)
                        $avgBackPain = $null
                        if ($backPainLevels.Count -gt 0) {
                            $avgBackPain = [math]::Round(($backPainLevels | Measure-Object -Average).Average, 1)
                        }
                        
                        # Create combined data object
                        $combinedPainData += [PSCustomObject]@{
                            Date = $dateStr
                            MaxPain = $maxPain
                            BackPain = $avgBackPain
                            Sleep = $sleepHours
                        }
                    }
                }
                
                # Sort by actual date and filter out entries without data
                $combinedPainData = $combinedPainData | Sort-Object { [datetime]::ParseExact($_.Date, "MM/dd", $null) }
                
                # Store chart data in cache for use by dynamic chart updates
                Set-PSUCache -Key "chartData" -Value $combinedPainData
                
            # Function to update chart based on checkbox states
            $UpdateChart = {
                $chartData = Get-PSUCache -Key "chartData"
                
                # Get checkbox states
                $showMaxPain = (Get-UDElement -Id "show_max_pain").checked
                $showBackPain = (Get-UDElement -Id "show_back_pain").checked
                $showSleep = (Get-UDElement -Id "show_sleep").checked
                
                # Create datasets array based on selected checkboxes
                $datasets = @()
                
                if ($showMaxPain) {
                    $datasets += New-UDChartJSDataset -DataProperty "MaxPain" -Label "Max Pain Level" -BackgroundColor "#dc3545" -BorderColor "#dc3545" -AdditionalOptions @{
                        fill = $false
                        tension = 0.1
                        pointRadius = 4
                        borderWidth = 2
                        showLine = $true
                        yAxisID = 'y'
                    }
                }
                
                if ($showBackPain) {
                    $datasets += New-UDChartJSDataset -DataProperty "BackPain" -Label "Average Back Pain" -BackgroundColor "#007bff" -BorderColor "#007bff" -AdditionalOptions @{
                        fill = $false
                        tension = 0.1
                        pointRadius = 4
                        borderWidth = 2
                        showLine = $true
                        yAxisID = 'y'
                    }
                }
                
                if ($showSleep) {
                    $datasets += New-UDChartJSDataset -DataProperty "Sleep" -Label "Sleep Hours" -BackgroundColor "#28a745" -BorderColor "#28a745" -AdditionalOptions @{
                        fill = $false
                        tension = 0.1
                        pointRadius = 4
                        borderWidth = 2
                        showLine = $true
                        yAxisID = 'y1'
                    }
                }
                
                # Only show chart if at least one dataset is selected
                if ($datasets.Count -gt 0) {
                    # Update the chart element
                    Set-UDElement -Id "dynamic_chart" -Content {
                        New-UDChartJS -Type 'line' -Data $chartData -Dataset $datasets -LabelProperty "Date" -Options @{
                            responsive = $true
                            plugins = @{
                                title = @{
                                    display = $true
                                    text = "Pain Levels & Sleep Over Time"
                                }
                                legend = @{
                                    display = $true
                                    position = "top"
                                }
                            }
                            scales = @{
                                y = @{
                                    type = 'linear'
                                    display = $true
                                    position = 'left'
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Pain Level (0-10)"
                                    }
                                    max = 10
                                }
                                y1 = @{
                                    type = 'linear'
                                    display = $true
                                    position = 'right'
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Sleep Hours"
                                    }
                                    max = 12
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
                            interaction = @{
                                mode = "index"
                                intersect = $false
                            }
                            elements = @{
                                line = @{
                                    tension = 0.1
                                }
                                point = @{
                                    radius = 4
                                }
                            }
                        }
                    }
                } else {
                    # Show message if no datasets selected
                    Set-UDElement -Id "dynamic_chart" -Content {
                        New-UDAlert -Severity info -Text "Please select at least one data series to display on the chart"
                    }
                }
            }
                
            # Chart Section
            New-UDRow -Columns {
                New-UDColumn -Size 12 -Content {
                    # Chart container
                    New-UDElement -Id "dynamic_chart" -Tag "div" -Content {
                        # Initial chart with Max Pain only (default)
                        New-UDChartJS -Type 'line' -Data $combinedPainData -Dataset @(
                            New-UDChartJSDataset -DataProperty "MaxPain" -Label "Max Pain Level" -BackgroundColor "#dc3545" -BorderColor "#dc3545" -AdditionalOptions @{
                                fill = $false
                                tension = 0.1
                                pointRadius = 4
                                borderWidth = 2
                                showLine = $true
                                yAxisID = 'y'
                            }
                        ) -LabelProperty "Date" -Options @{
                            responsive = $true
                            plugins = @{
                                title = @{
                                    display = $true
                                    text = "Pain Levels & Sleep Over Time"
                                }
                                legend = @{
                                    display = $true
                                    position = "top"
                                }
                            }
                            scales = @{
                                y = @{
                                    type = 'linear'
                                    display = $true
                                    position = 'left'
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Pain Level (0-10)"
                                    }
                                    max = 10
                                }
                                y1 = @{
                                    type = 'linear'
                                    display = $true
                                    position = 'right'
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Sleep Hours"
                                    }
                                    max = 12
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
                            interaction = @{
                                mode = "index"
                                intersect = $false
                            }
                            elements = @{
                                line = @{
                                    tension = 0.1
                                }
                                point = @{
                                    radius = 4
                                }
                            }
                        }
                    }
                }
            }
            
            # Interactive Controls Section
            New-UDRow -Columns {
                New-UDColumn -Size 12 -Content {
                    New-UDCard -Title "📊 Chart Display Options" -Content {
                        New-UDGrid -Container -Children {
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                New-UDCheckbox -Id "show_max_pain" -Label "🔴 Max Pain Level" -Checked:$true -OnChange $UpdateChart
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                New-UDCheckbox -Id "show_back_pain" -Label "🔵 Average Back Pain" -Checked:$false -OnChange $UpdateChart
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                New-UDCheckbox -Id "show_sleep" -Label "🟢 Sleep Hours" -Checked:$false -OnChange $UpdateChart
                            }
                        }
                        New-UDTypography -Text "💡 Select the data series you want to display on the chart above" -Variant caption -Style @{
                            marginTop = "10px"
                            color = "#666"
                            fontStyle = "italic"
                            textAlign = "center"
                        }
                    } -Style @{
                        marginTop = "15px"
                        marginBottom = "20px"
                    }
                }
            }
            
            } catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
            }
        } -Id "chart-data"
    }
}

# Return the dashboard
$Dashboard