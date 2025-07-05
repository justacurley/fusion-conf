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
            New-UDCard -Title 'Registration Fields' -Content {
                New-UDGrid -Item -ExtraSmallSize 6 -Direction row -Children {
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDTextbox -Id email -Label 'Email Address' -Type email -Required
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children {
                        New-UDTextbox -Id password -Label 'Password' -Type password -Required
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children { New-UDTextbox -Id confirm_password -Label 'Confirm Password' -Type password -Required }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children { New-UDTextbox -Id firstname -Label 'First Name' -Type text -Required }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children { New-UDTextbox -Id lastname -Label 'Last Name' -Type text -Required }
                    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Children { New-UDSelect -Id 'timezone' -Label 'Timezone' -Option {
                            # Auto-generate all system timezones
                            [System.TimeZoneInfo]::GetSystemTimeZones() | ForEach-Object {
                                New-UDSelectOption -Name $_.DisplayName -Value $_.Id
                            }
                        } -DefaultValue 'Mountain Standard Time' -Required
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -Children { 
                        New-UDCheckBox -Id tos -Label 'I have read and agree to the Terms of Service' -Required
                    }
                    New-UDGrid -Item -ExtraSmallSize 12 -Children { 
                        New-UDButton -Text "Create Account" -Color primary -Size large -FullWidth -Style @{
                            marginTop = '20px'
                            padding = '12px'
                            fontWeight = 'bold'
                        }
                    }
                } 
            } -Style @{
                padding         = '15px'
                margin          = '5px'
                backgroundColor = 'var(--theme-palette-background-default)'
                borderLeft      = '4px solid var(--theme-palette-primary-main)'
                borderRadius    = '8px'
                minHeight       = '120px'
                border          = '1px solid var(--theme-palette-divider)'
            }
        } -OnSubmit {}
    }
}