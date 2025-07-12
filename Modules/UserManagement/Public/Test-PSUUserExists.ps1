function Test-PSUUserExists {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Email
    )
    # Ensure the UserManagement module is imported
    if (-not (Get-Module UserManagement)) {
        Import-Module UserManagement -Force
    }
    
    return [UserProfile]::UserExists($Email)
}
