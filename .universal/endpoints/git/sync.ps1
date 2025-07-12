param(
    $Request,
    $Response
)

# This endpoint requires app token authentication
# The endpoint is configured with Administrator/Operator roles which requires proper authorization

try {
    # Validate that the request has proper authentication
    # PSU automatically handles app token validation when roles are specified

    # Log the sync request
    Write-PSULog -Level Information -Message "Git sync initiated via API endpoint by user: $($User.Identity.Name)"

    # Execute the git sync
    $syncResult = Sync-PSUGit

    if ($syncResult) {
        Write-PSULog -Level Information -Message "Git sync completed successfully"

        # Return success response
        @{
            success = $true
            message = "Git repository synchronized successfully"
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        } | ConvertTo-Json
    }
    else {
        Write-PSULog -Level Warning -Message "Git sync completed but returned null/empty result"

        # Return warning response
        @{
            success = $true
            message = "Git sync executed but no specific result returned"
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
        } | ConvertTo-Json
    }
}
catch {
    # Log the error
    Write-PSULog -Level Error -Message "Git sync failed: $($_.Exception.Message)"

    # Set error status code
    $Response.StatusCode = 500

    # Return error response
    @{
        success = $false
        error = "Git synchronization failed"
        details = $_.Exception.Message
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    } | ConvertTo-Json
}
