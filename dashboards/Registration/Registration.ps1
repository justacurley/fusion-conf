New-UDApp -Content { 
    # Add custom CSS for better form styling
    New-UDElement -Tag "style" -Content {
        @"
        .registration-form {
            max-width: 600px;
            margin: 0 auto;
            padding: 30px;
            background: var(--theme-palette-background-paper);
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        .registration-form .form-group {
            margin-bottom: 24px !important;
        }
        
        .registration-form .MuiFormControl-root {
            margin-bottom: 20px;
            width: 100%;
        }
        
        .registration-form .MuiButton-contained {
            background-color: var(--theme-palette-primary-main);
            color: white;
            padding: 12px 32px;
            font-size: 16px;
            font-weight: 600;
            border-radius: 8px;
            text-transform: none;
            margin-top: 20px;
        }
        
        .registration-form .MuiButton-contained:hover {
            background-color: var(--theme-palette-primary-dark);
            box-shadow: 0 6px 16px rgba(0,0,0,0.2);
        }
        
        .registration-form .MuiTextField-root {
            margin-bottom: 16px;
        }
        
        .registration-form .MuiFormHelperText-root {
            color: var(--theme-palette-text-secondary);
            font-size: 13px;
        }
        
        .registration-form .MuiFormControlLabel-root {
            margin-top: 16px;
            margin-bottom: 8px;
        }
        
        .registration-form .field-description {
            font-size: 14px;
            color: var(--theme-palette-text-secondary);
            margin-top: 4px;
        }
"@
    }
    
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
        } -Style @{ padding = '20px'; marginBottom = '30px'; backgroundColor = 'var(--theme-palette-background-paper)' }
        
        # Form container with better styling
        New-UDPaper -Children {
            New-UDForm -Schema @{
            title = "Registration Fields"
            type = "object"
            properties = @{
                email = @{
                    title = "Email Address"
                    type = "string"
                    format = "email"
                    description = "We'll use this to send you important account updates"
                }
                password = @{
                    title = "Password"
                    type = "string"
                    format = "password"
                    minLength = 8
                    maxLength = 128
                    pattern = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$"
                    description = "Must contain at least 8 characters with uppercase, lowercase, number, and special character (@$!%*?&)"
                }
                confirm_password = @{
                    title = "Confirm Password"
                    type = "string"
                    format = "password"
                    minLength = 8
                    maxLength = 128
                    description = "Re-enter your password to confirm (must match exactly)"
                }
                firstname = @{
                    title = "First Name"
                    type = "string"
                    minLength = 1
                    maxLength = 50
                }
                lastname = @{
                    title = "Last Name"
                    type = "string"
                    minLength = 1
                    maxLength = 50
                }
                timezone = @{
                    title = "Timezone"
                    type = "string"
                    enum = @(
                        "America/New_York",
                        "America/Chicago", 
                        "America/Denver",
                        "America/Phoenix",
                        "America/Los_Angeles",
                        "America/Anchorage",
                        "Pacific/Honolulu"
                    )
                    enumNames = @(
                        "Eastern Time (New York)",
                        "Central Time (Chicago)",
                        "Mountain Time (Denver)", 
                        "Arizona Time (Phoenix)",
                        "Pacific Time (Los Angeles)",
                        "Alaska Time (Anchorage)",
                        "Hawaii Time (Honolulu)"
                    )
                    default = "America/Denver"
                    description = "Select your local timezone for accurate time tracking"
                }
                tos = @{
                    title = "I have read and agree to the Terms of Service and Privacy Policy"
                    type = "boolean"
                    description = "You must accept our terms to create an account"
                }
            }
            required = @('email', 'password', 'confirm_password', 'firstname', 'lastname', 'timezone', 'tos')
        } -UiSchema @{
            "ui:order" = @('email', 'firstname', 'lastname', 'password', 'confirm_password', 'timezone', 'tos')
            email = @{
                "ui:help" = "Enter a valid email address"
                "ui:placeholder" = "your.email@example.com"
            }
            firstname = @{
                "ui:placeholder" = "Enter your first name"
            }
            lastname = @{
                "ui:placeholder" = "Enter your last name"
            }
            password = @{
                "ui:help" = "Required: 8+ characters, uppercase, lowercase, number, and special character (@$!%*?&)"
            }
            confirm_password = @{
                "ui:help" = "Must match your password exactly"
            }
            timezone = @{
                "ui:help" = "This helps us show times in your local timezone"
            }
            tos = @{
                "ui:widget" = "checkbox"
            }
        } -ButtonVariant "contained" -ClassName "registration-form" -OnSubmit {
            param($Data)
            
            # Password confirmation validation (schema can't handle this)
            if ($Data.password -ne $Data.confirm_password) {
                Show-UDToast -Message "Passwords do not match. Please try again." -MessageColor red
                return
            }
            
            # Additional password strength validation (backup to regex)
            if ($Data.password.Length -lt 8) {
                Show-UDToast -Message "Password must be at least 8 characters long." -MessageColor red
                return
            }
            
            if (-not ($Data.password -match "^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])")) {
                Show-UDToast -Message "Password must contain uppercase, lowercase, number, and special character." -MessageColor red
                return
            }
            
            # TODO: Implement registration logic
            Show-UDToast -Message "Registration functionality coming soon! Password validation passed." -MessageColor green
            
            # For now, just log the submitted data for testing (excluding passwords)
            $safeData = $Data | Select-Object * -ExcludeProperty password, confirm_password
            Write-Host "Registration data submitted: $($safeData | ConvertTo-Json -Depth 3)"
        }
        } -Style @{ padding = '0'; backgroundColor = 'transparent'; boxShadow = 'none' }
    }
}