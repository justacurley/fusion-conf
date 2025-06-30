$Dashboard = New-UDDashboard -Title "Medication Calendar Dashboard" -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Medication Adherence Calendar" -Variant h4 -Align center
        New-UDTypography -Text "Shows daily medication compliance - darker colors indicate more medications taken" -Variant body2 -Align center
        
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
            
            # Convert to DateTime objects properly and add some padding
            $From = [DateTime]::Parse($firstDate).AddDays(-7)  # Start a week before first data
            $To = [DateTime]::Parse($lastDate).AddDays(7)      # End a week after last data
            
            # Debug output (will show in browser console/logs)
            Write-Information "Date range: $From to $To"
            Write-Information "Total calendar data points: $($CalendarData.Count)"
        } else {
            # Fallback if no data
            $From = (Get-Date).AddDays(-365)
            $To = Get-Date
            Write-Information "No calendar data found, using fallback dates"
        }
        
        # Create the calendar chart
        New-UDNivoChart -Calendar -Data $CalendarData -From $From -To $To -Height 500 -Width 1000 -MarginTop 50 -MarginRight 130 -MarginBottom 50 -MarginLeft 60 -Colors @('nivo') -EmptyColor '#eeeeee'
        
        # Add a legend/summary
        New-UDTypography -Text "Calendar Legend:" -Variant h6 -Style @{ marginTop = '20px'; marginBottom = '10px' }
        New-UDTypography -Text "• Light colors = Fewer unique medications taken" -Variant body2
        New-UDTypography -Text "• Dark colors = More unique medications taken" -Variant body2
        New-UDTypography -Text "• Gray = No medications recorded" -Variant body2
        
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