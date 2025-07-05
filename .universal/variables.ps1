New-PSUVariable -Name "AWS_ACCESS_KEY_ID" -Vault "Database" 
New-PSUVariable -Name "AWS_REGION" -Value 'us-west-2' -Description "default aws region" 
New-PSUVariable -Name "AWS_SECRET_ACCESS_KEY" -Vault "Database" 
New-PSUVariable -Name "Variable" -Value '/home/data/fusion-data/entries/entries.json' -Description "Entries Path"