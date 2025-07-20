# Simple function that returns chart-ready sleep dataset
function Get-SleepChartData {
    param(
        [Parameter(Mandatory)]
        [Array]$Entries
    )
    # Function to parse sleep data from various formats
    function Get-SleepHours {
        param([string]$sleepValue)

        if ([string]::IsNullOrEmpty($sleepValue)) {
            return $null
        }

        # Parse "HH:MM" format like "7:39", "9:10", "6:03"
        if ($sleepValue -match '^(\d+):(\d+)$') {
            $hours = [int]$matches[1]
            $minutes = [int]$matches[2]
            return [math]::Round($hours + ($minutes / 60.0), 2)
        }
        # Handle decimal format like "7.5"
        elseif ($sleepValue -match '^(\d+(?:\.\d+)?)$') {
            return [double]$matches[1]
        }

        return $null
    }

    return $Entries |
    Where-Object {
        $_.entry_types -contains "sleep" -and
        $_.data.sleep.sleep_duration
    } |
    Group-Object date |
    ForEach-Object {
        $totalSleep = ($_.Group | ForEach-Object {
                Get-SleepHours -sleepValue $_.data.sleep.sleep_duration
            } | Where-Object { $_ -ne $null } | Measure-Object -Sum).Sum

        if ($totalSleep -gt 0) {
            [PSCustomObject]@{
                Date          = (Get-Date $_.Name).ToString("MM/dd")
                SleepDuration = [math]::Round($totalSleep, 2)
            }
        }
    } |
    Where-Object { $_ -ne $null } |
    Sort-Object { [DateTime]::ParseExact($_.Date + "/2025", "MM/dd/yyyy", $null) }
}