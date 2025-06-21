$filePath = "/home/data/Repository/fusion-data/entries/entries.json"
try {
    $jsonContent = Get-Content $filePath -Raw | ConvertFrom-Json
    Write-Output $jsonContent
} catch {
    Write-Error "Failed to read or parse $filePath ... $_"
}

Write-Output "Hello World!"