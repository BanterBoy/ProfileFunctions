Function Connect-OPExchange {
    <#
	.SYNOPSIS
		Connect-OPExchange - A function to 
	
	.DESCRIPTION
		Connect-OPExchange - A function to connect to Office 365 Exchange Online using Modern Authentication.
	
	.PARAMETER UserName
		[string]UserName - Enter a username with permissions to Office 365. If left blank it will try to use the default account for the powershell session, using the '$env:USERNAME' environment variable.
	
	.EXAMPLE
        Connect-OPExchange -UserName "lukeleigh.admin"
        Connects using the account named in UserName
	
	.EXAMPLE
        Connect-OPExchange
        Connects using the environment variable $Env:USERNAME
    
	.EXAMPLE
        ex365 -UserName "lukeleigh"
        Using the command alias, this command connects using the account named in UserName
	
	.OUTPUTS
		No output returned.
	
	.NOTES
		Author:     Luke Leigh
		Website:    https://scripts.lukeleigh.com/
		LinkedIn:   https://www.linkedin.com/in/lukeleigh/
		GitHub:     https://github.com/BanterBoy/
		GitHubGist: https://gist.github.com/BanterBoy
	
	.INPUTS
		You can pipe objects to these perameters.
		
		- UserName [string]
	
	.LINK
		https://scripts.lukeleigh.com
        Import-Module
		Connect-ExchangeOnline

#>
	
    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')]
    [OutputType([string], ParameterSetName = 'Default')]
    [Alias('ex365')]
    [OutputType([String])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter a login/SamAccountName with permissions to Office 365 e.g. "lukeleigh.admin". If left blank it will try to use the default account for the powershell session, using the env:USERNAME environment variable.')]
        [ValidateNotNullOrEmpty()]
        [Alias('user')]
        [string]$UserName = $env:USERNAME,

        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Select the Exchange Server to connect to.')]
        [ArgumentCompleter( {
                $Exchange = Get-ExchangeServerInSite
                $Servers = Get-Random -InputObject $Exchange -Shuffle:$true
                foreach ($Server in $Servers) {
                    $Server.FQDN
                }
            }) ]
        [Alias('server')]
        [string]$ComputerName
        
    )
    
    begin {

    }

    process {

        if ($PSCmdlet.ShouldProcess($ComputerName, "Creating Session for Exchange access")) {

            $ConnectionResult = Test-Connection -ComputerName $ComputerName -Ping -Count 1 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            if ($ConnectionResult) {
                Import-Module -Name ConnectExchangeOnPrem
                Connect-ExchangeOnPrem -ComputerName $ComputerName -Credential $creds -Authentication Kerberos
            }
            else {
                Write-Warning "Unable to connect to $ComputerName."
            }
            Write-Verbose "Exchange Session connected to : $ComputerName."
        }

    }
    
    end {

    }

}
