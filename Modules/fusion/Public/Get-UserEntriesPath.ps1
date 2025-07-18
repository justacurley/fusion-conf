function Get-UserEntriesPath {
    <#
    .SYNOPSIS
    Gets the entries.json file path for a specific user

    .DESCRIPTION
    Constructs the full path to a user's entries.json file based on their email address.
    The email is base64 encoded for safe filesystem usage.

    .PARAMETER UserEmail
    The user's email address

    .PARAMETER BaseDataPath
    Optional. The base data directory path. Defaults to appropriate path based on environment

    .EXAMPLE
    $entriesPath = Get-UserEntriesPath -UserEmail "user@example.com"

    .EXAMPLE
    $entriesPath = Get-UserEntriesPath -UserEmail "alex@domain.com" -BaseDataPath "/custom/data/path"

    .OUTPUTS
    Returns the full path to the user's entries.json file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[^@]+@[^@]+\.[^@]+$')]
        [string]$UserEmail,

        [Parameter(Mandatory = $false)]
        [string]$BaseDataPath
    )

    try {
        # Determine base data path if not provided
        if (-not $BaseDataPath) {
            $Remote = Get-ChildItem Env:HOSTNAME -ErrorAction Ignore
            if ($Remote -and $Remote.Value -like '*us-west-2*') {
                $BaseDataPath = '/home/data'
            }
            else {
                $BaseDataPath = '/home/alex/src/fusion-local/data'
            }
        }

        # Encode email address for safe filesystem usage
        $EncodedEmail = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($UserEmail))

        # Construct full path
        $UserEntriesPath = Join-Path $BaseDataPath "users" $EncodedEmail "health-data" "entries.json"

        Write-Information "Generated entries path for user '$UserEmail': $UserEntriesPath"
        return $UserEntriesPath
    }
    catch {
        Write-Error "Error generating user entries path: $($_.Exception.Message)"
        throw
    }
}
