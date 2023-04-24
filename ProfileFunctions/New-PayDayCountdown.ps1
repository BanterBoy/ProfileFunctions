function New-PayDayCountdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$PayDay = $null,
        [Switch]$ListAll,
        [Switch]$UpdateConfig
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
            $PayDay = [DateTime]::ParseExact($configData.NextPayDay, "dd/MM/yyyy HH:mm:ss", $null)
        }
    }
    else {
        $PayDay = [DateTime]::ParseExact($PayDay.ToString("dd/MM/yyyy"), "dd/MM/yyyy", $null)
    }

    if ($ListAll) {
        $configData | Select-Object -Property @{Name = "PayDay"; Expression = { [DateTime]::ParseExact($_.NextPayDay, "dd/MM/yyyy HH:mm:ss", $null) } }, DaysToPayDay
        return
    }

    if ($UpdateConfig) {
        $configData.NextPayDay = $PayDay.ToString("dd/MM/yyyy HH:mm:ss")
        $configData | ConvertTo-Json | Set-Content $configFile
        Write-Output "Payday updated to $($PayDay.ToString("dd/MM/yyyy"))."
        return
    }

    $daysToPayDay = [int]($PayDay - (Get-Date)).TotalDays
    if ($daysToPayDay -lt 0) {
        $daysToPayDay += 30
        Write-Warning "Payday has already passed this month. Please update the date."
    }

    # if ($daysToPayDay -eq 0) {
    #     Write-Output "Today is payday!"
    # }
    # elseif ($daysToPayDay -eq 1) {
    #     Write-Output "Tomorrow is payday!"
    # }
    # else {
    #     Write-Output "$daysToPayDay days until payday."
    # }

    [PSCustomObject]@{
        "NextPayDay"   = $PayDay
        "DaysToPayDay" = $daysToPayDay
        "Message"      = if ($daysToPayDay -lt 0) { "Payday has already passed this month. Please update the date." } else { "" }
    }
}

function Read-PayDay {
    $PayDay = $null
    while (!$PayDay) {
        $inputDate = Read-Host "Please enter your next payday (dd/mm/yyyy):"
        try {
            $PayDay = [DateTime]::ParseExact($inputDate, "dd/MM/yyyy", $null)
        }
        catch {
            Write-Host "Invalid date format. Please enter the date in the format dd/mm/yyyy." -ForegroundColor Red
        }
    }
    $PayDay
}
