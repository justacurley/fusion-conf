Function New-EntryModal () {

}
$Pages = @()
$Pages += New-UDPage -Name 'App' -Url '/db' -Content {
    New-UDTypography -Text 'App'
    $Query.test
    $Query['test']
}

New-UDApp -Title 'Pages' -Pages $Pages