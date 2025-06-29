param(
    [string]$EntriesPath
)
$ErrorActionPreference = "Stop"
try {
    Get-Item $EntriesPath -OutVariable Entries
    Copy-Item $Entries /home/data/fusion-data/entries/entries.json -Force
} catch {
    Write-Information "Failed to get $EntriesPath or failed to copy it"
    throw $_
}