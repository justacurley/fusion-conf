$Dashboard = New-UDDashboard -Title 'Health Timeline' -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    New-UDContainer -Content {
        New-UDTypography -Text 'Health Event Timeline' -Variant h4 -Align center

        New-UDDynamic -Content {

            $EntriesPath = Join-Path $UserData.UserDataPath 'health-data/entries.json'
            try {
                $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
                New-UDAlert -Severity success -Text "Loaded data from: $EntriesPath"

                # Process data for timeline
                $timelineItems = @()
                $dates = $entries.PSObject.Properties.Name | Sort-Object -Descending
                $previousPainLevel = $null
                $previousDilaudid = 0
                $previousValium = 0

                foreach ($date in $dates) {
                    $dateEntry = $entries.$date

                    # Skip if no max_pain_level (incomplete day)
                    if (-not $dateEntry.PSObject.Properties['max_pain_level']) {
                        continue
                    }

                    $maxPain = [double]$dateEntry.max_pain_level

                    # Convert MMDD to readable date
                    $month = $date.Substring(0, 2)
                    $day = $date.Substring(2, 2)
                    $dateStr = "$month/$day"

                    # Calculate daily medication totals
                    $totalDilaudid = 0
                    $totalValium = 0
                    $importantNotes = @()

                    # Check all timestamps for this date
                    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
                        if ($timestamp -match '^\d{4}$') {
                            # This is a timestamp
                            $entry = $dateEntry.$timestamp

                            # Process Medications
                            if ($entry.PSObject.Properties['Medications']) {
                                foreach ($medication in $entry.Medications.PSObject.Properties.Name) {
                                    if ($medication -eq 'dilaudid') {
                                        $dose = $entry.Medications.$medication
                                        if ($dose -match '(\d+(?:\.\d+)?)') {
                                            $dilaudidAmount = [double]$matches[1]
                                            $totalDilaudid += $dilaudidAmount
                                        }
                                    } elseif ($medication -eq 'valium') {
                                        $dose = $entry.Medications.$medication
                                        if ($dose -match '(\d+(?:\.\d+)?)') {
                                            $valiumAmount = [double]$matches[1]
                                            $totalValium += $valiumAmount
                                        }
                                    }
                                }
                            }

                            # Collect important notes
                            if ($entry.PSObject.Properties['note'] -and $entry.note -ne '') {
                                $importantNotes += $entry.note
                            }
                        }
                    }

                    # Determine event significance and color
                    $color = 'grey'  # default
                    $icon = 'Calendar'  # default
                    $significance = @()

                    # Pain level analysis
                    if ($maxPain -ge 7.0) {
                        $color = 'error'
                        $icon = 'ExclamationTriangle'
                        $significance += 'High pain day'
                    } elseif ($maxPain -le 3.5) {
                        $color = 'success'
                        $icon = 'CheckCircle'
                        $significance += 'Low pain day'
                    } elseif ($previousPainLevel -ne $null) {
                        $painChange = $maxPain - $previousPainLevel
                        if ($painChange -ge 2.0) {
                            $color = 'error'
                            $icon = 'ArrowUp'
                            $significance += 'Pain increased significantly'
                        } elseif ($painChange -le -2.0) {
                            $color = 'success'
                            $icon = 'ArrowDown'
                            $significance += 'Pain decreased significantly'
                        }
                    }

                    # Medication change analysis
                    $dilaudidChange = $totalDilaudid - $previousDilaudid
                    $valiumChange = $totalValium - $previousValium

                    if ($dilaudidChange -ge 4) {
                        $color = 'info'
                        $icon = 'Pills'
                        $significance += 'Dilaudid increased'
                    } elseif ($dilaudidChange -le -4) {
                        $color = 'info'
                        $icon = 'Pills'
                        $significance += 'Dilaudid decreased'
                    }

                    if ($valiumChange -ne 0) {
                        $color = 'info'
                        $icon = 'Pills'
                        if ($valiumChange -gt 0) {
                            $significance += 'Valium resumed'
                        } else {
                            $significance += 'Valium stopped'
                        }
                    }

                    # Check for important notes
                    $significantNotes = $importantNotes | Where-Object {
                        $_ -match 'dizzy|valium|stop|changed|feel|breakthrough'
                    }
                    if ($significantNotes.Count -gt 0) {
                        if ($color -eq 'grey') {
                            $color = 'info'
                            $icon = 'StickyNote'
                        }
                        $significance += 'Important notes'
                    }

                    # Build content string
                    $contentParts = @()
                    $contentParts += "Pain: $maxPain"

                    if ($totalDilaudid -gt 0) {
                        $contentParts += "Dilaudid: ${totalDilaudid}mg"
                    }
                    if ($totalValium -gt 0) {
                        $contentParts += "Valium: ${totalValium}mg"
                    }

                    if ($significance.Count -gt 0) {
                        $contentParts += '• ' + ($significance -join ', ')
                    }

                    if ($significantNotes.Count -gt 0) {
                        $contentParts += 'Notes: ' + ($significantNotes -join '; ')
                    }

                    $content = $contentParts -join ' | '

                    # Only add to timeline if there's something significant or it's recent
                    $shouldInclude = $significance.Count -gt 0 -or $significantNotes.Count -gt 0 -or $maxPain -ge 6.0 -or $maxPain -le 4.0

                    if ($shouldInclude) {
                        $timelineItems += [PSCustomObject]@{
                            Date     = $dateStr
                            Content  = $content
                            Color    = $color
                            Icon     = $icon
                            SortDate = $date
                        }
                    }

                    # Update previous values for next iteration
                    $previousPainLevel = $maxPain
                    $previousDilaudid = $totalDilaudid
                    $previousValium = $totalValium
                }

                if ($timelineItems.Count -eq 0) {
                    New-UDAlert -Severity warning -Text 'No significant events found for timeline'
                    return
                }

                # Sort timeline items chronologically (most recent first)
                $timelineItems = $timelineItems | Sort-Object SortDate -Descending

                # Create timeline
                New-UDTimeline -Position alternate -Children {
                    foreach ($item in $timelineItems) {
                        New-UDTimelineItem -Content {
                            New-UDTypography -Text $item.Content -Variant body1
                        } -OppositeContent {
                            New-UDTypography -Text $item.Date -Variant body2 -Style @{fontWeight = 'bold' }
                        } -Color $item.Color -Icon (New-UDIcon -Icon $item.Icon)
                    }
                }

                # Add summary statistics
                New-UDRow -Columns {
                    New-UDColumn -Size 12 -Content {
                        New-UDCard -Title 'Timeline Summary' -Content {
                            $totalEvents = $timelineItems.Count
                            $highPainDays = ($timelineItems | Where-Object { $_.Content -match 'High pain day' }).Count
                            $lowPainDays = ($timelineItems | Where-Object { $_.Content -match 'Low pain day' }).Count
                            $medChanges = ($timelineItems | Where-Object { $_.Content -match 'Dilaudid|Valium' -and $_.Content -match 'increased|decreased|stopped|resumed' }).Count

                            New-UDElement -Tag 'div' -Content {
                                New-UDTypography -Text "Total significant events: $totalEvents" -Variant h6
                                New-UDTypography -Text "High pain days: $highPainDays" -Variant h6
                                New-UDTypography -Text "Low pain days: $lowPainDays" -Variant h6
                                New-UDTypography -Text "Medication changes: $medChanges" -Variant h6
                            }
                        }
                    }
                }

            } catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
            }
        } -Id 'timeline-data'

        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                New-UDButton -Text 'Refresh Timeline' -OnClick {
                    Sync-UDElement -Id 'timeline-data'
                } -Color primary
            }
        }
    }
}

# Return the dashboard
$Dashboard
