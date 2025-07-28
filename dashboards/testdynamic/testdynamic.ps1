$Pages = @()
$Pages += New-UDPage -Name 'App' -Url '/db' -Content {
    New-UDTypography -Text 'App'
}

New-UDApp -Title 'Pages' -Pages $Pages