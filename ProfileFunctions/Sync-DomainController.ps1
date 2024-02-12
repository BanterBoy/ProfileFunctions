<#
.SYNOPSIS
    Synchronizes a domain controller with the Active Directory domain.

.DESCRIPTION
    The Sync-DomainController function synchronizes a domain controller with the Active Directory domain. It can be used to force synchronization on a specific domain controller or multiple domain controllers.

.PARAMETER Domain
    Specifies the domain to sync. If not provided, the current user's domain will be used.

.PARAMETER ComputerName
    Specifies the name of the domain controller(s) to sync. If not provided, the infrastructure master domain controller will be used.

.PARAMETER Credential
    Specifies the credentials to use for the remote session. If not provided, the session will be created without credentials.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.String. Returns the name of the domain controller(s) that were synchronized.

.EXAMPLE
    Sync-DomainController -Domain "contoso.com" -ComputerName "DC1", "DC2" -Credential $cred

    This example synchronizes the domain controllers "DC1" and "DC2" in the "contoso.com" domain using the specified credentials.

.LINK
    http://scripts.lukeleigh.com/

#>
function Sync-DomainController {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        HelpUri = 'http://scripts.lukeleigh.com/',
        PositionalBinding = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param(
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 0,
            HelpMessage = 'Enter the domain you would like to sync.')]
        [string] $Domain = $Env:USERDNSDOMAIN,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 1,
            HelpMessage = 'Enter the name of the domain controller you would like to sync.')]
        [Alias('cn')]
        [string[]]$ComputerName = (Get-ADDomain).InfrastructureMaster,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            Position = 2,
            HelpMessage = 'Enter the credentials you would like to use for the remote session.')]
        [System.Management.Automation.PSCredential]$Credential
    )
    begin {
        Write-Verbose -Message "Starting Sync-DomainController" -Verbose
        $DistinguishedName = (Get-ADDomain -Server $Domain).DistinguishedName
        (Get-ADDomainController -Filter * -Server $Domain).Name | ForEach-Object {
            Write-Verbose -Message "Sync-DomainController - Forcing synchronization $_" -Verbose
        }
        $scriptBlock = {
            param($DC, $DN)
            Write-Verbose -Message "Running repadmin /syncall $DC $DN /e /A" -Verbose
            repadmin /syncall $DC $DN /e /A | Out-Null
        }
    }
    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose -Message "Processing computer: $Computer" -Verbose
                if ($Credential) {
                    Write-Verbose -Message "Creating new session with credentials" -Verbose
                    $session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                    Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $_, $DistinguishedName
                    Remove-PSSession -Session $session
                }
                else {
                    Write-Verbose -Message "Creating new session without credentials" -Verbose
                    $session = New-PSSession -ComputerName $ComputerName
                    Invoke-Command -Session $session -ScriptBlock $scriptBlock -ArgumentList $_, $DistinguishedName
                    Remove-PSSession -Session $session
                }
            }
            catch {
                Write-Output "An error occurred: $_"
            }
        }
    }
    end {
        Write-Verbose -Message "Ending Sync-DomainController" -Verbose
    }
}
