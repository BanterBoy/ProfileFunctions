function Get-Uptime {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsPaging = $true,
        SupportsShouldProcess = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the Name/IP/FQDN for the computer you would like to retrieve the information from.')]
        [ValidateNotNullOrEmpty()]
        [Alias('cn')]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 1,
            HelpMessage = 'Only output the date of the uptime.')]
        [switch]
        $Since
    )

    process {
        if ($PSCmdlet.ShouldProcess("$($Computer)", "Retrieving ")) {
            foreach ($Computer in $ComputerName) {
                try {
                    $Date = (Get-CimInstance -ComputerName $Computer -Class Win32_OperatingSystem).LastBootUpTime
                    if ($Since) {
                        Write-Output $Date
                    } else {
                        New-Timespan -Start $Date
                    }
                }
                catch {
                    $properties = @{
                        'Date'              = $Date
                        'Days'              = $Date.Days
                        'Hours'             = $Date.Hours
                        'Minutes'           = $Date.Minutes
                        'Seconds'           = $Date.Seconds
                        'Milliseconds'      = $Date.Milliseconds
                        'Ticks'             = $Date.Ticks
                        'TotalDays'         = $Date.TotalDays
                        'TotalHours'        = $Date.TotalHours
                        'TotalMinutes'      = $Date.TotalMinutes
                        'TotalSeconds'      = $Date.TotalSeconds
                        'TotalMilliseconds' = $Date.TotalMilliseconds
                    }
                    $obj = New-Object PSObject -Property $properties
                    Write-Output $obj
                }
            }
        }
        else {
            Write-Error -Message $_
        }
    }
}
