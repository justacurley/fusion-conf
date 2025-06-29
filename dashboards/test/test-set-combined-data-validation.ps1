# Test script for Set-CombinedData validation

# Import the GetFusion module
Import-Module -Name "/home/alex/src/fusion-conf/Modules/GetFusion/GetFusion.psm1" -Force

Write-Host "=== Testing Set-CombinedData Validation ===" -ForegroundColor Green

try {
    # Create a base object
    $testObject = [PSCustomObject]@{
        Date = "06/29"
        MaxPain = 5
    }
    
    Write-Host "`n1. Testing successful property addition:" -ForegroundColor Yellow
    $testObject = Set-CombinedData -combinedData $testObject -name "Sleep" -data 7.5
    Write-Host "✅ Successfully added 'Sleep' property"
    $testObject | Format-List
    
    Write-Host "`n2. Testing duplicate property prevention:" -ForegroundColor Yellow
    try {
        $testObject = Set-CombinedData -combinedData $testObject -name "MaxPain" -data 8
        Write-Host "❌ This should not appear - validation failed!"
    }
    catch {
        Write-Host "✅ Correctly prevented duplicate property 'MaxPain': $($_.Exception.Message)" -ForegroundColor Green
    }
    
    Write-Host "`n3. Testing another successful addition:" -ForegroundColor Yellow
    $testObject = Set-CombinedData -combinedData $testObject -name "Activities" -data @("Walking", "Stretching")
    Write-Host "✅ Successfully added 'Activities' property"
    $testObject | Format-List
    
    Write-Host "`n4. Testing case sensitivity:" -ForegroundColor Yellow
    try {
        $testObject = Set-CombinedData -combinedData $testObject -name "date" -data "different case"
        Write-Host "✅ Successfully added 'date' property (case sensitive)"
        $testObject | Format-List
    }
    catch {
        Write-Host "❌ Case sensitivity test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host "`n5. Final object state:" -ForegroundColor Yellow
    Write-Host "Properties: $($testObject.PSObject.Properties.Name -join ', ')"
    $testObject | Format-List
    
} catch {
    Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Validation Benefits ===" -ForegroundColor Green
Write-Host "✅ Prevents accidental property overwrites"
Write-Host "✅ Clear error messages for debugging"
Write-Host "✅ Ensures data integrity in combined objects"
Write-Host "✅ Helps catch naming conflicts early"

Write-Host "`n=== Usage Recommendations ===" -ForegroundColor Green
Write-Host "• Use descriptive, unique property names"
Write-Host "• Check existing properties before adding if needed"
Write-Host "• Consider using Get-Member to inspect objects during development"
Write-Host "• Property names are case-sensitive in PowerShell"
