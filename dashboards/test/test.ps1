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
            # Medicatins Sectin
            New-UDTypography -Text "Medications" -Variant h6 -Style @{marginTop = "20px" }
            New-UDSelect -Id "meds" -Option {
                try {
                    $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/schema.json" | ConvertFrom-Json -AsHashtable
                    $Dosages = $MedData['Medications']
                }
                catch {
                    Write-Error "Failed to get or parse data $_"
                }
                foreach ($key in $Dosages.keys) {
                    $Dosages[$key].foreach({
                            New-UDSelectOption -Name "$key - $_" -Value "$key - $_"
                        })
                }
            } -Multiple
        } -OnSubmit {}
    }
}
