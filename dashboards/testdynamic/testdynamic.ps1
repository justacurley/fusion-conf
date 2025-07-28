$Pages = @()
$Pages += New-UDPage -Name 'Dashboard' -Url '/db/:user' -Content {
    New-UDTypography -Text 'Dashboard for user: $User'
}

New-UDApp -Title 'Pages' -Pages $Pages