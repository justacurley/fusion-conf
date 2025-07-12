# UserManagement Module - Main Entry Point
# This module provides comprehensive user management functionality for health tracking applications

# Note: The UserProfile class is loaded via ScriptsToProcess in the module manifest

# Import all private functions (internal use only)
Get-ChildItem "$PSScriptRoot\Private\*.ps1" | ForEach-Object {
    . $_.FullName
}

# Import all public functions (exported to consumers)
Get-ChildItem "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
    . $_.FullName
}

# Export only the public functions (defined in the manifest)
# The module manifest (.psd1) controls which functions are actually exported

# Export only the public functions (defined in the manifest)
# The module manifest (.psd1) controls which functions are actually exported
