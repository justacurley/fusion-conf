Set-PSUAuthenticationMethod -Type 'Form' -ScriptBlock {
    param(
        [PSCredential]$Credential
    )
    #
    #   You can call whatever cmdlets you like to conduct authentication here.
    #   Just make sure to return the $Result with the Success property set to $true
    #
    Import-Module UserManagement
    Write-PSULog -Level Information -Message 'Authentication attempt' -Feature 'Security' -Resource 'authentication.ps1' -Properties @{
        'UserName' = $Credential.UserName
        'Timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    
    # Validate user credentials and profile existence
    $AuthResult = Invoke-UserAuthentication -Email $Credential.UserName
    if ($AuthResult.Success) {
        Write-PSULog -Level Information -Message 'Authentication successful' -Feature 'Security' -Resource 'authentication.ps1' -Properties @{
            'UserEmail' = $AuthResult.UserProfile.Email
            'UserProfileId' = $AuthResult.UserProfile.ProfileId
            'LoginTime' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        
        # Return success - PSU will set $User variable automatically
        # Dashboards will use Get-CurrentUser for session validation and profile loading
        New-PSUAuthenticationResult -Success -UserName $Credential.UserName
    } else {
        Write-PSULog -Level Warning -Message 'Authentication failed' -Feature 'Security' -Resource 'authentication.ps1' -Properties @{
            'UserName' = $Credential.UserName
            'Reason' = $AuthResult.Message
            'Timestamp' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        New-PSUAuthenticationResult -ErrorMessage 'Invalid username or password'
    }
}