New-UDApp -Content {
    Import-Module UserManagement -Force
    $UserData = Initialize-UserContext -UserEmail $User
    New-UDLayout -Columns 3 -Content {
        $imagePath = '/home/data/fusion-data/img'
        $imageFiles = Get-ChildItem -Path $imagePath -File

        foreach ($img in $imageFiles) {
            $relativePath = $img.FullName.Replace($imagePath, '').TrimStart('/')
            $imageUrl = "/img/$relativePath"
            $Text = "$($img.Name.Substring(0, 2))/$($img.Name.Substring(2, 2))"
            
            New-UDCard -Content {
                New-UDImage -Url $imageUrl -Width 400 -Height 400
            } -Elevation 2 -Style @{width = 501; height = 501 } -Title $Text -TitleAlignment Center 
        }
    }
}

