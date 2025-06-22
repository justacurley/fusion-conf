New-UDApp -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Health Recovery Entry Form" -Variant h4 -Style @{marginBottom = "20px" }
        New-UDTypography -Text "Entry Date and Time" -Variant h6 -Style  @{marginTop = "20px"; marginBottom = "10px" }
        New-UDForm -Content {
            # Date and Time fields
            New-UDGrid -Container -Content {
                $MSTDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date), 'Mountain Standard Time') | ForEach-Object { $_.ToString("MMdd HHmm") }
                $MSTMMDD = $MSTDate.split(" ")[0]
                $MSTHHMM = $MSTDate.split(" ")[1]
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "date" -Label "Date (MMDD)" -Placeholder $MSTMMDD -FullWidth -Value $MSTMMDD
                }
                New-UDGrid -Item -ExtraSmallSize 6 -Content {
                    New-UDTextbox -Id "timestamp" -Label "Time (HHMM)" -Placeholder $MMSTHHMM -FullWidth -Value $MSTHHMM
                }
            }
            New-UDSelect -Id 'FirstSelect' -Option {
                New-UDSelectOption -Name 'Category A' -Value 'A'
                New-UDSelectOption -Name 'Category B' -Value 'B'
            } -Multiple -OnChange {
                Sync-UDElement -Id 'DynamicSection'
            }
            New-UDDynamic -Id 'DynamicSection' -Content {
                # Logic to determine options for the second dropdown based on the first select's value
                $selectedValue = (Get-UDElement -Id 'FirstSelect').Value

                if ($selectedValue -eq 'A') {
                    New-UDSelect -Id 'SecondSelect' -Option {
                        New-UDSelectOption -Name 'Item 1A' -Value '1A'
                        New-UDSelectOption -Name 'Item 2A' -Value '2A'
                    }
                }
                elseif ($selectedValue -eq 'B') {
                    New-UDSelect -Id 'SecondSelect' -Option {
                        New-UDSelectOption -Name 'Item 1B' -Value '1B'
                        New-UDSelectOption -Name 'Item 2B' -Value '2B'
                    }
                }
            }
            # Medicatins Sectin
            # New-UDTypography -Text "Medications" -Variant h6 -Style @{marginTop = "20px" }
            # New-UDSelect -Id "meds" -Option {
            #     try {
            #         $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/schema.json" | ConvertFrom-Json -AsHashtable
            #         $Dosages = $MedData['Medications']
            #     }
            #     catch {
            #         Write-Error "Failed to get or parse data $_"
            #     }
            #     foreach ($key in $Dosages.keys) {
            #         New-UDSelectOption -Name $key -Value $key
            #     }               
            # } -Multiple -OnChange {
            #     New-UDSelect -Id "doses" -Option {
            #         foreach ($item in $EventData.meds) {
            #             Show-UDToast -Message $item -Persistent
            #         }
            #     }
            #     foreach ($item in $EventData.meds) {
            #         Show-UDToast -Message "$item was selected" -Duration 5000
            #     }            
            #     }
        } -OnSubmit {
            param($Data)
            Write-Output $Data
        }
    }
}