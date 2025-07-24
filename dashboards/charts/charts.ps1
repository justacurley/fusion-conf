$Dashboard = New-UDDashboard -Title 'Pain Level Analysis' -Content {
    New-UDContainer -Content {
        New-UDTypography -Text 'Max Daily Pain Level Tracker' -Variant h4 -Align center

        New-UDDynamic -Content {

            try {
                # Import GetFusion module for v2 schema support
                Import-Module GetFusion -Force
                Import-Module UserManagement -Force
                $UserData = Initialize-UserContext -UserEmail $User

                $entries = $UserData.Entries

                # Use GetFusion to extract health metrics from v2 schema
                $healthMetrics = Get-HealthMetrics -Entries $entries -DataPoints @('MaxPain', 'BackPain', 'Sleep', 'ActivityDuration')
                Write-Information $healthMetrics
                # Transform data for charts
                $painData = $healthMetrics.CombinedHealthData | Where-Object { $null -ne $_.MaxPain } | ForEach-Object {
                    [PSCustomObject]@{
                        Date = (Get-Date $_.Date).ToString("MM/dd")
                        MaxPainLevel = $_.MaxPain
                    }
                } | Sort-Object { [DateTime]::ParseExact($_.Date + "/2025", "MM/dd/yyyy", $null) }

                $backPainData = $healthMetrics.CombinedHealthData | Where-Object { $null -ne $_.BackPain } | ForEach-Object {
                    [PSCustomObject]@{
                        Date = (Get-Date $_.Date).ToString("MM/dd")
                        AvgBackPain = $_.BackPain
                    }
                } | Sort-Object { [DateTime]::ParseExact($_.Date + "/2025", "MM/dd/yyyy", $null) }

                $sleepData = $healthMetrics.CombinedHealthData | Where-Object { $null -ne $_.Sleep } | ForEach-Object {
                    [PSCustomObject]@{
                        Date = (Get-Date $_.Date).ToString("MM/dd")
                        SleepHours = $_.Sleep
                    }
                } | Sort-Object { [DateTime]::ParseExact($_.Date + "/2025", "MM/dd/yyyy", $null) }

                $activityData = $healthMetrics.CombinedHealthData | Where-Object { $null -ne $_.ActivityDuration } | ForEach-Object {
                    [PSCustomObject]@{
                        Date = (Get-Date $_.Date).ToString("MM/dd")
                        TotalDuration = $_.ActivityDuration
                        Walking = 0  # Individual activity breakdown would need separate processing
                        Stairs = 0
                        Standing = 0
                    }
                } | Sort-Object { [DateTime]::ParseExact($_.Date + "/2025", "MM/dd/yyyy", $null) }

                # Process medication data - group by date and calculate daily totals
                $medicationData = $healthMetrics.Medications | Group-Object Date | ForEach-Object {
                    $dailyMeds = $_.Group
                    $totalDilaudid = ($dailyMeds | Where-Object { $_.Name -eq "dilaudid" } | ForEach-Object {
                        if ($_.Dosage -match '(\d+(?:\.\d+)?)') { [double]$matches[1] } else { 0 }
                    } | Measure-Object -Sum).Sum

                    $totalValium = ($dailyMeds | Where-Object { $_.Name -eq "valium" } | ForEach-Object {
                        if ($_.Dosage -match '(\d+(?:\.\d+)?)') { [double]$matches[1] } else { 0 }
                    } | Measure-Object -Sum).Sum

                    [PSCustomObject]@{
                        Date = (Get-Date $_.Name).ToString("MM/dd")
                        TotalDilaudid = $totalDilaudid
                        TotalValium = $totalValium
                    }
                } | Sort-Object { [DateTime]::ParseExact($_.Date + "/2025", "MM/dd/yyyy", $null) }

                # Handle case where no data is available
                if ($painData.Count -eq 0 -and $backPainData.Count -eq 0 -and $sleepData.Count -eq 0 -and $activityData.Count -eq 0 -and $medicationData.Count -eq 0) {
                    New-UDAlert -Severity warning -Text 'No health data found in entries. Data objects appear to be empty in the current entries.'
                    return
                }

                # Create charts only if data is available
                if ($painData.Count -gt 0) {
                    New-UDRow -Columns {
                        New-UDColumn -Size 12 -Content {
                            # Line chart for pain levels over time
                            New-UDChartJS -Type line -Data $painData -DataProperty MaxPainLevel -LabelProperty Date -Options @{
                                responsive = $true
                                scales     = @{
                                    y = @{
                                        beginAtZero = $true
                                        max         = 10
                                        title       = @{
                                            display = $true
                                            text    = 'Pain Level (0-10)'
                                        }
                                    }
                                    x = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                plugins    = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Daily Maximum Pain Levels'
                                    }
                                    legend = @{
                                        display = $true
                                    }
                                }
                            }
                        }
                    }
                }

                if ($backPainData.Count -gt 0) {
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
                                            text    = 'Average Back Pain Level (0-10)'
                                        }
                                    }
                                    x = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                plugins    = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Daily Average Back Pain Levels'
                                    }
                                    legend = @{
                                        display = $true
                                    }
                                }
                            }
                        }
                    }
                }

                if ($sleepData.Count -gt 0) {
                    New-UDRow -Columns {
                        New-UDColumn -Size 12 -Content {
                            # Line chart for sleep duration
                            New-UDChartJS -Type line -Data $sleepData -DataProperty SleepHours -LabelProperty Date -Options @{
                                responsive = $true
                                scales     = @{
                                    y = @{
                                        beginAtZero = $true
                                        max         = 12
                                        title       = @{
                                            display = $true
                                            text    = 'Sleep Duration (Hours)'
                                        }
                                    }
                                    x = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                plugins    = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Daily Sleep Duration'
                                    }
                                    legend = @{
                                        display = $true
                                    }
                                }
                            }
                        }
                    }
                }

                if ($medicationData.Count -gt 0) {
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
                                            text    = 'Dilaudid Amount (mg)'
                                        }
                                    }
                                    x = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                plugins    = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Daily Total Dilaudid Consumption'
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
                                            text    = 'Valium Amount (mg)'
                                        }
                                    }
                                    x = @{
                                        title = @{
                                            display = $true
                                            text    = 'Date'
                                        }
                                    }
                                }
                                plugins    = @{
                                    title  = @{
                                        display = $true
                                        text    = 'Daily Total Valium Consumption'
                                    }
                                    legend = @{
                                        display = $true
                                    }
                                }
                            }
                        }
                    }
                }


                New-UDRow -Columns {
                    New-UDColumn -Size 2 -Content {
                        # Pain Statistics card
                        if ($painData.Count -gt 0) {
                            $avgPain = [math]::Round(($painData.MaxPainLevel | Measure-Object -Average).Average, 1)
                            $maxPain = ($painData.MaxPainLevel | Measure-Object -Maximum).Maximum
                            $minPain = ($painData.MaxPainLevel | Measure-Object -Minimum).Minimum
                            $totalDays = $painData.Count

                            New-UDCard -Title 'Pain Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text "Average Pain Level: $avgPain" -Variant h6
                                    New-UDTypography -Text "Highest Pain Level: $maxPain" -Variant h6
                                    New-UDTypography -Text "Lowest Pain Level: $minPain" -Variant h6
                                    New-UDTypography -Text "Total Days Tracked: $totalDays" -Variant h6
                                }
                            }
                        } else {
                            New-UDCard -Title 'Pain Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text 'No pain data available' -Variant h6
                                }
                            }
                        }
                    }

                    New-UDColumn -Size 2 -Content {
                        # Sleep Statistics card
                        if ($sleepData.Count -gt 0) {
                            $avgSleep = [math]::Round(($sleepData.SleepHours | Measure-Object -Average).Average, 1)
                            $maxSleep = ($sleepData.SleepHours | Measure-Object -Maximum).Maximum
                            $minSleep = ($sleepData.SleepHours | Measure-Object -Minimum).Minimum
                            $sleepDays = $sleepData.Count

                            New-UDCard -Title 'Sleep Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text "Average Sleep: $avgSleep hrs" -Variant h6
                                    New-UDTypography -Text "Longest Sleep: $maxSleep hrs" -Variant h6
                                    New-UDTypography -Text "Shortest Sleep: $minSleep hrs" -Variant h6
                                    New-UDTypography -Text "Days with Sleep Data: $sleepDays" -Variant h6
                                }
                            }
                        } else {
                            New-UDCard -Title 'Sleep Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text 'No sleep data available' -Variant h6
                                }
                            }
                        }
                    }

                    New-UDColumn -Size 2 -Content {
                        # Activity Statistics card
                        if ($activityData.Count -gt 0) {
                            $avgActivity = [math]::Round(($activityData.TotalDuration | Measure-Object -Average).Average, 1)
                            $maxActivity = ($activityData.TotalDuration | Measure-Object -Maximum).Maximum
                            $totalActivity = ($activityData.TotalDuration | Measure-Object -Sum).Sum
                            $activeDays = ($activityData | Where-Object { $_.TotalDuration -gt 0 }).Count

                            New-UDCard -Title 'Activity Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text "Average Daily Activity: $avgActivity min" -Variant h6
                                    New-UDTypography -Text "Most Active Day: $maxActivity min" -Variant h6
                                    New-UDTypography -Text "Total Activity Time: $totalActivity min" -Variant h6
                                    New-UDTypography -Text "Days with Activity: $activeDays" -Variant h6
                                }
                            }
                        } else {
                            New-UDCard -Title 'Activity Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text 'No activity data available' -Variant h6
                                }
                            }
                        }
                    }

                    New-UDColumn -Size 2 -Content {
                        # Medication Statistics card
                        if ($medicationData.Count -gt 0) {
                            $totalDilaudidMg = ($medicationData.TotalDilaudid | Measure-Object -Sum).Sum
                            $totalValiumMg = ($medicationData.TotalValium | Measure-Object -Sum).Sum
                            $medDays = $medicationData.Count

                            New-UDCard -Title 'Medication Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text "Total Dilaudid: ${totalDilaudidMg}mg" -Variant h6
                                    New-UDTypography -Text "Total Valium: ${totalValiumMg}mg" -Variant h6
                                    New-UDTypography -Text "Days with Medications: $medDays" -Variant h6
                                }
                            }
                        } else {
                            New-UDCard -Title 'Medication Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text 'No medication data available' -Variant h6
                                }
                            }
                        }
                    }

                    New-UDColumn -Size 2 -Content {
                        # Dilaudid Statistics card
                        $avgDilaudid = [math]::Round(($medicationData.TotalDilaudid | Measure-Object -Average).Average, 1)
                        $maxDilaudid = ($medicationData.TotalDilaudid | Measure-Object -Maximum).Maximum
                        $totalDilaudid = ($medicationData.TotalDilaudid | Measure-Object -Sum).Sum
                        $dilaudidDays = ($medicationData | Where-Object { $_.TotalDilaudid -gt 0 }).Count

                        New-UDCard -Title 'Dilaudid Statistics' -Content {
                            New-UDElement -Tag 'div' -Content {
                                New-UDTypography -Text "Average Daily Dose: $avgDilaudid mg" -Variant h6
                                New-UDTypography -Text "Highest Daily Dose: $maxDilaudid mg" -Variant h6
                                New-UDTypography -Text "Total Consumed: $totalDilaudid mg" -Variant h6
                                New-UDTypography -Text "Days with Dilaudid: $dilaudidDays" -Variant h6
                            }
                        }
                    }

                    New-UDColumn -Size 2 -Content {
                        # Valium Statistics card
                        $avgValium = [math]::Round(($medicationData.TotalValium | Measure-Object -Average).Average, 1)
                        $maxValium = ($medicationData.TotalValium | Measure-Object -Maximum).Maximum
                        $totalValium = ($medicationData.TotalValium | Measure-Object -Sum).Sum
                        $valiumDays = ($medicationData | Where-Object { $_.TotalValium -gt 0 }).Count

                        New-UDCard -Title 'Valium Statistics' -Content {
                            New-UDElement -Tag 'div' -Content {
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

                            New-UDCard -Title 'Back Pain Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text "Average Back Pain: $avgBackPain" -Variant h6
                                    New-UDTypography -Text "Highest Daily Avg: $maxBackPain" -Variant h6
                                    New-UDTypography -Text "Lowest Daily Avg: $minBackPain" -Variant h6
                                    New-UDTypography -Text "Days with Back Pain: $backPainDays" -Variant h6
                                }
                            }
                        } else {
                            New-UDCard -Title 'Back Pain Statistics' -Content {
                                New-UDElement -Tag 'div' -Content {
                                    New-UDTypography -Text 'No back pain data available' -Variant h6
                                }
                            }
                        }
                    }
                }

                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        # Data table
                        New-UDTable -Title 'Daily Pain Data' -Data $painData -Columns @(
                            New-UDTableColumn -Property 'Date' -Title 'Date'
                            New-UDTableColumn -Property 'MaxPainLevel' -Title 'Max Pain Level'
                        ) -Sort -Filter -Search
                    }
                }

            } catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
            }
        } -Id 'pain-data'

        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                New-UDButton -Text 'Refresh Data' -OnClick {
                    Sync-UDElement -Id 'pain-data'
                } -Color primary
            }
        }
    }
}

# Return the dashboard
$Dashboard


