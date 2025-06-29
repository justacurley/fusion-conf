$Dashboard = New-UDDashboard -Title "Simple Interactive Chart" -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Interactive Chart with Toggleable Data Series" -Variant h4 -Align center
        
        New-UDDynamic -Content {
            # Import the GetFusion module for health data processing functions
            Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force
            
            # Clear any cached data to ensure fresh data load
            Clear-CachedData
            
            # Load and process the data using the simplified module functions
            $EntriesPath = "/home/data/fusion-data/entries/entries.json"
            try {
                # Load entries data once
                $entries = Get-EntriesData -entriesPath $EntriesPath
                
                # Get dates list (this will populate the cache for performance)
                $dates = Get-DatesList -entries $entries
                
                # Build combined health data using the new module functions
                $combinedPainData = @()
                foreach ($date in $dates) {
                    $dateEntry = $entries.$date
                    $baseObject = [PSCustomObject]@{
                        Date = Convert-DateToDisplay -date $date
                    }
                    
                    # Add max pain level if available
                    if ($dateEntry.PSObject.Properties['max_pain_level']) {
                        $baseObject = Set-CombinedData -combinedData $baseObject -name "MaxPain" -data ([double]$dateEntry.max_pain_level)
                    }
                    
                    # Add average back pain
                    $avgBackPain = Get-AverageBackPain -dateEntry $dateEntry
                    if ($null -ne $avgBackPain) {
                        $baseObject = Set-CombinedData -combinedData $baseObject -name "BackPain" -data $avgBackPain
                    }
                    
                    # Add sleep hours if available
                    if ($dateEntry.PSObject.Properties['sleep_hours']) {
                        $sleepHours = Get-SleepHours -sleepValue $dateEntry.sleep_hours
                        if ($null -ne $sleepHours) {
                            $baseObject = Set-CombinedData -combinedData $baseObject -name "Sleep" -data $sleepHours
                        }
                    }
                    
                    $combinedPainData += $baseObject
                }
                
                # Get additional data using the new optimized functions (will use cached dates)
                $allMedications = Get-MedicationData -entries $entries
                $allActivities = Get-ActivityData -entries $entries
                $allVitals = Get-VitalsData -entries $entries
                
                # Store chart data in cache for use by dynamic chart updates
                Set-PSUCache -Key "chartData" -Value $combinedPainData
                Set-PSUCache -Key "medicationData" -Value $allMedications
                Set-PSUCache -Key "activityData" -Value $allActivities
                Set-PSUCache -Key "vitalsData" -Value $allVitals
                Set-PSUCache -Key "distinctData" -Value $global:DistinctDataValues
                
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
            
            # Data Summary Section
            New-UDRow -Columns {
                New-UDColumn -Size 2 -Content {
                    New-UDCard -Title "📊 Health Data" -Content {
                        New-UDTypography -Text "Total Entries: $($combinedPainData.Count)" -Variant body2
                        if ($combinedPainData.Count -gt 0) {
                            $avgMaxPain = [math]::Round(($combinedPainData | Where-Object { $_.MaxPain -ne $null } | Measure-Object -Property MaxPain -Average).Average, 1)
                            $avgSleep = [math]::Round(($combinedPainData | Where-Object { $_.Sleep -ne $null } | Measure-Object -Property Sleep -Average).Average, 1)
                            New-UDTypography -Text "Avg Max Pain: $avgMaxPain" -Variant body2
                            New-UDTypography -Text "Avg Sleep: $avgSleep hrs" -Variant body2
                        }
                    } -Style @{ marginBottom = "15px" }
                }
                New-UDColumn -Size 2 -Content {
                    New-UDCard -Title "💊 Medications" -Content {
                        New-UDTypography -Text "Total Entries: $($allMedications.Count)" -Variant body2
                        if ($allMedications.Count -gt 0) {
                            $uniqueDates = ($allMedications | Group-Object Date).Count
                            $avgPerDay = [math]::Round($allMedications.Count / $uniqueDates, 1)
                            New-UDTypography -Text "Days with Meds: $uniqueDates" -Variant body2
                            New-UDTypography -Text "Avg per Day: $avgPerDay" -Variant body2
                        }
                    } -Style @{ marginBottom = "15px" }
                }
                New-UDColumn -Size 2 -Content {
                    New-UDCard -Title "🏃 Activities" -Content {
                        New-UDTypography -Text "Total Entries: $($allActivities.Count)" -Variant body2
                        if ($allActivities.Count -gt 0) {
                            $uniqueDates = ($allActivities | Group-Object Date).Count
                            $avgPerDay = [math]::Round($allActivities.Count / $uniqueDates, 1)
                            New-UDTypography -Text "Days with Activities: $uniqueDates" -Variant body2
                            New-UDTypography -Text "Avg per Day: $avgPerDay" -Variant body2
                        }
                    } -Style @{ marginBottom = "15px" }
                }
                New-UDColumn -Size 2 -Content {
                    New-UDCard -Title "🩺 Vitals" -Content {
                        New-UDTypography -Text "Total Entries: $($allVitals.Count)" -Variant body2
                        if ($allVitals.Count -gt 0) {
                            $uniqueDates = ($allVitals | Group-Object Date).Count
                            $avgPerDay = [math]::Round($allVitals.Count / $uniqueDates, 1)
                            New-UDTypography -Text "Days with Vitals: $uniqueDates" -Variant body2
                            New-UDTypography -Text "Avg per Day: $avgPerDay" -Variant body2
                        }
                    } -Style @{ marginBottom = "15px" }
                }
                New-UDColumn -Size 4 -Content {
                    New-UDCard -Title "🔍 Distinct Values Found" -Content {
                        if ($global:DistinctDataValues.ContainsKey('Medications')) {
                            New-UDTypography -Text "Unique Medications: $($global:DistinctDataValues['Medications'].Count)" -Variant body2
                            New-UDTypography -Text "($($global:DistinctDataValues['Medications'] -join ', '))" -Variant caption -Style @{ fontSize = "0.7rem"; color = "#666" }
                        }
                        if ($global:DistinctDataValues.ContainsKey('Activities')) {
                            New-UDTypography -Text "Unique Activities: $($global:DistinctDataValues['Activities'].Count)" -Variant body2 -Style @{ marginTop = "8px" }
                            New-UDTypography -Text "($($global:DistinctDataValues['Activities'] -join ', '))" -Variant caption -Style @{ fontSize = "0.7rem"; color = "#666" }
                        }
                        New-UDTypography -Text "🚀 Performance: Using cached dates list" -Variant caption -Style @{
                            marginTop = "8px"
                            color = "#28a745"
                            fontWeight = "bold"
                        }
                    } -Style @{ marginBottom = "15px" }
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
                        New-UDTypography -Text "✨ Enhanced with GetFusion Module v2: Cached performance + distinct value tracking" -Variant caption -Style @{
                            marginTop = "5px"
                            color = "#28a745"
                            fontStyle = "italic"
                            textAlign = "center"
                            fontWeight = "bold"
                        }
                    } -Style @{
                        marginTop = "15px"
                        marginBottom = "20px"
                    }
                }
            }
            
            # Data Tables Section
            New-UDRow -Columns {
                New-UDColumn -Size 12 -Content {
                    New-UDCard -Title "📋 Recent Data Entries" -Content {
                        New-UDTabs -Tabs {
                            New-UDTab -Text "💊 Recent Medications" -Content {
                                if ($allMedications.Count -gt 0) {
                                    New-UDTable -Data ($allMedications | Select-Object -Last 10) -Columns @(
                                        New-UDTableColumn -Property "Date" -Title "Date"
                                        New-UDTableColumn -Property "Timestamp" -Title "Time"
                                        New-UDTableColumn -Property "Medication" -Title "Medication"
                                    ) -Sort -Search
                                } else {
                                    New-UDTypography -Text "No medication data available" -Variant body1
                                }
                            }
                            New-UDTab -Text "🏃 Recent Activities" -Content {
                                if ($allActivities.Count -gt 0) {
                                    New-UDTable -Data ($allActivities | Select-Object -Last 10) -Columns @(
                                        New-UDTableColumn -Property "Date" -Title "Date"
                                        New-UDTableColumn -Property "Timestamp" -Title "Time"
                                        New-UDTableColumn -Property "Activity" -Title "Activity"
                                    ) -Sort -Search
                                } else {
                                    New-UDTypography -Text "No activity data available" -Variant body1
                                }
                            }
                            New-UDTab -Text "🩺 Recent Vitals" -Content {
                                if ($allVitals.Count -gt 0) {
                                    New-UDTable -Data ($allVitals | Select-Object -Last 10) -Columns @(
                                        New-UDTableColumn -Property "Date" -Title "Date"
                                        New-UDTableColumn -Property "Timestamp" -Title "Time"
                                        New-UDTableColumn -Property "Vital" -Title "Vital Signs"
                                    ) -Sort -Search
                                } else {
                                    New-UDTypography -Text "No vitals data available" -Variant body1
                                }
                            }
                        }
                    } -Style @{ marginTop = "15px"; marginBottom = "20px" }
                }
            }
            
            } catch {
                New-UDAlert -Severity error -Text "Error loading health data: $($_.Exception.Message)"
            }
            
            # ...existing code...
        } -Id "chart-data"
    }
}

# Return the dashboard
$Dashboard