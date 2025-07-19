#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Converts entries.json from the legacy format to v2 schema format (flat array).

.DESCRIPTION
    This script reads the existing entries.json file and converts it to match the
    unified health entry schema v2.0 as a flat array of entries.

.PARAMETER InputPath
    Path to the input entries.json file

.PARAMETER OutputPath
    Path for the output entries_v2.json file

.PARAMETER UserEmail
    User email to associate with all entries (required for v2 schema)

.EXAMPLE
    ./Convert-EntriesToV2-Simple.ps1 -InputPath "./entries.json" -OutputPath "./entries_v2.json" -UserEmail "user@example.com"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$InputPath = "./entries.json",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./entries_v2.json",

    [Parameter(Mandatory = $false)]
    [string]$UserEmail = "user@example.com"
)

# Helper function to convert date format from MMDD to YYYY-MM-DD
function Convert-DateFormat {
    param([string]$DateKey)

    # Assume current year (2025) for MMDD format
    $currentYear = 2025
    $month = $DateKey.Substring(0, 2)
    $day = $DateKey.Substring(2, 2)

    return "$currentYear-$month-$day"
}

# Helper function to convert time format from HHMM to HH:MM
function Convert-TimeFormat {
    param([string]$TimeKey)

    if ($TimeKey.Length -ne 4) {
        return $null
    }

    $hour = $TimeKey.Substring(0, 2)
    $minute = $TimeKey.Substring(2, 2)

    return "$($hour):$($minute)"
}

# Helper function to create composite entry ID (yyMMddHHmm)
function New-EntryId {
    param([string]$Date, [string]$Time)

    # Extract year (last 2 digits), month, day from YYYY-MM-DD
    $dateParts = $Date -split '-'
    $year = $dateParts[0].Substring(2, 2)  # Get last 2 digits of year
    $month = $dateParts[1]
    $day = $dateParts[2]

    # Extract hour and minute from HH:MM
    $timeParts = $Time -split ':'
    $hour = $timeParts[0]
    $minute = $timeParts[1]

    return "${year}${month}${day}${hour}${minute}"
}

# Main conversion logic
try {
    Write-Host "Loading entries from: $InputPath"

    if (-not (Test-Path $InputPath)) {
        throw "Input file not found: $InputPath"
    }

    $inputData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
    $outputEntries = @()

    Write-Host "Converting entries to v2 format..."

    foreach ($dateProperty in $inputData.PSObject.Properties) {
        $dateKey = $dateProperty.Name
        $dateData = $dateProperty.Value

        # Skip if this is not a valid date (MMDD format)
        if ($dateKey.Length -ne 4 -or $dateKey -notmatch '^\d{4}$') {
            Write-Warning "Skipping invalid date key: $dateKey"
            continue
        }

        $convertedDate = Convert-DateFormat -DateKey $dateKey

        foreach ($timeProperty in $dateData.PSObject.Properties) {
            $timeKey = $timeProperty.Name
            $timeData = $timeProperty.Value

            # Skip special fields like Sleep, max_pain_level, ScarImage
            if ($timeKey -in @("Sleep", "max_pain_level", "ScarImage")) {
                continue
            }

            $convertedTime = Convert-TimeFormat -TimeKey $timeKey

            if (-not $convertedTime) {
                Write-Warning "Skipping invalid time key: $timeKey for date: $dateKey"
                continue
            }

            # Build data object and entry types
            $data = @{}
            $entryTypes = @()

            # Handle Vitals (blood pressure, oxygen saturation)
            if ($timeData.bpr -or $timeData.o2) {
                $vitals = @{
                    blood_pressure = if ($timeData.bpr -and $timeData.bpr -ne "") { $timeData.bpr } else { $null }
                    heart_rate = $null  # Default value
                    oxygen_saturation = if ($timeData.o2 -and $timeData.o2 -ne "") { [int]$timeData.o2 } else { $null }
                    temperature = $null  # Default value
                }
                $data.vitals = $vitals
                $entryTypes += "vitals"
            }

            # Handle Medications
            if ($timeData.Medications -and $timeData.Medications.PSObject.Properties) {
                $medications = @()
                foreach ($med in $timeData.Medications.PSObject.Properties) {
                    if ($med.Value -and $med.Value -ne "") {
                        $medications += @{
                            name = $med.Name
                            dosage = $med.Value
                        }
                    }
                }
                if ($medications.Count -gt 0) {
                    $data.medications = $medications
                    $entryTypes += "medications"
                }
            }

            # Handle Activities
            if ($timeData.Activities -and $timeData.Activities.PSObject.Properties) {
                $activities = @()
                foreach ($activity in $timeData.Activities.PSObject.Properties) {
                    if ($activity.Value.duration) {
                        $activityObj = @{
                            name = $activity.Name
                            duration_minutes = [int]$activity.Value.duration
                        }

                        if ($activity.Value.note -and $activity.Value.note -ne "") {
                            $activityObj.note = $activity.Value.note
                        }

                        $activities += $activityObj
                    }
                }
                if ($activities.Count -gt 0) {
                    $data.activities = $activities
                    $entryTypes += "activities"
                }
            }

            # Handle Pain
            if ($timeData.Pain -and $timeData.Pain.PSObject.Properties) {
                $pain = @()
                foreach ($painLocation in $timeData.Pain.PSObject.Properties) {
                    if ($painLocation.Value.pain_level) {
                        $painObj = @{
                            location = $painLocation.Name
                            severity = [decimal]$painLocation.Value.pain_level
                        }

                        if ($painLocation.Value.note -and $painLocation.Value.note -ne "") {
                            $painObj.note = $painLocation.Value.note
                        }

                        $pain += $painObj
                    }
                }
                if ($pain.Count -gt 0) {
                    $data.pain = $pain
                    $entryTypes += "pain"
                }
            }

            # Only create entry if we have some data
            if ($data.Keys.Count -gt 0) {
                $entry = [ordered]@{
                    entry_id = New-EntryId -Date $convertedDate -Time $convertedTime
                    user_email = $UserEmail
                    date = $convertedDate
                    time = $convertedTime
                    entry_types = $entryTypes
                    data = $data
                    notes = if ($timeData.note -and $timeData.note -ne "") { $timeData.note } else { "" }
                }

                $outputEntries += $entry
            }
        }
    }

    Write-Host "Converted $($outputEntries.Count) entries"

    # Sort entries by entry_id (which is chronological)
    $outputEntries = $outputEntries | Sort-Object entry_id

    Write-Host "Writing converted data to: $OutputPath"

    # Ensure output directory exists
    $outputDir = Split-Path -Parent $OutputPath
    if ($outputDir -and -not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }

    # Convert to JSON as a simple array and save
    $jsonOutput = $outputEntries | ConvertTo-Json -Depth 10 -Compress:$false
    Set-Content -Path $OutputPath -Value $jsonOutput -Encoding UTF8

    Write-Host "Conversion completed successfully!"
    Write-Host "Total entries converted: $($outputEntries.Count)"
    Write-Host "Output saved to: $OutputPath"

    # Show a sample of the first few entries
    Write-Host "`nSample of converted entries:"
    $outputEntries[0..2] | ForEach-Object {
        Write-Host "Entry ID: $($_.entry_id), Date: $($_.date), Time: $($_.time), Types: $($_.entry_types -join ', ')"
    }

} catch {
    Write-Error "Conversion failed: $($_.Exception.Message)"
    Write-Error $_.ScriptStackTrace
    exit 1
}
