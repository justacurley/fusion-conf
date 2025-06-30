$Dashboard = New-UDDashboard -Title "Medication Heatmap Dashboard" -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Medication Adherence Heatmap" -Variant h4 -Align center
        New-UDTypography -Text "Shows weekly medication patterns - darker colors indicate more medications taken" -Variant body2 -Align center
        New-UDTypography -Text "Heatmap displays weeks vs days of week with your medication data" -Variant caption -Align center -Style @{ fontStyle = 'italic'; marginBottom = '20px' }
        
        # Import-Module -Name GetFusion -Force
        # Clear-CachedData
        # $Entries = Get-PSUCachedEntries
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
        
        # Debug: Show first few calendar data entries
        if ($CalendarData.Count -gt 0) {
            Write-Information "Sample calendar data:"
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
            Write-Information "No calendar data found, using fallback dates"
        }
        
        # Create the heatmap chart
        # Convert calendar data to heatmap format matching documentation example
        $HeatmapData = @()
        $dayKeys = @()
        
        if ($CalendarData.Count -gt 0) {
            # Create a simpler, more reliable data structure
            # Group by month to create a proper heatmap structure
            $MonthGroups = $CalendarData | Group-Object { 
                $date = [DateTime]::Parse($_.day)
                $date.ToString("yyyy-MM")
            }
            
            # First pass: determine all day keys needed
            $allDaysUsed = @()
            foreach ($monthGroup in $MonthGroups) {
                foreach ($entry in $monthGroup.Group) {
                    $date = [DateTime]::Parse($entry.day)
                    $dayOfMonth = $date.Day
                    $allDaysUsed += $dayOfMonth
                }
            }
            $dayKeys = ($allDaysUsed | Sort-Object -Unique) | ForEach-Object { "day$_" }
            
            # Second pass: create the data structure
            foreach ($monthGroup in $MonthGroups) {
                $monthData = @{ 
                    month = $monthGroup.Name
                }
                
                # Initialize all day keys with 0
                foreach ($dayKey in $dayKeys) {
                    $monthData[$dayKey] = 0
                }
                
                # Fill in actual data
                foreach ($entry in $monthGroup.Group) {
                    $date = [DateTime]::Parse($entry.day)
                    $dayOfMonth = $date.Day
                    $dayKey = "day$dayOfMonth"
                    if ($dayKeys -contains $dayKey) {
                        $monthData[$dayKey] = [int]$entry.value
                    }
                }
                
                $HeatmapData += $monthData
            }
            
            # Debug output
            Write-Information "Heatmap data created with $($HeatmapData.Count) months"
            Write-Information "Day keys: $($dayKeys -join ', ')"
            Write-Information "Sample month data: $($HeatmapData[0] | ConvertTo-Json -Compress)"
        } else {
            # Fallback empty data structure
            $dayKeys = @("day1", "day2", "day3", "day4", "day5")
            $HeatmapData = @(
                @{ month = "2025-01"; day1 = 0; day2 = 0; day3 = 0; day4 = 0; day5 = 0 }
            )
        }
        
        # Only render heatmap if we have valid data
        if ($HeatmapData.Count -gt 0 -and $dayKeys.Count -gt 0) {
            try {
                # Validate data structure before rendering
                $isValidData = $true
                foreach ($item in $HeatmapData) {
                    if (-not $item.ContainsKey('month')) {
                        $isValidData = $false
                        Write-Warning "Data item missing 'month' key"
                        break
                    }
                }
                
                if ($isValidData) {
                    New-UDNivoChart -Heatmap -Data $HeatmapData -IndexBy 'month' -Keys $dayKeys -Height 300 -Width 1200 -MarginTop 60 -MarginRight 50 -MarginBottom 60 -MarginLeft 100 -ForceSquare -Colors @('#f5f5f5', '#ffcccc', '#ffeb99', '#ffffcc', '#ccffcc', '#66ff66', '#00cc00')
                } else {
                    New-UDTypography -Text "Invalid data structure for heatmap" -Variant h6 -Align center -Style @{ marginTop = '40px'; color = '#ff6666' }
                }
            } catch {
                New-UDTypography -Text "Error rendering heatmap: $($_.Exception.Message)" -Variant h6 -Align center -Style @{ marginTop = '40px'; color = '#ff6666' }
                Write-Error "Heatmap rendering error: $($_.Exception.Message)"
            }
        } else {
            New-UDTypography -Text "No medication data available for heatmap visualization" -Variant h6 -Align center -Style @{ marginTop = '40px'; color = '#666' }
        }
        
        # Add a legend/summary
        New-UDTypography -Text "Heatmap Legend:" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px' }
        New-UDTypography -Text "• Each row represents a month, columns represent days of the month" -Variant body2
        New-UDTypography -Text "• 🔴 Red = Few medications (1-2)" -Variant body2
        New-UDTypography -Text "• 🟡 Yellow = Moderate medications (3-4)" -Variant body2
        New-UDTypography -Text "• 🟢 Green = Good adherence (5+ medications)" -Variant body2
        New-UDTypography -Text "• ⚪ Light gray = No medications recorded" -Variant body2
        
        # Display summary statistics
        if ($CalendarData.Count -gt 0) {
            $totalDaysWithMeds = $CalendarData.Count
            $avgMedsPerDay = [math]::Round(($CalendarData | Measure-Object -Property value -Average).Average, 1)
            $maxMedsInDay = ($CalendarData | Measure-Object -Property value -Maximum).Maximum
            
            New-UDTypography -Text "Summary Statistics:" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px' }
            New-UDTypography -Text "• Days with medication records: $totalDaysWithMeds" -Variant body2
            New-UDTypography -Text "• Average unique medications per day: $avgMedsPerDay" -Variant body2
            New-UDTypography -Text "• Maximum unique medications in a single day: $maxMedsInDay" -Variant body2
        }
    }
}
$Dashboard