@{
    # Script module or binary module file associated with this manifest
    RootModule = 'GetFusion.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = '12345678-1234-1234-1234-123456789abc'
    
    # Author of this module
    Author = 'Fusion Health Dashboard'
    
    # Company or vendor of this module
    CompanyName = 'Personal Health Tracking'
    
    # Copyright statement for this module
    Copyright = '(c) 2024 Fusion Health Dashboard. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'PowerShell module for processing health data from fusion entries.json files. Provides functions for parsing sleep data, calculating pain metrics, and extracting comprehensive health statistics for dashboard visualization.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.0'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Get-SleepHours', 
        'Get-AverageBackPain',
        'Convert-DateToDisplay',
        'Get-EntriesData',
        'Get-DatesList',
        'Sort-HealthDataByDate',
        'Set-CombinedData',
        'Get-DateMedicationData',
        'Get-DateActivityData',
        'Get-DateVitalsData',
        'Get-HealthMetrics',
        'Clear-CachedData'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Health', 'Dashboard', 'Data', 'PowerShellUniversal', 'JSON')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # Release notes of this module
            ReleaseNotes = 'Initial release with health data processing functions for PowerShell Universal dashboards.'
        }
    }
}
