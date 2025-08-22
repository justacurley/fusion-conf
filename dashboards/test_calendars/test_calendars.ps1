$Dashboard = New-UDDashboard -Title 'Medication Heatmap Dashboard' -Content { 
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    New-UDContainer -Content {
        # New-UDTypography -Text "Medication Adherence Heatmap" -Variant h4 -Align center
        # New-UDTypography -Text "Shows weekly medication patterns - darker colors indicate more medications taken" -Variant body2 -Align center
        # New-UDTypography -Text "Heatmap displays weeks vs days of week with your medication data" -Variant caption -Align center -Style @{ fontStyle = 'italic'; marginBottom = '20px' }
        
        # Import-Module -Name GetFusion -Force
        # Clear-CachedData
        # $Entries = Get-PSUCachedEntries
        Write-Information 'Getting medication data from cache...'
        $Meds = Get-PSUCache -Key 'medicationData' | Select-Object Date, Timestamp, Medication

        # Process medication data for calendar format
        $CalendarData = @()
        
        if ($Meds) {
            # Group medications by date and count unique medications per day
            $MedsByDate = $Meds | Group-Object -Property Date | ForEach-Object {
                $date = $_.Name
                $uniqueMeds = ($_.Group | Select-Object -Unique Medication).Count
                
                # Convert date format from MM/dd to yyyy-MM-dd (assuming current year)
                try {
                    $currentYear = (Get-Date).Year
                    $parsedDate = [DateTime]::ParseExact("$currentYear/$date", 'yyyy/MM/dd', $null)
                    $formattedDate = $parsedDate.ToString('yyyy-MM-dd')
                    
                    $CalendarData += @{
                        day   = $formattedDate
                        value = $uniqueMeds
                    }
                } catch {
                    Write-Warning "Could not parse date: $date"
                }
            }
        }
        
        # Debug: Show first few calendar data entries
        if ($CalendarData.Count -gt 0) {
            Write-Information 'Sample calendar data:'
            $CalendarData | Select-Object -First 5 | ForEach-Object { 
                Write-Information "  Day: $($_.day), Value: $($_.value)" 
            }
        }
    
        # Set date range based on actual medication data
        if ($CalendarData.Count -gt 0) {
            $sortedDates = $CalendarData | Sort-Object { [DateTime]$_.day }
            $firstDate = ($sortedDates | Select-Object -First 1).day
            $lastDate = ($sortedDates | Select-Object -Last 1).day
            
            # Convert to DateTime objects - let's try without padding first
            $From = [DateTime]::Parse($firstDate)
            $To = [DateTime]::Parse($lastDate)
            
            # Debug output (will show in browser console/logs)
            Write-Information "Date range: $From to $To"
            Write-Information "Total calendar data points: $($CalendarData.Count)"
            Write-Information "First date: $firstDate, Last date: $lastDate"
        } else {
            # Fallback if no data
            $From = (Get-Date).AddDays(-365)
            $To = Get-Date
            Write-Information 'No calendar data found, using fallback dates'
        }
        
        # Create the heatmap chart
        # Convert calendar data to heatmap format matching documentation example
        $HeatmapData = @()
        if ($CalendarData.Count -gt 0) {
            # Group by month to create a proper heatmap structure
            $MonthGroups = $CalendarData | Group-Object { 
                $date = [DateTime]::Parse($_.day)
                $date.ToString('yyyy-MM')
            }
            Write-Information "MonthGroups: $($MonthGroups|ConvertTo-Json -Depth 3)"
            foreach ($monthGroup in $MonthGroups) {
                $monthData = @{ 
                    month = $monthGroup.Name
                }
                
                # Only include days that have actual data (instead of all 31 days)
                $daysWithData = @()
                foreach ($entry in $monthGroup.Group) {
                    $date = [DateTime]::Parse($entry.day)
                    $dayOfMonth = $date.Day
                    $dayKey = "day$dayOfMonth"
                    $monthData[$dayKey] = $entry.value
                    $daysWithData += $dayOfMonth
                }
                
                # Fill in missing days between min and max with 0 for context
                if ($daysWithData.Count -gt 0) {
                    $minDay = ($daysWithData | Measure-Object -Minimum).Minimum
                    $maxDay = ($daysWithData | Measure-Object -Maximum).Maximum
                    
                    for ($i = $minDay; $i -le $maxDay; $i++) {
                        $dayKey = "day$i"
                        if (-not $monthData.ContainsKey($dayKey)) {
                            $monthData[$dayKey] = 0
                        }
                    }
                }
                
                Write-Information "monthData: $($monthData | ConvertTo-Json -Depth 3)"
                $HeatmapData += $monthData
            }
            
            # Create keys array only for days that exist in the data
            $allDaysUsed = @()
            foreach ($monthData in $HeatmapData) {
                $monthData.Keys | Where-Object { $_ -ne 'month' } | ForEach-Object {
                    $dayNum = $_ -replace 'day', ''
                    $allDaysUsed += [int]$dayNum
                }
            }
            $dayKeys = ($allDaysUsed | Sort-Object -Unique) | ForEach-Object { "day$_" }
            
            # Debug heatmap data
            Write-Information "Heatmap structure created with $($HeatmapData.Count) months"
            Write-Information "Day keys: $($dayKeys -join ', ')"
        }
        $ChartParams = @{
            Heatmap      = $true
            Data         = $HeatmapData
            IndexBy      = 'month'
            Keys         = $dayKeys
            Height       = 500
            Width        = 1200
            MarginTop    = 60
            MarginRight  = 50
            MarginBottom = 60
            MarginLeft   = 100
            colors       = @{
                type      = 'sequential'
                scheme    = 'blues'
                divergeAt = 0.5
                steps     = 10
                minValue  = 1
                maxValue  = 10
            }
            theme        = @{
                emptyColor = '#ff5c5c' # appears to do nothing
            }
            enableGridX  = $true
        }

        New-UDNivoChart @ChartParams
        
        # # Add a legend/summary
        # New-UDTypography -Text "Heatmap Legend:" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px' }
        # New-UDTypography -Text "• Each row represents a month, columns represent days of the month" -Variant body2
        # New-UDTypography -Text "• Light colors = Fewer unique medications taken" -Variant body2
        # New-UDTypography -Text "• Dark colors = More unique medications taken" -Variant body2
        # New-UDTypography -Text "• Empty/zero = No medications recorded that day" -Variant body2
        
        # # Display summary statistics
        # if ($CalendarData.Count -gt 0) {
        #     $totalDaysWithMeds = $CalendarData.Count
        #     $avgMedsPerDay = [math]::Round(($CalendarData | Measure-Object -Property value -Average).Average, 1)
        #     $maxMedsInDay = ($CalendarData | Measure-Object -Property value -Maximum).Maximum
            
        #     New-UDTypography -Text "Summary Statistics:" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px' }
        #     New-UDTypography -Text "• Days with medication records: $totalDaysWithMeds" -Variant body2
        #     New-UDTypography -Text "• Average unique medications per day: $avgMedsPerDay" -Variant body2
        #     New-UDTypography -Text "• Maximum unique medications in a single day: $maxMedsInDay" -Variant body2
        # }
    }
}
$Dashboard