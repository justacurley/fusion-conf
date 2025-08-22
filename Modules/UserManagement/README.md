# UserManagement Module

A comprehensive PowerShell module for user management and health tracking functionality, designed for use with PowerShell Universal (PSU) applications.

## Module Structure

The module has been split into a logical, maintainable structure:

```
UserManagement/
├── UserManagement.psd1          # Module manifest
├── UserManagement.psm1          # Main module file (imports everything)
├── Classes/
│   └── UserProfile.ps1          # UserProfile class definition
├── Public/
│   ├── New-PSUUser.ps1          # Create new PSU users
│   ├── Test-PSUUserExists.ps1   # Check if user exists
│   ├── Invoke-UserAuthentication.ps1
│   ├── Test-UserSession.ps1     # Validate user sessions
│   ├── Get-CurrentUser.ps1      # Get current user data
│   ├── Clear-UserSession.ps1    # Clear user sessions
│   ├── Initialize-UserContext.ps1
│   ├── New-UserHealthPreferences.ps1
│   ├── New-MedicationSchedule.ps1
│   └── New-SampleHealthEntries.ps1
├── Private/
│   ├── Set-UserSession.ps1      # Internal session management
│   ├── Set-UserCacheData.ps1    # Internal caching functions
│   └── Get-UserCacheData.ps1
├── UserManagement.psm1.backup   # Backup of original monolithic file
└── README.md                    # This file
```

## Benefits of the Split Structure

### 1. **Better Organization & Maintainability**
- **Separation of Concerns**: Class definition vs. function implementations
- **Easier Navigation**: Developers can quickly find either class methods or module functions
- **Reduced Cognitive Load**: Each file has a single, clear responsibility

### 2. **Improved Development Experience**
- **Faster Loading**: Smaller files load quicker in editors
- **Better IntelliSense**: IDEs perform better with smaller, focused files
- **Easier Code Reviews**: Changes to class vs. functions can be reviewed separately

### 3. **Enhanced Modularity**
- **Independent Evolution**: Class and functions can evolve at different rates
- **Selective Importing**: Other modules could import just the class if needed
- **Testing**: Unit tests can be more focused (test class separately from functions)

### 4. **PowerShell Module Benefits**
- **Better Performance**: PowerShell can load and parse smaller files more efficiently
- **Cleaner Module Structure**: Follows PowerShell best practices for module organization

## Public Functions

The following functions are exported and available to consumers of the module:

- `New-PSUUser` - Create new PowerShell Universal users
- `Test-PSUUserExists` - Check if a user exists in PSU
- `Invoke-UserAuthentication` - Authenticate users and load their profiles
- `Test-UserSession` - Validate user sessions using PSU context
- `Get-CurrentUser` - Get current user data and preferences
- `Clear-UserSession` - Clear user session variables
- `Initialize-UserContext` - Initialize user context with caching
- `New-UserHealthPreferences` - Configure user health tracking preferences
- `New-MedicationSchedule` - Create detailed medication schedules
- `New-SampleHealthEntries` - Generate sample health data for testing

## Private Functions

The following functions are internal to the module and not exported:

- `Set-UserSession` - Internal session variable management
- `Set-UserCacheData` - Internal user data caching
- `Get-UserCacheData` - Internal cache retrieval

## UserProfile Class

The `UserProfile` class provides comprehensive user management functionality:

- User profile creation and management
- PowerShell Universal identity integration
- File system operations for user data
- User preference configuration
- Data validation and repair utilities

## Usage

```powershell
# Import the module
Import-Module UserManagement

# Create a new user
$NewUser = New-PSUUser -Email "user@example.com" -FirstName "John" -LastName "Doe" -Password (ConvertTo-SecureString "password" -AsString -Force) -Timezone "America/Denver" -TOSAccepted

# Check if user exists
$UserExists = Test-PSUUserExists -Email "user@example.com"

# Configure user preferences
New-UserHealthPreferences -Email "user@example.com" -TrackBloodPressure -TrackWeight -TemperatureUnit "fahrenheit"

# Access the UserProfile class
[UserProfile]::UserExists("user@example.com")
```

## Dependencies

- PowerShell 5.1 or later
- PowerShell Universal module
- Access to PSU identity management functions

## Migration Notes

- The original monolithic file is backed up as `UserManagement.psm1.backup`
- All existing functionality remains unchanged
- The split does not affect the public API
- Existing scripts using this module should continue to work without modification

## Development

When adding new functionality:

1. **Public functions** go in `Public/` directory
2. **Private/internal functions** go in `Private/` directory
3. **Class modifications** go in `Classes/UserProfile.ps1`
4. **Update the manifest** (`UserManagement.psd1`) to export new public functions
5. **Test thoroughly** to ensure the module loads and functions work correctly

## Testing

Test the module structure:

```powershell
# Test module loading
Import-Module ./UserManagement.psd1 -Force

# Verify functions are exported
Get-Command -Module UserManagement

# Verify class is available
[UserProfile]::BaseProfilePath
```
