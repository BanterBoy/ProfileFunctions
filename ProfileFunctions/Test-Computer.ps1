function Test-Computer {
    <#
    .SYNOPSIS
    The function Test-Computer can be used to test a computer and return the current status of the computer. This includes DNS, RDP, AD, and DHCP IP address information. 

    .DESCRIPTION
    The function Test-Computer can be used to test a computer and return the current status of the computer. The function performs a number of tests to retrieve the DNS, RDP, AD, and DHCP IP address information. The tests performed are as follows:
        - Test-Connection
        - Get-ADComputer
        - Resolve-DnsName
        - Test-OpenPorts
        - Get-NetIPAddress
    Each test is performed and the results are returned in a custom object.
    The first test performed is a Test-Connection to the computer. If the computer is not online, the function will return a custom object with the computer name and the status of "Inactive" and will not perform any further tests.

    .PARAMETER ComputerName
    The ComputerName parameter is used to specify the name of the computer you would like to test.
    This can be entered as a string or an array of strings. The format of the string can be either the computer name or the FQDN.

    .EXAMPLE
    Test-Computer -ComputerName "Computer01"

    This will test and return the current status of the computer using the computer name. This includes DNS, RDP, AD, and DHCP IP address information.

    .EXAMPLE
    Test-Computer -ComputerName "Computer01.contoso.com"

    This will test and return the current status of the computer using the FQDN. This includes DNS, RDP, AD, and DHCP IP address information.

    .OUTPUTS
    System.Object. Test-Computer returns a custom object with the results of the tests.

    .NOTES
    Author:     Luke Leigh
    Website:    https://scripts.lukeleigh.com/
    LinkedIn:   https://www.linkedin.com/in/lukeleigh/
    GitHub:     https://github.com/BanterBoy/
    GitHubGist: https://gist.github.com/BanterBoy

    .INPUTS
    You can pipe objects to this parameter.
    - ComputerName [string[]]

    .LINK
    https://scripts.lukeleigh.com
    Test-Connection
    Get-ADComputer
    Resolve-DnsName
    Test-OpenPorts
    Get-NetIPAddress
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/',
        PositionalBinding = $true)]
    [OutputType([PSCustomObject], ParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'Enter the Name of the computer you would like to test.')]
        [Alias('cn')]
        [string[]]$ComputerName
    )

    begin {
    }

    process {
        $total = $ComputerName.Count
        $count = 0

        foreach ($Computer in $ComputerName) {
            $count++
            $percentComplete = ($count / $total) * 100
            Write-Progress -Activity "Testing Computers" -Status "Initializing test for $Computer ($count of $total)" -PercentComplete $percentComplete

            if ($PSCmdlet.ShouldProcess("$Computer", "Performing DNS, RDP, AD, and Status tests")) {
                $properties = [ordered]@{
                    ComputerName         = $Computer
                    'Active AD Object'   = "Error"
                    'DNS Registration'   = "Error"
                    'RDP Enabled'        = "Error"
                    'Powershell Enabled' = "Error"
                    'DHCP IP'            = "Error"
                    Online               = "Error"
                }

                Write-Progress -Activity "Testing Computers" -Status "Pinging $Computer" -PercentComplete $percentComplete
                try {
                    $ConnectionResult = Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue
                    if ($ConnectionResult) {
                        $properties['Online'] = "Online"
                    } else {
                        $properties['Online'] = "Offline"
                    }
                } catch {
                    Write-Error -Message "Failed to ping $($Computer): $_"
                }

                Write-Progress -Activity "Testing Computers" -Status "Fetching AD information for $Computer" -PercentComplete $percentComplete
                try {
                    $ADResultFQDN = Get-ADComputer -Filter "DNSHostName -like '$Computer'" -Properties IPv4Address -ErrorAction SilentlyContinue
                    $ADResult = Get-ADComputer -Filter "Name -like '$Computer'" -Properties IPv4Address -ErrorAction SilentlyContinue
                    if ($ADResult) {
                        $properties['Active AD Object'] = $ADResult.Enabled
                    } elseif ($ADResultFQDN) {
                        $properties['Active AD Object'] = $ADResultFQDN.Enabled
                    } else {
                        $properties['Active AD Object'] = "NoObject"
                    }
                } catch {
                    Write-Error -Message "Failed to get AD information for $($Computer): $_"
                }

                Write-Progress -Activity "Testing Computers" -Status "Resolving DNS for $Computer" -PercentComplete $percentComplete
                try {
                    $DNSResult = Resolve-DnsName $Computer -ErrorAction SilentlyContinue
                    if ($DNSResult) {
                        $properties['DNS Registration'] = $DNSResult.IP4Address
                    } else {
                        $properties['DNS Registration'] = "NoRegistration"
                    }
                } catch {
                    Write-Error -Message "Failed to resolve DNS for $($Computer): $_"
                }

                Write-Progress -Activity "Testing Computers" -Status "Checking RDP port for $Computer" -PercentComplete $percentComplete
                try {
                    $RDPResult = Test-OpenPorts -ComputerName $Computer -Ports 3389 -ErrorAction SilentlyContinue
                    if ($RDPResult) {
                        $properties['RDP Enabled'] = $RDPResult.Status
                    } else {
                        $properties['RDP Enabled'] = "Unavailable"
                    }
                } catch {
                    Write-Error -Message "Failed to check RDP port for $($Computer): $_"
                }

                Write-Progress -Activity "Testing Computers" -Status "Checking PowerShell port for $Computer" -PercentComplete $percentComplete
                try {
                    $PwshResult = Test-OpenPorts -ComputerName $Computer -Ports 5985 -ErrorAction SilentlyContinue
                    if ($PwshResult) {
                        $properties['Powershell Enabled'] = $PwshResult.Status
                    } else {
                        $properties['Powershell Enabled'] = "Unavailable"
                    }
                } catch {
                    Write-Error -Message "Failed to check PowerShell port for $($Computer): $_"
                }

                Write-Progress -Activity "Testing Computers" -Status "Fetching DHCP IP for $Computer" -PercentComplete $percentComplete
                try {
                    $LocalIPResult = Get-NetIPAddress -CimSession $Computer -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object -Property PrefixOrigin -eq "Dhcp"
                    if ($LocalIPResult) {
                        $properties['DHCP IP'] = $LocalIPResult.IPAddress
                    } else {
                        $properties['DHCP IP'] = "Unavailable"
                    }
                } catch {
                    Write-Error -Message "Failed to get DHCP IP for $($Computer): $_"
                }

                Write-Output -InputObject ([PSCustomObject]$properties)
            }
        }
    }

    end {
        Write-Progress -Activity "Testing Computers" -Completed
    }
}
