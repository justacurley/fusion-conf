New-UDApp -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Health Recovery Entry Form" -Variant h4 -Style @{marginBottom = "20px"}
        
        New-UDForm -Content {
            # Date and Time fields
            New-UDGrid -Container -Content {
                $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time') | ForEach-Object { $_.ToString("MMdd HHmm") }
                $MSTMMDD = $MSTDate.split(" ")[0]
                $MSTHHMM = $MSTDate.split(" ")[1]
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "date" -Label "Date (MMDD)" -Placeholder "0620" -FullWidth -Value $MSTMMDD
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "timestamp" -Label "Time (HHMM)" -Placeholder "1430" -FullWidth -Value $MSTHHMM
                }
            }
            
            # Medications section
            New-UDTypography -Text "Medications" -Variant h6 -Style @{marginTop = "20px"; marginBottom = "10px"}
            New-UDDynamic -Id "medications-section" -Content {
                New-UDGrid -Container -Content {
                    # Initial medication row
                    New-UDGrid -Item -ExtraSmallSize 12 -Content {
                        New-UDGrid -Container -Content {
                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                New-UDSelect -Id "medication_1" -Label "Medication" -Option @(
                                    New-UDSelectOption -Name "Select..." -Value ""
                                    New-UDSelectOption -Name "Oxycodone" -Value "oxycodone"
                                    New-UDSelectOption -Name "Dilaudid" -Value "dilaudid"
                                    New-UDSelectOption -Name "Journavx" -Value "journavx"
                                    New-UDSelectOption -Name "Tylenol" -Value "tylenol"
                                    New-UDSelectOption -Name "Valium" -Value "valium"
                                    New-UDSelectOption -Name "Lexapro" -Value "lexapro"
                                )
                            }
                            New-UDGrid -Item -ExtraSmallSize 5 -Content {
                                New-UDSelect -Id "dose_1" -Label "Dose" -Option @(
                                    New-UDSelectOption -Name "Select..." -Value ""
                                ) -Disabled
                            }
                            New-UDGrid -Item -ExtraSmallSize 2 -Content {
                                New-UDButton -Text "+" -Id "add-medication" -Color primary -Size small
                            }
                        }
                    }
                }
            }
            
            # Pain section
            New-UDTypography -Text "Pain Levels (0-10)" -Variant h6 -Style @{marginTop = "20px"; marginBottom = "10px"}
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "pain_back" -Label "Back Pain" -Placeholder "6-7-8"
                }
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "pain_legs" -Label "Legs Pain" -Placeholder "5-6"
                }
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "pain_quads" -Label "Quads Pain" -Placeholder "6-7"
                }
            }
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "pain_glutes" -Label "Glutes Pain" -Placeholder "5-6"
                }
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "pain_righthip" -Label "Right Hip Pain" -Placeholder "4-5"
                }
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "pain_other" -Label "Other Location"
                    New-UDTextbox -Id "pain_other_level" -Label "Other Pain Level"
                }
            }
            
            # Activities section
            New-UDTypography -Text "Activities (Duration in minutes)" -Variant h6 -Style @{marginTop = "20px"; marginBottom = "10px"}
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "activity_standing" -Label "Standing (minutes)" -Type number
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "activity_walking" -Label "Walking (minutes)" -Type number
                }
            }
            
            # Vitals section
            New-UDTypography -Text "Vital Signs" -Variant h6 -Style @{marginTop = "20px"; marginBottom = "10px"}
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "o2" -Label "Oxygen Saturation %" -Placeholder "88"
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "bpr" -Label "Blood Pressure" -Placeholder "129/59"
                }
            }
            
            # Notes and Sleep
            New-UDGrid -Container -Content {
                New-UDGrid -Item -ExtraSmallSize 8 -Content {
                    New-UDTextbox -Id "notes" -Label "Notes" -Multiline -Rows 3 -FullWidth
                }
                New-UDGrid -Item -ExtraSmallSize 4 -Content {
                    New-UDTextbox -Id "sleep" -Label "Sleep Duration" -Placeholder "7:39"
                }
            }
            
            # Photo upload
            New-UDUpload -Id "photo" -Text "Upload Photo" -Accept ".jpg,.jpeg,.png,.gif"
        } -OnSubmit {
            param($Data)
            
            # Get form data
            $Date = $Data.date
            $Timestamp = $Data.timestamp
            $Photo = $Data.photo
            
            # Build medications object
            $Medications = @{}
            $medicationCounter = 1
            while ($Data.ContainsKey("medication_$medicationCounter")) {
                $med = $Data["medication_$medicationCounter"]
                $dose = $Data["dose_$medicationCounter"]
                if ($med -and $dose) {
                    $Medications[$med] = $dose
                }
                $medicationCounter++
            }
            
            # Build pain object
            $Pain = @{}
            if ($Data.pain_back) { $Pain["back"] = $Data.pain_back }
            if ($Data.pain_legs) { $Pain["legs"] = $Data.pain_legs }
            if ($Data.pain_quads) { $Pain["quads"] = $Data.pain_quads }
            if ($Data.pain_glutes) { $Pain["glutes"] = $Data.pain_glutes }
            if ($Data.pain_righthip) { $Pain["righthip"] = $Data.pain_righthip }
            if ($Data.pain_other -and $Data.pain_other_level) { $Pain[$Data.pain_other] = $Data.pain_other_level }
            
            # Build activities object
            $Activities = @{}
            if ($Data.activity_standing) { $Activities["standing"] = [int]$Data.activity_standing }
            if ($Data.activity_walking) { $Activities["walking"] = [int]$Data.activity_walking }
            
            # Handle photo upload
            $PhotoFileName = $null
            if ($Photo -and $Photo.Count -gt 0) {
                # Create directory if it doesn't exist
                $PhotoDir = "/fusion-data/img"
                if (-not (Test-Path $PhotoDir)) {
                    New-Item -ItemType Directory -Path $PhotoDir -Force
                }
                
                # Generate filename in MMdd format
                $DateForFilename = if ($Date) { $Date } else { (Get-Date).ToString("MMdd") }
                
                # Get file extension from uploaded file
                $OriginalFileName = $Photo[0].Name
                $FileExtension = [System.IO.Path]::GetExtension($OriginalFileName)
                
                # Create new filename
                $PhotoFileName = "$DateForFilename$FileExtension"
                $PhotoPath = Join-Path $PhotoDir $PhotoFileName
                
                # Save the uploaded file
                $PhotoData = $Photo[0].Data
                [System.IO.File]::WriteAllBytes($PhotoPath, $PhotoData)
            }
            
            # Create entry object matching existing schema
            $Entry = @{
                "Medications" = $Medications
                "Pain" = $Pain
                "Activities" = $Activities
                "o2" = $Data.o2 ?? ""
                "bpr" = $Data.bpr ?? ""
                "note" = $Data.notes ?? ""
            }
            
            # Add photo if uploaded
            if ($PhotoFileName) {
                $Entry["photo"] = $PhotoFileName
            }
            
            # Load existing entries or create new structure
            $FilePath = "/fusion-data/entries/entries.json"
            $EntriesData = @{}
            
            if (Test-Path $FilePath) {
                try {
                    $EntriesData = Get-Content $FilePath | ConvertFrom-Json -AsHashtable
                } catch {
                    $EntriesData = @{}
                }
            }
            
            # Create date entry if it doesn't exist
            if (-not $EntriesData.ContainsKey($Date)) {
                $EntriesData[$Date] = @{}
            }
            
            # Add sleep field at date level if provided
            if ($Data.sleep) {
                $EntriesData[$Date]["Sleep"] = $Data.sleep
            }
            
            # Add the timestamp entry
            $EntriesData[$Date][$Timestamp] = $Entry
            
            # Save back to file
            try {
                # Ensure directory exists
                $DirPath = Split-Path $FilePath -Parent
                if (-not (Test-Path $DirPath)) {
                    New-Item -ItemType Directory -Path $DirPath -Force
                }
                
                $EntriesData | ConvertTo-Json -Depth 10 | Out-File $FilePath -Encoding UTF8
                Show-UDToast -Message "Entry saved successfully!" -MessageColor Success
            } catch {
                Show-UDToast -Message "Error saving entry: $($_.Exception.Message)" -MessageColor Error
            }
            
            # Reset the form
            @("date", "timestamp", "pain_back", "pain_legs", "pain_quads", "pain_glutes", "pain_righthip", "pain_other", "pain_other_level",
              "activity_standing", "activity_walking", "o2", "bpr", "notes", "sleep", "photo") | ForEach-Object {
                Clear-UDElement -Id $_
            }
            
            # Reset medications section
            Sync-UDElement -Id "medications-section"
            
            # Refresh the submissions display
            Sync-UDElement -Id "submissions"
        }
        
        # Display recent submissions
        New-UDDynamic -Content {
            $FilePath = "/fusion-data/entries/entries.json"
            if (Test-Path $FilePath) {
                try {
                    $Data = Get-Content $FilePath | ConvertFrom-Json -AsHashtable
                    New-UDTypography -Text "Recent Entries:" -Variant h6 -Style @{marginTop = "30px"; marginBottom = "10px"}
                    
                    # Get the most recent entries across all dates
                    $RecentEntries = @()
                    foreach ($Date in $Data.Keys) {
                        foreach ($Time in $Data[$Date].Keys) {
                            if ($Time -ne "Sleep") {
                                $Entry = $Data[$Date][$Time]
                                $Entry["Date"] = $Date
                                $Entry["Time"] = $Time
                                $RecentEntries += $Entry
                            }
                        }
                    }
                    
                    # Sort by date and time, take last 10
                    $SortedEntries = $RecentEntries | Sort-Object Date, Time | Select-Object -Last 10
                    
                    foreach ($Entry in $SortedEntries) {
                        New-UDCard -Content {
                            New-UDTypography -Text "Date: $($Entry.Date) Time: $($Entry.Time)" -Variant h6
                            
                            if ($Entry.Medications -and $Entry.Medications.Keys.Count -gt 0) {
                                $MedText = ($Entry.Medications.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ", "
                                New-UDTypography -Text "Medications: $MedText" -Variant body2
                            }
                            
                            if ($Entry.Pain -and $Entry.Pain.Keys.Count -gt 0) {
                                $PainText = ($Entry.Pain.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)" }) -join ", "
                                New-UDTypography -Text "Pain: $PainText" -Variant body2
                            }
                            
                            if ($Entry.Activities -and $Entry.Activities.Keys.Count -gt 0) {
                                $ActivityText = ($Entry.Activities.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value)min" }) -join ", "
                                New-UDTypography -Text "Activities: $ActivityText" -Variant body2
                            }
                            
                            if ($Entry.o2) { New-UDTypography -Text "O2: $($Entry.o2)%" -Variant body2 }
                            if ($Entry.bpr) { New-UDTypography -Text "BP: $($Entry.bpr)" -Variant body2 }
                            if ($Entry.note) { New-UDTypography -Text "Notes: $($Entry.note)" -Variant body2 }
                            
                            if ($Entry.photo) {
                                New-UDTypography -Text "Photo: $($Entry.photo)" -Variant body2
                                New-UDImage -Url "/fusion-data/img/$($Entry.photo)" -Height 100 -Width 100
                            }
                        } -Style @{marginBottom = "10px"}
                    }
                } catch {
                    New-UDTypography -Text "Error loading entries: $($_.Exception.Message)" -Variant body1
                }
            } else {
                New-UDTypography -Text "No entries yet." -Variant body1
            }
        } -Id "submissions"
    }
    
    # Add JavaScript for medication interactions
    New-UDElement -Tag "script" -Content {
        "
        let medicationCount = 1;
        
        const medicationDoses = {
            'oxycodone': ['5mg', '10mg'],
            'dilaudid': ['4mg', '2mg'],
            'journavx': ['100mg', '50mg'],
            'tylenol': ['1g', '500mg'],
            'valium': ['5mg', '2.5mg'],
            'lexapro': ['10mg', '20mg']
        };
        
        function updateDoseOptions(medicationSelect, doseSelect) {
            const medication = medicationSelect.value;
            
            // Clear existing options
            doseSelect.innerHTML = '<option value=\"\">Select...</option>';
            
            if (medication && medicationDoses[medication]) {
                doseSelect.disabled = false;
                medicationDoses[medication].forEach(dose => {
                    const option = document.createElement('option');
                    option.value = dose;
                    option.textContent = dose;
                    doseSelect.appendChild(option);
                });
            } else {
                doseSelect.disabled = true;
            }
        }
        
        function addMedicationRow() {
            medicationCount++;
            const container = document.querySelector('#medications-section .MuiGrid-container');
            
            if (container) {
                const newRow = document.createElement('div');
                newRow.className = 'MuiGrid-item MuiGrid-grid-xs-12';
                newRow.innerHTML = `
                    <div class=\"MuiGrid-container MuiGrid-spacing-xs-3\">
                        <div class=\"MuiGrid-item MuiGrid-grid-xs-5\">
                            <div class=\"MuiFormControl-root\">
                                <label class=\"MuiInputLabel-root\">Medication</label>
                                <select id=\"medication_${medicationCount}\" class=\"MuiSelect-root medication-select\">
                                    <option value=\"\">Select...</option>
                                    <option value=\"oxycodone\">Oxycodone</option>
                                    <option value=\"dilaudid\">Dilaudid</option>
                                    <option value=\"journavx\">Journavx</option>
                                    <option value=\"tylenol\">Tylenol</option>
                                    <option value=\"valium\">Valium</option>
                                    <option value=\"lexapro\">Lexapro</option>
                                </select>
                            </div>
                        </div>
                        <div class=\"MuiGrid-item MuiGrid-grid-xs-5\">
                            <div class=\"MuiFormControl-root\">
                                <label class=\"MuiInputLabel-root\">Dose</label>
                                <select id=\"dose_${medicationCount}\" class=\"MuiSelect-root dose-select\" disabled>
                                    <option value=\"\">Select...</option>
                                </select>
                            </div>
                        </div>
                        <div class=\"MuiGrid-item MuiGrid-grid-xs-2\">
                            <button type=\"button\" class=\"MuiButton-root remove-medication\" onclick=\"removeMedicationRow(this)\">-</button>
                        </div>
                    </div>
                `;
                
                container.appendChild(newRow);
                
                // Add event listener to the new medication select
                const newMedicationSelect = document.getElementById(`medication_${medicationCount}`);
                const newDoseSelect = document.getElementById(`dose_${medicationCount}`);
                
                newMedicationSelect.addEventListener('change', function() {
                    updateDoseOptions(this, newDoseSelect);
                });
            }
        }
        
        function removeMedicationRow(button) {
            const row = button.closest('.MuiGrid-item.MuiGrid-grid-xs-12');
            if (row) {
                row.remove();
            }
        }
        
        document.addEventListener('DOMContentLoaded', function() {
            // Handle initial medication dropdown
            const initialMedSelect = document.getElementById('medication_1');
            const initialDoseSelect = document.getElementById('dose_1');
            
            if (initialMedSelect && initialDoseSelect) {
                initialMedSelect.addEventListener('change', function() {
                    updateDoseOptions(this, initialDoseSelect);
                });
            }
            
            // Handle add medication button
            const addButton = document.getElementById('add-medication');
            if (addButton) {
                addButton.addEventListener('click', addMedicationRow);
            }
        });
        
        // Make functions globally available
        window.addMedicationRow = addMedicationRow;
        window.removeMedicationRow = removeMedicationRow;
        "
    }
}