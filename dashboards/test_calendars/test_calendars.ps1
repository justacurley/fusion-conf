$Dashboard = New-UDDashboard -Title "Test Calendar Dashboard" -Content { 
    New-UDContainer -Content {
        New-UDTypography -Text "Test Calendar Charts" -Variant h4 -Align center
        Import-Module -Name GetFusion -Force
        Clear-CachedData
        $Entries = Get-PSUCachedEntries
        

        $Data = @()
        for ($i = 365; $i -gt 0; $i--) {
            $Data += @{
                day   = (Get-Date).AddDays($i * -1).ToString('yyyy-MM-dd')
                value = Get-Random
            }
        }
    
        $From = (Get-Date).AddDays(-365)
        $To = Get-Date
    
        New-UDNivoChart -Calendar -Data $Data -From $From -To $To -Height 500 -Width 1000 -MarginTop 50 -MarginRight 130 -MarginBottom 50 -MarginLeft 60

    }
}
$Dashboard