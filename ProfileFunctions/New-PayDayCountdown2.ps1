function New-PayDayCountdown2 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$PayDay = $null,
        [Switch]$ListAll,
        [Switch]$UpdateConfig,
        [string]$DateFormat = "dd/MM/yyyy"
    )
    $profileDir = $env:USERPROFILE
    $configFile = "$profileDir\PayDayCountdownConfig.json"
    $configData = Get-Content $configFile -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (!$configData) {
        $configData = @{}
    }
    if ($PayDay -eq $null) {
        if ($null -eq $configData.NextPayDay) {
            $PayDay = Read-PayDay
        }
        else {
            $PayDay = [DateTime]::ParseExact($configData.NextPayDay, $DateFormat, $null)
        }
    }
    else {
        $PayDay = [DateTime]::ParseExact($PayDay, $DateFormat, $null)
    }

    if ($ListAll) {
        $configData | Select-Object -Property @{Name = "PayDay"; Expression = { [DateTime]::ParseExact($_.NextPayDay, $DateFormat, $null) } }, DaysToPayDay
        return
    }

    if ($UpdateConfig) {
        $configData.NextPayDay = $PayDay.ToString($DateFormat)
        $configData | ConvertTo-Json | Set-Content $configFile
        Write-Output "Payday updated to $($PayDay.ToString($DateFormat))."
        return
    }

    $daysToPayDay = [int]($PayDay - (Get-Date)).TotalDays
    if ($daysToPayDay -lt 0) {
        $daysToPayDay += 30
        Write-Warning "Payday has already passed this month. Please update the date."
    }

    if ($daysToPayDay -eq 0) {
        Write-Output "Today is payday!"
    }
}

function Read-PayDay {
    $PayDay = $null
    while (!$PayDay) {
        $inputDate = Read-Host "Please enter your next payday (dd/mm/yyyy)"
        try {
            $PayDay = [DateTime]::Parse($inputDate, "dd/MM/yyyy", $null)
        }
        catch {
            Write-Host "Invalid date format. Please enter the date in the format dd/mm/yyyy." -ForegroundColor Red
        }
    }
    $PayDay
}
