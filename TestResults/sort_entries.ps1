# Sort entries.json by MMDD date keys in descending order

$inputPath = "/home/alex/src/fusion-conf/fusion-data/entries.json"
$outputPath = "/home/alex/src/fusion-conf/fusion-data/entries_sorted.json"

try {
    # Read the JSON file
    $entries = Get-Content -Path $inputPath | ConvertFrom-Json
    
    # Get all property names (date keys) and sort them in descending order
    $sortedDateKeys = $entries.PSObject.Properties.Name | Sort-Object -Descending
    
    # Create a new ordered hashtable to maintain the sort order
    $sortedEntries = [ordered]@{}
    
    # Add each entry in the sorted order
    foreach ($dateKey in $sortedDateKeys) {
        $sortedEntries[$dateKey] = $entries.$dateKey
    }
    
    # Convert back to JSON with proper formatting
    $sortedEntries | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputPath -Encoding UTF8
    
    Write-Host "Successfully sorted entries by date (descending) and saved to: $outputPath"
    Write-Host "Date range: $($sortedDateKeys[0]) to $($sortedDateKeys[-1])"
    Write-Host "Total entries: $($sortedDateKeys.Count)"
    
} catch {
    Write-Error "Error processing entries: $($_.Exception.Message)"
}
