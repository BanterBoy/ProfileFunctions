function Get-SpoolerService {
    Get-Service -Name Spooler
}

function Set-SpoolerServiceStatus {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'https://github.com/BanterBoy',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Computer,
        [Parameter(Mandatory = $true)]
        [string]$Status,
        [Parameter(Mandatory = $true)]
        [System.ServiceProcess.ServiceController]$SpoolerService
    )

    switch ($Status) {
        'Running' {
            if ($SpoolerService.Status -ne 'Running') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Start Spooler service")) {
                    $SpoolerService | Start-Service
                    Write-Output "Started Spooler service on $Computer"
                }
            }
        }
        'Stopped' {
            if ($SpoolerService.Status -ne 'Stopped') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Stop Spooler service")) {
                    $SpoolerService | Stop-Service
                    Write-Output "Stopped Spooler service on $Computer"
                }
            }
        }
        'Disabled' {
            if ($SpoolerService.StartType -ne 'Disabled') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Disable Spooler service")) {
                    $SpoolerService | Set-Service -StartupType Disabled
                    Write-Output "Disabled Spooler service on $Computer"
                }
            }
        }
        'Enabled' {
            if ($SpoolerService.StartType -eq 'Disabled') {
                if ($PSCmdlet.ShouldProcess("$Computer", "Enable Spooler service")) {
                    $SpoolerService | Set-Service -StartupType Automatic
                    Write-Output "Enabled Spooler service on $Computer"
                }
            }
        }
    }
}

function Set-PrintSpoolerConfig {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'https://github.com/BanterBoy',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter computer name or pipe input')]
        [Alias('cn')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            HelpMessage = 'Enter desired status of the Print Spooler service')]
        [ValidateSet('Running', 'Stopped', 'Disabled', 'Enabled')]
        [string]$Status
    )

    PROCESS {

        foreach ($Computer in $ComputerName) {
            try {
                $localComputerName = [System.Environment]::MachineName
                if ($localComputerName -eq $Computer) {
                    # Run the command locally
                    $spoolerService = Get-SpoolerService
                    Set-SpoolerServiceStatus -Computer $Computer -Status $Status -SpoolerService $spoolerService
                }
                else {
                    # Run the command remotely
                    Invoke-Command -ComputerName $Computer -ScriptBlock {
                        $spoolerService = Get-SpoolerService
                        Set-SpoolerServiceStatus -Computer $using:Computer -Status $using:Status -SpoolerService $spoolerService
                    }
                }
            }
            catch {
                Write-Error "Failed to set Print Spooler service status on ${Computer}: $_"
            }
        }
    }
}