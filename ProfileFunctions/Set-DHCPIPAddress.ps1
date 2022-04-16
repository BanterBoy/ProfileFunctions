function Set-DHCPIPAddress {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        HelpUri = 'https://github.com/BanterBoy')]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter Current IPAddress or pipe input')]
        [Alias('ci')]
        [string[]]$CurrentIPAddress
    )
    BEGIN {
    }
    PROCESS {
        foreach ($IPAddress in $CurrentIPAddress) {
            $NetworkCard = Get-NetIPAddress -IPAddress $IPAddress
            Get-NetIPInterface -InterfaceIndex $NetworkCard.InterfaceIndex | Set-NetIPInterface -Dhcp Enabled -ErrorAction SilentlyContinue
        }
    }
    END {
    }
}

# Set-DHCPIPAddress -CurrentIPAddress '192.168.1.20'
# Clear-DnsClientCache
# Register-DnsClient
