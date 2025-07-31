$Pages += New-UDPage -Name 'entry' -url '/entry:entryid' -content {
    Show-UDToast -Message $entryid -Persistent
    Import-Module UserManagement -Force
    Import-Module GetFusion -Force

    $UserData = Initialize-UserContext -UserEmail $User

    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text '✏️ Update Health Entries v2.0' -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = '#1976d2'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Select a date to view and edit all health entries for that day' -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = '#666'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '20px'; backgroundColor = '#f8f9fa' }

        # Date Selection Section
        New-UDCard -Title '📅 Select Date' -Content {
            New-UDGrid -Container -Children {
                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                    # Current date in Mountain Time
                    $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time')
                    $currentDate = $MSTDate.ToString('yyyy-MM-dd')
                    if ($Query.Id) {
                        try {
                            $entryId = $Query.Id
                            if ($entryId.Length -eq 10) {
                                $year = "20" + $entryId.Substring(0, 2)
                                $month = $entryId.Substring(2, 2)
                                $day = $entryId.Substring(4, 2)
                                $currentDate = "$year-$month-$day"
                                $parsedDate = [DateTime]::ParseExact($currentDate, 'yyyy-MM-dd', $null)
                                Write-Information "Using date from Query.Id: $currentDate (Entry ID: $entryId)"
                            }
                            else {
                                Write-Warning "Invalid Query.Id format: $entryId (expected 10 characters)"
                            }
                        }
                        catch {
                            Write-Warning "Could not parse Query.Id '$($Query.Id)': $($_.Exception.Message)"
                        }
                    }
                    New-UDTextbox -Id 'selectedDate' -Label '📅 Date' -Type 'date' -FullWidth -Value $currentDate -OnChange {
                        # Load entries for selected date
                        $selectedDateValue = $EventData
                        if (-not [string]::IsNullOrWhiteSpace($selectedDateValue)) {
                            try {
                                # Parse the selected date
                                $parsedDate = [datetime]::Parse($selectedDateValue)
                                $selectedDateFormatted = $parsedDate.ToString('yyyy-MM-dd')

                                # Import UserManagement for context
                                Import-Module UserManagement -Force
                                $UserData = Initialize-UserContext -UserEmail $User

                                # Ensure EntriesPath is available
                                if (-not $UserData.EntriesPath -and $UserData.UserDataPath) {
                                    $UserData | Add-Member -MemberType NoteProperty -Name 'EntriesPath' -Value (Join-Path $UserData.UserDataPath 'health-data/entries.json') -Force
                                }

                                # Load user's v2 entries
                                if ($UserData.EntriesPath -and (Test-Path $UserData.EntriesPath)) {
                                    $AllEntries = Get-Content $UserData.EntriesPath -Raw | ConvertFrom-Json

                                    # Filter entries for the selected date
                                    $DayEntries = $AllEntries | Where-Object { $_.date -eq $selectedDateFormatted }

                                    if ($DayEntries.Count -gt 0) {
                                        # Sort entries by time
                                        $SortedEntries = $DayEntries | Sort-Object time

                                        # Build the entries display
                                        $entriesContent = @()

                                        foreach ($entry in $SortedEntries) {
                                            $entryJson = $entry | ConvertTo-Json -Depth 10 -Compress:$false

                                            # Create entry type badges
                                            $entryTypeBadges = $entry.entry_types | ForEach-Object {
                                                $badgeColor = switch ($_) {
                                                    'mood' { 'success' }
                                                    'vitals' { 'primary' }
                                                    'medications' { 'warning' }
                                                    'activities' { 'info' }
                                                    'pain' { 'error' }
                                                    'weight' { 'secondary' }
                                                    'sleep' { 'default' }
                                                    default { 'default' }
                                                }
                                                New-UDChip -Label $_ -Color $badgeColor -Size small
                                            }

                                            $entriesContent += New-UDPaper -Children {
                                                New-UDGrid -Container -Children {
                                                    # Entry header with time and ID
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDGrid -Container -Children {
                                                            New-UDGrid -Item -ExtraSmallSize 6 -Children {
                                                                New-UDTypography -Text "🕐 $($entry.time)" -Variant h6 -Style @{
                                                                    marginBottom = '10px'
                                                                    color        = '#1976d2'
                                                                    fontWeight   = '600'
                                                                }
                                                            }
                                                            New-UDGrid -Item -ExtraSmallSize 6 -Children {
                                                                New-UDTypography -Text "ID: $($entry.entry_id)" -Variant caption -Style @{
                                                                    marginBottom = '10px'
                                                                    color        = '#666'
                                                                    textAlign    = 'right'
                                                                    fontFamily   = 'monospace'
                                                                }
                                                            }
                                                        }
                                                    }

                                                    # Entry type badges
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDGrid -Container -Spacing 1 -Children {
                                                            $entryTypeBadges
                                                        }
                                                    } -Style @{ marginBottom = '15px' }

                                                    # JSON editor
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDTextbox -Id "entry_$($entry.entry_id)" -Label 'Health Entry Data (JSON)' -Multiline -Rows 20 -FullWidth -Value $entryJson -Style @{
                                                            fontFamily = 'monospace'
                                                            fontSize   = '12px'
                                                        }
                                                    }

                                                    # Action buttons
                                                    New-UDGrid -Item -ExtraSmallSize 12 -Children {
                                                        New-UDGrid -Container -Children {
                                                            New-UDGrid -Item -ExtraSmallSize 8 -Children {
                                                                New-UDButton -Text "💾 Update Entry ($($entry.time))" -Color primary -FullWidth -OnClick {
                                                                    try {
                                                                        # Get the updated JSON data
                                                                        $updatedJson = (Get-UDElement -Id "entry_$($entry.entry_id)").value
                                                                        $updatedEntry = $updatedJson | ConvertFrom-Json

                                                                        # Validate entry has required fields
                                                                        $requiredFields = @('entry_id', 'user_email', 'date', 'time', 'entry_types', 'data', 'notes')
                                                                        $missingFields = $requiredFields | Where-Object { -not $updatedEntry.PSObject.Properties.Name.Contains($_) }

                                                                        if ($missingFields.Count -gt 0) {
                                                                            throw "Missing required fields: $($missingFields -join ', ')"
                                                                        }

                                                                        # Load current entries
                                                                        Import-Module UserManagement -Force
                                                                        $UserData = Initialize-UserContext -UserEmail $User

                                                                        # Ensure EntriesPath is available
                                                                        if (-not $UserData.EntriesPath -and $UserData.UserDataPath) {
                                                                            $UserData | Add-Member -MemberType NoteProperty -Name 'EntriesPath' -Value (Join-Path $UserData.UserDataPath 'health-data/entries.json') -Force
                                                                        }

                                                                        $AllEntries = Get-Content $UserData.EntriesPath -Raw | ConvertFrom-Json

                                                                        # Find and update the specific entry
                                                                        $entryIndex = $AllEntries | ForEach-Object { $i = 0 } { if ($_.entry_id -eq $entry.entry_id) { $i }; $i++ }

                                                                        if ($entryIndex -ne $null) {
                                                                            $AllEntries[$entryIndex] = $updatedEntry

                                                                            # Save back to file
                                                                            $AllEntries | ConvertTo-Json -Depth 10 | Set-Content -Path $UserData.EntriesPath -Encoding UTF8

                                                                            Show-UDToast -Message "✅ Successfully updated entry at $($entry.time)" -MessageColor Green -Duration 4000
                                                                        }
                                                                        else {
                                                                            throw "Entry not found in user's data"
                                                                        }
                                                                    }
                                                                    catch {
                                                                        Show-UDToast -Message "❌ Error updating entry: $($_.Exception.Message)" -MessageColor Red -Duration 6000
                                                                        Write-Error "Error updating entry: $($_.Exception.Message)"
                                                                    }
                                                                }
                                                            }
                                                            New-UDGrid -Item -ExtraSmallSize 4 -Children {
                                                                New-UDButton -Text '🗑️ Delete' -Color secondary -FullWidth -OnClick {
                                                                    # Show confirmation dialog
                                                                    Show-UDModal -Content {
                                                                        New-UDCard -Title '⚠️ Confirm Deletion' -Content {
                                                                            New-UDTypography -Text "Are you sure you want to delete the entry at $($entry.time) on $($parsedDate.ToString('MM/dd/yyyy'))?" -Variant body1 -Style @{
                                                                                marginBottom = '20px'
                                                                                textAlign    = 'center'
                                                                            }
                                                                            New-UDTypography -Text "Entry Types: $($entry.entry_types -join ', ')" -Variant body2 -Style @{
                                                                                marginBottom = '20px'
                                                                                textAlign    = 'center'
                                                                                fontWeight   = 'bold'
                                                                            }
                                                                            New-UDTypography -Text 'This action cannot be undone. A backup will be created automatically.' -Variant caption -Style @{
                                                                                marginBottom = '20px'
                                                                                textAlign    = 'center'
                                                                                color        = '#666'
                                                                                fontStyle    = 'italic'
                                                                            }

                                                                            New-UDGrid -Container -Children {
                                                                                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                                                                                    New-UDButton -Text '❌ Cancel' -Color default -FullWidth -OnClick {
                                                                                        Hide-UDModal
                                                                                    }
                                                                                }
                                                                                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                                                                                    New-UDButton -Text '🗑️ Delete Entry' -Color secondary -FullWidth -OnClick {
                                                                                        try {
                                                                                            # Create backup first
                                                                                            Import-Module UserManagement -Force
                                                                                            $UserData = Initialize-UserContext -UserEmail $User

                                                                                            # Ensure EntriesPath is available
                                                                                            if (-not $UserData.EntriesPath -and $UserData.UserDataPath) {
                                                                                                $UserData | Add-Member -MemberType NoteProperty -Name 'EntriesPath' -Value (Join-Path $UserData.UserDataPath 'health-data/entries.json') -Force
                                                                                            }

                                                                                            $AllEntries = Get-Content $UserData.EntriesPath -Raw | ConvertFrom-Json

                                                                                            # Create backup file
                                                                                            $backupPath = $UserData.EntriesPath + ".backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                                                                                            $AllEntries | ConvertTo-Json -Depth 10 | Set-Content -Path $backupPath -Encoding UTF8

                                                                                            # Remove the entry
                                                                                            $UpdatedEntries = $AllEntries | Where-Object { $_.entry_id -ne $entry.entry_id }

                                                                                            # Save updated entries
                                                                                            $UpdatedEntries | ConvertTo-Json -Depth 10 | Set-Content -Path $UserData.EntriesPath -Encoding UTF8

                                                                                            Show-UDToast -Message "✅ Successfully deleted entry at $($entry.time). Backup created." -MessageColor Green -Duration 4000

                                                                                            # Hide the modal
                                                                                            Hide-UDModal

                                                                                            # Refresh the data by triggering date change
                                                                                            Invoke-UDJavaScript -JavaScript @'
                                                                                                document.getElementById('selectedDate').dispatchEvent(new Event('change'));
'@
                                                                                        }
                                                                                        catch {
                                                                                            Show-UDToast -Message "❌ Error deleting entry: $($_.Exception.Message)" -MessageColor Red -Duration 6000
                                                                                            Write-Error "Error deleting entry: $($_.Exception.Message)"
                                                                                            Hide-UDModal
                                                                                        }
                                                                                    }
                                                                                }
                                                                            }
                                                                        }
                                                                    } -FullWidth -MaxWidth 'sm'
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            } -Style @{
                                                padding         = '20px'
                                                margin          = '10px 0'
                                                backgroundColor = '#f8f9fa'
                                                borderLeft      = '4px solid #007bff'
                                                borderRadius    = '8px'
                                            }
                                        }

                                        # Update the entries container
                                        Set-UDElement -Id 'entriesContainer' -Content {
                                            $entriesContent
                                        }

                                        # Show summary info
                                        $entryTypeCount = @{}
                                        $DayEntries | ForEach-Object {
                                            $_.entry_types | ForEach-Object {
                                                if ($entryTypeCount.ContainsKey($_)) {
                                                    $entryTypeCount[$_]++
                                                }
                                                else {
                                                    $entryTypeCount[$_] = 1
                                                }
                                            }
                                        }

                                        $summaryItems = $entryTypeCount.GetEnumerator() | ForEach-Object {
                                            "$($_.Key): $($_.Value)"
                                        }

                                        Set-UDElement -Id 'summaryContainer' -Content {
                                            New-UDAlert -Severity info -Text "📊 Day Summary: $($DayEntries.Count) entries | $($summaryItems -join ' | ')"
                                        }

                                        Show-UDToast -Message "📋 Loaded $($DayEntries.Count) health entries for $($parsedDate.ToString('MM/dd/yyyy'))" -MessageColor Blue -Duration 3000
                                    }
                                    else {
                                        Set-UDElement -Id 'entriesContainer' -Content {
                                            New-UDAlert -Severity warning -Text "No health entries found for $($parsedDate.ToString('MM/dd/yyyy')). Please select a date that has existing health data."
                                        }
                                        Set-UDElement -Id 'summaryContainer' -Content { }
                                    }
                                }
                                else {
                                    Set-UDElement -Id 'entriesContainer' -Content {
                                        New-UDAlert -Severity error -Text "No entries file found. Please create some health entries first."
                                    }
                                    Set-UDElement -Id 'summaryContainer' -Content { }
                                }
                            }
                            catch {
                                Show-UDToast -Message "❌ Error loading entries: $($_.Exception.Message)" -MessageColor Red -Duration 5000
                                Write-Error "Error loading entries for date: $($_.Exception.Message)"
                                Set-UDElement -Id 'entriesContainer' -Content {
                                    New-UDAlert -Severity error -Text "Error loading entries: $($_.Exception.Message)"
                                }
                            }
                        }
                    }
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                    New-UDButton -Text '🔄 Refresh Data' -Color secondary -FullWidth -OnClick {
                        # Trigger the date change event to reload data
                        $currentSelectedDate = (Get-UDElement -Id 'selectedDate').value
                        if (-not [string]::IsNullOrWhiteSpace($currentSelectedDate)) {
                            Invoke-UDJavaScript -JavaScript @'
                                document.getElementById('selectedDate').dispatchEvent(new Event('change'));
'@
                        }
                    }
                }
            }

            New-UDTypography -Text '💡 Select a date above to load all health entries for editing' -Variant caption -Style @{
                marginTop = '15px'
                color     = '#666'
                fontStyle = 'italic'
                textAlign = 'center'
            }
        } -Style @{ marginBottom = '20px' }

        # Summary Information Container
        New-UDElement -Id 'summaryContainer' -Tag 'div'

        # Entries Container
        New-UDElement -Id 'entriesContainer' -Tag 'div' -Content {
            New-UDTypography -Text '👆 Please select a date above to view and edit health entries' -Variant body1 -Style @{
                textAlign = 'center'
                color     = '#999'
                margin    = '40px 0'
                fontStyle = 'italic'
            }
        }

        # Help Section
        New-UDCard -Title 'ℹ️ Help & Tips (Schema v2.0)' -Content {
            New-UDList -Children {
                New-UDListItem -Label '📝 Each entry shows the complete v2 schema JSON structure'
                New-UDListItem -Label '🏷️ Entry type badges show what health data is included in each entry'
                New-UDListItem -Label '⚠️ Ensure all required fields are present: entry_id, user_email, date, time, entry_types, data, notes'
                New-UDListItem -Label '🔢 Entry IDs use yyMMddHHmm format (e.g., 2507151430 for July 15, 2025, 2:30 PM)'
                New-UDListItem -Label '📊 Data section contains arrays for medications, activities, pain; objects for mood, vitals, weight, sleep'
                New-UDListItem -Label '💾 Click Update Entry to save changes to a health entry'
                New-UDListItem -Label '�️ Delete operations create automatic timestamped backups'
                New-UDListItem -Label '� Use Refresh to reload data if it seems outdated'
                New-UDListItem -Label '� All data is user-specific and isolated from other users'
            }
        } -Style @{ marginTop = '30px'; backgroundColor = '#f0f8ff' }
    }
}

New-UDApp -Title 'Update Entry' -Pages $Pages