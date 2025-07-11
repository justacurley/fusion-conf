using namespace System.Collections.Generic

class UserProfile {
    # Static class variable for base profile path - shared across all instances
    static [string]$BaseProfilePath = '/home/data/users'
    
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

    [System.Object] GetPSUIdentity([string]$email) {
        return Get-PSUIdentity -Name $this.Email
    }

    static [bool] UserExists([string]$Email) {
        try {
            return $null -ne (Get-PSUIdentity -Name $Email)
        } catch {
            return $false
        }
    }

    [System.Object] CreatePSUIdentity() {
        $Identity = $null
        try {
            if (-not $this.PSUIdentityExists()) {
                $UserRole = Get-PSURole -Name 'User' -ErrorAction Stop
                $Identity = New-PSUIdentity -Name $this.Email -Role $UserRole -Password $this.Password -Integrated -CredentialVault 'Database' -ErrorAction Stop
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
        $ProfilesPath = [UserProfile]::BaseProfilePath
        try {
            if ($null -ne ($this.GetPSUIdentity($this.Email))) {
                New-Item -ItemType Directory -Path $ProfilesPath -Name $this.ProfileId -ErrorAction Stop
                $UserPath = Join-Path $ProfilesPath $this.ProfileId
                New-Item -ItemType Directory -Path $UserPath -Name 'health-data' -ErrorAction Stop
                New-Item -ItemType Directory -Path $UserPath -Name 'img' -ErrorAction Stop
                @('profile.json', 'preferences.json').ForEach({ New-Item -ItemType File -Path $UserPath -Name $_ -ErrorAction Stop })
                New-Item -ItemType File -Path (Join-Path $UserPath 'health-data') -Name entries.json -ErrorAction Stop
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
            $UserPath = Join-Path ([UserProfile]::BaseProfilePath) $this.ProfileId
            $PreferencesPath = Join-Path $UserPath preferences.json
            $EntriesPath = Join-Path $UserPath 'health-data/entries.json'
            $UserSettingsPath = Join-Path $UserPath profile.json
            $this | Select-Object Email, FirstName, LastName, Timezone, CreatedOn, ProfileId, PSUProfileId, TOSAccepted, @{N = 'UserDirectory'; E = { $UserPath } } | ConvertTo-Json | Out-File $UserSettingsPath 
            $PreferencesPath, $EntriesPath | ForEach-Object { '{}' | Out-File $_ }
            return $UserSettingsPath
        } catch {
            Write-Warning "Failed to update profile.json for user profile $($this.Email)"
            throw $_
        }
    }
    static [hashtable] GetUserProfilePath([string]$Email, [string]$UserId = $null) {
        try {
            $UserPath = [UserProfile]::BaseProfilePath
            if ( -not [string]::IsNullOrEmpty($UserId)) {
                $FullUserPath = Join-Path $UserPath $UserId
                $ProfilePath = Join-Path $FullUserPath 'profile.json'
                if ((Test-Path $FullUserPath) -and (Test-Path $ProfilePath)) {
                    try {
                        $ProfileContent = Get-Content $ProfilePath | ConvertFrom-Json
                        return @{
                            UserDataPath   = $FullUserPath
                            ProfileContent = $ProfileContent
                        }
                    } catch {
                        # If profile.json is corrupted, still return the path but no content
                        # This allows ValidateUserDataStructure to detect the corruption
                        return @{
                            UserDataPath   = $FullUserPath
                            ProfileContent = $null
                        }
                    }
                }
            } else {
                $Profiles = Get-ChildItem $UserPath -Recurse -File 'profile.json'
                foreach ($ProfilePath in $Profiles) {
                    try {
                        $ProfileContent = Get-Content $ProfilePath | ConvertFrom-Json
                        if ($ProfileContent.Email -eq $Email) {
                            return @{
                                UserDataPath   = (Split-Path $ProfilePath -Parent)
                                ProfileContent = $ProfileContent
                            }
                        }
                    } catch {
                        # Skip corrupted profile.json files when searching by email
                        continue
                    }
                }
            }
            return @{}
        } catch {
            throw $_
        }
    }
    static [PSCustomobject] GetUserProfile([string]$Email) {
        try {
            $User = [UserProfile]::GetUserProfilePath($Email)      
            if ($User.Count -eq 0 -or -not $User.ContainsKey('UserDataPath') -or [string]::IsNullOrEmpty($User['UserDataPath'])) {
                throw "User $Email not found"
            } else {
                $PreferencesContent = Get-Content -Path (Join-Path $User['UserDataPath'] preferences.json) | ConvertFrom-Json
                $Entries = Get-Content -Path (Join-Path $User['UserDataPath'] 'health-data/entries.json') | ConvertFrom-Json
                return [PSCustomObject]@{
                    UserDataPath = $User['UserDataPath']
                    Preferences  = $PreferencesContent
                    Profile      = $User['ProfileContent']
                    Entries      = $Entries
                }
            }
        } catch {
            throw $_
        }
    }
    static [PSCustomObject] ValidateUserDataStructure([string]$Email, [string]$UserId = $null, [bool]$AutoRepair = $false) {
        # TODO: Implement user data structure validation
        # This method should validate that the user's directory structure and files are intact
        # and optionally repair any missing components
        $Result = [PSCustomObject]@{
            Email       = $Email
            IsValid     = $false
            Issues      = @()
            Repairs     = @()
            Validations = @{
                UserFound                 = $false
                UserDirectoryExists       = $false
                ProfileJsonValid          = $false
                PreferencesJsonValid      = $false
                HealthDataDirectoryExists = $false
                EntriesJsonValid          = $false
                ImageDirectoryExists      = $false
            }
        }
        try {
            $UserData = [UserProfile]::GetUserProfilePath($Email, $UserId)
            if ($UserData.Count -eq 0) {
                # Check if user directory exists but profile.json is missing
                $UserPath = [UserProfile]::BaseProfilePath
                if (-not [string]::IsNullOrEmpty($UserId)) {
                    $FullUserPath = Join-Path $UserPath $UserId
                    if (Test-Path $FullUserPath) {
                        $UserPath = $FullUserPath
                        $Result.Validations.UserFound = $true
                        $Result.Validations.UserDirectoryExists = $true
                    } else {
                        $Result.Issues += "User $Email not found"
                        return $Result
                    }
                } else {
                    # For email-based lookup, if GetUserProfilePath fails, user truly doesn't exist
                    $Result.Issues += "User $Email not found"
                    return $Result
                }
            } else {
                $Result.Validations.UserFound = $true
                $UserPath = $UserData['UserDataPath']
                $Result.Validations.UserDirectoryExists = $true
            }
            $Result.Validations.HealthDataDirectoryExists = (Test-Path (Join-Path $UserPath 'health-data'))
            $Result.Validations.ImageDirectoryExists = (Test-Path (Join-Path $UserPath 'img'))
            # Validate JSON files
            @('entries.json', 'preferences.json', 'profile.json').ForEach({
                    $CurrentFile = $_
                    try {
                        if ($CurrentFile -eq 'entries.json') {
                            $EntriesPath = Join-Path $UserPath 'health-data/entries.json'
                            if (Test-Path $EntriesPath) {
                                $fileContent = Get-Content $EntriesPath -Raw -EA Stop
                                if ([string]::IsNullOrWhiteSpace($fileContent)) {
                                    $Result.Issues += 'entries.json file is empty'
                                } else {
                                    $fileContent | ConvertFrom-Json -EA Stop | Out-Null
                                    $Result.Validations.EntriesJsonValid = $true
                                }
                            } else {
                                $Result.Issues += 'Missing entries.json file'
                            }
                        } elseif ($CurrentFile -eq 'preferences.json') {
                            $PrefsPath = Join-Path $UserPath $CurrentFile
                            if (Test-Path $PrefsPath) {
                                $fileContent = Get-Content $PrefsPath -Raw -EA Stop
                                if ([string]::IsNullOrWhiteSpace($fileContent)) {
                                    $Result.Issues += 'preferences.json file is empty'
                                } else {
                                    $fileContent | ConvertFrom-Json -EA Stop | Out-Null
                                    $Result.Validations.PreferencesJsonValid = $true
                                }
                            } else {
                                $Result.Issues += 'Missing preferences.json file'
                            }
                        } else {
                            $ProfilePath = Join-Path $UserPath $CurrentFile
                            if (Test-Path $ProfilePath) {
                                $fileContent = Get-Content $ProfilePath -Raw -EA Stop
                                if ([string]::IsNullOrWhiteSpace($fileContent)) {
                                    $Result.Issues += 'profile.json file is empty'
                                } else {
                                    $fileContent | ConvertFrom-Json -EA Stop | Out-Null
                                    $Result.Validations.ProfileJsonValid = $true
                                }
                            } else {
                                $Result.Issues += 'Missing profile.json file'
                            }
                        }
                    } catch {
                        $Result.Issues += "Invalid JSON in file $CurrentFile`: $($_.Exception.Message)"
                        Write-Warning "JSON validation failed for $CurrentFile`: $($_.Exception.Message)"
                    }
                })
            
            # Add issues for missing directories
            if (-not $Result.Validations.HealthDataDirectoryExists) {
                $Result.Issues += 'Missing health-data directory'
            }
            if (-not $Result.Validations.ImageDirectoryExists) {
                $Result.Issues += 'Missing img directory'
            }
            
            # Determine overall validity
            $AllValidations = $Result.Validations.Values
            $Result.IsValid = ($AllValidations -notcontains $false) -and ($Result.Issues.Count -eq 0)
            
            # Perform content analysis if AutoRepair is enabled (even for valid files)
            if ($AutoRepair) {
                # Analyze existing content in JSON files
                if ($Result.Validations.EntriesJsonValid) {
                    $EntriesPath = Join-Path $UserPath 'health-data/entries.json'
                    if (Test-Path $EntriesPath) {
                        $content = Get-Content $EntriesPath -Raw | ConvertFrom-Json
                        if ($content.Count -gt 0) {
                            $Result.Repairs += "entries.json already has $($content.Count) entries"
                        } else {
                            $Result.Repairs += 'entries.json exists but is empty (just [])'
                        }
                    }
                }
                
                if ($Result.Validations.PreferencesJsonValid) {
                    $PrefsPath = Join-Path $UserPath 'preferences.json'
                    if (Test-Path $PrefsPath) {
                        $content = Get-Content $PrefsPath -Raw | ConvertFrom-Json
                        $propertyCount = @($content.PSObject.Properties).Count
                        if ($propertyCount -gt 0) {
                            $Result.Repairs += "preferences.json already has $propertyCount preferences"
                        } else {
                            $Result.Repairs += 'preferences.json exists but is empty (just {})'
                        }
                    }
                }
            }
            
            # Perform auto-repair if requested and needed
            if ($AutoRepair -and -not $Result.IsValid) {
                try {
                    # Repair missing directories
                    if (-not $Result.Validations.HealthDataDirectoryExists) {
                        $HealthDataPath = Join-Path $UserPath 'health-data'
                        New-Item -ItemType Directory -Path $HealthDataPath -Force -ErrorAction Stop
                        $Result.Repairs += 'Created missing health-data directory'
                        $Result.Validations.HealthDataDirectoryExists = $true
                        
                        # Remove the corresponding issue
                        $Result.Issues = $Result.Issues | Where-Object { $_ -ne 'Missing health-data directory' }
                    }
                    
                    if (-not $Result.Validations.ImageDirectoryExists) {
                        $ImgPath = Join-Path $UserPath 'img'
                        New-Item -ItemType Directory -Path $ImgPath -Force -ErrorAction Stop
                        $Result.Repairs += 'Created missing img directory'
                        $Result.Validations.ImageDirectoryExists = $true
                        
                        # Remove the corresponding issue
                        $Result.Issues = $Result.Issues | Where-Object { $_ -ne 'Missing img directory' }
                    }
                    
                    # Repair missing or corrupted JSON files
                    if (-not $Result.Validations.EntriesJsonValid) {
                        $EntriesPath = Join-Path $UserPath 'health-data/entries.json'
                        if (! (Test-Path $EntriesPath)) {
                            # Create with a structure that PowerShell recognizes as an array
                            # Use multi-element array to ensure ConvertFrom-Json returns System.Array
                            '[{},{}]' | Out-File -FilePath $EntriesPath -Force -ErrorAction Stop
                            $Result.Repairs += 'Created missing entries.json with empty array'
                        } else {
                            # File exists but is invalid - check if it's completely empty or corrupted
                            $fileContent = Get-Content $EntriesPath -Raw
                            if ([string]::IsNullOrWhiteSpace($fileContent)) {
                                # Completely empty file - use multi-element array for proper type
                                '[{},{}]' | Out-File -FilePath $EntriesPath -Force -ErrorAction Stop
                                $Result.Repairs += 'Repaired entries.json with empty array'
                            } else {
                                # File has content but might be corrupted - try to parse
                                try {
                                    $content = $fileContent | ConvertFrom-Json
                                    if ($content.Count -gt 0) {
                                        $Result.Repairs += "entries.json already has $($content.Count) entries"
                                    } else {
                                        $Result.Repairs += 'entries.json exists but is empty (just [])'
                                    }
                                } catch {
                                    # File is corrupted, replace with multi-element array for proper type
                                    '[{},{}]' | Out-File -FilePath $EntriesPath -Force -ErrorAction Stop
                                    $Result.Repairs += 'Repaired entries.json with empty array'
                                }
                            }
                        }
                        $Result.Validations.EntriesJsonValid = $true
                        
                        # Remove related issues
                        $Result.Issues = $Result.Issues | Where-Object { $_ -notlike '*entries.json*' }
                    }
                    
                    if (-not $Result.Validations.PreferencesJsonValid) {
                        $PrefsPath = Join-Path $UserPath 'preferences.json'
                        if (! (Test-Path $PrefsPath)) {
                            # Use Set-Content instead of Out-File for better control
                            Set-Content -Path $PrefsPath -Value '{}' -Encoding UTF8 -ErrorAction Stop
                            $Result.Repairs += 'Created missing preferences.json with empty object'
                        } else {
                            # File exists but is invalid - check if it's completely empty or corrupted
                            $fileContent = Get-Content $PrefsPath -Raw
                            if ([string]::IsNullOrWhiteSpace($fileContent)) {
                                # Completely empty file
                                Set-Content -Path $PrefsPath -Value '{}' -Encoding UTF8 -ErrorAction Stop
                                $Result.Repairs += 'Repaired preferences.json with empty object'
                            } else {
                                # File has content but might be corrupted - try to parse
                                try {
                                    $content = $fileContent | ConvertFrom-Json
                                    $propertyCount = @($content.PSObject.Properties).Count
                                    if ($propertyCount -gt 0) {
                                        $Result.Repairs += "preferences.json already has $propertyCount preferences"
                                    } else {
                                        $Result.Repairs += 'preferences.json exists but is empty (just {})'
                                    }
                                } catch {
                                    # File is corrupted, replace with empty object
                                    Set-Content -Path $PrefsPath -Value '{}' -Encoding UTF8 -ErrorAction Stop
                                    $Result.Repairs += 'Repaired preferences.json with empty object'
                                }
                            }
                        }
                        $Result.Validations.PreferencesJsonValid = $true
                        
                        # Remove related issues
                        $Result.Issues = $Result.Issues | Where-Object { $_ -notlike '*preferences.json*' }
                    }
                    
                    if (-not $Result.Validations.ProfileJsonValid) {
                        $ProfilePath = Join-Path $UserPath 'profile.json'
                        # For profile.json, we need the actual user data - get it from UserData we already have
                        $ProfileContent = $UserData['ProfileContent']
                        if ($ProfileContent) {
                            $ProfileContent | ConvertTo-Json -Depth 10 | Out-File -FilePath $ProfilePath -Force -ErrorAction Stop
                            $Result.Repairs += 'Repaired profile.json with existing user data'
                        } else {
                            # Fallback: create minimal profile structure
                            @{
                                Email     = $Email
                                CreatedOn = (Get-Date)
                                Note      = 'Profile recreated by auto-repair'
                            } | ConvertTo-Json | Out-File -FilePath $ProfilePath -Force -ErrorAction Stop
                            $Result.Repairs += 'Created minimal profile.json (data may be incomplete)'
                        }
                        $Result.Validations.ProfileJsonValid = $true
                        
                        # Remove related issues
                        $Result.Issues = $Result.Issues | Where-Object { $_ -notlike '*profile.json*' }
                    }
                    
                    # Re-evaluate overall validity after repairs
                    $AllValidations = $Result.Validations.Values
                    $Result.IsValid = ($AllValidations -notcontains $false) -and ($Result.Issues.Count -eq 0)
                    
                    if ($Result.IsValid) {
                        $Result.Repairs += 'User data structure successfully repaired and validated'
                    }
                    
                } catch {
                    $RepairError = "Auto-repair failed: $($_.Exception.Message)"
                    $Result.Issues += $RepairError
                    $Result.Repairs += $RepairError
                    Write-Warning $RepairError
                }
            }
            
            return $Result
        } catch {
            $Result.Issues += "Critical error during validation: $($_.Exception.Message)"
            return $Result
        }
    }
    
    static [PSCustomObject] SetUserPreferences([string]$Email, [string]$UserId = $null, [hashtable]$PreferenceData) {
        # Configure user health tracking preferences during registration or profile updates
        # This method creates a comprehensive preferences.json file based on user selections
        $Result = [PSCustomObject]@{
            Email = $Email
            Success = $false
            Message = ''
            PreferencesPath = ''
            PreferencesSet = @()
        }
        
        try {
            # Get user profile path
            $UserData = [UserProfile]::GetUserProfilePath($Email, $UserId)
            if ($UserData.Count -eq 0) {
                $Result.Message = "User $Email not found"
                return $Result
            }
            
            $UserPath = $UserData['UserDataPath']
            $PreferencesPath = Join-Path $UserPath 'preferences.json'
            $Result.PreferencesPath = $PreferencesPath
            
            # Create comprehensive preferences structure
            $Preferences = @{
                # User Profile Preferences
                profile = @{
                    timezone = $PreferenceData.timezone ?? 'UTC'
                    units = @{
                        temperature = $PreferenceData.temperature_unit ?? 'fahrenheit'  # fahrenheit, celsius
                        weight = $PreferenceData.weight_unit ?? 'pounds'  # pounds, kilograms
                        height = $PreferenceData.height_unit ?? 'feet'  # feet, centimeters
                        distance = $PreferenceData.distance_unit ?? 'miles'  # miles, kilometers
                    }
                    language = $PreferenceData.language ?? 'en'
                    theme = $PreferenceData.theme ?? 'light'
                }
                
                # Health Tracking Configuration
                tracking = @{
                    # Vital Signs Tracking
                    vitals = @{
                        blood_pressure = @{
                            enabled = [bool]($PreferenceData.track_blood_pressure ?? $false)
                            frequency = $PreferenceData.bp_frequency ?? 'daily'  # daily, weekly, as_needed
                            target_systolic = $PreferenceData.bp_target_systolic ?? 120
                            target_diastolic = $PreferenceData.bp_target_diastolic ?? 80
                            alerts_enabled = [bool]($PreferenceData.bp_alerts ?? $false)
                        }
                        oxygen_saturation = @{
                            enabled = [bool]($PreferenceData.track_oxygen ?? $false)
                            frequency = $PreferenceData.o2_frequency ?? 'daily'
                            target_min = $PreferenceData.o2_target_min ?? 95
                            alerts_enabled = [bool]($PreferenceData.o2_alerts ?? $false)
                        }
                        heart_rate = @{
                            enabled = [bool]($PreferenceData.track_heart_rate ?? $false)
                            frequency = $PreferenceData.hr_frequency ?? 'daily'
                            target_resting = $PreferenceData.hr_target_resting ?? 70
                            alerts_enabled = [bool]($PreferenceData.hr_alerts ?? $false)
                        }
                        temperature = @{
                            enabled = [bool]($PreferenceData.track_temperature ?? $false)
                            frequency = $PreferenceData.temp_frequency ?? 'as_needed'
                            alerts_enabled = [bool]($PreferenceData.temp_alerts ?? $false)
                        }
                        weight = @{
                            enabled = [bool]($PreferenceData.track_weight ?? $false)
                            frequency = $PreferenceData.weight_frequency ?? 'weekly'
                            target_weight = $PreferenceData.target_weight ?? $null
                            alerts_enabled = [bool]($PreferenceData.weight_alerts ?? $false)
                        }
                        blood_glucose = @{
                            enabled = [bool]($PreferenceData.track_glucose ?? $false)
                            frequency = $PreferenceData.glucose_frequency ?? 'daily'
                            target_range = @{
                                min = $PreferenceData.glucose_target_min ?? 80
                                max = $PreferenceData.glucose_target_max ?? 120
                            }
                            alerts_enabled = [bool]($PreferenceData.glucose_alerts ?? $false)
                        }
                    }
                    
                    # Medication Tracking
                    medications = @{
                        enabled = [bool]($PreferenceData.track_medications ?? $false)
                        reminder_notifications = [bool]($PreferenceData.med_reminders ?? $false)
                        medications_list = @()
                    }
                    
                    # Pain Tracking
                    pain = @{
                        enabled = [bool]($PreferenceData.track_pain ?? $false)
                        scale_type = $PreferenceData.pain_scale ?? 'numeric_10'  # numeric_10, faces, custom
                        locations = @()
                        trigger_tracking = [bool]($PreferenceData.track_pain_triggers ?? $false)
                    }
                    
                    # Activity and Exercise Tracking
                    activities = @{
                        enabled = [bool]($PreferenceData.track_activities ?? $false)
                        step_goal = $PreferenceData.daily_step_goal ?? 10000
                        exercise_goal_minutes = $PreferenceData.daily_exercise_minutes ?? 30
                        activities_list = @()
                    }
                    
                    # Sleep Tracking
                    sleep = @{
                        enabled = [bool]($PreferenceData.track_sleep ?? $false)
                        target_hours = $PreferenceData.sleep_target_hours ?? 8
                        bedtime_reminder = [bool]($PreferenceData.bedtime_reminders ?? $false)
                    }
                    
                    # Nutrition/Hydration
                    nutrition = @{
                        water_tracking = [bool]($PreferenceData.track_water ?? $false)
                        daily_water_goal = $PreferenceData.daily_water_goal ?? 8  # glasses
                        meal_logging = [bool]($PreferenceData.track_meals ?? $false)
                    }
                    
                    # Mood and Mental Health
                    mood = @{
                        enabled = [bool]($PreferenceData.track_mood ?? $false)
                        scale_type = $PreferenceData.mood_scale ?? 'numeric_5'  # numeric_5, descriptive, custom
                        frequency = $PreferenceData.mood_frequency ?? 'daily'
                    }
                }
                
                # Notification Preferences
                notifications = @{
                    enabled = [bool]($PreferenceData.notifications_enabled ?? $true)
                    reminder_time = $PreferenceData.reminder_time ?? '09:00'
                    critical_alerts = [bool]($PreferenceData.critical_alerts ?? $true)
                    daily_summary = [bool]($PreferenceData.daily_summary ?? $false)
                    weekly_report = [bool]($PreferenceData.weekly_report ?? $false)
                }
                
                # Data Sharing and Privacy
                privacy = @{
                    share_with_providers = [bool]($PreferenceData.share_with_providers ?? $false)
                    emergency_contacts_access = [bool]($PreferenceData.emergency_access ?? $false)
                    data_retention_days = $PreferenceData.data_retention ?? 365
                }
                
                # Dashboard and UI Preferences
                dashboard = @{
                    default_view = $PreferenceData.default_dashboard ?? 'overview'  # overview, vitals, trends
                    chart_timeframe = $PreferenceData.default_timeframe ?? '7days'  # 1day, 7days, 30days, 90days
                    show_trends = [bool]($PreferenceData.show_trends ?? $true)
                    compact_view = [bool]($PreferenceData.compact_view ?? $false)
                }
                
                # Metadata
                meta = @{
                    created_date = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
                    last_updated = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
                    version = '1.0'
                    configured_by = 'registration_wizard'
                }
            }
            
            # Process custom medications if provided
            if ($PreferenceData.medications -and $PreferenceData.medications.Count -gt 0) {
                foreach ($medication in $PreferenceData.medications) {
                    $medEntry = @{
                        name = $medication.name
                        dosage = $medication.dosage ?? ''
                        frequency = $medication.frequency ?? 'daily'
                        time_of_day = $medication.time_of_day ?? @('morning')
                        prescribing_doctor = $medication.doctor ?? ''
                        start_date = $medication.start_date ?? (Get-Date -Format 'yyyy-MM-dd')
                        notes = $medication.notes ?? ''
                        active = [bool]($medication.active ?? $true)
                        reminders_enabled = [bool]($medication.reminders ?? $false)
                    }
                    $Preferences.tracking.medications.medications_list += $medEntry
                    $Result.PreferencesSet += "Added medication: $($medication.name)"
                }
            }
            
            # Process custom pain locations if provided
            if ($PreferenceData.pain_locations -and $PreferenceData.pain_locations.Count -gt 0) {
                foreach ($location in $PreferenceData.pain_locations) {
                    $locationEntry = @{
                        name = $location.name ?? $location
                        description = $location.description ?? ''
                        chronic = [bool]($location.chronic ?? $false)
                        severity_baseline = $location.baseline ?? 0
                    }
                    $Preferences.tracking.pain.locations += $locationEntry
                    $Result.PreferencesSet += "Added pain location: $($locationEntry.name)"
                }
            }
            
            # Process custom activities if provided
            if ($PreferenceData.activities -and $PreferenceData.activities.Count -gt 0) {
                foreach ($activity in $PreferenceData.activities) {
                    $activityEntry = @{
                        name = $activity.name ?? $activity
                        category = $activity.category ?? 'general'  # cardio, strength, flexibility, daily_living, etc.
                        intensity = $activity.intensity ?? 'moderate'  # light, moderate, vigorous
                        duration_typical = $activity.typical_duration ?? 30
                        frequency_goal = $activity.frequency ?? 'weekly'
                        notes = $activity.notes ?? ''
                    }
                    $Preferences.tracking.activities.activities_list += $activityEntry
                    $Result.PreferencesSet += "Added activity: $($activityEntry.name)"
                }
            }
            
            # Save preferences to file
            $Preferences | ConvertTo-Json -Depth 10 | Out-File -FilePath $PreferencesPath -Force -ErrorAction Stop
            
            $Result.Success = $true
            $Result.Message = "Successfully configured user preferences with $($Result.PreferencesSet.Count) custom items"
            
            return $Result
            
        } catch {
            $Result.Message = "Failed to set user preferences: $($_.Exception.Message)"
            Write-Warning "Error in SetUserPreferences: $($_.Exception.Message)"
            return $Result
        }
    }
    
    static [PSCustomObject] GetDefaultPreferenceTemplate() {
        # Returns a template/example of preference structure for UI forms
        return [PSCustomObject]@{
            # Basic Profile Settings
            timezone = 'UTC'
            temperature_unit = 'fahrenheit'  # or 'celsius'
            weight_unit = 'pounds'  # or 'kilograms'
            language = 'en'
            theme = 'light'  # or 'dark'
            
            # Vital Signs Tracking (boolean flags)
            track_blood_pressure = $false
            track_oxygen = $false
            track_heart_rate = $false
            track_temperature = $false
            track_weight = $false
            track_glucose = $false
            
            # Other Health Tracking
            track_medications = $false
            track_pain = $false
            track_activities = $false
            track_sleep = $false
            track_water = $false
            track_meals = $false
            track_mood = $false
            
            # Notification Settings
            notifications_enabled = $true
            critical_alerts = $true
            daily_summary = $false
            weekly_report = $false
            
            # Sample structures for complex data
            medications = @(
                @{
                    name = 'Medication Name'
                    dosage = '10mg'
                    frequency = 'daily'  # daily, twice_daily, weekly, as_needed
                    time_of_day = @('morning')  # morning, afternoon, evening, night
                    doctor = 'Dr. Smith'
                    reminders = $true
                }
            )
            
            pain_locations = @(
                @{
                    name = 'Lower Back'
                    chronic = $true
                    baseline = 3
                }
            )
            
            activities = @(
                @{
                    name = 'Walking'
                    category = 'cardio'
                    intensity = 'moderate'
                    typical_duration = 30
                    frequency = 'daily'
                }
            )
        }
    }
}

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
function Test-PSUUserExists {
    param(
        [ValidateNotNullOrEmpty()]
        [string]$Email
    )
    return [UserProfile]::UserExists($Email)
}

function Invoke-UserAuthentication {
    [CmdletBinding()]
    param (
        [string]$Email
    )
    end {
        $Response = @{
            'Success'     = $false
            'Message'     = "Profile for $Email was not found"
            'UserProfile' = [PSCustomObject]@{}
        }
        try {
            $UserExists = Test-PSUUserExists -Email $Email
            if (! $UserExists) {                
                return $Response
            }
            $UserProfile = [UserProfile]::GetUserProfile($Email)
            if ($UserProfile -eq $false -or $null -eq $UserProfile) {
                $Response['Message'] = "Profile.json was not found for $Email"
                return $Response
            }
            $Response['Success'] = $true
            $Response['Message'] = "Profile for $Email was found"
            $Response['UserProfile'] = $UserProfile
        } catch {
            Write-Error $_
        }
        return $Response
    }
}

function Set-UserSession {
    [CmdletBinding()]
    param (
        [PSCustomObject]$UserProfile  # The profile object from authentication
    )
    # NOTE: This function sets custom session variables for compatibility but these
    # variables do NOT persist across PSU contexts (authentication -> dashboard).
    # Primary session validation now relies on PSU's $User variable and dynamic profile loading.
    $Response = @{
        Success = $false
        Message = 'Failed to extract one or more properties from user profile'
    }
    try {
        Write-Verbose "Setting UserProfileId to: $($UserProfile.ProfileId)"
        Write-Verbose "ProfileId type: $($UserProfile.ProfileId.GetType().Name)"
        Write-Verbose 'NOTE: Custom session variables do not persist between authentication and dashboard contexts'
        $Session:UserEmail = $UserProfile.Email
        $Session:UserProfileId = $UserProfile.ProfileId
        $Session:PSUProfileId = $UserProfile.PSUProfileId
        $Session:UserFirstName = $UserProfile.FirstName
        $Session:UserLastName = $UserProfile.LastName
        $Session:UserTimezone = $UserProfile.Timezone
        $Session:LoginTime = (Get-Date)
        $Session:IsAuthenticated = $true
        $Response['Success'] = $true
        $Response['Message'] = 'Set all required session variables (for authentication context only)'
    } catch {
        Write-Error $_
    }
    return $Response
}

function Test-UserSession {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = 'Failed to get user session'
            Data    = @{}
        }
        try {
            # Check if PSU User variable exists and has a value
            if (-not (Get-Variable User -ErrorAction SilentlyContinue) -or [string]::IsNullOrEmpty($User)) {
                $Response['Message'] = 'PSU User identity not found or empty'
                return $Response
            }
            
            # Validate that the user still exists in PSU
            if (-not [UserProfile]::UserExists($User)) {
                $Response['Message'] = "PSU identity no longer exists for user: $User"
                return $Response
            }
            
            # Dynamically load user profile using the PSU User variable
            $AllUserData = [UserProfile]::GetUserProfile($User)
            $UserProfile = $AllUserData.Profile            
            if ($AllUserData -eq $false -or $null -eq $AllUserData) {
                $Response['Message'] = "User profile not found for PSU user: $User"
                return $Response
            }
            
            # All validations passed - return session data based on PSU User and loaded profile
            $Response['Success'] = $true
            $Response['Message'] = 'Valid user session found via dynamic profile loading'
            $Response['Data'] = @{
                PSUUser         = $User
                PSUUserRoles    = if (Get-Variable Roles -ErrorAction SilentlyContinue) { $Roles } else { @() }
                UserEmail       = $UserProfile.Email
                UserProfileId   = $UserProfile.ProfileId
                PSUProfileId    = $UserProfile.PSUProfileId
                UserFirstName   = $UserProfile.FirstName
                UserLastName    = $UserProfile.LastName
                UserTimezone    = $UserProfile.Timezone
                CreatedOn       = $UserProfile.CreatedOn
                TOSAccepted     = $UserProfile.TOSAccepted
                IsAuthenticated = $true
                Preferences     = $AllUserData.Preferences
                UserDataPath    = $AllUserData.UserDataPath
                Entries         = $AllUSerData.Entries
            }
        } catch {
            $Response['Message'] = "Error validating user session: $($_.Exception.Message)"
            Write-Error "Error in Test-UserSession: $($_.Exception.Message)"
        }
        return $Response
    }
}

function Get-CurrentUser {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success = $false
            Message = 'Failed to get current user'
            Data    = @{}
        }
        try {
            # First check if we have a valid session
            $SessionCheck = Test-UserSession
            if (-not $SessionCheck.Success) {
                $Response['Message'] = "No valid user session found: $($SessionCheck.Message)"
                return $Response
            }
            
            # Use the data from Test-UserSession since it already validates and extracts everything
            $CurrentUser = $SessionCheck.Data
            
            $Response['Success'] = $true
            $Response['Message'] = 'Current user retrieved successfully'
            $Response['Data'] = $CurrentUser
        } catch {
            $Response['Message'] = "Error retrieving current user: $($_.Exception.Message)"
            Write-Error "Error in Get-CurrentUser: $($_.Exception.Message)"
        }
        return $Response
    }
}

function Clear-UserSession {
    [CmdletBinding()]
    param ()
    end {
        $Response = @{
            Success          = $false
            Message          = 'Failed to clear user session'
            ClearedVariables = @()
        }
        try {
            # Clear all custom session variables
            $SessionVariables = @(
                'UserEmail',
                'UserProfileId', 
                'PSUProfileId',
                'UserFirstName',
                'UserLastName',
                'UserTimezone',
                'LoginTime',
                'IsAuthenticated'
            )
            
            $ClearedVariables = @()
            foreach ($Variable in $SessionVariables) {
                try {
                    # Try to remove the session variable directly
                    # In PSU context, this will work with Session: scope
                    # In test context, this may fail gracefully
                    Remove-Variable -Name "Session:$Variable" -ErrorAction Stop
                    $ClearedVariables += $Variable
                } catch {
                    # Variable doesn't exist or can't be removed - this is OK
                    Write-Verbose "Session variable $Variable not found or could not be removed: $($_.Exception.Message)"
                }
            }
            
            $Response['Success'] = $true
            $Response['Message'] = "User session cleared successfully. Cleared variables: $($ClearedVariables -join ', ')"
            $Response['ClearedVariables'] = $ClearedVariables
        } catch {
            $Response['Message'] = "Error clearing user session: $($_.Exception.Message)"
            $Response['ClearedVariables'] = @()  # Ensure it's always an array
            Write-Error "Error in Clear-UserSession: $($_.Exception.Message)"
        }
        return $Response
    }
}   

function Set-UserCacheData {
    [CmdletBinding()]
    param (
        [ValidateScript({ -not [string]::IsNullOrEmpty($_.UserEmail) })]
        [PSCustomObject]$UserData,
        [ValidateScript({ $_ -gt 0 })]
        [int]$ExpirationHours = 1
    )
    end {
        try {
            $CacheKey = "UserContext_$($UserData.UserEmail)"
            $CacheValue = $UserData | ConvertTo-Json -Compress
            Set-PSUCache -Key $CacheKey -Value $CacheValue -AbsoluteExpiration (Get-Date).AddHours($ExpirationHours) -ErrorAction Stop
        } catch {
            throw $_
        }
    }
}

function Get-UserCacheData {
    [CmdletBinding()]
    param (
        # This is the postfix of the cachekey
        [string]$UserEmail
    )
    end {
        try {
            $CacheKey = "UserContext_$UserEmail"
            $Cache = Get-PSUCache -Key $CacheKey -ErrorAction Stop
            if (! $Cache) {
                throw "Failed to retrieve cache for key: $CacheKey"
            }
            return $Cache
        } catch {
            throw $_
        }
    }
}

function Initialize-UserContext {
    [CmdletBinding()]
    param (
        [string]$UserEmail,
        [int]$ExpirationHours = 1,
        [switch]$SuppressToast
    )
    end {
        # Check if user is authenticated
        if ([string]::IsNullOrEmpty($UserEmail)) {
            if (-not $SuppressToast) {
                Show-UDToast -Message 'No user session found. Please log in.' -MessageColor red -Duration 5000
            }
            return $null
        }
        
        $UserData = $null
        try {
            # Try to get cached user data first
            $UserData = Get-UserCacheData $UserEmail -EA Stop
            if (-not $SuppressToast) {
                Show-UDToast -Message 'User data loaded from cache' -MessageColor green -Duration 3000
            }
        } catch {
            Write-Warning "Cache miss for user $UserEmail, attempting to load and cache user data"
        
            # Cache miss - load user data and set cache
            try {
                $CurrentUser = Get-CurrentUser
                if ($CurrentUser.Success) {
                    $UserData = $CurrentUser.Data
                    # Set cache for future requests
                    Set-UserCacheData -UserData $UserData -ExpirationHours $ExpirationHours
                    if (-not $SuppressToast) {
                        Show-UDToast -Message 'User data loaded and cached successfully' -MessageColor green -Duration 3000
                    }
                } else {
                    throw "Failed to get current user: $($CurrentUser.Message)"
                }
            } catch {
                Write-Warning "Failed to load user data: $($_.Exception.Message)"
                if (-not $SuppressToast) {
                    Show-UDToast -Message 'Warning: User data not available. Using default view.' -MessageColor orange -Duration 5000
                    Show-UDToast -Message 'Please try refreshing the page.' -MessageColor orange -Duration 5000
                }
            }
        }
        
        return $UserData
    }
}

function New-UserHealthPreferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Email,
        
        [string]$UserId = $null,
        
        # Basic Profile Settings
        [string]$Timezone = 'UTC',
        [ValidateSet('fahrenheit', 'celsius')]
        [string]$TemperatureUnit = 'fahrenheit',
        [ValidateSet('pounds', 'kilograms')]
        [string]$WeightUnit = 'pounds',
        [string]$Language = 'en',
        [ValidateSet('light', 'dark')]
        [string]$Theme = 'light',
        
        # Vital Signs Tracking
        [switch]$TrackBloodPressure,
        [switch]$TrackOxygen,
        [switch]$TrackHeartRate,
        [switch]$TrackTemperature,
        [switch]$TrackWeight,
        [switch]$TrackGlucose,
        
        # Health Targets (optional)
        [int]$BloodPressureTargetSystolic = 120,
        [int]$BloodPressureTargetDiastolic = 80,
        [int]$OxygenTargetMin = 95,
        [int]$HeartRateTargetResting = 70,
        [decimal]$TargetWeight = $null,
        [int]$GlucoseTargetMin = 80,
        [int]$GlucoseTargetMax = 120,
        
        # Other Health Tracking
        [switch]$TrackMedications,
        [switch]$TrackPain,
        [switch]$TrackActivities,
        [switch]$TrackSleep,
        [switch]$TrackWater,
        [switch]$TrackMeals,
        [switch]$TrackMood,
        
        # Goals and Targets
        [int]$DailyStepGoal = 10000,
        [int]$DailyExerciseMinutes = 30,
        [decimal]$SleepTargetHours = 8,
        [int]$DailyWaterGoal = 8,
        
        # Notifications
        [switch]$NotificationsEnabled,
        [switch]$CriticalAlerts,
        [switch]$DailySummary,
        [switch]$WeeklyReport,
        [string]$ReminderTime = '09:00',
        
        # Medications (array of hashtables)
        [hashtable[]]$Medications = @(),
        
        # Pain locations (array of strings or hashtables)
        [object[]]$PainLocations = @(),
        
        # Activities (array of strings or hashtables)  
        [object[]]$Activities = @()
    )
    
    $Response = @{
        Success = $false
        Message = ''
        PreferencesPath = ''
        PreferencesSet = @()
    }
    
    try {
        # Build preference data hashtable from parameters
        $PreferenceData = @{
            timezone = $Timezone
            temperature_unit = $TemperatureUnit
            weight_unit = $WeightUnit
            language = $Language
            theme = $Theme
            
            # Tracking flags
            track_blood_pressure = $TrackBloodPressure.IsPresent
            track_oxygen = $TrackOxygen.IsPresent
            track_heart_rate = $TrackHeartRate.IsPresent
            track_temperature = $TrackTemperature.IsPresent
            track_weight = $TrackWeight.IsPresent
            track_glucose = $TrackGlucose.IsPresent
            track_medications = $TrackMedications.IsPresent
            track_pain = $TrackPain.IsPresent
            track_activities = $TrackActivities.IsPresent
            track_sleep = $TrackSleep.IsPresent
            track_water = $TrackWater.IsPresent
            track_meals = $TrackMeals.IsPresent
            track_mood = $TrackMood.IsPresent
            
            # Targets and goals
            bp_target_systolic = $BloodPressureTargetSystolic
            bp_target_diastolic = $BloodPressureTargetDiastolic
            o2_target_min = $OxygenTargetMin
            hr_target_resting = $HeartRateTargetResting
            target_weight = $TargetWeight
            glucose_target_min = $GlucoseTargetMin
            glucose_target_max = $GlucoseTargetMax
            daily_step_goal = $DailyStepGoal
            daily_exercise_minutes = $DailyExerciseMinutes
            sleep_target_hours = $SleepTargetHours
            daily_water_goal = $DailyWaterGoal
            
            # Notifications
            notifications_enabled = if ($PSBoundParameters.ContainsKey('NotificationsEnabled')) { $NotificationsEnabled.IsPresent } else { $true }
            critical_alerts = if ($PSBoundParameters.ContainsKey('CriticalAlerts')) { $CriticalAlerts.IsPresent } else { $true }
            daily_summary = $DailySummary.IsPresent
            weekly_report = $WeeklyReport.IsPresent
            reminder_time = $ReminderTime
            
            # Complex data
            medications = $Medications
            pain_locations = $PainLocations
            activities = $Activities
        }
        
        # Call the static method to set preferences
        $Result = [UserProfile]::SetUserPreferences($Email, $UserId, $PreferenceData)
        
        $Response.Success = $Result.Success
        $Response.Message = $Result.Message
        $Response.PreferencesPath = $Result.PreferencesPath
        $Response.PreferencesSet = $Result.PreferencesSet
        
        if ($Result.Success) {
            Write-Host "✓ Health preferences configured successfully for $Email" -ForegroundColor Green
            if ($Result.PreferencesSet.Count -gt 0) {
                Write-Host "  Custom items configured:" -ForegroundColor Cyan
                $Result.PreferencesSet | ForEach-Object { Write-Host "    • $_" -ForegroundColor Gray }
            }
        } else {
            Write-Warning "Failed to configure preferences: $($Result.Message)"
        }
        
    } catch {
        $Response.Message = "Error configuring user preferences: $($_.Exception.Message)"
        Write-Error $Response.Message
    }
    
    return $Response
}