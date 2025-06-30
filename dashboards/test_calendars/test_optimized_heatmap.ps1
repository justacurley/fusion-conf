# Optimized Medication Heatmap Dashboard
$Dashboard = New-UDDashboard -Title 'Medication Adherence Heatmap' -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "📊 Medication Adherence Heatmap" -Variant h3 -Align center -Style @{ marginBottom = '10px'; color = '#2c3e50' }
        New-UDTypography -Text "Visual analysis of daily medication patterns" -Variant subtitle1 -Align center -Style @{ marginBottom = '30px'; color = '#7f8c8d' }
        
        # Get medication data from cache
        $Meds = Get-PSUCache -Key 'medicationData' | Select-Object Date, Timestamp, Medication
        
        # Process medication data
        $CalendarData = @()
        
        if ($Meds -and $Meds.Count -gt 0) {
            Write-Information "Processing $($Meds.Count) medication entries"
            
            # Group medications by date and count unique medications per day
            $MedsByDate = $Meds | Group-Object -Property Date | ForEach-Object {
                $date = $_.Name
                $uniqueMeds = ($_.Group | Select-Object -Unique Medication).Count
                
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
        }
        
        # Create heatmap data structure
        $HeatmapData = @()
        $dayKeys = @()
        
        if ($CalendarData.Count -gt 0) {
            # Group by month
            $MonthGroups = $CalendarData | Group-Object { 
                $date = [DateTime]::Parse($_.day)
                $date.ToString("yyyy-MM")
            }
            
            foreach ($monthGroup in $MonthGroups) {
                $monthData = @{ 
                    month = $monthGroup.Name
                }
                
                # Track all days with data
                $daysWithData = @()
                foreach ($entry in $monthGroup.Group) {
                    $date = [DateTime]::Parse($entry.day)
                    $dayOfMonth = $date.Day
                    $dayKey = "day$dayOfMonth"
                    $monthData[$dayKey] = [int]$entry.value
                    $daysWithData += $dayOfMonth
                }
                
                # Fill gaps with zeros for visual continuity
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
            
            # Create day keys from all used days
            $allDaysUsed = @()
            foreach ($monthData in $HeatmapData) {
                $monthData.Keys | Where-Object { $_ -ne 'month' } | ForEach-Object {
                    $dayNum = [int]($_ -replace 'day', '')
                    $allDaysUsed += $dayNum
                }
            }
            $dayKeys = ($allDaysUsed | Sort-Object -Unique) | ForEach-Object { "day$_" }
            
            Write-Information "Heatmap created: $($HeatmapData.Count) months, $($dayKeys.Count) day columns"
        }
        
        # Render optimized heatmap
        if ($HeatmapData.Count -gt 0 -and $dayKeys.Count -gt 0) {
            New-UDNivoChart -Heatmap `
                -Data $HeatmapData `
                -IndexBy 'month' `
                -Keys $dayKeys `
                -Height 400 `
                -Width 1400 `
                -MarginTop 80 `
                -MarginRight 80 `
                -MarginBottom 80 `
                -MarginLeft 120 `
                -ForceSquare `
                -Colors @('#ecf0f1', '#bdc3c7', '#f39c12', '#e67e22', '#d35400', '#27ae60', '#2ecc71', '#16a085') `
                -MinValue 0 `
                -MaxValue 7 `
                -Padding 0.05 `
                -CellBorderWidth 1 `
                -LabelTextColor '#2c3e50' `
                -DisableAnimations
                
            # Enhanced legend with color coding
            New-UDRow -Columns {
                New-UDColumn -Size 6 -Content {
                    New-UDTypography -Text "📖 Legend" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px'; color = '#2c3e50' }
                    New-UDTypography -Text "• Rows: Months" -Variant body2
                    New-UDTypography -Text "• Columns: Days of month" -Variant body2
                    New-UDTypography -Text "• Light gray: No medications (0)" -Variant body2 -Style @{ color = '#95a5a6' }
                    New-UDTypography -Text "• Orange: Low adherence (1-3)" -Variant body2 -Style @{ color = '#e67e22' }
                    New-UDTypography -Text "• Green: Good adherence (4+)" -Variant body2 -Style @{ color = '#27ae60' }
                }
                New-UDColumn -Size 6 -Content {
                    if ($CalendarData.Count -gt 0) {
                        $totalDaysWithMeds = $CalendarData.Count
                        $avgMedsPerDay = [math]::Round(($CalendarData | Measure-Object -Property value -Average).Average, 1)
                        $maxMedsInDay = ($CalendarData | Measure-Object -Property value -Maximum).Maximum
                        $minMedsInDay = ($CalendarData | Measure-Object -Property value -Minimum).Minimum
                        
                        New-UDTypography -Text "📊 Statistics" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px'; color = '#2c3e50' }
                        New-UDTypography -Text "• Days with records: $totalDaysWithMeds" -Variant body2
                        New-UDTypography -Text "• Average per day: $avgMedsPerDay medications" -Variant body2
                        New-UDTypography -Text "• Range: $minMedsInDay - $maxMedsInDay medications" -Variant body2
                        New-UDTypography -Text "• Total entries: $($Meds.Count)" -Variant body2
                    }
                }
            }
        } else {
            New-UDAlert -Severity info -Text "No medication data available for visualization"
        }
    }
}
$Dashboard
