function Get-RestartHistory {
    Param (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the computer name or pipe input'
        )]
        [Alias('cn')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter your credentials or pipe input'
        )]
        [Alias('cred')]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )
    BEGIN {
    }
    PROCESS {
        foreach ($Computer in $ComputerName) {
            $eventLogs = Get-WinEvent -ComputerName $Computer -FilterHashtable @{ LogName = "System"; Id = '6005', '6006', '6008', '6009', '6013', '1074', '1076' } -ErrorAction SilentlyContinue
            foreach ($eventLog in $eventLogs) {
                try {
                    $properties = @{
                        Message      = [string]$eventLog.Message
                        Id           = [int]$eventLog.Id
                        LogName      = [string]$eventLog.LogName
                        MachineName  = [string]$eventLog.MachineName
                        ProviderName = [string]$eventLog.ProviderName
                        TimeCreated  = [datetime]$eventLog.TimeCreated
                    }
                    $obj = New-Object -TypeName PSObject -Property $Properties
                    Write-Output $obj
                }
                catch {
                    Write-Error "Failed with error: $_.Message"
                }
            }
        }
    }
    END {
    }
}

<#
    Get-RestartHistory -ComputerName KAMINO | Where-Object -Property timecreated -GT (Get-Date).AddDays(-7) | Where-Object -FilterScript { ( $_.ID -EQ 6005 ) -or ($_.ID -EQ 6006) } | ft -AutoSize
#>
