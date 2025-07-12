# Example: How to call the Git Sync API endpoint with an App Token
#
# Prerequisites:
# 1. Generate an App Token in PSU Admin Console (Security -> App Tokens)
# 2. Ensure the user account associated with the token has Administrator or Operator role
# 3. Replace 'YOUR_APP_TOKEN_HERE' with your actual app token
# 4. Replace 'http://localhost:5000' with your PSU server URL

param(
    [Parameter(Mandatory = $true)]
    [string]$AppToken,

    [Parameter(Mandatory = $false)]
    [string]$PSUServerUrl = "http://localhost:5000"
)

# Construct the API endpoint URL
$apiUrl = "$PSUServerUrl/api/git/sync"

# Set up headers with app token authentication
$headers = @{
    "Authorization" = "Bearer $AppToken"
    "Content-Type" = "application/json"
}

try {
    Write-Host "Initiating Git sync via API..." -ForegroundColor Yellow

    # Make the API call
    $response = Invoke-RestMethod -Uri $apiUrl -Method POST -Headers $headers

    if ($response.success) {
        Write-Host "✅ Git sync completed successfully!" -ForegroundColor Green
        Write-Host "Message: $($response.message)" -ForegroundColor Green
        Write-Host "Timestamp: $($response.timestamp)" -ForegroundColor Gray
    }
    else {
        Write-Host "❌ Git sync failed!" -ForegroundColor Red
        Write-Host "Error: $($response.error)" -ForegroundColor Red
        if ($response.details) {
            Write-Host "Details: $($response.details)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "❌ Failed to call Git sync API!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red

    # Check for common authentication issues
    if ($_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*Unauthorized*") {
        Write-Host "💡 This looks like an authentication issue. Please check:" -ForegroundColor Cyan
        Write-Host "   - App token is valid and not expired" -ForegroundColor Cyan
        Write-Host "   - User associated with token has Administrator or Operator role" -ForegroundColor Cyan
        Write-Host "   - Token is properly formatted (no extra spaces)" -ForegroundColor Cyan
    }
    elseif ($_.Exception.Message -like "*403*" -or $_.Exception.Message -like "*Forbidden*") {
        Write-Host "💡 This looks like an authorization issue. Please check:" -ForegroundColor Cyan
        Write-Host "   - User associated with token has Administrator or Operator role" -ForegroundColor Cyan
        Write-Host "   - Endpoint role requirements are properly configured" -ForegroundColor Cyan
    }
}

# Example usage:
# .\Test-GitSyncAPI.ps1 -AppToken "your-app-token-here"
# .\Test-GitSyncAPI.ps1 -AppToken "your-app-token-here" -PSUServerUrl "https://yourserver.com"
