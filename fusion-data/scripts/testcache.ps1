# Script contents

$Entries = (Get-PSUCache -Key 'entriesData' -OutVariable TempEntry) ? $TempEntry : (& {
        Write-Information "Could not find entriesData cache"
        $EntriesPath = "/home/data/fusion-data/entries/entries.json"
        Get-EntriesData -Path $EntriesPath
        # Set-PSUCache -Key "Entries" -Value $Entries -Expiration (New-TimeSpan -Days 1) | Out-Null
    })
$Entries

Get-Variable TempEntry