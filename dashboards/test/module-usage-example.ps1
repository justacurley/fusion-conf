# Example script showing how to use the GetFusion module functions

# Import the GetFusion module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

# Set the path to your entries.json file
$EntriesPath = "/home/data/fusion-data/entries/entries.json"

Write-Host "=== GetFusion Module Usage Example ===" -ForegroundColor Green

try {
    # Example 1: Get all health data using the main function
    Write-Host "`n1. Getting comprehensive health data:" -ForegroundColor Yellow
    $healthData = Get-HealthData -entriesPath $EntriesPath
    Write-Host "Found $($healthData.Count) days of data"
    
    # Show first few entries
    $healthData | Select-Object -First 3 | Format-Table -AutoSize
    
    # Example 2: Test individual functions
    Write-Host "`n2. Testing individual helper functions:" -ForegroundColor Yellow
    
    # Test sleep parsing
    $sleepExamples = @("7:39", "9:10", "8.5", "6:03")
    foreach ($sleep in $sleepExamples) {
        $parsed = Get-SleepHours -sleepValue $sleep
        Write-Host "Sleep '$sleep' -> $parsed hours"
    }
    
    # Test date conversion
    $dateExamples = @("0523", "0610", "0627")
    foreach ($date in $dateExamples) {
        $converted = Convert-DateToDisplay -date $date
        Write-Host "Date '$date' -> '$converted'"
    }
    
    # Example 3: Statistics
    Write-Host "`n3. Quick statistics:" -ForegroundColor Yellow
    $validMaxPain = $healthData | Where-Object { $_.MaxPain -ne $null }
    $validBackPain = $healthData | Where-Object { $_.BackPain -ne $null }
    $validSleep = $healthData | Where-Object { $_.Sleep -ne $null }
    
    Write-Host "Days with max pain data: $($validMaxPain.Count)"
    Write-Host "Days with back pain data: $($validBackPain.Count)"
    Write-Host "Days with sleep data: $($validSleep.Count)"
    
    if ($validMaxPain.Count -gt 0) {
        $avgMaxPain = ($validMaxPain.MaxPain | Measure-Object -Average).Average
        Write-Host "Average max pain level: $([math]::Round($avgMaxPain, 1))"
    }
    
    if ($validSleep.Count -gt 0) {
        $avgSleep = ($validSleep.Sleep | Measure-Object -Average).Average
        Write-Host "Average sleep hours: $([math]::Round($avgSleep, 1))"
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Module functions available ===" -ForegroundColor Green
Write-Host "- Get-HealthData: Main function to get all processed health data"
Write-Host "- Get-SleepHours: Parse sleep data from HH:MM or decimal format"
Write-Host "- Get-AverageBackPain: Calculate average back pain for a date entry"
Write-Host "- Convert-DateToDisplay: Convert MMDD to MM/DD format"
