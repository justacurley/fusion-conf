$Dashboard = New-UDDashboard -Title "Simple Interactive Chart" -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Interactive Chart with Toggleable Data Series" -Variant h4 -Align center
        
        New-UDDynamic -Content {
            # Create sample data
            $sampleData = @(
                [PSCustomObject]@{ Date = "06/20"; MaxPain = 4.5; BackPain = 3.2 }
                [PSCustomObject]@{ Date = "06/21"; MaxPain = 5.0; BackPain = 3.8 }
                [PSCustomObject]@{ Date = "06/22"; MaxPain = 3.5; BackPain = 2.5 }
                [PSCustomObject]@{ Date = "06/23"; MaxPain = 6.0; BackPain = 4.1 }
                [PSCustomObject]@{ Date = "06/24"; MaxPain = 4.0; BackPain = 3.0 }
                [PSCustomObject]@{ Date = "06/25"; MaxPain = 5.5; BackPain = 4.5 }
                [PSCustomObject]@{ Date = "06/26"; MaxPain = 3.0; BackPain = 2.8 }
                [PSCustomObject]@{ Date = "06/27"; MaxPain = 4.5; BackPain = 3.5 }
                [PSCustomObject]@{ Date = "06/28"; MaxPain = 5.0; BackPain = 3.9 }
            )
            
            # Store chart data in cache for use by dynamic chart updates
            Set-PSUCache -Key "chartData" -Value $sampleData
                
            # Function to update chart based on checkbox states
            $UpdateChart = {
                $chartData = Get-PSUCache -Key "chartData"
                
                # Get checkbox states
                $showMaxPain = (Get-UDElement -Id "show_max_pain").checked
                $showBackPain = (Get-UDElement -Id "show_back_pain").checked
                
                # Create datasets array based on selected checkboxes
                $datasets = @()
                
                if ($showMaxPain) {
                    $datasets += New-UDChartJSDataset -DataProperty "MaxPain" -Label "Max Pain Level" -BackgroundColor "#dc3545" -BorderColor "#dc3545" -AdditionalOptions @{
                        fill = $false
                        tension = 0.1
                        pointRadius = 4
                        borderWidth = 2
                        showLine = $true
                    }
                }
                
                if ($showBackPain) {
                    $datasets += New-UDChartJSDataset -DataProperty "BackPain" -Label "Back Pain Level" -BackgroundColor "#007bff" -BorderColor "#007bff" -AdditionalOptions @{
                        fill = $false
                        tension = 0.1
                        pointRadius = 4
                        borderWidth = 2
                        showLine = $true
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
                                    text = "Pain Levels Over Time"
                                }
                                legend = @{
                                    display = $true
                                    position = "top"
                                }
                            }
                            scales = @{
                                y = @{
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Pain Level (0-10)"
                                    }
                                    max = 10
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
                        New-UDChartJS -Type 'line' -Data $sampleData -Dataset @(
                            New-UDChartJSDataset -DataProperty "MaxPain" -Label "Max Pain Level" -BackgroundColor "#dc3545" -BorderColor "#dc3545" -AdditionalOptions @{
                                fill = $false
                                tension = 0.1
                                pointRadius = 4
                                borderWidth = 2
                                showLine = $true
                            }
                        ) -LabelProperty "Date" -Options @{
                            responsive = $true
                            plugins = @{
                                title = @{
                                    display = $true
                                    text = "Pain Levels Over Time"
                                }
                                legend = @{
                                    display = $true
                                    position = "top"
                                }
                            }
                            scales = @{
                                y = @{
                                    beginAtZero = $true
                                    title = @{
                                        display = $true
                                        text = "Pain Level (0-10)"
                                    }
                                    max = 10
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
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                New-UDCheckbox -Id "show_max_pain" -Label "🔴 Max Pain Level" -Checked:$true -OnChange $UpdateChart
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                                New-UDCheckbox -Id "show_back_pain" -Label "🔵 Back Pain Level" -Checked:$false -OnChange $UpdateChart
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
        } -Id "chart-data"
    }
}

# Return the dashboard
$Dashboard