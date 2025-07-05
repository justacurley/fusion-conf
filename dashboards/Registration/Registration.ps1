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
        New-UDForm -Schema @{
            title = "Registration Fields"
            type = "object"
            properties = @{
                email = @{
                    title = "Email Address"
                    type = "string"
                    format = "email"
                }
                password = @{
                    title = "Password"
                    type = "string"
                    format = "password"
                    minLength = 8
                }
                confirm_password = @{
                    title = "Confirm Password"
                    type = "string"
                    format = "password"
                }
                firstname = @{
                    title = "First Name"
                    type = "string"
                }
                lastname = @{
                    title = "Last Name"
                    type = "string"
                }
                timezone = @{
                    title = "Timezone"
                    type = "string"
                    enum = @([System.TimeZoneInfo]::GetSystemTimeZones() | ForEach-Object { $_.Id })
                    default = "Mountain Standard Time"
                }
                tos = @{
                    title = "I have read and agree to the Terms of Service"
                    type = "boolean"
                }
            }
            required = @('email', 'password', 'confirm_password', 'firstname', 'lastname', 'timezone', 'tos')
        } -OnSubmit {}
    }
}