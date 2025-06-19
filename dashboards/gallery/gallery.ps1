New-UDApp -Content {
    New-UDLayout -Columns 2 -content {
        $imagePath = "/home/data/Repository/fusion-data/img"
        $imageFiles = Get-ChildItem -Path $imagePath -File
    }
    foreach ($img in $imageFiles) {
        $relativePath = $img.FullName.Replace($imagePath,"").TrimStart("/")
        $imageUrl = "/images/$relativePath"

        New-UDCard -Content {
            New-UDImage -url $imageUrl -Width 200 -Height 200
            New-UDTypography -Text $img.Name -Variant subtitle1
        } -Elevation 2
    }
}