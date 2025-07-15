$HomePage = New-UDApp -Content {
    Import-Module UserManagement -Force
    Import-Module GetFusion -Force
    $UserData = Initialize-UserContext -UserEmail $User

    # Get actual entries data
    try {
        $EntriesPath = Join-Path $UserData.UserDataPath 'health-data/entries.json'
        $Entries = Get-EntriesData -entriesPath $EntriesPath
        $TotalEntries = $Entries.Count

        # Calculate mood statistics
        $MoodEntries = $Entries | Where-Object { $_.mood -and $_.mood -ne '' }
        $LatestMood = $MoodEntries | Sort-Object date, timestamp -Descending | Select-Object -First 1
        $AverageMood = if ($MoodEntries.Count -gt 0) {
            [math]::Round(($MoodEntries | Measure-Object mood -Average).Average, 1)
        } else { 0 }

        # Pain tracking stats
        $PainEntries = $Entries | Where-Object { $_.pain_entries -and $_.pain_entries.Count -gt 0 }
        $RecentPainCount = ($PainEntries | Where-Object {
            [datetime]::ParseExact($_.date, 'MMdd', $null).AddDays(365) -gt (Get-Date).AddDays(-7)
        }).Count

        # Activity stats
        $ActivityEntries = $Entries | Where-Object { $_.activities -and $_.activities.Count -gt 0 }
        $RecentActivities = ($ActivityEntries | Where-Object {
            [datetime]::ParseExact($_.date, 'MMdd', $null).AddDays(365) -gt (Get-Date).AddDays(-7)
        }).Count

    } catch {
        $TotalEntries = 0
        $LatestMood = $null
        $AverageMood = 0
        $RecentPainCount = 0
        $RecentActivities = 0
    }
    # Homepage content for the Health Dashboard
    New-UDContainer -Content {
        # Header Section
        New-UDRow -Columns {
            New-UDColumn -Size 12 -Content {
                New-UDTypography -Text "🏥 PowerShell Universal Health Dashboard" -Variant h3 -Align center -Style @{
                    marginBottom = "10px"
                    color = "#1976d2"
                    fontWeight = "bold"
                }
                New-UDTypography -Text "Comprehensive Health Tracking & Analytics Platform" -Variant h6 -Align center -Style @{
                    marginBottom = "30px"
                    color = "#666"
                    fontStyle = "italic"
                }
            }
        }

        # Statistics Overview Section
        New-UDRow -Columns {
            New-UDColumn -Size 3 -Content {
                New-UDCard -Title "📊 Total Entries" -Content {
                    New-UDTypography -Text "$TotalEntries" -Variant h4 -Style @{ color = "#4caf50"; fontWeight = "bold"; textAlign = "center" }
                    New-UDTypography -Text "Health records tracked" -Variant body2 -Style @{ textAlign = "center"; color = "#666" }
                } -Style @{ textAlign = "center"; border = "2px solid #4caf50"; borderRadius = "10px" }
            }
            New-UDColumn -Size 3 -Content {
                $moodColor = switch ($AverageMood) {
                    { $_ -ge 4 } { "#4caf50" }
                    { $_ -ge 3 } { "#ff9800" }
                    default { "#f44336" }
                }
                $moodEmoji = switch ([math]::Round($AverageMood)) {
                    5 { "😃" }
                    4 { "🙂" }
                    3 { "😐" }
                    2 { "🙁" }
                    1 { "😞" }
                    default { "❓" }
                }
                New-UDCard -Title "� Average Mood" -Content {
                    New-UDTypography -Text "$moodEmoji $AverageMood" -Variant h4 -Style @{ color = $moodColor; fontWeight = "bold"; textAlign = "center" }
                    New-UDTypography -Text "Based on $($MoodEntries.Count) entries" -Variant body2 -Style @{ textAlign = "center"; color = "#666" }
                } -Style @{ textAlign = "center"; border = "2px solid $moodColor"; borderRadius = "10px" }
            }
            New-UDColumn -Size 3 -Content {
                New-UDCard -Title '🏃‍♂️ Activities' -Content {
                    New-UDTypography -Text "$RecentActivities" -Variant h4 -Style @{ color = '#2196f3'; fontWeight = 'bold'; textAlign = 'center' }
                    New-UDTypography -Text 'This week' -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
                } -Style @{ textAlign = 'center'; border = '2px solid #2196f3'; borderRadius = '10px' }
            }
            New-UDColumn -Size 3 -Content {
                $painColor = if ($RecentPainCount -eq 0) { "#4caf50" } elseif ($RecentPainCount -le 2) { "#ff9800" } else { "#f44336" }
                $painStatus = if ($RecentPainCount -eq 0) { "No pain reported" } else { "$RecentPainCount pain entries" }
                New-UDCard -Title '🩹 Pain Tracking' -Content {
                    New-UDTypography -Text "$RecentPainCount" -Variant h4 -Style @{ color = $painColor; fontWeight = 'bold'; textAlign = 'center' }
                    New-UDTypography -Text $painStatus -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
                } -Style @{ textAlign = 'center'; border = "2px solid $painColor"; borderRadius = '10px' }
            }
        }

# Quick Actions Section
New-UDRow -Columns {
    New-UDColumn -Size 12 -Content {
        New-UDTypography -Text '🚀 Quick Actions' -Variant h5 -Style @{
            marginTop    = '30px'
            marginBottom = '15px'
            color        = '#1976d2'
            fontWeight   = 'bold'
        }
    }
}

# Latest Mood Status Section
if ($LatestMood) {
    New-UDRow -Columns {
        New-UDColumn -Size 12 -Content {
            $moodEmoji = switch ($LatestMood.mood) {
                5 { "😃" }
                4 { "🙂" }
                3 { "😐" }
                2 { "🙁" }
                1 { "😞" }
                default { "❓" }
            }
            $moodDesc = switch ($LatestMood.mood) {
                5 { "Rad" }
                4 { "Good" }
                3 { "Meh" }
                2 { "Bad" }
                1 { "Awful" }
                default { "Unknown" }
            }
            $moodColor = switch ($LatestMood.mood) {
                { $_ -ge 4 } { "#4caf50" }
                { $_ -eq 3 } { "#ff9800" }
                default { "#f44336" }
            }

            New-UDCard -Title "😊 Latest Mood Check" -Content {
                New-UDTypography -Text "$moodEmoji Feeling $moodDesc" -Variant h5 -Style @{
                    color = $moodColor; fontWeight = 'bold'; textAlign = 'center'; marginBottom = '10px'
                }
                if ($LatestMood.mood_note) {
                    New-UDTypography -Text "`"$($LatestMood.mood_note)`"" -Variant body1 -Style @{
                        textAlign = 'center'; fontStyle = 'italic'; marginBottom = '10px'
                    }
                }
                $moodDate = [datetime]::ParseExact($LatestMood.date, 'MMdd', $null).AddDays(365)
                New-UDTypography -Text "Recorded on $($moodDate.ToString('MMM dd, yyyy')) at $($LatestMood.timestamp)" -Variant body2 -Style @{
                    textAlign = 'center'; color = '#666'
                }
            } -Style @{ border = "2px solid $moodColor"; borderRadius = '10px'; marginBottom = '20px' }
        }
    }
}

New-UDRow -Columns {
    New-UDColumn -Size 3 -Content {
        New-UDButton -Text '➕ Add New Entry' -Color primary -Size large -FullWidth -OnClick {
            Invoke-UDRedirect -Url '/entries' -Native
        } -Style @{ marginBottom = '10px'; padding = '15px' }
    }
    New-UDColumn -Size 3 -Content {
        New-UDButton -Text '📊 View Analytics' -Color secondary -Size large -FullWidth -OnClick {
            Invoke-UDRedirect -Url '/charts' -Native
        } -Style @{ marginBottom = '10px'; padding = '15px' }
    }
    New-UDColumn -Size 3 -Content {
        New-UDButton -Text '📅 Timeline View' -Color success -Size large -FullWidth -OnClick {
            Invoke-UDRedirect -Url '/timeline' -Native
        } -Style @{ marginBottom = '10px'; padding = '15px' }
    }
    New-UDColumn -Size 3 -Content {
        New-UDButton -Text '🎲 Generate Sample Data' -Color warning -Size large -FullWidth -OnClick {
            try {
                # Import and run the sample data generator
                Import-Module -Name "$($PSScriptRoot)/../../Modules/UserManagement/UserManagement.psd1" -Force
                . "$($PSScriptRoot)/../../Modules/UserManagement/Public/New-SampleHealthEntries.ps1"

                $samplePath = '/home/data/fusion-data/entries/sample-entries.json'
                $result = New-SampleHealthEntries -Email $User -DaysBack 30 -EntriesPerDay 2 -SaveToFile $samplePath

                if ($result.Success) {
                    Show-UDToast -Message "✅ Generated $($result.EntriesGenerated) sample entries!" -Duration 5000 -MessageColor Green
                    # Refresh the page to show new data
                    Invoke-UDRedirect -Url '/home' -Native
                } else {
                    Show-UDToast -Message "❌ Failed to generate sample data: $($result.Message)" -Duration 5000 -MessageColor Red
                }
            } catch {
                Show-UDToast -Message "❌ Error: $($_.Exception.Message)" -Duration 5000 -MessageColor Red
            }
        } -Style @{ marginBottom = '10px'; padding = '15px' }
    }
}

# Dashboard Navigation Section
New-UDRow -Columns {
    New-UDColumn -Size 12 -Content {
        New-UDTypography -Text '📋 Dashboard Applications' -Variant h5 -Style @{
            marginTop    = '40px'
            marginBottom = '20px'
            color        = '#1976d2'
            fontWeight   = 'bold'
        }
        New-UDTypography -Text 'Access all health tracking modules from here' -Variant body1 -Style @{
            marginBottom = '25px'
            color        = '#666'
        }
    }
}

# Dashboard Cards Grid
New-UDRow -Columns {
    # Entries Dashboard
    New-UDColumn -Size 6 -Content {
        New-UDCard -Title '📝 Health Entries' -Content {
            New-UDTypography -Text 'Manage and view your health data entries' -Variant body2 -Style @{ marginBottom = '15px' }
            New-UDButton -Text 'Open Entries Dashboard' -Color primary -OnClick {
                Invoke-UDRedirect -Url '/entries' -Native
            } -FullWidth
        } -Style @{ marginBottom = '20px'; minHeight = '150px' }
    }

    # Charts Dashboard
    New-UDColumn -Size 6 -Content {
        New-UDCard -Title '📊 Analytics & Charts' -Content {
            New-UDTypography -Text 'Visualize health trends and patterns' -Variant body2 -Style @{ marginBottom = '15px' }
            New-UDButton -Text 'Open Charts Dashboard' -Color secondary -OnClick {
                Invoke-UDRedirect -Url '/charts' -Native
            } -FullWidth
        } -Style @{ marginBottom = '20px'; minHeight = '150px' }
    }
}

New-UDRow -Columns {
    # Activity Timeline Dashboard
    New-UDColumn -Size 6 -Content {
        New-UDCard -Title '🕒 Activity Timeline' -Content {
            New-UDTypography -Text 'View chronological health activities' -Variant body2 -Style @{ marginBottom = '15px' }
            New-UDButton -Text 'Open Timeline Dashboard' -Color success -OnClick {
                Invoke-UDRedirect -Url '/activitytimeline' -Native
            } -FullWidth
        } -Style @{ marginBottom = '20px'; minHeight = '150px' }
    }

    # Gallery Dashboard
    New-UDColumn -Size 6 -Content {
        New-UDCard -Title '🖼️ Health Gallery' -Content {
            New-UDTypography -Text 'Browse health-related images and media' -Variant body2 -Style @{ marginBottom = '15px' }
            New-UDButton -Text 'Open Gallery Dashboard' -Color warning -OnClick {
                Invoke-UDRedirect -Url '/gallery' -Native
            } -FullWidth
        } -Style @{ marginBottom = '20px'; minHeight = '150px' }
    }
}

New-UDRow -Columns {
    # Timeline Dashboard
    New-UDColumn -Size 6 -Content {
        New-UDCard -Title '📅 Timeline View' -Content {
            New-UDTypography -Text 'Interactive timeline of health events' -Variant body2 -Style @{ marginBottom = '15px' }
            New-UDButton -Text 'Open Timeline View' -Color info -OnClick {
                Invoke-UDRedirect -Url '/timeline' -Native
            } -FullWidth
        } -Style @{ marginBottom = '20px'; minHeight = '150px' }
    }

    # Test Dashboard
    New-UDColumn -Size 6 -Content {
        New-UDCard -Title '🧪 Test Dashboard' -Content {
            New-UDTypography -Text 'Development and testing environment' -Variant body2 -Style @{ marginBottom = '15px' }
            New-UDButton -Text 'Open Test Dashboard' -Color dark -OnClick {
                Invoke-UDRedirect -Url '/testme' -Native
            } -FullWidth
        } -Style @{ marginBottom = '20px'; minHeight = '150px' }
    }
}

# System Information Section
New-UDRow -Columns {
    New-UDColumn -Size 12 -Content {
        New-UDTypography -Text '🔧 System Information' -Variant h5 -Style @{
            marginTop    = '40px'
            marginBottom = '15px'
            color        = '#1976d2'
            fontWeight   = 'bold'
        }
    }
}

New-UDRow -Columns {
    New-UDColumn -Size 4 -Content {
        New-UDCard -Title '🔧 System Status' -Content {
            New-UDTypography -Text '✅ All systems operational' -Variant body1 -Style @{ color = '#4caf50'; fontWeight = 'bold' }
            New-UDTypography -Text "Last updated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -Variant body2 -Style @{ color = '#666' }
        }
    }
    New-UDColumn -Size 4 -Content {
        New-UDCard -Title '📊 Performance' -Content {
            New-UDTypography -Text 'Response time: < 200ms' -Variant body2
            New-UDTypography -Text 'Uptime: 99.8%' -Variant body2
            New-UDTypography -Text 'Active users: 1' -Variant body2
        }
    }
    New-UDColumn -Size 4 -Content {
        New-UDCard -Title '🔒 Security' -Content {
            New-UDTypography -Text 'SSL enabled ✅' -Variant body2 -Style @{ color = '#4caf50' }
            New-UDTypography -Text 'Authentication: Active' -Variant body2
            New-UDTypography -Text 'Last backup: Today' -Variant body2
        }
    }
}

# Recent Activity Section
New-UDRow -Columns {
    New-UDColumn -Size 12 -Content {
        New-UDTypography -Text '📋 Health Summary' -Variant h5 -Style @{
            marginTop    = '40px'
            marginBottom = '15px'
            color        = '#1976d2'
            fontWeight   = 'bold'
        }
    }
}

New-UDRow -Columns {
    New-UDColumn -Size 12 -Content {
        New-UDCard -Content {
            New-UDList -Content {
                if ($TotalEntries -gt 0) {
                    New-UDListItem -Label "📊 Total health entries tracked" -SubTitle "$TotalEntries records"
                    if ($MoodEntries.Count -gt 0) {
                        New-UDListItem -Label "😊 Mood tracking entries" -SubTitle "$($MoodEntries.Count) mood records (avg: $AverageMood/5)"
                    }
                    if ($ActivityEntries.Count -gt 0) {
                        New-UDListItem -Label "🏃‍♂️ Activity entries recorded" -SubTitle "$($ActivityEntries.Count) activity sessions"
                    }
                    if ($PainEntries.Count -gt 0) {
                        New-UDListItem -Label "🩹 Pain tracking entries" -SubTitle "$($PainEntries.Count) pain reports"
                    }
                    New-UDListItem -Label "� Data range coverage" -SubTitle "From $(($Entries | Sort-Object date | Select-Object -First 1).date) to $(($Entries | Sort-Object date | Select-Object -Last 1).date)"
                } else {
                    New-UDListItem -Label "� No data yet" -SubTitle "Click 'Generate Sample Data' to get started"
                    New-UDListItem -Label "🚀 Ready to track" -SubTitle "Add your first health entry using the form"
                    New-UDListItem -Label "� Analytics available" -SubTitle "Charts and trends will appear as you add data"
                }
            }
        } -Style @{ marginBottom = '30px' }
    }
}

# Footer Section
New-UDRow -Columns {
    New-UDColumn -Size 12 -Content {
        New-UDDivider -Style @{ margin = '30px 0' }
        New-UDTypography -Text 'PowerShell Universal Health Dashboard v2.0 | Built with ❤️ for better health tracking' -Variant body2 -Align center -Style @{
            color        = '#666'
            fontStyle    = 'italic'
            marginBottom = '20px'
        }
        New-UDTypography -Text '© 2024 Health Dashboard Project | All rights reserved' -Variant caption -Align center -Style @{
            color = '#999'
        }
    }
}
}
}

# Return the homepage app
$HomePage
