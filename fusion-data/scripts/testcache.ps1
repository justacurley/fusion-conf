# Script contents
param($key)
$DNE = Get-PSUCache -Key $Key
if ( -not $DNE) {
    Write-Information "no $Key cache"
} else {
    Write-Information "Found $Key cache"
    $DNE | Get-Member
 }