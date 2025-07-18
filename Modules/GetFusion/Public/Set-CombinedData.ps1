# Function to add additional data to a combined data object
function Set-CombinedData {
    param(
        [PSCustomObject]$combinedData,
        [string]$name,
        $data
    )

    # Add the new property to the existing object
    $combinedData | Add-Member -MemberType NoteProperty -Name $name -Value $data -Force

    return $combinedData
}
