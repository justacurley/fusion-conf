# Quick test script to validate GetFusion module functionality

# Import the module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

# Clear cached data
Clear-CachedData

# Load entries data
$EntriesPath = "/home/alex/src/fusion-conf/fusion-data/entries.json"
$entries = Get-EntriesData -entriesPath $EntriesPath

Write-Host "Testing GetFusion Module..." -ForegroundColor Green

# Test 1: Get all health metrics
Write-Host "`n1. Testing Get-HealthMetrics with all data points..." -ForegroundColor Yellow
$healthMetrics = Get-HealthMetrics -Entries $entries -DataPoints @('MaxPain', 'BackPain', 'Sleep', 'Medications', 'Activities', 'Vitals')

Write-Host "   Combined Health Data entries: $($healthMetrics['CombinedHealthData'].Count)" -ForegroundColor Cyan
Write-Host "   Medications entries: $($healthMetrics['Medications'].Count)" -ForegroundColor Cyan
Write-Host "   Activities entries: $($healthMetrics['Activities'].Count)" -ForegroundColor Cyan
Write-Host "   Vitals entries: $($healthMetrics['Vitals'].Count)" -ForegroundColor Cyan

# Test 2: Check distinct values tracking
Write-Host "`n2. Testing distinct values tracking..." -ForegroundColor Yellow
if ($global:DistinctDataValues.ContainsKey('Medications')) {
    Write-Host "   Unique Medications: $($global:DistinctDataValues['Medications'].Count)" -ForegroundColor Cyan
    Write-Host "   List: $($global:DistinctDataValues['Medications'] -join ', ')" -ForegroundColor Gray
}
if ($global:DistinctDataValues.ContainsKey('Activities')) {
    Write-Host "   Unique Activities: $($global:DistinctDataValues['Activities'].Count)" -ForegroundColor Cyan
    Write-Host "   List: $($global:DistinctDataValues['Activities'] -join ', ')" -ForegroundColor Gray
}

# Test 3: Show sample data
Write-Host "`n3. Sample data preview..." -ForegroundColor Yellow

if ($healthMetrics['CombinedHealthData'].Count -gt 0) {
    Write-Host "   Sample Combined Health Data:" -ForegroundColor Cyan
    $healthMetrics['CombinedHealthData'] | Select-Object -First 3 | Format-Table -AutoSize
}

if ($healthMetrics['Medications'].Count -gt 0) {
    Write-Host "   Sample Medications:" -ForegroundColor Cyan
    $healthMetrics['Medications'] | Select-Object -First 3 | Format-Table -AutoSize
}

if ($healthMetrics['Vitals'].Count -gt 0) {
    Write-Host "   Sample Vitals:" -ForegroundColor Cyan
    $healthMetrics['Vitals'] | Select-Object -First 3 | Format-Table -AutoSize
}

Write-Host "`nTest completed! ✅" -ForegroundColor Green
