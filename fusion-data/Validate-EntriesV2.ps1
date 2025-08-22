#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Validates entries_v2.json against the v2 schema requirements.

.DESCRIPTION
    This script performs basic validation to ensure the converted entries
    match the unified health entry schema v2.0 requirements.

.PARAMETER FilePath
    Path to the entries_v2.json file to validate

.EXAMPLE
    ./Validate-EntriesV2.ps1 -FilePath "./entries_v2.json"
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$FilePath = "./entries_v2.json"
)

function Test-EntryId {
    param([string]$EntryId)
    return $EntryId -match '^\d{10}$'
}

function Test-Email {
    param([string]$Email)
    return $Email -match '^[^@]+@[^@]+\.[^@]+$'
}

function Test-Date {
    param([string]$Date)
    return $Date -match '^\d{4}-\d{2}-\d{2}$'
}

function Test-Time {
    param([string]$Time)
    return $Time -match '^\d{2}:\d{2}$'
}

try {
    Write-Host "Validating entries from: $FilePath"

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $entries = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

    if (-not $entries -or $entries.Count -eq 0) {
        throw "No entries found or invalid JSON format"
    }

    Write-Host "Found $($entries.Count) entries to validate"

    $errors = @()
    $validatedCount = 0

    foreach ($entry in $entries) {
        $validatedCount++

        # Required fields validation
        if (-not $entry.entry_id) {
            $errors += "Entry $validatedCount : Missing entry_id"
        } elseif (-not (Test-EntryId $entry.entry_id)) {
            $errors += "Entry $validatedCount : Invalid entry_id format: $($entry.entry_id)"
        }

        if (-not $entry.user_email) {
            $errors += "Entry $validatedCount : Missing user_email"
        } elseif (-not (Test-Email $entry.user_email)) {
            $errors += "Entry $validatedCount : Invalid email format: $($entry.user_email)"
        }

        if (-not $entry.date) {
            $errors += "Entry $validatedCount : Missing date"
        } elseif (-not (Test-Date $entry.date)) {
            $errors += "Entry $validatedCount : Invalid date format: $($entry.date)"
        }

        if (-not $entry.time) {
            $errors += "Entry $validatedCount : Missing time"
        } elseif (-not (Test-Time $entry.time)) {
            $errors += "Entry $validatedCount : Invalid time format: $($entry.time)"
        }

        if (-not $entry.entry_types -or $entry.entry_types.Count -eq 0) {
            $errors += "Entry $validatedCount : Missing or empty entry_types"
        }

        if (-not $entry.data) {
            $errors += "Entry $validatedCount : Missing data object"
        }

        if ($null -eq $entry.notes) {
            $errors += "Entry $validatedCount : Missing notes field (can be empty string)"
        }

        # Data validation
        if ($entry.data) {
            # Validate vitals if present
            if ($entry.data.vitals) {
                $vitals = $entry.data.vitals
                if ($vitals.blood_pressure -and ($vitals.blood_pressure -notmatch '^\d{2,3}/\d{2,3}$')) {
                    $errors += "Entry $validatedCount : Invalid blood_pressure format"
                }
                if ($vitals.heart_rate -and ($vitals.heart_rate -lt 40 -or $vitals.heart_rate -gt 220)) {
                    $errors += "Entry $validatedCount : Invalid heart_rate value"
                }
                if ($vitals.oxygen_saturation -and ($vitals.oxygen_saturation -lt 70 -or $vitals.oxygen_saturation -gt 100)) {
                    $errors += "Entry $validatedCount : Invalid oxygen_saturation value"
                }
                if ($vitals.temperature -and ($vitals.temperature -lt 95.0 -or $vitals.temperature -gt 110.0)) {
                    $errors += "Entry $validatedCount : Invalid temperature value"
                }
            }

            # Validate medications if present
            if ($entry.data.medications) {
                foreach ($med in $entry.data.medications) {
                    if (-not $med.name -or -not $med.dosage) {
                        $errors += "Entry $validatedCount : Medication missing name or dosage"
                    }
                }
            }

            # Validate activities if present
            if ($entry.data.activities) {
                foreach ($activity in $entry.data.activities) {
                    if (-not $activity.name -or -not $activity.duration_minutes) {
                        $errors += "Entry $validatedCount : Activity missing name or duration_minutes"
                    } elseif ($activity.duration_minutes -lt 1 -or $activity.duration_minutes -gt 480) {
                        $errors += "Entry $validatedCount : Activity duration_minutes out of range (1-480)"
                    }
                }
            }

            # Validate pain if present
            if ($entry.data.pain) {
                foreach ($pain in $entry.data.pain) {
                    if (-not $pain.location -or $null -eq $pain.severity) {
                        $errors += "Entry $validatedCount : Pain missing location or severity"
                    } elseif ($pain.severity -lt 0.0 -or $pain.severity -gt 10.0) {
                        $errors += "Entry $validatedCount : Pain severity out of range (0.0-10.0)"
                    }
                }
            }
        }

        # Show progress every 50 entries
        if ($validatedCount % 50 -eq 0) {
            Write-Host "Validated $validatedCount entries..."
        }
    }

    Write-Host "`nValidation Complete!"
    Write-Host "Total entries validated: $validatedCount"

    if ($errors.Count -eq 0) {
        Write-Host "✅ All entries passed validation!" -ForegroundColor Green
    } else {
        Write-Host "❌ Found $($errors.Count) validation errors:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }

    # Summary statistics
    $entryTypeCounts = @{}
    foreach ($entry in $entries) {
        foreach ($type in $entry.entry_types) {
            if ($entryTypeCounts.ContainsKey($type)) {
                $entryTypeCounts[$type]++
            } else {
                $entryTypeCounts[$type] = 1
            }
        }
    }

    Write-Host "`nEntry Type Statistics:"
    $entryTypeCounts.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        Write-Host "  $($_.Key): $($_.Value) entries"
    }

} catch {
    Write-Error "Validation failed: $($_.Exception.Message)"
    exit 1
}
