Set-PSUAuthenticationMethod -Type "Form" -ScriptBlock {
param(
        [PSCredential]$Credential
    )
    #
    #   You can call whatever cmdlets you like to conduct authentication here.
    #   Just make sure to return the $Result with the Success property set to $true
    #
    Import-Module UserManagement
    Write-PSULog -Level Information -Message "vars" -Feature "Security" -Resource 'authentication.ps1' -Properties (gv|convertto-json|convertfrom-json -ashashtable)
    $AuthResult = Invoke-UserAuthentication -Email $Credential.UserName
    if ($AuthResult.Success) {
        Write-PSULog -Level Information -Message "Auth Result" -Feature "Security" -Resource 'authentication.ps1' -Properties ($AuthResult | ConvertTo-Json -depth 3 | ConvertFrom-Json -AsHashtable)
        $SessionResult = Set-UserSession -UserProfile $AuthResult.UserProfile
        if ($SessionResult.Success) {
            Write-PSULog -Level Information -Message "Session Result" -Feature "Security" -Resource 'authentication.ps1' -Properties ($SessionResult | ConvertTo-Json -depth 3 | Convertfrom-json -AsHashtable)
            New-PSUAuthenticationResult -Success -UserName $Credential.UserName
        } else {
            New-PSUAuthenticationResult -ErrorMessage 'Session setup failed'
        }
    } else {
        New-PSUAuthenticationResult -ErrorMessage 'Bad username or password'
    }
    Write-PSULog -Level Information -Message "varsEND" -Feature "Security" -Resource 'authentication.ps1' -Properties (gv|convertto-json|convertfrom-json -ashashtable)
}