$Dashboard = New-UDDashboard -Title 'Medication Heatmap Dashboard' -Content { 
    New-UDContainer -Content {
        # Get medication data from cache
        $Meds = Get-PSUCache -Key 'medicationData' | Select-Object Date, Timestamp, Medication
        
        # Process medication data for calendar format
        $CalendarData = @()
        
        if ($Meds -and $Meds.Count -gt 0) {
            Write-Information "Processing $($Meds.Count) medication entries"
            
            # Group medications by date and count unique medications per day
            $MedsByDate = $Meds | Group-Object -Property Date | ForEach-Object {
                $date = $_.Name
                $uniqueMeds = ($_.Group | Select-Object -Unique Medication).Count
                
                # Convert date format from MM/dd to yyyy-MM-dd (assuming current year)
                try {
                    $currentYear = (Get-Date).Year
                    $parsedDate = [DateTime]::ParseExact("$currentYear/$date", "yyyy/MM/dd", $null)
                    $formattedDate = $parsedDate.ToString("yyyy-MM-dd")
                    
                    $CalendarData += @{
                        day = $formattedDate
                        value = $uniqueMeds
                    }
                } catch {
                    Write-Warning "Could not parse date: $date"
                }
            }
        } else {
            Write-Information "No medication data found in cache"
        }
        
        # Create the heatmap chart
        $HeatmapData = @()
        if ($CalendarData.Count -gt 0) {
            # Group by month to create a proper heatmap structure
            $MonthGroups = $CalendarData | Group-Object { 
                $date = [DateTime]::Parse($_.day)
                $date.ToString("yyyy-MM")
            }
            
            foreach ($monthGroup in $MonthGroups) {
                $monthData = @{ 
                    month = $monthGroup.Name
                }
                
                # Only include days that have actual data
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
            
            Write-Information "Heatmap structure created with $($HeatmapData.Count) months"
            Write-Information "Day keys: $($dayKeys -join ', ')"
        }
        
        # Render heatmap only
        New-UDNivoChart -Heatmap -Data $HeatmapData -IndexBy 'month' -Keys $dayKeys -Height 400 -Width 1400 -MarginTop 80 -MarginRight 80 -MarginBottom 80 -MarginLeft 120 -ForceSquare -Colors @('#f5f5f5', '#ffcccc', '#ff9999', '#ff6666', '#66ccff', '#33aaff', '#0088ff', '#005599') -MinValue 0 -MaxValue 6 -Padding 0.1 -CellBorderWidth 1 -LabelTextColor '#333333' -DisableAnimations
    }
}
$Dashboard
