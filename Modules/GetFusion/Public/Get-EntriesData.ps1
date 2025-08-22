# Function to load and parse entries.json file (unified schema v2.0)
function Get-EntriesData {
    param([string]$entriesPath)

    $entries = Get-Content -Path $entriesPath | ConvertFrom-Json

    # Validate this is unified schema v2.0 format
    if (-not ($entries -is [Array] -and $entries.Count -gt 0 -and $entries[0].PSObject.Properties['entry_id'])) {
        throw "Invalid entries format. Expected unified schema v2.0 with entry_id fields."
    }

    Write-Information "Loaded $($entries.Count) entries from unified schema v2.0"
    return $entries
}
