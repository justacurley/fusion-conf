New-UDApp -Content { 
    New-UDContainer -Children {
        New-UDPaper -Children {
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Health Recovery Registration Form' -Variant h4 -Style @{
                    textAlign    = 'center'
                    marginBottom = '5px'
                    color        = 'var(--theme-palette-primary-main)'
                    fontWeight   = 'bold'
                }
            }
            New-UDGrid -Container -Children {
                New-UDTypography -Text 'Register your account' -Variant subtitle1 -Style @{
                    textAlign    = 'center'
                    marginBottom = '20px'
                    marginTop    = '8px'
                    color        = 'var(--theme-palette-text-secondary)'
                    fontStyle    = 'italic'
                }
            }
        } -Style @{ padding = '20px'; marginBottom = '20px'; backgroundColor = 'var(--theme-palette-background-paper)' }
        New-UDForm -Children {
            New-UDCard -Title "Registration Fields" -Content {
                New-UDGrid -Item -ExtraSmallSize 6 -Children {
                    New-UDTextbox -id email -label 'Email Address' -Type text
                    New-UDTextbox -id password -label 'Password' -Type password 
                    New-UDTextbox -id confirm_password -label 'Confirm Password' -Type password 
                }
            }
        }
    }
}