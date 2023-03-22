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
                    $RDPResult = Test-OpenPorts -ComputerName $Computer -Ports 3389 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    $PwshResult = Test-OpenPorts -ComputerName $Computer -Ports 5985 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                    if ($ConnectionResult -and $RDPResult) {
                        if ($ADResult) {
                            $properties = [ordered]@{
                                ComputerName         = $ADResult.DNSHostName
                                'Active ADOBJect'    = $ADResult.Enabled
                                'DNS Registration'   = $DNSResult.IP4Address
                                'RDP Enabled'        = $RDPResult.Status
                                'Powershell Enabled' = $PwshResult.Status
                                Online               = $ConnectionResult.Status
                            }
                            # Write-Output -InputObject $properties
                        }
                        if ($ADResultFQDN) {
                            $properties = [ordered]@{
                                ComputerName         = $ADResultFQDN.DNSHostName
                                'Active ADOBJect'    = $ADResultFQDN.Enabled
                                'DNS Registration'   = $DNSResult.IP4Address
                                'RDP Enabled'        = $RDPResult.Status
                                'Powershell Enabled' = $PwshResult.Status
                                Online               = $ConnectionResult.Status
                            }
                            # Write-Output -InputObject $properties
                        }
                    }
                    else {
                        throw
                    }
                }
                catch {
                    $properties = [ordered]@{
                        ComputerName         = $Computer
                        'ActiveADOBJect'     = "NoObject"
                        'DNSRegistration'    = "NoRegistration"
                        'RDPEnabled'         = "Unavailable"
                        'Powershell Enabled' = "Unavailable"
                        Online               = "Inactive"
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
