<#
.SYNOPSIS
Retrieves the fully qualified domain name (FQDN) of an Organizational Unit (OU) in Active Directory.

.DESCRIPTION
The Get-OUfqdn function retrieves the FQDN of an OU in Active Directory. It accepts an OU name as input and returns the FQDN of the matching OU.

.PARAMETER SelectOU
Specifies the name of the OU to retrieve the FQDN for. This parameter is mandatory and can be provided through the pipeline or by property name.

.INPUTS
[System.String]
Accepts a string representing the name of the OU.

.OUTPUTS
[System.String]
Returns a string representing the FQDN of the OU.

.EXAMPLE
PS C:\> Get-OUfqdn -SelectOU "Sales"
Returns the FQDN of the "Sales" OU in Active Directory.

.EXAMPLE
PS C:\> "Sales" | Get-OUfqdn
Returns the FQDN of the "Sales" OU in Active Directory.

#>
function Get-OUfqdn {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ParameterSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [OutputType([string])]
        [ArgumentCompleter( {
                $baseOU = (Get-ADDomain).DistinguishedName
                $OUs = Get-ADOrganizationalUnit -Filter * -SearchScope SubTree -SearchBase $baseOU | Sort-Object -Property DistinguishedName
                foreach ($OU in $OUs) { 
                    ($OU).DistinguishedName
                }
            } ) ]
        [string]
        $SelectOU
    )
}
