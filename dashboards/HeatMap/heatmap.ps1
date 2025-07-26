New-UDApp -Content {
    Import-Module UserManagement -Force
    Import-Module GetFusion -Force

    $UserData = Initialize-UserContext -UserEmail $User

    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text '🔥 Health Entry Activity Heatmap' -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = '#1976d2'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Visual overview of your complete health tracking activity - darker colors indicate more entries' -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = '#666'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '20px'; backgroundColor = '#f8f9fa' }

        # Auto-Generate Heatmap
        New-UDCard -Title '� Your Health Activity Overview' -Content {
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDButton -Text '� Generate Activity Heatmap' -Color primary -FullWidth -Size large -OnClick {
                        try {
                            # Load user's entries
                            Import-Module UserManagement -Force
                            $UserData = Initialize-UserContext -UserEmail $User
                            $AllEntries = if ($UserData.Entries) {
                                $UserData.Entries
                            }
                            elseif (Test-Path $UserData.EntriesPath) {
                                Get-Content $UserData.EntriesPath -Raw | ConvertFrom-Json
                            }
                            else {
                                Show-UDToast -Message "⚠️ No entries file found. Create some health entries first." -MessageColor Orange -Duration 4000
                                Set-UDElement -Id 'heatmapContainer' -Content {
                                    New-UDAlert -Severity warning -Text "No health entries found. Please create some entries to view the heatmap."
                                }
                                return
                            }

                            if (-not $AllEntries -or $AllEntries.Count -eq 0) {
                                Show-UDToast -Message "⚠️ No entries found" -MessageColor Orange -Duration 4000
                                Set-UDElement -Id 'heatmapContainer' -Content {
                                    New-UDAlert -Severity info -Text "No health entries found. Please create some entries to view the heatmap."
                                }
                                return
                            }

                            # Automatically determine date range from data
                            $FromTo = $AllEntries | Measure-Object -Property Date -Maximum -Minimum
                            $fromDate = [datetime]::Parse($FromTo.Minimum)
                            $toDate = [datetime]::Parse($FromTo.Maximum)

                            # Create a hashtable to count entries per day
                            $dailyCounts = @{}

                            # Process each entry
                            foreach ($entry in $AllEntries) {
                                try {
                                    $entryDate = [datetime]::Parse($entry.date)
                                    $dateKey = $entryDate.ToString('yyyy-MM-dd')

                                    if ($dailyCounts.ContainsKey($dateKey)) {
                                        $dailyCounts[$dateKey]++
                                    }
                                    else {
                                        $dailyCounts[$dateKey] = 1
                                    }
                                }
                                catch {
                                    Write-Warning "Could not parse date for entry: $($entry.date)"
                                }
                            }

                            # Prepare data for calendar heatmap
                            $calendarData = @()
                            foreach ($dateKey in $dailyCounts.Keys) {
                                $calendarData += @{
                                    day   = $dateKey
                                    value = $dailyCounts[$dateKey]
                                }
                            }

                            # Calculate statistics
                            $totalEntries = ($dailyCounts.Values | Measure-Object -Sum).Sum
                            $activeDays = $dailyCounts.Keys.Count
                            $maxEntriesPerDay = if ($dailyCounts.Values.Count -gt 0) { ($dailyCounts.Values | Measure-Object -Maximum).Maximum } else { 0 }
                            $avgEntriesPerDay = if ($activeDays -gt 0) { [math]::Round($totalEntries / $activeDays, 2) } else { 0 }

                            # Create the calendar heatmap
                            Set-UDElement -Id 'heatmapContainer' -Content {
                                New-UDGrid -Container -Children {
                                    # Statistics cards
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        New-UDGrid -Container -Spacing 2 -Children {
                                            New-UDGrid -Item -ExtraSmallSize 3 -Children {
                                                New-UDCard -Content {
                                                    New-UDTypography -Text "$totalEntries" -Variant h4 -Style @{ color = '#1976d2'; textAlign = 'center'; fontWeight = 'bold' }
                                                    New-UDTypography -Text "Total Entries" -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
                                                } -Style @{ padding = '15px'; textAlign = 'center' }
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 3 -Children {
                                                New-UDCard -Content {
                                                    New-UDTypography -Text "$activeDays" -Variant h4 -Style @{ color = '#388e3c'; textAlign = 'center'; fontWeight = 'bold' }
                                                    New-UDTypography -Text "Active Days" -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
                                                } -Style @{ padding = '15px'; textAlign = 'center' }
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 3 -Children {
                                                New-UDCard -Content {
                                                    New-UDTypography -Text "$maxEntriesPerDay" -Variant h4 -Style @{ color = '#f57c00'; textAlign = 'center'; fontWeight = 'bold' }
                                                    New-UDTypography -Text "Max Per Day" -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
                                                } -Style @{ padding = '15px'; textAlign = 'center' }
                                            }
                                            New-UDGrid -Item -ExtraSmallSize 3 -Children {
                                                New-UDCard -Content {
                                                    New-UDTypography -Text "$avgEntriesPerDay" -Variant h4 -Style @{ color = '#7b1fa2'; textAlign = 'center'; fontWeight = 'bold' }
                                                    New-UDTypography -Text "Avg Per Day" -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
                                                } -Style @{ padding = '15px'; textAlign = 'center' }
                                            }
                                        }
                                    } -Style @{ marginBottom = '20px' }

                                    # Calendar heatmap
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        if ($calendarData.Count -gt 0) {
                                            # Add date range info
                                            New-UDTypography -Text "📅 Showing data from $($fromDate.ToString('MMMM dd, yyyy')) to $($toDate.ToString('MMMM dd, yyyy'))" -Variant body2 -Style @{
                                                textAlign = 'center'
                                                marginBottom = '15px'
                                                color = '#666'
                                                fontStyle = 'italic'
                                            }

                                            New-UDNivoChart -Calendar -Data $calendarData -From $fromDate -To $toDate `
                                                -Height 400 -Width 1200 -MarginTop 50 -MarginRight 130 -MarginBottom 50 `
                                                -MarginLeft 60 -MonthSpacing 10 -DaySpacing 5 -OnClick {
                                                    # EventData is already a PowerShell object, not JSON
                                                    if ($EventData.day) {
                                                        $entryCount = $EventData.value
                                                        $clickedDate = [datetime]::Parse($EventData.day).ToString('MMMM dd, yyyy')
                                                        Show-UDToast -Message "📅 $clickedDate - $entryCount entries" -MessageColor Blue -Duration 3000
                                                    }
                                                }
                                        }
                                        else {
                                            New-UDAlert -Severity info -Text "No data available. Create some health entries to view the heatmap."
                                        }
                                    }

                                    # Color legend
                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                        New-UDCard -Title '🌈 Color Legend' -Content {
                                            New-UDTypography -Text "The color intensity represents the number of health entries per day:" -Variant body1 -Style @{ marginBottom = '10px' }
                                            New-UDList -Children {
                                                New-UDListItem -Label "⬜ Light: Few entries (1-2 per day)"
                                                New-UDListItem -Label "🟨 Medium: Moderate activity (3-5 per day)"
                                                New-UDListItem -Label "🟧 Dark: High activity (6-10 per day)"
                                                New-UDListItem -Label "🟥 Darkest: Very high activity (10+ per day)"
                                                New-UDListItem -Label "⬛ No color: No entries for that day"
                                            }
                                        } -Style @{ marginTop = '20px' }
                                    }
                                }
                            }

                            Show-UDToast -Message "📊 Heatmap generated successfully! Found $totalEntries entries across $activeDays days from $($fromDate.ToString('MMM yyyy')) to $($toDate.ToString('MMM yyyy'))." -MessageColor Green -Duration 5000

                        }
                        catch {
                            Show-UDToast -Message "❌ Error generating heatmap: $($_.Exception.Message)" -MessageColor Red -Duration 6000
                            Write-Error "Error generating heatmap: $($_.Exception.Message)"
                        }
                    }
                }
            }

            New-UDTypography -Text '💡 Click the button above to automatically generate your complete health activity heatmap' -Variant caption -Style @{
                marginTop = '15px'
                color     = '#666'
                fontStyle = 'italic'
                textAlign = 'center'
            }
        } -Style @{ marginBottom = '20px' }

        # Heatmap Container
        New-UDElement -Id 'heatmapContainer' -Tag 'div' -Content {
            New-UDCard -Content {
                New-UDTypography -Text '👆 Click "Generate Activity Heatmap" to view your complete health tracking activity' -Variant body1 -Style @{
                    textAlign = 'center'
                    color     = '#999'
                    margin    = '40px 0'
                    fontStyle = 'italic'
                }
            }
        }

        # Help Section
        New-UDCard -Title 'ℹ️ About the Health Activity Heatmap' -Content {
            New-UDList -Children {
                New-UDListItem -Label '📊 The heatmap automatically shows your complete health tracking history'
                New-UDListItem -Label '🔥 Darker red colors indicate days with more health entries'
                New-UDListItem -Label '📅 Click on any day in the heatmap to see the exact number of entries'
                New-UDListItem -Label '📈 Use the statistics cards to understand your tracking patterns'
                New-UDListItem -Label '🤖 Fully automated - no date selection needed, shows all your data'
                New-UDListItem -Label '🎯 Aim for consistent daily tracking to maintain good health visibility'
                New-UDListItem -Label '💡 Gaps in the heatmap might indicate days you could improve your tracking'
                New-UDListItem -Label '🏆 Regular patterns show good health monitoring habits'
            }
        } -Style @{ marginTop = '30px'; backgroundColor = '#f0f8ff' }
    }
}
