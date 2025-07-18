# Function to get cached entries from PowerShell Universal
function Get-PSUCachedEntries {
    $Entries = (Get-PSUCache -Key 'entriesData' -OutVariable TempEntry) ? $TempEntry : (& {
            Write-Information 'Could not find entriesData cache'
            $EntriesPath = '/home/data/fusion-data/entries/entries.json'
            Get-EntriesData -entriesPath $EntriesPath
            Set-PSUCache -Key 'entriesData' -Value $Entries -Expiration (New-TimeSpan -Days 1) | Out-Null
            $Entries
        })
    $TempEntry ? (Remove-Variable -Name TempEntry -ErrorAction Ignore) : $null
    return $Entries
}
