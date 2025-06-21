New-UDApp -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Data Entry Form" -Variant h4 -Style @{marginBottom = "20px"}
        
        New-UDForm -Content {
            New-UDTextbox -Id "datetime" -Label "Date/Time (MST)" -Type datetime-local -FullWidth
            New-UDTextbox -Id "notes" -Label "Notes" -Multiline -Rows 4 -FullWidth
            New-UDUpload -Id "photo" -Text "Upload Photo" -Accept ".jpg,.jpeg,.png,.gif"
        } -OnSubmit {
            param($Data)
            
            # Get the submitted data
            $DateTime = $Data.datetime
            $Notes = $Data.notes
            $Photo = $Data.photo
            
            # Convert datetime to MST if needed
            if ($DateTime) {
                $MST = [System.TimeZoneInfo]::FindSystemTimeZoneById("Mountain Standard Time")
                $DateTimeMST = [System.TimeZoneInfo]::ConvertTime([DateTime]$DateTime, $MST)
            }
            
            # Handle photo upload
            $PhotoFileName = $null
            if ($Photo -and $Photo.Count -gt 0) {
                # Create directory if it doesn't exist
                $PhotoDir = "/fusion-data/img"
                if (-not (Test-Path $PhotoDir)) {
                    New-Item -ItemType Directory -Path $PhotoDir -Force
                }
                
                # Generate filename in MMdd format
                $DateForFilename = if ($DateTime) { 
                    $DateTimeMST.ToString("MMdd") 
                } else { 
                    (Get-Date).ToString("MMdd") 
                }
                
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
            
            # Create form data object
            $FormData = @{
                DateTime = $DateTimeMST.ToString("yyyy-MM-dd HH:mm:ss MST")
                Notes = $Notes
                Photo = $PhotoFileName
                Timestamp = Get-Date
            }
            
            # Show success message
            Show-UDToast -Message "Entry submitted successfully!" -MessageColor Success
            
            # Optionally save to a JSON file
            $FilePath = "/home/data/entries.json"
            if (Test-Path $FilePath) {
                $ExistingData = Get-Content $FilePath | ConvertFrom-Json
                $AllData = @($ExistingData) + $FormData
            } else {
                $AllData = @($FormData)
            }
            $AllData | ConvertTo-Json -Depth 3 | Out-File $FilePath
            
            # Reset the form
            Clear-UDElement -Id "datetime"
            Clear-UDElement -Id "notes"
            Clear-UDElement -Id "photo"
            
            # Refresh the submissions display
            Sync-UDElement -Id "submissions"
        }
        
        # Display recent submissions
        New-UDDynamic -Content {
            $FilePath = "/home/data/entries.json"
            if (Test-Path $FilePath) {
                $Data = Get-Content $FilePath | ConvertFrom-Json
                New-UDTypography -Text "Recent Entries:" -Variant h6 -Style @{marginTop = "30px"; marginBottom = "10px"}
                
                foreach ($Entry in ($Data | Select-Object -Last 10)) {
                    New-UDCard -Content {
                        New-UDTypography -Text "DateTime: $($Entry.DateTime)" -Variant body2
                        New-UDTypography -Text "Notes: $($Entry.Notes)" -Variant body2
                        if ($Entry.Photo) {
                            New-UDTypography -Text "Photo: $($Entry.Photo)" -Variant body2
                            New-UDImage -Url "/fusion-data/img/$($Entry.Photo)" -Height 100 -Width 100
                        }
                        New-UDTypography -Text "Submitted: $($Entry.Timestamp)" -Variant caption -Style @{color = "gray"}
                    } -Style @{marginBottom = "10px"}
                }
            } else {
                New-UDTypography -Text "No entries yet." -Variant body1
            }
        } -Id "submissions"
    }
}