# Simple heatmap test to troubleshoot rendering issues
$Dashboard = New-UDDashboard -Title "Simple Heatmap Test" -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Simple Heatmap Test" -Variant h4 -Align center
        
        # Create minimal test data matching the documentation example
        $TestData = @(
            [ordered]@{
                state = "idaho"
                cats = 72
                dogs = 23
                moose = 45
                bears = 7
            }
            [ordered]@{
                state = "wisconsin"
                cats = 234
                dogs = 345
                moose = 1
                bears = 234
            }
            [ordered]@{
                state = "montana"
                cats = 92
                dogs = 397
                moose = 234
                bears = 347
            }
        )
        
        Write-Information "Test data created with $($TestData.Count) entries"
        
        try {
            New-UDNivoChart -Heatmap -Data $TestData -IndexBy 'state' -Keys @('cats', 'dogs', 'moose', 'bears') -Height 300 -Width 800 -MarginTop 50 -MarginRight 50 -MarginBottom 50 -MarginLeft 100
            
            New-UDTypography -Text "✅ Heatmap rendered successfully with test data" -Variant h6 -Style @{ marginTop = '20px'; color = 'green' }
        } catch {
            New-UDTypography -Text "❌ Error rendering heatmap: $($_.Exception.Message)" -Variant h6 -Style @{ marginTop = '20px'; color = 'red' }
        }
        
        # Show the data structure
        New-UDTypography -Text "Test Data Structure:" -Variant h6 -Style @{ marginTop = '20px' }
        New-UDElement -Tag 'pre' -Content {
            $TestData | ConvertTo-Json -Depth 2
        }
    }
}
$Dashboard
