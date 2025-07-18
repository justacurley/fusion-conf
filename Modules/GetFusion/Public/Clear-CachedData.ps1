# Function to clear cached data (useful when entries data changes)
function Clear-CachedData {
    $global:DatesList = $null
    $global:DistinctDataValues = @{}
}
