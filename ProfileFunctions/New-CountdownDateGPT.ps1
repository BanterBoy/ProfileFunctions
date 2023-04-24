<#
function New-PayDayCountdownGPT {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
                if ($_ -as [DateTime]) { $true }
                else { throw "Please enter a valid date in format dd/MM/yyyy." }
            })]
        [DateTime]$PayDay,

        [Parameter(Mandatory = $false, Position = 1)]
        [Switch]$UpdateConfig,

        [Parameter(Mandatory = $false, Position = 2)]
        [Switch]$ListAll
    )

    # Get the current date and time in the user's culture
    $now = Get-Date

    # Check if the PayDay date is in the future
    if ($PayDay -lt $now.Date) {
        Write-Warning "The payday date has already passed."
        return
    }

    # Calculate the number of days until payday
    $daysToPayDay = ($PayDay.Date - $now.Date).Days

    # Output a PSObject with the relevant information
    $outputObject = [PSCustomObject] @{
        NextPayDay   = $PayDay
        DaysToPayDay = $daysToPayDay
        Message      = if ($daysToPayDay -eq 0) { "Today is payday!" }
        elseif ($daysToPayDay -eq 1) { "Tomorrow is payday!" }
        else { "$daysToPayDay days until payday." }
    }

    # If the ListAll switch is specified, also output the current payday date from the config file
    if ($ListAll) {
        $configData = Get-Content "$env:USERPROFILE\paydaycountdown.config.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        $currentPayDay = $configData.NextPayDay

        $outputObject | Add-Member -MemberType NoteProperty -Name "CurrentPayDay" -Value $currentPayDay
    }

    # If the UpdateConfig switch is specified, update the payday date in the config file
    if ($UpdateConfig) {
        $configData = Get-Content "$env:USERPROFILE\paydaycountdown.config.json" -ErrorAction SilentlyContinue | ConvertFrom-Json

        if ($configData) {
            $configData.NextPayDay = $PayDay
            $configData | ConvertTo-Json -Depth 10 | Set-Content "$env:USERPROFILE\paydaycountdown.config.json"
        }
        else {
            $newConfigData = [PSCustomObject] @{
                NextPayDay = $PayDay
            }
            $newConfigData | ConvertTo-Json -Depth 10 | Set-Content "$env:USERPROFILE\paydaycountdown.config.json"
        }
    }

    Write-Output $outputObject
}
#>

function New-PayDayCountdownGPT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [DateTime]$PayDay = $null,
        [Switch]$UpdateConfig,
        [Switch]$ListAll
    )
    $configFile = $PSScriptRoot + "PayDayCountdownGPT.config.json"
    if ($UpdateConfig) {
        if (-not (Test-Path $configFile)) {
            $configData = [PSCustomObject]@{
                NextPayDay = $PayDay
            }
        }
        else {
            $configData = Get-Content $configFile -Raw | ConvertFrom-Json
            $configData.NextPayDay = $PayDay
        }
        $configData | ConvertTo-Json | Out-File $configFile
    }
    else {
        if (-not (Test-Path $configFile)) {
            Write-Warning "Config file not found. Creating new config file with default values."
            $configData = [PSCustomObject]@{
                NextPayDay = $PayDay
            }
            $configData | ConvertTo-Json | Out-File $configFile
        }
        else {
            $configData = Get-Content $configFile -Raw | ConvertFrom-Json
        }
        if ($ListAll) {
            $configData | Select-Object -Property NextPayDay, @{Name = 'DaysToPayDay'; Expression = { New-TimeSpan -Start (Get-Date) -End $_.NextPayDay | Select-Object -ExpandProperty Days } }
        }
        else {
            $payDay = [DateTime]::ParseExact($configData.NextPayDay.ToString("dd/MM/yyyy"), "dd/MM/yyyy", [System.Globalization.CultureInfo]::CreateSpecificCulture("en-GB"))
            $daysToPayDay = (New-TimeSpan -Start (Get-Date) -End $payDay).Days
            $message = "$daysToPayDay days until payday."
            if ($daysToPayDay -eq 0) {
                $message = "Today is payday!"
            }
            elseif ($daysToPayDay -eq 1) {
                $message = "Tomorrow is payday!"
            }
            [PSCustomObject]@{
                NextPayDay   = $payDay
                DaysToPayDay = $daysToPayDay
                Message      = $message
            }
        }
    }
}
