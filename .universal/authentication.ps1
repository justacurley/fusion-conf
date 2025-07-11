Set-PSUAuthenticationMethod -Type 'Form' -ScriptBlock {
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
        $SessionResult = Set-UserSession -UserPRofile $AuthResult.UserProfile
        if ($SessionResult.Success) {
            try {
                if ($Credential.UserName -ine 'admin') {
                    $CurrentUser = Get-CurrentUser
                    Show-UDToast "Got Current User, attempting to set cache."
                    Write-Information "Got Current User, attempting to set cache."

                    $UserData = $CurrentUser.Data
                    Set-UserCacheData -UserData $UserData -ExpirationHours 1
                }
                New-PSUAuthenticationResult -Success -UserName $Credential.UserName                
            }
            catch {
                Write-Warning "Failed to cache data for $($Credential.UserName)"
                throw $_
            }
        } else {
            New-PSUAuthenticationResult -ErrorMessage 'Session setup failed'
        }
    } else {
        New-PSUAuthenticationResult -ErrorMessage 'Bad username or password'
    }
}