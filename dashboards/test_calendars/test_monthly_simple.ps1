# Alternative approach: Use monthly totals instead of weeks
$Dashboard = New-UDDashboard -Title "Medication Monthly Heatmap" -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Monthly Medication Summary" -Variant h4 -Align center
        
        # Get medication data
        $Meds = Get-PSUCache -Key 'medicationData' | Select-Object Date, Timestamp, Medication
        
        # Process into monthly totals
        $MonthlyData = @()
        
        if ($Meds -and $Meds.Count -gt 0) {
            Write-Information "Processing $($Meds.Count) medication entries for monthly view"
            
            # Group by month and calculate totals
            $MonthGroups = $Meds | Group-Object { 
                try {
                    $currentYear = (Get-Date).Year
                    $parsedDate = [DateTime]::ParseExact("$currentYear/$($_.Date)", "yyyy/MM/dd", $null)
                    $parsedDate.ToString("yyyy-MM")
                } catch {
                    "Unknown"
                }
            } | Where-Object { $_.Name -ne "Unknown" }
            
            foreach ($monthGroup in $MonthGroups) {
                # Count unique medications and total entries
                $uniqueMeds = ($monthGroup.Group | Select-Object -Unique Medication).Count
                $totalEntries = $monthGroup.Count
                $daysWithMeds = ($monthGroup.Group | Group-Object Date).Count
                $avgMedsPerDay = if ($daysWithMeds -gt 0) { [math]::Round($totalEntries / $daysWithMeds, 1) } else { 0 }
                
                $MonthlyData += @{
                    month = $monthGroup.Name
                    unique_meds = $uniqueMeds
                    total_entries = $totalEntries
                    days_with_meds = $daysWithMeds
                    avg_per_day = $avgMedsPerDay
                }
            }
            
            Write-Information "Created monthly data for $($MonthlyData.Count) months"
            Write-Information "Sample: $($MonthlyData[0] | ConvertTo-Json -Compress)"
            
            # Create heatmap with monthly data
            try {
                New-UDNivoChart -Heatmap -Data $MonthlyData -IndexBy 'month' -Keys @('unique_meds', 'total_entries', 'days_with_meds', 'avg_per_day') -Height 300 -Width 800 -MarginTop 60 -MarginRight 50 -MarginBottom 60 -MarginLeft 100 -Colors @('#f5f5f5', '#ffcccc', '#ffeb99', '#ffffcc', '#ccffcc', '#66ff66', '#00cc00')
                
                New-UDTypography -Text "✅ Monthly heatmap rendered successfully" -Variant h6 -Style @{ marginTop = '20px'; color = 'green' }
                
                # Legend
                New-UDTypography -Text "Columns:" -Variant h6 -Style @{ marginTop = '20px' }
                New-UDTypography -Text "• unique_meds: Number of different medications" -Variant body2
                New-UDTypography -Text "• total_entries: Total medication entries" -Variant body2
                New-UDTypography -Text "• days_with_meds: Days with any medication" -Variant body2
                New-UDTypography -Text "• avg_per_day: Average medications per day" -Variant body2
                
            } catch {
                New-UDTypography -Text "❌ Error: $($_.Exception.Message)" -Variant h6 -Style @{ color = 'red' }
            }
        } else {
            New-UDTypography -Text "No medication data found" -Variant h6 -Align center
        }
    }
}
$Dashboard
