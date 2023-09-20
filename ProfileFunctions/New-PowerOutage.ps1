function New-PowerOutage {

    <#
    .SYNOPSIS
        Shuts down a computer or a list of computers and optionally monitors virtual machines until they are stopped.

    .DESCRIPTION
        The New-PowerOutage function shuts down a computer or a list of computers and optionally monitors virtual machines until they are stopped. 
        If the -Report switch is specified, the function will monitor virtual machines until all are stopped before shutting down the computer. 
        The function checks if the computer is online before shutting it down and waits for the computer to shut down before completing.

    .PARAMETER ComputerName
        Enter the Name/IP/FQDN for the computer you would like to retrieve the information from or pipe in a list of computers.

    .PARAMETER Report
        If specified, the function will monitor virtual machines until all are stopped before shutting down the computer.

    .EXAMPLE
        New-PowerOutage -ComputerName "Computer01" -Report
        Shuts down "Computer01" and monitors virtual machines until all are stopped.

    .EXAMPLE
        "Computer01", "Computer02" | New-PowerOutage
        Shuts down "Computer01" and "Computer02".

    .NOTES
        Author: Luke Leigh/Github Copilot
        Date: 2023-09-20
    #>


    [CmdletBinding(SupportsShouldProcess = $true)]

    param(
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the Name/IP/FQDN for the computer you would like to retrieve the information from or pipe in a list of computers.')]
        [ValidateNotNullOrEmpty()]
        [Alias('cn')]
        [string[]]$ComputerName,
        [switch]$Report
    )

    begin {
        Write-Verbose "Starting power outage..." -Verbose
    }

    process {
        foreach ($Computer in $ComputerName) {
            if ($PSCmdlet.ShouldProcess("$Computer", "Shut down")) {
                try {
                    # Check if ComputerName is online
                    Write-Verbose "Checking if ComputerName is online..." -Verbose
                    $ComputerState = Test-Connection -ComputerName $Computer -Count 1 -Quiet
                    if (!$ComputerState) {
                        Write-Error "$Computer is offline."
                        return
                    }
                    if ($Report) {
                        Write-Verbose "Monitoring virtual machines..." -Verbose
                        # Monitor virtual machines until all are stopped
                        do {
                            $VirtualMachineState = Get-VM -ComputerName $Computer | Select-Object Name, State
                            $RunningVMs = $VirtualMachineState | Where-Object { $_.State -eq "Running" }
                            Get-VM -ComputerName $Computer | Stop-VM -Force
                            if ($RunningVMs) {
                                $RunningVMs | Format-Table -AutoSize
                            }
                            Start-Sleep -Seconds 5
                        } until (!$RunningVMs)
                    }

                    # Shut down ComputerName
                    Write-Verbose "Shutting down $Computer..." -Verbose
                    Stop-Computer -ComputerName $Computer -Force

                    # Wait for ComputerName to shut down
                    Write-Verbose "Waiting for $Computer to shut down..." -Verbose
                    do {
                        $ComputerState = Test-Connection -ComputerName $Computer -Count 1 -Quiet
                        Start-Sleep -Seconds 5
                    } until (!$ComputerState)
                }
                catch {
                    Write-Error $_.Exception.Message
                }
                finally {
                    Write-Verbose "Power outage complete." -Verbose
                }
            }
        }

    }
    end {
    }   

}
