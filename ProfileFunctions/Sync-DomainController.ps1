<#
.SYNOPSIS
    Synchronizes a domain controller with the Active Directory domain.

.DESCRIPTION
    The Sync-DomainController function synchronizes a domain controller with the Active Directory domain. 
    It can be used to force synchronization on a specific domain controller or multiple domain controllers.

.PARAMETER Domain
    Specifies the domain to sync. If not provided, the current user's domain will be used.

.PARAMETER ComputerName
    Specifies the name of the domain controller(s) to sync. If not provided, all domain controllers in the specified domain will be used.

.PARAMETER Credential
    Specifies the credentials to use for the remote session. If not provided, the session will be created without credentials.

.INPUTS
    System.String. You can pipe strings representing domain controller names to this function.

.OUTPUTS
    System.String. Returns the name of the domain controller(s) that were synchronized.

.EXAMPLE
    Sync-DomainController -Domain "contoso.com" -ComputerName "DC1", "DC2" -Credential $cred

    This example synchronizes the domain controllers "DC1" and "DC2" in the "contoso.com" domain using the specified credentials.

.EXAMPLE
    Sync-DomainController

    This example synchronizes all domain controllers in the current user's domain.

.EXAMPLE
    "DC1", "DC2" | Sync-DomainController -Domain "contoso.com"

    This example synchronizes the domain controllers "DC1" and "DC2" in the "contoso.com" domain using piped input.
    
.LINK
    http://scripts.lukeleigh.com/
#>
function Sync-DomainController {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        HelpUri = 'http://scripts.lukeleigh.com/',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'Enter the domain you would like to sync.')]
        [string] $Domain = $Env:USERDNSDOMAIN,
        
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            HelpMessage = 'Enter the name of the domain controller you would like to sync.')]
        [Alias('cn')]
        [ArgumentCompleter({
                $dCList = (Get-ADForest).Domains | ForEach-Object { Get-ADDomainController -Filter * -Server $_ } | Select-Object -ExpandProperty Name
                $dCList
            })]
        [string[]] $ComputerName,
        
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            Position = 2,
            HelpMessage = 'Enter the credentials you would like to use for the remote session.')]
        [System.Management.Automation.PSCredential] $Credential
    )
    begin {
        Write-Verbose -Message "Starting Sync-DomainController"
        
        # Get all domain controllers if none are specified
        if (-not $ComputerName) {
            Write-Verbose -Message "No specific domain controllers provided. Retrieving all domain controllers in the domain $Domain."
            $ComputerName = (Get-ADDomainController -Filter * -Server $Domain).Name
        }

        # Log the retrieved domain controllers
        Write-Verbose -Message "Domain controllers retrieved: $($ComputerName -join ', ')"

        # Define the distinguished name of the domain
        $DistinguishedName = (Get-ADDomain -Server $Domain).DistinguishedName

        # Define the script block to be executed on the remote domain controllers
        $scriptBlock = {
            param($DC, $DN)
            Write-Verbose -Message "Running repadmin /syncall $DC $DN /e /A"
            repadmin /syncall $DC $DN /e /A | Out-Null
        }
    }
    process {
        if ($null -eq $ComputerName) {
            $ComputerName = $_
        }
        
        $total = $ComputerName.Count
        $count = 0

        foreach ($Computer in $ComputerName) {
            $count++
            $percentComplete = ($count / $total) * 100
            Write-Progress -Activity "Syncing Domain Controllers" -Status "Processing $Computer ($count of $total)" -PercentComplete $percentComplete
            try {
                # Create a new PowerShell session on the remote computer
                if ($Credential) {
                    $session = New-PSSession -ComputerName $Computer -Credential $Credential
                }
                else {
                    $session = New-PSSession -ComputerName $Computer
                }

                # Invoke the script block on the remote session
                Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $Computer, $DistinguishedName

                # Remove the remote session
                Remove-PSSession -Session $session
                Write-Output "Synchronized $Computer successfully."
            }
            catch {
                Write-Output "An error occurred while processing $($Computer): $_"
            }
        }
    }
    end {
        Write-Progress -Activity "Syncing Domain Controllers" -Completed
        Write-Verbose -Message "Ending Sync-DomainController"
    }
}

# Example of how to call the function with enhanced logging
# $creds = Get-Credential
# Sync-DomainController -Domain $env:USERDNSDOMAIN -ComputerName "KAMINO", "TATOOINE" -Credential $creds -Verbose
