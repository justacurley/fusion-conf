$ErrorActionPreference = "Stop"
$timestamp = Get-Date -f yyyyMMdd-HHmm
try {
    Get-Item /home/data/fusion-data/entries/entries.json -OutVariable entries
    Copy-Item $entries "/home/data/Repository/fusion-data/entries_$timestamp.json" -Force
} catch {
    Write-Information "Failed to get or copy /home/data/fusion-data/entries/entries.json"
    throw $_
}