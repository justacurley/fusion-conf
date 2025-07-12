function New-PSUUser {
    param (
        [string]$Email,
        [string]$FirstName,
        [string]$LastName,
        [securestring]$Password,
        [string]$Timezone,
        [switch]$TOSAccepted
    )
    $Response = @{}
    try {
        # Ensure the UserManagement module is imported
        if (-not (Get-Module UserManagement)) {
            Import-Module UserManagement -Force
        }

        $NewUser = [UserProfile]::new($Email, $FirstName, $LastName, $Password, $Timezone, $TOSAccepted)
        $NewUser.CreatePSUIdentity()
        $NewUser.CreateUserDirectory()
        $NewUser.SaveUserProfile()
        $Response['Success'] = $true
        $Response['Message'] = "User $Email registered successfully"
        $Response['UserProfile'] = $NewUser
    } catch {
        $Response['Success'] = $false
        $Response['Message'] = "User $Email failed to register"
        $Response['UserProfile'] = $null
        Write-Error $_
    }
    return $Response
}
