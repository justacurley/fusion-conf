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
        
        if ($Meds) {
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
        # Convert calendar data to heatmap format (date vs medication count)
        $HeatmapData = @()
        if ($CalendarData.Count -gt 0) {
            # Group by week and day of week
            $WeekGroups = $CalendarData | Group-Object { 
                $date = [DateTime]::Parse($_.day)
                "Week " + (Get-Culture).Calendar.GetWeekOfYear($date, [System.Globalization.CalendarWeekRule]::FirstDay, [DayOfWeek]::Sunday)
            }
            
            foreach ($week in $WeekGroups) {
                $weekData = @{ id = $week.Name }
                
                # Initialize all days of week to 0
                $daysOfWeek = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
                foreach ($day in $daysOfWeek) {
                    $weekData[$day] = 0
                }
                
                # Fill in actual medication data
                foreach ($entry in $week.Group) {
                    $date = [DateTime]::Parse($entry.day)
                    $dayName = $date.DayOfWeek.ToString()
                    $weekData[$dayName] = $entry.value
                }
                
                $HeatmapData += $weekData
            }
        }
        
        New-UDNivoChart -Heatmap -Data $HeatmapData -IndexBy 'id' -Keys @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday') -Height 400 -Width 1000 -MarginTop 50 -MarginRight 130 -MarginBottom 50 -MarginLeft 100 -Colors @('nivo')
        
        # Add a legend/summary
        New-UDTypography -Text "Heatmap Legend:" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px' }
        New-UDTypography -Text "• Each row represents a week, columns represent days of the week" -Variant body2
        New-UDTypography -Text "• Light colors = Fewer unique medications taken" -Variant body2
        New-UDTypography -Text "• Dark colors = More unique medications taken" -Variant body2
        New-UDTypography -Text "• Empty/zero = No medications recorded" -Variant body2
        
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