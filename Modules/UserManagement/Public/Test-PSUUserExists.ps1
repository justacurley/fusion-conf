function Test-PSUUserExists {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Email
    )
    return [UserProfile]::UserExists($Email)
}
