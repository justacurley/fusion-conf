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
    $SessionResult = Set-UserSession -UserPRofile $AuthResult.UserProfile
    if ($SessionResult.Success) {
        New-PSUAuthenticationResult -Success -UserName $Credential.UserName
    } else {
        New-PSUAuthenticationResult -ErrorMessage 'Session setup failed'
    }
} else {
    New-PSUAuthenticationResult -ErrorMessage 'Bad username or password'
}
}