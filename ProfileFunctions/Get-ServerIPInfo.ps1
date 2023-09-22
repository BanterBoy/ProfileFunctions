function Get-ServerIPInfo {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true,
        SupportsShouldProcess = $true)]
    Param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a computer name or pipe input'
        )]
        [Alias('cn')]
        [string[]]$ComputerName
    )

    begin {
    }

    process {
        foreach ($Computer in $ComputerName) {
            if ($PSCmdlet.ShouldProcess("Target", "Operation")) {
                
                $result = @()
                $Invoke = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Get-NetIPConfiguration | Select-Object -Property InterfaceAlias, Ipv4Address, DNSServer
                    Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -ExpandProperty NextHop
                }
                $result += New-Object -TypeName PSCustomObject -Property ([ordered]@{
                        'Server'      = $Computer
                        'Interface'   = $Invoke.InterfaceAlias -join ','
                        'IPv4Address' = $Invoke.Ipv4Address.IPAddress -join ','
                        'Gateway'     = $Invoke | Select-Object -Last 1
                        'DNSServer'   = ($Invoke.DNSServer | Select-Object -ExpandProperty ServerAddresses) -join ',' 
                    })
            }
            $result
        }
    }

    end {
    }
}
