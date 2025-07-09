Set-PSUAuthenticationMethod -Type "Form" -ScriptBlock {
param(
        [PSCredential]$Credential
    )
    #
    #   You can call whatever cmdlets you like to conduct authentication here.
    #   Just make sure to return the $Result with the Success property set to $true
    #
    Import-Module UserManagement
    $AuthResult = Invoke-UserAuthentication -Email $Credential.UserName
    if ($AuthResult.Success) {
        Write-Information "Auth Result:"
        Write-Information ($AuthResult | ConvertTo-Json -depth 3)
        $SessionResult = Set-UserSession -UserProfile $AuthResult.UserProfile
        if ($SessionResult.Success) {
            Write-Information "Session Result:"
            Write-Information ($SessionResult | ConvertTo-Json -depth 3)
            New-PSUAuthenticationResult -Success -UserName $Credential.UserName
        } else {
            New-PSUAuthenticationResult -ErrorMessage 'Session setup failed'
        }
    } else {
        New-PSUAuthenticationResult -ErrorMessage 'Bad username or password'
    }
}