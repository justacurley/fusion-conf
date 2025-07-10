# PSU Session Management Integration Test
# This script can be run in PSU to test the authentication flow

Import-Module UserManagement -Force

Write-Host "=== PSU Session Management Integration Test ===" -ForegroundColor Cyan

# Test 1: Check if we're in PSU context
Write-Host "`n1. Testing PSU Context:" -ForegroundColor Yellow
if (Get-Variable User -ErrorAction SilentlyContinue) {
    Write-Host "   ✓ PSU User variable exists: $User" -ForegroundColor Green
    $userExists = $true
} else {
    Write-Host "   ✗ PSU User variable not found" -ForegroundColor Red
    $userExists = $false
}

# Test 2: Test session validation
Write-Host "`n2. Testing Session Validation:" -ForegroundColor Yellow
try {
    $sessionResult = Test-UserSession
    Write-Host "   Session Success: $($sessionResult.Success)" -ForegroundColor $(if ($sessionResult.Success) { "Green" } else { "Red" })
    Write-Host "   Message: $($sessionResult.Message)" -ForegroundColor Gray
    
    if ($sessionResult.Success) {
        Write-Host "   User Email: $($sessionResult.Data.UserEmail)" -ForegroundColor Gray
        Write-Host "   Profile ID: $($sessionResult.Data.UserProfileId)" -ForegroundColor Gray
        Write-Host "   PSU User: $($sessionResult.Data.PSUUser)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Error testing session: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Test Get-CurrentUser
Write-Host "`n3. Testing Get-CurrentUser:" -ForegroundColor Yellow
try {
    $currentUser = Get-CurrentUser
    Write-Host "   Current User Success: $($currentUser.Success)" -ForegroundColor $(if ($currentUser.Success) { "Green" } else { "Red" })
    Write-Host "   Message: $($currentUser.Message)" -ForegroundColor Gray
    
    if ($currentUser.Success) {
        Write-Host "   Welcome: $($currentUser.Data.UserFirstName) $($currentUser.Data.UserLastName)" -ForegroundColor Green
        Write-Host "   Email: $($currentUser.Data.UserEmail)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ✗ Error getting current user: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Check file system access
Write-Host "`n4. Testing File System Access:" -ForegroundColor Yellow
$usersPath = "/home/data/users"
if (Test-Path $usersPath) {
    Write-Host "   ✓ Users directory exists: $usersPath" -ForegroundColor Green
    $userFolders = Get-ChildItem $usersPath -Directory -ErrorAction SilentlyContinue
    Write-Host "   User folders found: $($userFolders.Count)" -ForegroundColor Gray
} else {
    Write-Host "   ✗ Users directory not found: $usersPath" -ForegroundColor Red
}

# Test 5: Module functions available
Write-Host "`n5. Testing Module Functions:" -ForegroundColor Yellow
$functions = @('Test-UserSession', 'Get-CurrentUser', 'Set-UserSession', 'Clear-UserSession', 'Invoke-UserAuthentication')
foreach ($func in $functions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "   ✓ $func available" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $func not found" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan

if ($userExists -and $sessionResult.Success -and $currentUser.Success) {
    Write-Host "🎉 All core functionality working correctly!" -ForegroundColor Green
    Write-Host "Dashboard should display properly for authenticated user." -ForegroundColor Green
} else {
    Write-Host "⚠️ Some functionality needs attention." -ForegroundColor Yellow
    Write-Host "Check user authentication and profile setup." -ForegroundColor Yellow
}
