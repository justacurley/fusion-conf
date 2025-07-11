$Dashboard = New-UDDashboard -Title 'Activity Timeline' -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    New-UDContainer -Content {
        New-UDTypography -Text 'Activity Progress Timeline' -Variant h4 -Align center
        
        New-UDDynamic -Content {
            
            $EntriesPath = '/home/data/fusion-data/entries/entries.json'
            try {
                $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
                New-UDAlert -Severity success -Text "Loaded data from: $EntriesPath"
            
                # Process data for activity timeline
                $activityItems = @()
                $dates = $entries.PSObject.Properties.Name | Sort-Object
                
                # Track personal records for each activity type
                $personalRecords = @{
                    'walking'  = 0
                    'stairs'   = 0
                    'standing' = 0
                }
                
                foreach ($date in $dates) {
                    $dateEntry = $entries.$date
                    
                    # Convert MMDD to readable date
                    $month = $date.Substring(0, 2)
                    $day = $date.Substring(2, 2)
                    $dateStr = "$month/$day"
                    
                    # Check all timestamps for this date
                    foreach ($timestamp in $dateEntry.PSObject.Properties.Name) {
                        if ($timestamp -match '^\d{4}$') {
                            # This is a timestamp
                            $entry = $dateEntry.$timestamp
                            
                            # Process Activities
                            if ($entry.PSObject.Properties['Activities']) {
                                foreach ($activityType in $entry.Activities.PSObject.Properties.Name) {
                                    $activityInfo = $entry.Activities.$activityType
                                    
                                    if ($activityInfo.PSObject.Properties['duration']) {
                                        $duration = [int]$activityInfo.duration
                                        
                                        # Check if this is a new personal record
                                        $isNewRecord = $false
                                        if ($personalRecords.ContainsKey($activityType)) {
                                            if ($duration -gt $personalRecords[$activityType]) {
                                                $personalRecords[$activityType] = $duration
                                                $isNewRecord = $true
                                            }
                                        } else {
                                            # New activity type
                                            $personalRecords[$activityType] = $duration
                                            $isNewRecord = $true
                                        }
                                        
                                        # Determine color and icon
                                        $color = 'info'  # default blue
                                        $icon = 'Walking'  # default
                                        $significance = @()
                                        
                                        # Activity-specific icons
                                        switch ($activityType) {
                                            'walking' { $icon = 'Walking' }
                                            'stairs' { $icon = 'ArrowUp' }
                                            'standing' { $icon = 'User' }
                                            default { $icon = 'Dumbbell' }
                                        }
                                        
                                        # Color coding
                                        if ($isNewRecord) {
                                            $color = 'success'  # Green for new records
                                            $significance += 'New Personal Record!'
                                        }
                                        
                                        # Add duration significance
                                        if ($duration -ge 30) {
                                            if ($color -eq 'info') {
                                                $color = 'warning'  # Orange for longer sessions
                                            }
                                            $significance += 'Extended session'
                                        }
                                        
                                        # Format time (convert 24hr to 12hr)
                                        $hour = [int]$timestamp.Substring(0, 2)
                                        $minute = $timestamp.Substring(2, 2)
                                        $timeStr = if ($hour -eq 0) {
                                            "12:${minute} AM"
                                        } elseif ($hour -lt 12) {
                                            "${hour}:${minute} AM"
                                        } elseif ($hour -eq 12) {
                                            "12:${minute} PM"
                                        } else {
                                            $displayHour = $hour - 12
                                            "${displayHour}:${minute} PM"
                                        }
                                        
                                        # Build content string
                                        $contentParts = @()
                                        $contentParts += "$($activityType.ToUpper()): ${duration} minutes"
                                        
                                        if ($significance.Count -gt 0) {
                                            $contentParts += '🎉 ' + ($significance -join ', ')
                                        }
                                        
                                        # Add notes if available
                                        if ($activityInfo.PSObject.Properties['note'] -and $activityInfo.note -ne '') {
                                            $contentParts += "Note: $($activityInfo.note)"
                                        }
                                        
                                        $content = $contentParts -join ' | '
                                        
                                        # Add to timeline
                                        $activityItems += [PSCustomObject]@{
                                            DateTime     = "$dateStr $timeStr"
                                            Content      = $content
                                            Color        = $color
                                            Icon         = $icon
                                            SortDateTime = "${date}${timestamp}"
                                            ActivityType = $activityType
                                            Duration     = $duration
                                            IsRecord     = $isNewRecord
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                if ($activityItems.Count -eq 0) {
                    New-UDAlert -Severity warning -Text 'No activity data found for timeline'
                    return
                }
                
                # Sort timeline items chronologically (most recent first)
                $activityItems = $activityItems | Sort-Object SortDateTime -Descending
                
                # Create timeline
                New-UDTimeline -Position alternate -Children {
                    foreach ($item in $activityItems) {
                        New-UDTimelineItem -Content {
                            New-UDTypography -Text $item.Content -Variant body1
                        } -OppositeContent {
                            New-UDTypography -Text $item.DateTime -Variant body2 -Style @{fontWeight = 'bold' }
                        } -Color $item.Color -Icon (New-UDIcon -Icon $item.Icon)
                    }
                }
                
                # Add summary statistics
                New-UDRow -Columns {
                    New-UDColumn -Size 6 -Content {
                        New-UDCard -Title 'Activity Summary' -Content {
                            $totalActivities = $activityItems.Count
                            $newRecords = ($activityItems | Where-Object { $_.IsRecord }).Count
                            $walkingSessions = ($activityItems | Where-Object { $_.ActivityType -eq 'walking' }).Count
                            $stairsSessions = ($activityItems | Where-Object { $_.ActivityType -eq 'stairs' }).Count
                            $standingSessions = ($activityItems | Where-Object { $_.ActivityType -eq 'standing' }).Count
                            
                            New-UDElement -Tag 'div' -Content {
                                New-UDTypography -Text "Total activity sessions: $totalActivities" -Variant h6
                                New-UDTypography -Text "New personal records: $newRecords" -Variant h6
                                New-UDTypography -Text "Walking sessions: $walkingSessions" -Variant h6
                                New-UDTypography -Text "Stairs sessions: $stairsSessions" -Variant h6
                                New-UDTypography -Text "Standing sessions: $standingSessions" -Variant h6
                            }
                        }
                    }
                    
                    New-UDColumn -Size 6 -Content {
                        New-UDCard -Title 'Personal Records' -Content {
                            New-UDElement -Tag 'div' -Content {
                                foreach ($activityType in $personalRecords.Keys | Sort-Object) {
                                    $record = $personalRecords[$activityType]
                                    if ($record -gt 0) {
                                        New-UDTypography -Text "$($activityType.ToUpper()): $record minutes" -Variant h6
                                    }
                                }
                            }
                        }
                    }
                }
                
            } catch {
                New-UDAlert -Severity error -Text "Error loading entries data: $($_.Exception.Message)"
            }
        } -Id 'activity-timeline-data'
        
        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                New-UDButton -Text 'Refresh Timeline' -OnClick {
                    Sync-UDElement -Id 'activity-timeline-data'
                } -Color primary
            }
        }
    }
}

# Return the dashboard
$Dashboard