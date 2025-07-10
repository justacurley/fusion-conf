$HomePage = New-UDApp -Content {
    Import-Module UserManagement -Force
    $CurrentUser = Get-CurrentUser
    Write-Information "Get-CurrentUser Output: $($CurrentUser | Convertto-Json -Depth 3)"
    if (-not $CurrentUser.Success) {
        Show-UDToast -Message "Authentication issue, redirecting to login page" -MessageColor Red -Duration 2000
        Invoke-UDRedirect -Url /login -Native
    } else {
        Write-Information "Current user successfully authenticated"
        $UserData = $CurrentUser.Data
        # Set Cache. This is the landing page after logging in, hoping we only have to set these once. 
        Set-UserCacheData -UserData $UserData -ExpirationHours 1
    }
    Write-Information -MessageData (Get-Variable | ConvertTo-Json -Depth 5)
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
                    New-UDTypography -Text "2, 847" -Variant h4 -Style @{ color = "#4caf50"; fontWeight = "bold"; textAlign = "center" }
                    New-UDTypography -Text "Health records tracked" -Variant body2 -Style @{ textAlign = "center"; color = "#666" }
                } -Style @{ textAlign = "center"; border = "2px solid #4caf50"; borderRadius = "10px" }
}
New-UDColumn -Size 3 -Content {
    New-UDCard -Title '💊 Medications' -Content {
        New-UDTypography -Text '12' -Variant h4 -Style @{ color = '#ff9800'; fontWeight = 'bold'; textAlign = 'center' }
        New-UDTypography -Text 'Active prescriptions' -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
    } -Style @{ textAlign = 'center'; border = '2px solid #ff9800'; borderRadius = '10px' }
}
New-UDColumn -Size 3 -Content {
    New-UDCard -Title '⚠️ Alerts' -Content {
        New-UDTypography -Text '3' -Variant h4 -Style @{ color = '#f44336'; fontWeight = 'bold'; textAlign = 'center' }
        New-UDTypography -Text 'Requires attention' -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
    } -Style @{ textAlign = 'center'; border = '2px solid #f44336'; borderRadius = '10px' }
}
New-UDColumn -Size 3 -Content {
    New-UDCard -Title '📈 Trends' -Content {
        New-UDTypography -Text '↗️' -Variant h4 -Style @{ color = '#2196f3'; fontWeight = 'bold'; textAlign = 'center' }
        New-UDTypography -Text 'Health improving' -Variant body2 -Style @{ textAlign = 'center'; color = '#666' }
    } -Style @{ textAlign = 'center'; border = '2px solid #2196f3'; borderRadius = '10px' }
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

New-UDRow -Columns {
    New-UDColumn -Size 4 -Content {
        New-UDButton -Text '➕ Add New Entry' -Color primary -Size large -FullWidth -OnClick {
            Invoke-UDRedirect -Url '/entries' -Native
        } -Style @{ marginBottom = '10px'; padding = '15px' }
    }
    New-UDColumn -Size 4 -Content {
        New-UDButton -Text '📊 View Analytics' -Color secondary -Size large -FullWidth -OnClick {
            Invoke-UDRedirect -Url '/charts' -Native
        } -Style @{ marginBottom = '10px'; padding = '15px' }
    }
    New-UDColumn -Size 4 -Content {
        New-UDButton -Text '📅 Timeline View' -Color success -Size large -FullWidth -OnClick {
            Invoke-UDRedirect -Url '/timeline' -Native
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
        New-UDTypography -Text '📋 Recent Activity' -Variant h5 -Style @{
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
                New-UDListItem -Label '🩺 Health check completed' -SubTitle '2 hours ago'
                New-UDListItem -Label '💊 Medication reminder sent' -SubTitle '4 hours ago'
                New-UDListItem -Label '📊 Weekly report generated' -SubTitle '1 day ago'
                New-UDListItem -Label '🔄 Data sync completed' -SubTitle '2 days ago'
                New-UDListItem -Label '📝 New entry added' -SubTitle '3 days ago'
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
