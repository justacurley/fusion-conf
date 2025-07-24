# Function to add additional data to a combined data object
function Set-CombinedData {
    param(
        [PSCustomObject]$combinedData,
        [string]$name,
        $data,
        [PSCustomObject]$preCombinedData
    )

    # Add the new property to the existing object
    if (-not $preCombinedData) {
        $combinedData | Add-Member -MemberType NoteProperty -Name $name -Value $data -Force
    }
    else {
        $data = @()
        $PropName = ($preCombinedData |  Get-Member -MemberType NoteProperty | ? name -ne 'Date').Name
        Write-Host $PropName
        Write-Host $preCombinedData.$PropName
        foreach ($date in $preCombinedData.Date) {
            if ($date -in $combinedData.Date) {
                $data += $preCombinedData.$PropName
            }
        }
        Write-Host $data
        $combinedData | Add-Member -MemberType NoteProperty -Name $PropName -Value $data
    }
    return $combinedData
}
