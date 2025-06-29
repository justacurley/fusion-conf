$Dashboard = New-UDDashboard -Title "Combined Pain Analysis & Chart" -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Max Pain vs Average Back Pain Analysis" -Variant h4 -Align center
        
        New-UDDynamic -Content {
            
            $EntriesPath = "/home/data/fusion-data/entries/entries.json"
            try {
                $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
                New-UDAlert -Severity success -Text "Loaded data from: $EntriesPath"
            
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
                            MaxPainLevel = $maxPain
                            AvgBackPain = $avgBackPain
                            SleepHours = $sleepHours
                            SortDate = $date
                            HasBackPainData = $backPainLevels.Count -gt 0
                            HasSleepData = $sleepHours -ne $null
                        }
                    }
                }
                
                if ($combinedPainData.Count -eq 0) {
                    New-UDAlert -Severity warning -Text "No pain level data found in entries"
                    return
                }
                
                # Sort by actual date
                $combinedPainData = $combinedPainData | Sort-Object SortDate
                
                # Remove SortDate property as it's only needed for sorting
                $combinedPainData = $combinedPainData | Select-Object Date, MaxPainLevel, AvgBackPain, SleepHours, HasBackPainData, HasSleepData
                
                # Display data summary for debugging
                $sleepDataCount = ($combinedPainData | Where-Object { $_.HasSleepData }).Count
                New-UDAlert -Severity info -Text "Data processed: $($combinedPainData.Count) days total, $sleepDataCount days with sleep data"
                
                # Create triple-series line chart for Max Pain, Average Back Pain, and Sleep
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Prepare data for charting - include all dates (sleep can be null and will just not show points)
                        $chartData = $combinedPainData
                        
                        if ($chartData.Count -gt 0) {
                            # Create datasets for all three series with additional options for line connections
                            $maxPainDataset = New-UDChartJSDataset -DataProperty "MaxPainLevel" -Label "Max Pain Level" -BackgroundColor "#dc3545" -BorderColor "#dc3545" -AdditionalOptions @{
                                fill = $false
                                tension = 0.1
                                pointRadius = 4
                                borderWidth = 2
                                showLine = $true
                                yAxisID = 'y'
                            }
                            $avgBackPainDataset = New-UDChartJSDataset -DataProperty "AvgBackPain" -Label "Average Back Pain" -BackgroundColor "#007bff" -BorderColor "#007bff" -AdditionalOptions @{
                                fill = $false
                                tension = 0.1
                                pointRadius = 4
                                borderWidth = 2
                                showLine = $true
                                yAxisID = 'y'
                            }
                            $sleepDataset = New-UDChartJSDataset -DataProperty "SleepHours" -Label "Sleep Hours" -BackgroundColor "#28a745" -BorderColor "#28a745" -AdditionalOptions @{
                                fill = $false
                                tension = 0.1
                                pointRadius = 4
                                borderWidth = 2
                                showLine = $true
                                yAxisID = 'y1'
                            }
                            
                            # Create the triple-series line chart with dual y-axes
                            New-UDChartJS -Type 'line' -Data $chartData -Dataset @($maxPainDataset, $avgBackPainDataset, $sleepDataset) -LabelProperty "Date" -Options @{
                                responsive = $true
                                plugins = @{
                                    title = @{
                                        display = $true
                                        text = "Pain Levels vs Sleep Duration Over Time"
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
                        } else {
                            New-UDAlert -Severity warning -Text "No data available for triple-series chart"
                        }
                    }
                }
                
                # Show sample data in a table below the chart
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        New-UDTable -Title "Combined Pain & Sleep Data (Sample)" -Data ($combinedPainData | Select-Object -First 10) -Columns @(
                            New-UDTableColumn -Property "Date" -Title "Date"
                            New-UDTableColumn -Property "MaxPainLevel" -Title "Max Pain Level"
                            New-UDTableColumn -Property "AvgBackPain" -Title "Avg Back Pain"
                            New-UDTableColumn -Property "SleepHours" -Title "Sleep Hours"
                            New-UDTableColumn -Property "HasBackPainData" -Title "Has Back Data"
                            New-UDTableColumn -Property "HasSleepData" -Title "Has Sleep Data"
                        ) -Sort
                    }
                }
                
                # Show statistics
                New-UDRow -Columns {
                    New-UDColumn -Size 4 -Content {
                        New-UDCard -Title "Max Pain Statistics" -Content {
                            $avgMaxPain = [math]::Round(($combinedPainData.MaxPainLevel | Measure-Object -Average).Average, 1)
                            $maxMaxPain = ($combinedPainData.MaxPainLevel | Measure-Object -Maximum).Maximum
                            $minMaxPain = ($combinedPainData.MaxPainLevel | Measure-Object -Minimum).Minimum
                            
                            New-UDElement -Tag "div" -Content {
                                New-UDTypography -Text "Average Max Pain: $avgMaxPain" -Variant h6
                                New-UDTypography -Text "Highest Max Pain: $maxMaxPain" -Variant h6
                                New-UDTypography -Text "Lowest Max Pain: $minMaxPain" -Variant h6
                            }
                        }
                    }
                    
                    New-UDColumn -Size 4 -Content {
                        New-UDCard -Title "Back Pain Statistics" -Content {
                            $backPainDays = ($combinedPainData | Where-Object { $_.HasBackPainData }).Count
                            $backPainValues = $combinedPainData | Where-Object { $_.AvgBackPain -ne $null } | Select-Object -ExpandProperty AvgBackPain
                            
                            if ($backPainValues.Count -gt 0) {
                                $avgBackPain = [math]::Round(($backPainValues | Measure-Object -Average).Average, 1)
                                $maxBackPain = ($backPainValues | Measure-Object -Maximum).Maximum
                                $minBackPain = ($backPainValues | Measure-Object -Minimum).Minimum
                                
                                New-UDElement -Tag "div" -Content {
                                    New-UDTypography -Text "Days with back pain data: $backPainDays" -Variant h6
                                    New-UDTypography -Text "Average back pain: $avgBackPain" -Variant h6
                                    New-UDTypography -Text "Highest back pain: $maxBackPain" -Variant h6
                                    New-UDTypography -Text "Lowest back pain: $minBackPain" -Variant h6
                                }
                            } else {
                                New-UDElement -Tag "div" -Content {
                                    New-UDTypography -Text "No back pain data available" -Variant h6
                                }
                            }
                        }
                    }
                    
                    New-UDColumn -Size 4 -Content {
                        New-UDCard -Title "Sleep Statistics" -Content {
                            $sleepDays = ($combinedPainData | Where-Object { $_.HasSleepData }).Count
                            $sleepValues = $combinedPainData | Where-Object { $_.SleepHours -ne $null } | Select-Object -ExpandProperty SleepHours
                            
                            if ($sleepValues.Count -gt 0) {
                                $avgSleep = [math]::Round(($sleepValues | Measure-Object -Average).Average, 1)
                                $maxSleep = ($sleepValues | Measure-Object -Maximum).Maximum
                                $minSleep = ($sleepValues | Measure-Object -Minimum).Minimum
                                
                                New-UDElement -Tag "div" -Content {
                                    New-UDTypography -Text "Days with sleep data: $sleepDays" -Variant h6
                                    New-UDTypography -Text "Average sleep: $avgSleep hrs" -Variant h6
                                    New-UDTypography -Text "Longest sleep: $maxSleep hrs" -Variant h6
                                    New-UDTypography -Text "Shortest sleep: $minSleep hrs" -Variant h6
                                }
                            } else {
                                New-UDElement -Tag "div" -Content {
                                    New-UDTypography -Text "No sleep data available" -Variant h6
                                }
                            }
                        }
                    }
                }
                
            } catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
            }
        } -Id "combined-pain-data"
        
        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                New-UDButton -Text "Refresh Data" -OnClick {
                    Sync-UDElement -Id "combined-pain-data"
                } -Color primary
            }
        }
    }
}

# Return the dashboard
$Dashboard