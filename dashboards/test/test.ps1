```powershell
New-UDDashboard -Title "Pain Level Analysis" -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Max Daily Pain Level Tracker" -Variant h4 -Align center
        
        New-UDDynamic -Content {
            
            $EntriesPath = "/home/data/fusion-data/entries/entries.json"
            try {
                $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
                New-UDAlert -Severity success -Text "Loaded data from: $EntriesPath"
            }
            catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
                return
            }
        }
                
        # Extract max_pain_level data for each date
        $painData = @()
        $dates = $entries.PSObject.Properties.Name | Sort-Object
                
        foreach ($date in $dates) {
            $dateEntry = $entries.$date
            if ($dateEntry.PSObject.Properties['max_pain_level']) {
                $maxPain = [double]$dateEntry.max_pain_level
                        
                # Convert MMDD to readable date
                $month = $date.Substring(0, 2)
                $day = $date.Substring(2, 2)
                $dateStr = "$month/$day"
                        
                $painData += [PSCustomObject]@{
                    Date         = $dateStr
                    MaxPainLevel = $maxPain
                    SortDate     = $date
                }
            }
        }
                
        if ($painData.Count -eq 0) {
            New-UDAlert -Severity warning -Text "No pain level data found in entries"
            return
        }
                
        # Sort by actual date
        $painData = $painData | Sort-Object SortDate
                
        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                # Line chart for pain levels over time
                New-UDChartJS -Type line -Data @{
                    labels   = $painData.Date
                    datasets = @(
                        @{
                            label           = "Max Daily Pain Level"
                            data            = $painData.MaxPainLevel
                            borderColor     = 'rgb(255, 99, 132)'
                            backgroundColor = 'rgba(255, 99, 132, 0.2)'
                            tension         = 0.1
                            fill            = $true
                        }
                    )
                } -Options @{
                    responsive = $true
                    plugins    = @{
                        title  = @{
                            display = $true
                            text    = "Daily Maximum Pain Levels"
                        }
                        legend = @{
                            display = $true
                        }
                    }
                    scales     = @{
                        y = @{
                            beginAtZero = $true
                            max         = 10
                            title       = @{
                                display = $true
                                text    = "Pain Level (0-10)"
                            }
                        }
                        x = @{
                            title = @{
                                display = $true
                                text    = "Date"
                            }
                        }
                    }
                }
            }
        }
                
        New-UDRow -Columns {
            New-UDColumn -Size 6 -Content {
                # Statistics card
                $avgPain = [math]::Round(($painData.MaxPainLevel | Measure-Object -Average).Average, 1)
                $maxPain = ($painData.MaxPainLevel | Measure-Object -Maximum).Maximum
                $minPain = ($painData.MaxPainLevel | Measure-Object -Minimum).Minimum
                $totalDays = $painData.Count
                        
                New-UDCard -Title "Pain Statistics" -Content {
                    New-UDElement -Tag "div" -Content {
                        New-UDTypography -Text "Average Pain Level: $avgPain" -Variant body1
                        New-UDTypography -Text "Highest Pain Level: $maxPain" -Variant body1
                        New-UDTypography -Text "Lowest Pain Level: $minPain" -Variant body1
                        New-UDTypography -Text "Total Days Tracked: $totalDays" -Variant body1
                    }
                }
            }
                    
            New-UDColumn -Size 6 -Content {
                # Pain level distribution
                $painDistribution = $painData | Group-Object MaxPainLevel | ForEach-Object {
                    [PSCustomObject]@{
                        PainLevel = [double]$_.Name
                        Count     = $_.Count
                    }
                } | Sort-Object PainLevel
                        
                New-UDChartJS -Type bar -Data @{
                    labels   = $painDistribution.PainLevel
                    datasets = @(
                        @{
                            label           = "Days at Pain Level"
                            data            = $painDistribution.Count
                            backgroundColor = @(
                                'rgba(54, 162, 235, 0.5)',
                                'rgba(255, 206, 86, 0.5)',
                                'rgba(255, 99, 132, 0.5)',
                                'rgba(75, 192, 192, 0.5)',
                                'rgba(153, 102, 255, 0.5)',
                                'rgba(255, 159, 64, 0.5)'
                            )
                            borderColor     = @(
                                'rgba(54, 162, 235, 1)',
                                'rgba(255, 206, 86, 1)',
                                'rgba(255, 99, 132, 1)',
                                'rgba(75, 192, 192, 1)',
                                'rgba(153, 102, 255, 1)',
                                'rgba(255, 159, 64, 1)'
                            )
                            borderWidth     = 1
                        }
                    )
                } -Options @{
                    responsive = $true
                    plugins    = @{
                        title  = @{
                            display = $true
                            text    = "Pain Level Distribution"
                        }
                        legend = @{
                            display = $false
                        }
                    }
                    scales     = @{
                        y = @{
                            beginAtZero = $true
                            title       = @{
                                display = $true
                                text    = "Number of Days"
                            }
                        }
                        x = @{
                            title = @{
                                display = $true
                                text    = "Pain Level"
                            }
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
```

