$Dashboard = New-UDDashboard -Title 'Simple Interactive Chart' -Content {
    Import-Module UserManagement -Force
    $Session:UserData = Initialize-UserContext -UserEmail $User
    New-UDContainer -Content {
        New-UDTypography -Text 'Interactive Chart with Toggleable Data Series' -Variant h4 -Align center

        New-UDDynamic -Content {
            # Import the GetFusion module for health data processing functions
            Import-Module -Name GetFusion.psm1 -Force

            # Load and process the data using the simplified module functions
            try {
                # Load entries data once
                $Session:Entries = $Session:UserData.Entries

                # Use the new Get-HealthMetrics orchestrator function to get all data
                $Session:HealthData = Get-HealthMetrics -Entries $Session:Entries -DataPoints @('MaxPain', 'BackPain', 'Sleep', 'ActivityDuration', 'Medications', 'Activities', 'Vitals')

                # Extract the different data types from the results
                $Session:CombinedPainData = $Session:HealthData['CombinedHealthData']
                $Session:AllMedications = $Session:HealthData['Medications']
                $Session:AllActivities = $Session:HealthData['Activities']
                $Session:AllVitals = $Session:HealthData['Vitals']

                # Function to update chart based on checkbox states
                $UpdateChart = {
                    $chartData = $Session:CombinedPainData

                    # Get checkbox states
                    $showMaxPain = (Get-UDElement -Id 'show_max_pain').checked
                    $showBackPain = (Get-UDElement -Id 'show_back_pain').checked
                    $showSleep = (Get-UDElement -Id 'show_sleep').checked
                    $showActivityDuration = (Get-UDElement -Id 'show_activity_duration').checked

                    # Create datasets array based on selected checkboxes
                    $datasets = @()

                    if ($showMaxPain) {
                        $datasets += New-UDChartJSDataset -DataProperty 'MaxPain' -Label 'Max Pain Level' -BackgroundColor '#dc3545' -BorderColor '#dc3545' -AdditionalOptions @{
                            fill        = $false
                            tension     = 0.1
                            pointRadius = 4
                            borderWidth = 2
                            showLine    = $true
                            yAxisID     = 'y'
                        }
                    }

                    if ($showBackPain) {
                        $datasets += New-UDChartJSDataset -DataProperty 'BackPain' -Label 'Average Back Pain' -BackgroundColor '#007bff' -BorderColor '#007bff' -AdditionalOptions @{
                            fill        = $false
                            tension     = 0.1
                            pointRadius = 4
                            borderWidth = 2
                            showLine    = $true
                            yAxisID     = 'y'
                        }
                    }

                    if ($showSleep) {
                        $datasets += New-UDChartJSDataset -DataProperty 'Sleep' -Label 'Sleep Hours' -BackgroundColor '#28a745' -BorderColor '#28a745' -AdditionalOptions @{
                            fill        = $false
                            tension     = 0.1
                            pointRadius = 4
                            borderWidth = 2
                            showLine    = $true
                            yAxisID     = 'y1'
                        }
                    }

                    if ($showActivityDuration) {
                        $datasets += New-UDChartJSDataset -DataProperty 'ActivityDuration' -Label 'Activity Duration (min)' -BackgroundColor '#ffc107' -BorderColor '#ffc107' -AdditionalOptions @{
                            fill        = $false
                            tension     = 0.1
                            pointRadius = 4
                            borderWidth = 2
                            showLine    = $true
                            yAxisID     = 'y2'
                        }
                    }

                    # Only show chart if at least one dataset is selected
                    if ($datasets.Count -gt 0) {
                        # Update the chart element
                        Set-UDElement -Id 'dynamic_chart' -Content {
                            New-UDChartJS -Type 'line' -Data $chartData -Dataset $datasets -LabelProperty 'Date' -Options @{
                                responsive  = $true
                                plugins     = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Pain Levels & Sleep Over Time'
                                    }
                                    legend = @{
                                        display  = $true
                                        position = 'top'
                                    }
                                }
                                scales      = @{
                                    y  = @{
                                        type        = 'linear'
                                        display     = $true
                                        position    = 'left'
                                        beginAtZero = $true
                                        title       = @{
                                            display = $true
                                            text    = 'Pain Level (0-10)'
                                        }
                                        max         = 10
                                    }
                                    y1 = @{
                                        type        = 'linear'
                                        display     = $true
                                        position    = 'right'
                                        beginAtZero = $true
                                        title       = @{
                                            display = $true
                                            text    = 'Sleep Hours'
                                        }
                                        max         = 12
                                        grid        = @{
                                            drawOnChartArea = $false
                                        }
                                    }
                                    y2 = @{
                                        type        = 'linear'
                                        display     = $false
                                        position    = 'right'
                                        beginAtZero = $true
                                        title       = @{
                                            display = $true
                                            text    = 'Activity Duration (min)'
                                        }
                                        grid        = @{
                                            drawOnChartArea = $false
                                        }
                                    }
                                    x  = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                interaction = @{
                                    mode      = 'index'
                                    intersect = $false
                                }
                                elements    = @{
                                    line  = @{
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
                        Set-UDElement -Id 'dynamic_chart' -Content {
                            New-UDAlert -Severity info -Text 'Please select at least one data series to display on the chart'
                        }
                    }
                }

                # Chart Section
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Chart container
                        New-UDElement -Id 'dynamic_chart' -Tag 'div' -Content {
                            # Initial chart with Max Pain only (default)
                            New-UDChartJS -Type 'line' -Data $Session:CombinedPainData -Dataset @(
                                New-UDChartJSDataset -DataProperty 'MaxPain' -Label 'Max Pain Level' -BackgroundColor '#dc3545' -BorderColor '#dc3545' -AdditionalOptions @{
                                    fill        = $false
                                    tension     = 0.1
                                    pointRadius = 4
                                    borderWidth = 2
                                    showLine    = $true
                                    yAxisID     = 'y'
                                }
                            ) -LabelProperty 'Date' -Options @{
                                responsive  = $true
                                plugins     = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Pain Levels & Sleep Over Time'
                                    }
                                    legend = @{
                                        display  = $true
                                        position = 'top'
                                    }
                                }
                                scales      = @{
                                    y  = @{
                                        type        = 'linear'
                                        display     = $true
                                        position    = 'left'
                                        beginAtZero = $true
                                        title       = @{
                                            display = $true
                                            text    = 'Pain Level (0-10)'
                                        }
                                        max         = 10
                                    }
                                    y1 = @{
                                        type        = 'linear'
                                        display     = $true
                                        position    = 'right'
                                        beginAtZero = $true
                                        title       = @{
                                            display = $true
                                            text    = 'Sleep Hours'
                                        }
                                        max         = 12
                                        grid        = @{
                                            drawOnChartArea = $false
                                        }
                                    }
                                    y2 = @{
                                        type        = 'linear'
                                        display     = $false
                                        position    = 'right'
                                        beginAtZero = $true
                                        title       = @{
                                            display = $true
                                            text    = 'Activity Duration (min)'
                                        }
                                        grid        = @{
                                            drawOnChartArea = $false
                                        }
                                    }
                                    x  = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                interaction = @{
                                    mode      = 'index'
                                    intersect = $false
                                }
                                elements    = @{
                                    line  = @{
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
                        New-UDCard -Title '📊 Chart Display Options' -Content {
                            New-UDGrid -Container -Children {
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                    New-UDCheckBox -Id 'show_max_pain' -Label '🔴 Max Pain Level' -Checked:$true -OnChange $UpdateChart
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                    New-UDCheckBox -Id 'show_back_pain' -Label '🔵 Average Back Pain' -Checked:$false -OnChange $UpdateChart
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                    New-UDCheckBox -Id 'show_sleep' -Label '🟢 Sleep Hours' -Checked:$false -OnChange $UpdateChart
                                }
                                New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                    New-UDCheckBox -Id 'show_activity_duration' -Label '🟡 Activity Duration' -Checked:$false -OnChange $UpdateChart
                                }
                            }
                            New-UDTypography -Text '💡 Select the data series you want to display on the chart above' -Variant caption -Style @{
                                marginTop = '10px'
                                color     = '#666'
                                fontStyle = 'italic'
                                textAlign = 'center'
                            }
                            New-UDTypography -Text '✨ Enhanced with GetFusion Module v2: Get-HealthMetrics orchestrator + optimized data extraction' -Variant caption -Style @{
                                marginTop  = '5px'
                                color      = '#28a745'
                                fontStyle  = 'italic'
                                textAlign  = 'center'
                                fontWeight = 'bold'
                            }
                        } -Style @{
                            marginTop    = '15px'
                            marginBottom = '20px'
                        }
                    }
                }

                # Data Tables Section
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        New-UDCard -Title '📋 Recent Data Entries' -Content {
                            New-UDTabs -Tabs {
                                New-UDTab -Text '💊 Recent Medications' -Content {
                                    if ($Session:AllMedications.Count -gt 0) {
                                        New-UDTable -Data ($Session:AllMedications | Select-Object -Last 10) -Columns @(
                                            New-UDTableColumn -Property 'Date' -Title 'Date'
                                            New-UDTableColumn -Property 'Timestamp' -Title 'Time'
                                            New-UDTableColumn -Property 'Medication' -Title 'Medication'
                                            New-UDTableColumn -Property 'Dose' -Title 'Dose'
                                        ) -Sort -Search
                                    } else {
                                        New-UDTypography -Text 'No medication data available' -Variant body1
                                    }
                                }
                                New-UDTab -Text '🏃 Recent Activities' -Content {
                                    if ($Session:AllActivities.Count -gt 0) {
                                        New-UDTable -Data ($Session:AllActivities | Select-Object -Last 10) -Columns @(
                                            New-UDTableColumn -Property 'Date' -Title 'Date'
                                            New-UDTableColumn -Property 'Timestamp' -Title 'Time'
                                            New-UDTableColumn -Property 'Activity' -Title 'Activity'
                                            New-UDTableColumn -Property 'Note' -Title 'Note'
                                            New-UDTableColumn -Property 'Duration' -Title 'Duration'
                                        ) -Sort -Search
                                    } else {
                                        New-UDTypography -Text 'No activity data available' -Variant body1
                                    }
                                }
                                New-UDTab -Text '🩺 Recent Vitals' -Content {
                                    if ($Session:AllVitals.Count -gt 0) {
                                        New-UDTable -Data ($Session:AllVitals | Select-Object -Last 10) -Columns @(
                                            New-UDTableColumn -Property 'Date' -Title 'Date'
                                            New-UDTableColumn -Property 'Timestamp' -Title 'Time'
                                            New-UDTableColumn -Property 'VitalType' -Title 'Vital Type'
                                            New-UDTableColumn -Property 'Vital' -Title 'Value'
                                        ) -Sort -Search
                                    } else {
                                        New-UDTypography -Text 'No vitals data available' -Variant body1
                                    }
                                }
                            }
                        } -Style @{ marginTop = '15px'; marginBottom = '20px' }
                    }
                }

            } catch {
                New-UDAlert -Severity error -Text "Error loading health data: $($_.Exception.Message)"
            }

            # ...existing code...
        } -Id 'chart-data'
    }
}

# Return the dashboard
$Dashboard