$Nav = New-UDList -Content {
    New-UDListItem -Label "Test1" -Href '/test'  -Icon (New-UDIcon -Icon Cog -Size 1x)
    New-UDListItem -Label "Test2" -Href '/test2'  -Icon (New-UDIcon -Icon Cog -Size 1x)
    New-UDListItem -Label "Test3" -Href '/test3'  -Icon (New-UDIcon -Icon Cog -Size 1x)
}

$Pages = @()

$Pages += New-UDPage -Name 'test' -url '/test/:id' -Content {
    "User ID: $id"
}

$Pages += New-UDPage -Name 'test2' -url '/test2' -Content {

}

$Pages += New-UDPage -Name 'test3' -url '/test3' -Content {

}

New-UDApp -Title 'Navigation' -Pages $Pages -Navigation $Nav -NavigationLayout permanent