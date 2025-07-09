# Homepage content for the Health Dashboard
New-UDContainer -Content {
    Write-Information "User authenticated: $($User.Identity.IsAuthenticated)"
    Write-Information "User name: $($User.Identity.Name)"
    Write-Information "Session UserEmail: $($Session:UserEmail)"
    Write-Information "Session UserProfileId: $($Session:UserProfileId)"
    # Header Section
    New-UDRow -Content {
        New-UDColumn -Size 12 -Content {
            New-UDTypography -Text '🏥 PowerShell Universal Health Dashboard' -Variant h3 -Align center -Style @{
                marginBottom = '10px'
                color        = '#1976d2'
                fontWeight   = 'bold'
            }
            New-UDTypography -Text 'Comprehensive Health Tracking & Analytics Platform' -Variant h6 -Align center -Style @{
                marginBottom = '30px'
                color        = '#666'
                fontStyle    = 'italic'
            }
        }
    }

    # Statistics Overview Section
    New-UDRow -Content {
        New-UDColumn -Size 12 -Content {
            New-UDTypography -Text '📊 Quick Stats' -Variant h5 -Style @{
                marginBottom = '20px'
                color        = '#333'
            }
        }
    }

    New-UDDynamic -Content {
        try {
            $EntriesPath = '/home/data/fusion-data/entries/entries.json'
            $entries = Get-Content -Path $EntriesPath | ConvertFrom-Json
            $dates = $entries.PSObject.Properties.Name | Sort-Object
            
            # Calculate quick stats
            $totalDays = $dates.Count
            $latestDate = $dates | Select-Object -Last 1
            $month = $latestDate.Substring(0, 2)
            $day = $latestDate.Substring(2, 2)
            $latestDateFormatted = "$month/$day"
            
            # Count total entries
            $totalEntries = 0
            foreach ($date in $dates) {
                $dateEntry = $entries.$date
                $totalEntries += ($dateEntry.PSObject.Properties.Name | Where-Object { $_ -match '^\d{4}$' }).Count
            }

            New-UDRow -Content {
                New-UDColumn -Size 3 -Content {
                    New-UDCard -Content {
                        New-UDTypography -Text "$totalDays" -Variant h4 -Align center -Style @{color = '#4caf50'; fontWeight = 'bold' }
                        New-UDTypography -Text 'Days Tracked' -Variant body2 -Align center
                    } -Style @{backgroundColor = '#f8f9fa'; textAlign = 'center' }
                }
                New-UDColumn -Size 3 -Content {
                    New-UDCard -Content {
                        New-UDTypography -Text "$totalEntries" -Variant h4 -Align center -Style @{color = '#2196f3'; fontWeight = 'bold' }
                        New-UDTypography -Text 'Total Entries' -Variant body2 -Align center
                    } -Style @{backgroundColor = '#f8f9fa'; textAlign = 'center' }
                }
                New-UDColumn -Size 3 -Content {
                    New-UDCard -Content {
                        New-UDTypography -Text "$latestDateFormatted" -Variant h4 -Align center -Style @{color = '#ff9800'; fontWeight = 'bold' }
                        New-UDTypography -Text 'Latest Entry' -Variant body2 -Align center
                    } -Style @{backgroundColor = '#f8f9fa'; textAlign = 'center' }
                }
                New-UDColumn -Size 3 -Content {
                    New-UDCard -Content {
                        New-UDTypography -Text 'Active' -Variant h4 -Align center -Style @{color = '#4caf50'; fontWeight = 'bold' }
                        New-UDTypography -Text 'System Status' -Variant body2 -Align center
                    } -Style @{backgroundColor = '#f8f9fa'; textAlign = 'center' }
                }
            }
        } catch {
            New-UDAlert -Severity warning -Text "Unable to load statistics: $_"
        }
    }

    # Quick Actions Section
    New-UDRow -Content {
        New-UDColumn -Size 12 -Content {
            New-UDTypography -Text '⚡ Quick Actions' -Variant h5 -Style @{
                marginTop    = '40px'
                marginBottom = '20px'
                color        = '#333'
            }
        }
    }

    New-UDRow -Content {
        New-UDColumn -Size 12 -Content {
            New-UDCard -Content {
                New-UDCardBody -Content {
                    New-UDGrid -Container -Content {
                        New-UDGrid -Item -ExtraSmallSize 3 -Content {
                            New-UDButton -Text '📝 Quick Entry' -Color primary -Variant contained -OnClick {
                                Invoke-UDRedirect -Url '/entries'
                            } -FullWidth -Style @{margin = '5px' }
                        }
                        New-UDGrid -Item -ExtraSmallSize 3 -Content {
                            New-UDButton -Text '📊 View Charts' -Color secondary -Variant contained -OnClick {
                                Invoke-UDRedirect -Url '/charts'
                            } -FullWidth -Style @{margin = '5px' }
                        }
                        New-UDGrid -Item -ExtraSmallSize 3 -Content {
                            New-UDButton -Text '⏰ Check Timeline' -Color success -Variant contained -OnClick {
                                Invoke-UDRedirect -Url '/timeline'
                            } -FullWidth -Style @{margin = '5px' }
                        }
                        New-UDGrid -Item -ExtraSmallSize 3 -Content {
                            New-UDButton -Text '🏃 Activities' -Color info -Variant contained -OnClick {
                                Invoke-UDRedirect -Url '/activitytimeline'
                            } -FullWidth -Style @{margin = '5px' }
                        }
                    }
                }
            }
        }
    }

    # Dashboard Overview Section
    New-UDRow -Content {
        New-UDColumn -Size 12 -Content {
            New-UDTypography -Text '🚀 Available Dashboards' -Variant h5 -Style @{
                marginTop    = '40px'
                marginBottom = '20px'
                color        = '#333'
            }
        }
    }

    # Dashboard Cards
    New-UDRow -Content {
        New-UDColumn -Size 4 -Content {
            New-UDCard -Content {
                New-UDCardHeader -Title '📈 Health Metrics'
                New-UDCardBody -Content {
                    New-UDTypography -Text 'Comprehensive health analytics with interactive charts showing pain levels, medication usage, and activity tracking over time.' -Style @{marginBottom = '15px' }
                    New-UDList -Content {
                        New-UDListItem -Label 'Max daily pain tracking'
                        New-UDListItem -Label 'Medication usage statistics'
                        New-UDListItem -Label 'Activity duration analysis'
                        New-UDListItem -Label 'Daily health summaries'
                    }
                }
                New-UDCardActions -Content {
                    New-UDButton -Text 'View Metrics' -Color primary -Variant contained -OnClick {
                        Invoke-UDRedirect -Url '/charts'
                    } -FullWidth
                }
            } -Style @{height = '350px' }
        }

        New-UDColumn -Size 4 -Content {
            New-UDCard -Content {
                New-UDCardHeader -Title '🔍 Pain Analysis'
                New-UDCardBody -Content {
                    New-UDTypography -Text 'Advanced pain correlation analysis comparing maximum daily pain levels with average back pain patterns.' -Style @{marginBottom = '15px' }
                    New-UDList -Content {
                        New-UDListItem -Label 'Dual-series line charts'
                        New-UDListItem -Label 'Pain trend analysis'
                        New-UDListItem -Label 'Back pain correlation'
                        New-UDListItem -Label 'Professional visualizations'
                    }
                }
                New-UDCardActions -Content {
                    New-UDButton -Text 'Analyze Pain' -Color secondary -Variant contained -OnClick {
                        Invoke-UDRedirect -Url '/testme'
                    } -FullWidth
                }
            } -Style @{height = '350px' }
        }

        New-UDColumn -Size 4 -Content {
            New-UDCard -Content {
                New-UDCardHeader -Title '⏰ Health Timeline'
                New-UDCardBody -Content {
                    New-UDTypography -Text 'Interactive timeline visualization of health events, medication changes, and pain patterns with color-coded categorization.' -Style @{marginBottom = '15px' }
                    New-UDList -Content {
                        New-UDListItem -Label 'Chronological health events'
                        New-UDListItem -Label 'Color-coded pain levels'
                        New-UDListItem -Label 'Medication tracking'
                        New-UDListItem -Label 'Event categorization'
                    }
                }
                New-UDCardActions -Content {
                    New-UDButton -Text 'View Timeline' -Color success -Variant contained -OnClick {
                        Invoke-UDRedirect -Url '/timeline'
                    } -FullWidth
                }
            } -Style @{height = '350px' }
        }
    }

    # Additional Dashboard Cards
    New-UDRow -Content {
        New-UDColumn -Size 4 -Content {
            New-UDCard -Content {
                New-UDCardHeader -Title '🏃 Activity Timeline'
                New-UDCardBody -Content {
                    New-UDTypography -Text 'Track physical activity progress with personal record highlighting and comprehensive activity statistics.' -Style @{marginBottom = '15px' }
                    New-UDList -Content {
                        New-UDListItem -Label 'Activity progress tracking'
                        New-UDListItem -Label 'Personal record detection'
                        New-UDListItem -Label 'Walking & stairs analysis'
                        New-UDListItem -Label 'Standing time monitoring'
                    }
                }
                New-UDCardActions -Content {
                    New-UDButton -Text 'View Activities' -Color info -Variant contained -OnClick {
                        Invoke-UDRedirect -Url '/activitytimeline'
                    } -FullWidth
                }
            } -Style @{height = '350px' }
        }

        New-UDColumn -Size 4 -Content {
            New-UDCard -Content {
                New-UDCardHeader -Title '✏️ Data Entry'
                New-UDCardBody -Content {
                    New-UDTypography -Text 'Comprehensive health data entry form for recording pain levels, medications, activities, and notes.' -Style @{marginBottom = '15px' }
                    New-UDList -Content {
                        New-UDListItem -Label 'Pain level recording'
                        New-UDListItem -Label 'Medication logging'
                        New-UDListItem -Label 'Activity tracking'
                        New-UDListItem -Label 'Notes & observations'
                    }
                }
                New-UDCardActions -Content {
                    New-UDButton -Text 'Add New Entry' -Color warning -Variant contained -OnClick {
                        Invoke-UDRedirect -Url '/entries'
                    } -FullWidth
                }
            } -Style @{height = '350px' }
        }

        New-UDColumn -Size 4 -Content {
            New-UDCard -Content {
                New-UDCardHeader -Title '🖼️ Photo Gallery'
                New-UDCardBody -Content {
                    New-UDTypography -Text 'Visual documentation gallery for tracking recovery progress through images organized by date.' -Style @{marginBottom = '15px' }
                    New-UDList -Content {
                        New-UDListItem -Label 'Date-organized photos'
                        New-UDListItem -Label 'Recovery documentation'
                        New-UDListItem -Label 'Visual progress tracking'
                        New-UDListItem -Label 'Image browsing interface'
                    }
                }
                New-UDCardActions -Content {
                    New-UDButton -Text 'Browse Gallery' -Color error -Variant contained -OnClick {
                        Invoke-UDRedirect -Url '/gallery'
                    } -FullWidth
                }
            } -Style @{height = '350px' }
        }
    }

    # Footer Section
    New-UDRow -Content {
        New-UDColumn -Size 12 -Content {
            New-UDCard -Content {
                New-UDCardBody -Content {
                    New-UDTypography -Text '💡 System Information' -Variant h6 -Style @{marginBottom = '10px' }
                    New-UDTypography -Text 'PowerShell Universal Health Dashboard - Built with PowerShell Universal, featuring comprehensive health tracking, pain monitoring, medication logging, and interactive data visualizations.' -Style @{marginBottom = '10px' }
                    New-UDTypography -Text '🔧 Technical Stack: PowerShell Universal, ChartJS, Material-UI Components' -Variant body2 -Style @{color = '#666' }
                    New-UDTypography -Text '📅 Last Updated: June 26, 2025 | Status: Active Development 🚧' -Variant body2 -Style @{color = '#666'; fontStyle = 'italic' }
                }
            } -Style @{backgroundColor = '#f5f5f5'; marginTop = '40px' }
        }
    }
}
