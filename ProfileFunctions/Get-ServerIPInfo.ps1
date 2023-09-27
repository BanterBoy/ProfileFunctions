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
            if ($PSCmdlet.ShouldProcess("$Computer", "exporting IP information")) {
                $result = @()
                $Invoke = Invoke-Command -ComputerName $Computer -ScriptBlock {
                    Get-NetIPConfiguration | Select-Object -Property InterfaceAlias, Ipv4Address, DNSServer
                    Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Select-Object -ExpandProperty NextHop
                }
                foreach ($Interface in $Invoke.InterfaceAlias) {
                    $InterfaceDetails = $Invoke | Where-Object { $_.InterfaceAlias -eq $Interface }
                    $result += New-Object -TypeName PSCustomObject -Property ([ordered]@{
                            'Server'      = $Computer
                            'Interface'   = $Interface
                            'IPv4Address' = $InterfaceDetails.Ipv4Address.IPAddress -join ','
                            'Gateway'     = $Invoke | Select-Object -Last 1
                            'DNSServer'   = ($InterfaceDetails.DNSServer | Select-Object -ExpandProperty ServerAddresses) -join ',' 
                        })
                }
            }
            $result
        }
    }

    end {
    }
}