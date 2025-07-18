# Function to extract medication data (unified schema v2.0)
function Get-DateMedicationData {
    param([string]$date, $entries)

    # Initialize Medications array in global variable if it doesn't exist
    if (-not $global:DistinctDataValues.ContainsKey('Medications')) {
        $global:DistinctDataValues['Medications'] = @()
    }

    $medications = @()

    # Get all medication entries for the specified date - updated for schema v2.0
    $dateEntries = $entries | Where-Object { $_.date -eq $date -and $_.entry_types -contains "medications" }

    foreach ($entry in $dateEntries) {
        if ($entry.data.medications) {
            # Handle medications as array in schema v2.0
            foreach ($medication in $entry.data.medications) {
                $medicationName = $medication.name
                $dosage = $medication.dosage

                # Track unique medications in global variable
                if ($global:DistinctDataValues['Medications'] -notcontains $medicationName) {
                    $global:DistinctDataValues['Medications'] += $medicationName
                }

                $medicationWithContext = [PSCustomObject]@{
                    Date       = $entry.date
                    Timestamp  = $entry.time
                    EntryId    = $entry.entry_id
                    Medication = $medicationName
                    Dose       = $dosage
                    Notes      = $entry.notes
                }
                $medications += $medicationWithContext
            }
        }
    }

    return $medications
}
