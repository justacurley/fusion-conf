# Test Configuration and Helper Functions
# Shared test utilities and configuration for UserManagement module tests

# Test configuration
$script:TestConfig = @{
    TestDataPath = "$env:TEMP\UserManagementTests"
    MockUserCount = 5
    TestTimeout = 30 # seconds
}

# Helper function to create mock user data
function New-MockUserData {
    param(
        [int]$Count = 1,
        [string]$EmailDomain = "example.com"
    )
    
    $users = @()
    for ($i = 1; $i -le $Count; $i++) {
        $users += @{
            Email = "testuser$i@$EmailDomain"
            FirstName = "Test$i"
            LastName = "User$i"
            Timezone = "America/New_York"
            Password = "SecurePass$i!"
        }
    }
    
    if ($Count -eq 1) {
        return $users[0]
    }
    return $users
}

# Helper function to cleanup test data
function Remove-TestData {
    param([string]$Path = $script:TestConfig.TestDataPath)
    
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Helper function to setup test environment
function Initialize-TestEnvironment {
    $testPath = $script:TestConfig.TestDataPath
    Remove-TestData $testPath
    New-Item $testPath -ItemType Directory -Force | Out-Null
    return $testPath
}

# Helper function to convert string to SecureString
function New-SecureString {
    param(
        [Parameter(Mandatory)]
        [string]$PlainText
    )
    
    return $PlainText | ConvertTo-SecureString -AsPlainText -Force
}

# Export helper functions for use in test files
Export-ModuleMember -Function New-MockUserData, Remove-TestData, Initialize-TestEnvironment, New-SecureString
Export-ModuleMember -Variable TestConfig
