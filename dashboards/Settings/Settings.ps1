$SettingsPage = New-UDApp -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    if (!$UserData) {
        sleep 2
        Invoke-UDRedirect -Url /login -Native
    }
    # Add custom CSS for settings form styling
    New-UDElement -Tag 'style' -Content {
        @'
        .settings-form {
            max-width: 900px;
            margin: 0 auto;
            padding: 20px;
        }

        .settings-section {
            margin-bottom: 30px;
            background: var(--theme-palette-background-paper);
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        .settings-section h5 {
            color: var(--theme-palette-primary-main);
            font-weight: 600;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid var(--theme-palette-primary-light);
        }

        .settings-form .MuiFormControl-root {
            margin-bottom: 16px;
            width: 100%;
        }

        .settings-form .MuiButton-contained {
            background-color: var(--theme-palette-primary-main);
            color: white;
            padding: 12px 32px;
            font-size: 16px;
            font-weight: 600;
            border-radius: 8px;
            text-transform: none;
            margin-top: 20px;
        }

        .settings-form .MuiButton-contained:hover {
            background-color: var(--theme-palette-primary-dark);
            box-shadow: 0 6px 16px rgba(0,0,0,0.2);
        }

        .tracking-toggle {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
            border-left: 4px solid var(--theme-palette-primary-main);
        }

        .medication-item, .activity-item, .pain-location-item {
            background: #f0f7ff;
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 12px;
            border: 1px solid #e3f2fd;
        }

        .remove-btn {
            background-color: #f44336 !important;
            color: white !important;
            min-width: 40px !important;
            padding: 8px !important;
        }

        .add-btn {
            background-color: #4caf50 !important;
            color: white !important;
            margin-top: 12px !important;
        }

        .section-description {
            color: var(--theme-palette-text-secondary);
            font-size: 14px;
            margin-bottom: 20px;
            font-style: italic;
        }
'@
    }

    New-UDContainer -Children {
        # Header Section
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text '⚙️ Health Tracking Settings' -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = 'var(--theme-palette-primary-main)'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Configure your personalized health tracking preferences' -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = 'var(--theme-palette-text-secondary)'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '30px'; backgroundColor = 'var(--theme-palette-background-paper)' }

        New-UDElement -Tag 'div' -Attributes @{ class = 'settings-form' } -Content {

            # Basic Profile Settings Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '👤 Profile Preferences' -Variant h5
                New-UDTypography -Text 'Basic settings for your health dashboard experience' -Style @{ class = 'section-description' }

                New-UDGrid -Container -Children {
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'timezone' -Label '🌍 Timezone' -FullWidth -Option {
                            New-UDSelectOption -Name 'UTC' -Value 'UTC'
                            New-UDSelectOption -Name 'Eastern Time' -Value 'America/New_York'
                            New-UDSelectOption -Name 'Central Time' -Value 'America/Chicago'
                            New-UDSelectOption -Name 'Mountain Time' -Value 'America/Denver'
                            New-UDSelectOption -Name 'Pacific Time' -Value 'America/Los_Angeles'
                        } -DefaultValue 'America/Denver'
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'theme' -Label '🎨 Theme' -FullWidth -Option {
                            New-UDSelectOption -Name 'Light' -Value 'light'
                            New-UDSelectOption -Name 'Dark' -Value 'dark'
                        } -DefaultValue 'light'
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'temperature_unit' -Label '🌡️ Temperature Unit' -FullWidth -Option {
                            New-UDSelectOption -Name 'Fahrenheit' -Value 'fahrenheit'
                            New-UDSelectOption -Name 'Celsius' -Value 'celsius'
                        } -DefaultValue 'fahrenheit'
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDSelect -Id 'weight_unit' -Label '⚖️ Weight Unit' -FullWidth -Option {
                            New-UDSelectOption -Name 'Pounds' -Value 'pounds'
                            New-UDSelectOption -Name 'Kilograms' -Value 'kilograms'
                        } -DefaultValue 'pounds'
                    }
                }
            }

            # Vital Signs Tracking Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '💓 Vital Signs Tracking' -Variant h5
                New-UDTypography -Text 'Choose which vital signs you want to track regularly' -Style @{ class = 'section-description' }

                # Blood Pressure
                New-UDElement -Tag 'div' -Attributes @{ class = 'tracking-toggle' } -Content {
                    New-UDGrid -Container -Children {
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            New-UDCheckbox -Id 'track_blood_pressure' -Label '🩸 Track Blood Pressure' -Style @{ marginBottom = '16px' }
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDTextbox -Id 'bp_target_systolic' -Label 'Target Systolic' -Type 'number' -Value '120' -FullWidth
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDTextbox -Id 'bp_target_diastolic' -Label 'Target Diastolic' -Type 'number' -Value '80' -FullWidth
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDSelect -Id 'bp_frequency' -Label 'Frequency' -FullWidth -Option {
                                New-UDSelectOption -Name 'Daily' -Value 'daily'
                                New-UDSelectOption -Name 'Weekly' -Value 'weekly'
                                New-UDSelectOption -Name 'As Needed' -Value 'as_needed'
                            } -DefaultValue 'daily'
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDCheckbox -Id 'bp_alerts' -Label '🔔 Enable Alerts'
                        }
                    }
                }

                # Oxygen Saturation
                New-UDElement -Tag 'div' -Attributes @{ class = 'tracking-toggle' } -Content {
                    New-UDGrid -Container -Children {
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            New-UDCheckbox -Id 'track_oxygen' -Label '🫁 Track Oxygen Saturation' -Style @{ marginBottom = '16px' }
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDTextbox -Id 'o2_target_min' -Label 'Target Minimum %' -Type 'number' -Value '95' -FullWidth
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDSelect -Id 'o2_frequency' -Label 'Frequency' -FullWidth -Option {
                                New-UDSelectOption -Name 'Daily' -Value 'daily'
                                New-UDSelectOption -Name 'Weekly' -Value 'weekly'
                                New-UDSelectOption -Name 'As Needed' -Value 'as_needed'
                            } -DefaultValue 'daily'
                        }
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            New-UDCheckbox -Id 'o2_alerts' -Label '🔔 Enable Alerts'
                        }
                    }
                }

                # Heart Rate
                New-UDElement -Tag 'div' -Attributes @{ class = 'tracking-toggle' } -Content {
                    New-UDGrid -Container -Children {
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            New-UDCheckbox -Id 'track_heart_rate' -Label '💗 Track Heart Rate' -Style @{ marginBottom = '16px' }
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDTextbox -Id 'hr_target_resting' -Label 'Target Resting HR' -Type 'number' -Value '70' -FullWidth
                        }
                        New-UDGrid -Item -ExtraSmallSize 6 -Children {
                            New-UDSelect -Id 'hr_frequency' -Label 'Frequency' -FullWidth -Option {
                                New-UDSelectOption -Name 'Daily' -Value 'daily'
                                New-UDSelectOption -Name 'Weekly' -Value 'weekly'
                                New-UDSelectOption -Name 'As Needed' -Value 'as_needed'
                            } -DefaultValue 'daily'
                        }
                        New-UDGrid -Item -ExtraSmallSize 12 -Children {
                            New-UDCheckbox -Id 'hr_alerts' -Label '🔔 Enable Alerts'
                        }
                    }
                }

                # Additional Vitals
                New-UDGrid -Container -Children {
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_temperature' -Label '🌡️ Track Temperature'
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_weight' -Label '⚖️ Track Weight'
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_glucose' -Label '🩸 Track Blood Glucose'
                    }
                }
            }

            # Other Health Tracking Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '🏥 Other Health Tracking' -Variant h5
                New-UDTypography -Text 'Additional health metrics and lifestyle tracking' -Style @{ class = 'section-description' }

                New-UDGrid -Container -Children {
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_pain' -Label '🩹 Track Pain Levels'
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_activities' -Label '🏃 Track Activities & Exercise'
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_sleep' -Label '😴 Track Sleep'
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_mood' -Label '😊 Track Mood'
                    }
                    New-UDGrid -Item -ExtraSmallSize 6 -Children {
                        New-UDCheckbox -Id 'track_medications' -Label '💊 Track Medications'
                    }
                }
            }

            # Medications Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '💊 Medications' -Variant h5
                New-UDTypography -Text 'Add medications you are currently taking' -Style @{ class = 'section-description' }

                New-UDElement -Id 'medications-container' -Tag 'div' -Content {
                    # Initial medication entry
                    New-UDElement -Tag 'div' -Attributes @{ class = 'medication-item' } -Content {
                        New-UDGrid -Container -Children {
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                New-UDTextbox -Id 'med_name_1' -Label 'Medication Name' -FullWidth
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                New-UDTextbox -Id 'med_dosage_1' -Label 'Dosage (e.g., 10mg)' -FullWidth
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                New-UDSelect -Id 'med_frequency_1' -Label 'Frequency' -FullWidth -Option {
                                    New-UDSelectOption -Name 'Once Daily' -Value 'daily'
                                    New-UDSelectOption -Name 'Twice Daily' -Value 'twice_daily'
                                    New-UDSelectOption -Name 'Three Times Daily' -Value 'three_times_daily'
                                    New-UDSelectOption -Name 'As Needed' -Value 'as_needed'
                                    New-UDSelectOption -Name 'Weekly' -Value 'weekly'
                                }
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 2 -Children {
                                New-UDCheckbox -Id 'med_reminders_1' -Label '🔔 Reminders'
                            }
                        }
                    }
                }

                New-UDButton -Text '+ Add Another Medication' -Color success -OnClick {
                    # TODO: Add logic to dynamically add medication entries
                    Show-UDToast -Message 'Medication entry added!' -Duration 2000
                } -Style @{ class = 'add-btn' }
            }

            # Pain Locations Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '🩹 Pain Tracking Locations' -Variant h5
                New-UDTypography -Text 'Specify body areas where you experience pain' -Style @{ class = 'section-description' }

                New-UDElement -Id 'pain-locations-container' -Tag 'div' -Content {
                    # Initial pain location entry
                    New-UDElement -Tag 'div' -Attributes @{ class = 'pain-location-item' } -Content {
                        New-UDGrid -Container -Children {
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                New-UDSelect -Id 'pain_location_1' -Label 'Pain Location' -FullWidth -Option {
                                    New-UDSelectOption -Name 'Lower Back' -Value 'lower_back'
                                    New-UDSelectOption -Name 'Upper Back' -Value 'upper_back'
                                    New-UDSelectOption -Name 'Neck' -Value 'neck'
                                    New-UDSelectOption -Name 'Right Hip' -Value 'right_hip'
                                    New-UDSelectOption -Name 'Left Hip' -Value 'left_hip'
                                    New-UDSelectOption -Name 'Right Knee' -Value 'right_knee'
                                    New-UDSelectOption -Name 'Left Knee' -Value 'left_knee'
                                    New-UDSelectOption -Name 'Right Shoulder' -Value 'right_shoulder'
                                    New-UDSelectOption -Name 'Left Shoulder' -Value 'left_shoulder'
                                    New-UDSelectOption -Name 'Head/Headache' -Value 'head'
                                    New-UDSelectOption -Name 'Other' -Value 'other'
                                }
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 4 -Children {
                                New-UDTextbox -Id 'pain_description_1' -Label 'Description (optional)' -FullWidth
                            }
                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                New-UDCheckbox -Id 'pain_chronic_1' -Label 'Chronic'
                            }
                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                New-UDTextbox -Id 'pain_baseline_1' -Label 'Baseline (0-10)' -Type 'number' -Value '0' -FullWidth
                            }
                        }
                    }
                }

                New-UDButton -Text '+ Add Another Pain Location' -Color success -OnClick {
                    # TODO: Add logic to dynamically add pain location entries
                    Show-UDToast -Message 'Pain location added!' -Duration 2000
                } -Style @{ class = 'add-btn' }
            }

            # Activities Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '🏃 Activities & Exercise' -Variant h5
                New-UDTypography -Text 'Define activities and exercises you want to track' -Style @{ class = 'section-description' }

                New-UDElement -Id 'activities-container' -Tag 'div' -Content {
                    # Initial activity entry
                    New-UDElement -Tag 'div' -Attributes @{ class = 'activity-item' } -Content {
                        New-UDGrid -Container -Children {
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                New-UDTextbox -Id 'activity_name_1' -Label 'Activity Name' -FullWidth
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 3 -Children {
                                New-UDSelect -Id 'activity_category_1' -Label 'Category' -FullWidth -Option {
                                    New-UDSelectOption -Name 'Cardio' -Value 'cardio'
                                    New-UDSelectOption -Name 'Strength Training' -Value 'strength'
                                    New-UDSelectOption -Name 'Flexibility/Stretching' -Value 'flexibility'
                                    New-UDSelectOption -Name 'Physical Therapy' -Value 'physical_therapy'
                                    New-UDSelectOption -Name 'Daily Living' -Value 'daily_living'
                                    New-UDSelectOption -Name 'Sports' -Value 'sports'
                                    New-UDSelectOption -Name 'Other' -Value 'other'
                                }
                            }
                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                New-UDSelect -Id 'activity_intensity_1' -Label 'Intensity' -FullWidth -Option {
                                    New-UDSelectOption -Name 'Light' -Value 'light'
                                    New-UDSelectOption -Name 'Moderate' -Value 'moderate'
                                    New-UDSelectOption -Name 'Vigorous' -Value 'vigorous'
                                } -DefaultValue 'moderate'
                            }
                            New-UDGrid -Item -ExtraSmallSize 6 -SmallSize 2 -Children {
                                New-UDTextbox -Id 'activity_duration_1' -Label 'Duration (min)' -Type 'number' -Value '30' -FullWidth
                            }
                            New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 2 -Children {
                                New-UDSelect -Id 'activity_frequency_1' -Label 'Goal Frequency' -FullWidth -Option {
                                    New-UDSelectOption -Name 'Daily' -Value 'daily'
                                    New-UDSelectOption -Name 'Weekly' -Value 'weekly'
                                    New-UDSelectOption -Name 'Monthly' -Value 'monthly'
                                } -DefaultValue 'weekly'
                            }
                        }
                    }
                }

                New-UDButton -Text '+ Add Another Activity' -Color success -OnClick {
                    # TODO: Add logic to dynamically add activity entries
                    Show-UDToast -Message 'Activity added!' -Duration 2000
                } -Style @{ class = 'add-btn' }
            }

            # Notifications Section
            New-UDElement -Tag 'div' -Attributes @{ class = 'settings-section' } -Content {
                New-UDTypography -Text '🔔 Notifications & Reminders' -Variant h5
                New-UDTypography -Text 'Configure when and how you want to be reminded' -Style @{ class = 'section-description' }

                New-UDGrid -Container -Children {
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDCheckbox -Id 'notifications_enabled' -Label '🔔 Enable Notifications' -Checked
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDTextbox -Id 'reminder_time' -Label '⏰ Daily Reminder Time' -Type 'time' -Value '09:00' -FullWidth
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDCheckbox -Id 'critical_alerts' -Label '🚨 Critical Health Alerts' -Checked
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDCheckbox -Id 'daily_summary' -Label '📊 Daily Summary'
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDCheckbox -Id 'weekly_report' -Label '📈 Weekly Report'
                    }
                }
            }

            # Save Settings Button
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 12 -Children {
                    New-UDButton -Text '💾 Save Health Tracking Settings' -Color primary -Size large -FullWidth -OnClick {
                        # TODO: Implement settings save logic here
                        # Collect all form data and call [UserProfile]::SetUserPreferences()
                        Show-UDToast -Message 'Settings saved successfully!' -Duration 3000 -BackgroundColor '#4caf50'
                    } -Style @{
                        marginTop = '30px'
                        padding = '16px 0'
                        fontSize = '18px'
                        fontWeight = 'bold'
                    }
                }
            }
        }
    }
}
# Return the settings app
$SettingsPage
