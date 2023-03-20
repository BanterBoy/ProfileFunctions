Function Test-Computer {

    <#
	.SYNOPSIS
		A brief description of the Test-Computer function.
	
	.DESCRIPTION
		A detailed description of the Test-Computer function.
	
	.PARAMETER ComputerName
		A description of the ComputerName parameter.
	
	.EXAMPLE
		​PS C:\> Test-Computer -ComputerName COMPUTERONE
		This will test COMPUTERONE
	
	.OUTPUTS
		System.String. Test-Computer returns an object of type System.String.
	
	.NOTES
		Author:     Luke Leigh
		Website:    https://scripts.lukeleigh.com/
		LinkedIn:   https://www.linkedin.com/in/lukeleigh/
		GitHub:     https://github.com/BanterBoy/
		GitHubGist: https://gist.github.com/BanterBoy
	
	.INPUTS
		You can pipe objects to these perameters.
		
		- ComputerName [string[]]
	
	.LINK
		https://scripts.lukeleigh.com
		Get-
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the Name of the computer you would like to connect to.')]
        [Alias('cn')]
        [string[]]$ComputerName

    )

    begin {
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            if ($PSCmdlet.ShouldProcess("$Computer", "Performing DNS, RDP, AD and Status tests")) {
                
                try {
                    $ConnectionResult = Test-Connection -ComputerName $Computer -Ping -Count 1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    $ADResultFQDN = Get-ADComputer -Filter 'DNSHostName -like $Computer ' -Properties IPv4Address -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    $ADResult = Get-ADComputer -Filter 'Name -like $Computer ' -Properties IPv4Address -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    $DNSResult = Resolve-DnsName $Computer -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    $PortResult = Test-OpenPorts -ComputerName $Computer -Ports 3389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if ($ConnectionResult -and $PortResult) {
                        í
                        if ($ADResult) {
                            $properties = [ordered]@{
                                ComputerName      = $ADResult.DNSHostName
                                'ActiveADOBJect'  = $ADResult.Enabled
                                'DNSRegistration' = $DNSResult.IP4Address
                                'RDPEnabled'      = $PortResult.Status
                                Online            = $ConnectionResult.Status
                            }
                        }
                        if ($ADResultFQDN) {
                            $properties = [ordered]@{
                                ComputerName      = $ADResultFQDN.DNSHostName
                                'ActiveADOBJect'  = $ADResultFQDN.Enabled
                                'DNSRegistration' = $DNSResult.IP4Address
                                'RDPEnabled'      = $PortResult.Status
                                Online            = $ConnectionResult.Status
                            }
                        }
                    }
                    else {
                        throw
                    }
                }
                catch {
                    $properties = [ordered]@{
                        ComputerName      = $Computer
                        'ActiveADOBJect'  = "NoObject"
                        'DNSRegistration' = "NoRegistration"
                        'RDPEnabled'      = "Unavailble"
                        Online            = "Inactive"
                    }
                }
                finally {
                    Write-Output -InputObject $properties
                }
            }
        }
    }
    end {
    }

}
