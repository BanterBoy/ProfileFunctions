function Get-RDPStatus {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $ComputerName
    )
    process {
        foreach ($Computer in $ComputerName) {
            try {
                $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computer -ErrorAction Stop
                $tsobj = Get-CimInstance -ClassName "Win32_TerminalServiceSetting" -Namespace "root/CIMV2/TerminalServices" -ComputerName $Computer -ErrorAction Stop
                if ($tsobj.AllowTSConnections -eq '1') {
                    Write-Verbose "$($Computer): RDP is enabled"
                    [pscustomobject]@{
                        ComputerName = $Computer
                        RDPStatus    = 'Enabled'
                    }
                }
                else {
                    Write-Verbose "$($Computer): RDP is disabled"
                    [pscustomobject]@{
                        ComputerName = $Computer
                        RDPStatus    = 'Disabled'
                    }
                }
            }
            catch {
                Write-Warning "Error retrieving RDP status for computer '$Computer': $_"
            }
        }
    }
}