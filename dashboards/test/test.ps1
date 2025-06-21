New-UDApp -Content {
    New-UDContainer -Content {
        New-UDTypography -Text "Health Recovery Entry Form" -Variant h4 -Style @{marginBottom = "20px" }
        New-UDTypography -Text "Entry Date and Time" -Variant h6 -Style  @{marginTop = "20px"; marginBottom="10px"}
        New-UDForm -Content {
            # Get Medication Data
            try {
                $MedData = Get-Content -Path "/home/data/Repository/fusion-data/entries/schema.json" | ConvertFrom-Json
                $Dosages = $MedData.Medications
                Show-UDModal -Content {
                    New-UDTypography -Text "Json data loaded"
                    New-UDJson -json ($Dosages | ConvertTo-Json)
                }

            } catch {
                Write-Error "Failed to get or parse data $_"
            }
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
            New-UDTypography -Text "Medications" -Variant h6 -Style @{marginTop = "20px"}
            New-UDSelect -Id "meds" -Option {
                New-UDSelectOption -Name "opt1" -Value "5mg"
                New-UDSelectOption -Name "opt2" -Value "10mg"
                New-UDSelectOption -Name "opt3" -Value "20mg"
            } -Multiple -PlaceHolder "Select Options" -OnChange {
                $EventData = $body | ConvertFrom-Json 
                Show-UDToast -Message "selected $($EventData -join ","")"
            }
        } -OnSubmit {
            param($Data)
            Write-Output $Data
        }
    }
}