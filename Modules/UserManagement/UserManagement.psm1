using namespace System.Collections.Generic

class UserProfile {
    [ValidateNotNullOrEmpty()]
    [string]$Email
    [ValidateNotNullOrEmpty()]
    [string]$FirstName
    [ValidateNotNullOrEmpty()]
    [string]$LastName
    [ValidateNotNullOrEmpty()]
    [securestring]$Password
    [ValidateNotNullOrEmpty()]
    [string]$Timezone
    [switch]$TOSAccepted
    [datetime]$CreatedOn = (Get-Date)
    [guid]$ProfileId = (New-Guid)
    [int]$PSUProfileId = 0

    UserProfile() {}

    UserProfile([string]$Email, [string]$FirstName, [string]$LastName, [securestring]$Password, [string]$Timezone, [switch]$TOSAccepted) {
        if ($TOSAccepted -eq $false) {
            throw 'Terms of Service must be accepted'
        }
        $this.Email = $Email
        $this.FirstName = $FirstName
        $this.LastName = $LastName
        $this.Password = $Password
        $this.Timezone = $Timezone
        $this.TOSAccepted = $TOSAccepted
    }

    [bool] PSUIdentityExists() {
        return $null -ne (Get-PSUIdentity -Name $this.Email)
    }

    [PowerShellUniversal.Identity] GetPSUIdentity([string]$email) {
        return Get-PSUIdentity -Name $this.Email
    }

    [System.Object] CreatePSUIdentity() {
        $Identity = $null
        try {
            if (-not $this.PSUIdentityExists()) {
                $UserRole = Get-PSURole -Name 'User' -ErrorAction Stop
                $Identity = New-PSUIdentity -Name $this.Email -Role $UserRole -Password $this.Password -ErrorAction Stop
                $this.PSUProfileId = $Identity.Id
            } else {
                Write-Warning "Profile for $($this.Email) already exists"
            }
        } catch {
            Write-Warning "Failed to create user for $($this.email)"
            throw $_
        }
        return $Identity
    }

    [string] CreateUserDirectory() {
        $ProfilesPath = '/home/data/users/'
        try {
            if ($null -ne ($this.GetPSUIdentity($this.Email))) {
                New-Item -ItemType Directory -Path $ProfilesPath -Name $this.ProfileId -ErrorAction Stop
                $UserPath = Join-Path $ProfilesPath $this.ProfileId
                New-Item -ItemType Directory -Path $UserPath -Name 'health-data' -ErrorAction Stop
                @('profile.json', 'preferences.json').ForEach({ New-Item -ItemType File -Path $UserPath -Name $_ -ErrorAction Stop })
                return $UserPath
            } else {
                throw "Could not find identity for $($this.Email)"
            }            
        } catch {
            Write-Warning "Failed to create directory for user profile $($this.Email)"
            throw $_
        }
    }
    
    [string] SaveUserProfile() {
        try {
            $UserPath = "/home/data/users/$($this.ProfileId)"
            $UserSettingsPath = Join-Path $UserPath profile.json
            $this | Select-Object Email,FirstName,LastName,Timezone,CreatedOn,ProfileId,PSUProfileId,TOSAccepted | ConvertTo-Json | Out-File $UserSettingsPath 
            return $UserSettingsPath
        } catch {
            Write-Warning "Failed to update profile.json for user profile $($this.Email)"
            throw $_
        }

    }
}
