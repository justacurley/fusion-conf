$Dashboard = New-UDDashboard -Title "Medication Heatmap Dashboard" -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Medication Adherence Heatmap" -Variant h4 -Align center
        New-UDTypography -Text "Shows weekly medication patterns - darker colors indicate more medications taken" -Variant body2 -Align center
        New-UDTypography -Text "Heatmap displays months vs weeks with total medication counts per week" -Variant caption -Align center -Style @{ fontStyle = 'italic'; marginBottom = '20px' }
        
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
        # Convert calendar data to heatmap format with limited columns for better rendering
        $HeatmapData = @()
        $dayKeys = @()
        
        if ($CalendarData.Count -gt 0) {
            # Group by month to create a proper heatmap structure
            $MonthGroups = $CalendarData | Group-Object { 
                $date = [DateTime]::Parse($_.day)
                $date.ToString("yyyy-MM")
            }
            
            # Limit to a reasonable number of day columns (weeks of month)
            # Group days into weeks instead of individual days
            foreach ($monthGroup in $MonthGroups) {
                $monthData = @{ 
                    month = $monthGroup.Name
                    week1 = 0
                    week2 = 0
                    week3 = 0
                    week4 = 0
                    week5 = 0
                }
                
                # Assign days to weeks and sum medication counts
                foreach ($entry in $monthGroup.Group) {
                    $date = [DateTime]::Parse($entry.day)
                    $dayOfMonth = $date.Day
                    $weekNum = [math]::Ceiling($dayOfMonth / 7)
                    
                    switch ($weekNum) {
                        1 { $monthData.week1 += [int]$entry.value }
                        2 { $monthData.week2 += [int]$entry.value }
                        3 { $monthData.week3 += [int]$entry.value }
                        4 { $monthData.week4 += [int]$entry.value }
                        default { $monthData.week5 += [int]$entry.value }
                    }
                }
                
                $HeatmapData += $monthData
            }
            
            $dayKeys = @('week1', 'week2', 'week3', 'week4', 'week5')
            
            # Debug output
            Write-Information "Heatmap data created with $($HeatmapData.Count) months using week-based grouping"
            Write-Information "Week keys: $($dayKeys -join ', ')"
            Write-Information "Sample month data: $($HeatmapData[0] | ConvertTo-Json -Compress)"
        } else {
            # Fallback empty data structure
            $dayKeys = @('week1', 'week2', 'week3', 'week4', 'week5')
            $HeatmapData = @(
                @{ month = "2025-01"; week1 = 0; week2 = 0; week3 = 0; week4 = 0; week5 = 0 }
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
        New-UDTypography -Text "• Each row represents a month, columns represent weeks of the month" -Variant body2
        New-UDTypography -Text "• 🔴 Red = Low medication adherence (1-10 total medications)" -Variant body2
        New-UDTypography -Text "• 🟡 Yellow = Moderate adherence (11-20 total medications)" -Variant body2
        New-UDTypography -Text "• 🟢 Green = Good adherence (21+ total medications)" -Variant body2
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