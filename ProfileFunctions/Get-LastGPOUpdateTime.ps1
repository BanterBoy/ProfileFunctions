function Get-LastGPOUpdateTime {
    param (
        # The name of the computer to query
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    try {
        # Invoke a command on the remote computer to get the last Group Policy update time
        $gpResult = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Query the registry for the last Group Policy update time
            [datetime]::FromFileTime(([Int64] ((Get-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}").startTimeHi) -shl 32) -bor ((Get-ItemProperty -Path "Registry::HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Extension-List\{00000000-0000-0000-0000-000000000000}").startTimeLo))
        }
        # Convert the result to a date
        $lastGPUpdateDate = Get-Date ($gpResult[0])
        # Calculate the time span since the last Group Policy update
        $timeSinceLastUpdate = New-TimeSpan -Start $lastGPUpdateDate -End (Get-Date)

        # Create a custom object to hold the results
        $result = New-Object PSObject
        $result | Add-Member -Type NoteProperty -Name "ComputerName" -Value $ComputerName
        $result | Add-Member -Type NoteProperty -Name "LastGPOUpdateTime" -Value $lastGPUpdateDate
        $result | Add-Member -Type NoteProperty -Name "DaysSinceLastUpdate" -Value $timeSinceLastUpdate.Days
        $result | Add-Member -Type NoteProperty -Name "TimeSinceLastUpdate" -Value ("{0} hours, {1} minutes, {2} seconds" -f $timeSinceLastUpdate.Hours, $timeSinceLastUpdate.Minutes, $timeSinceLastUpdate.Seconds)

        # Return the result object
        return $result
    }
    catch {
        # If an error occurs, print a relevant error message and return a custom object with the error details
        $errMsg = $_.Exception.Message
        Write-Verbose "An error occurred while querying the Group Policy update time on $($ComputerName): $errMsg"

        # Create a custom object to hold the error details
        $errorDetails = New-Object PSObject
        $errorDetails | Add-Member -Type NoteProperty -Name "ComputerName" -Value $ComputerName
        $errorDetails | Add-Member -Type NoteProperty -Name "Error" -Value $errMsg

        # Return the error details object
        return $errorDetails
    }
}