<#
.SYNOPSIS
    Retrieves the fully qualified domain name (FQDN) of the specified Organizational Unit (OU).

.DESCRIPTION
    The Get-OUfqdn function retrieves the FQDN of the specified OU by searching for the OU in the Active Directory domain.
    It returns the FQDN as a string.

.PARAMETER SelectOU
    Specifies the name of the OU to retrieve the FQDN for. This parameter is mandatory.
    The value can be provided through the pipeline or by property name.

.OUTPUTS
    System.String
    The function returns the FQDN of the specified OU as a string.

.EXAMPLE
    Get-OUfqdn -SelectOU "OU=Sales,OU=Departments,DC=contoso,DC=com"
    Retrieves the FQDN of the "Sales" OU in the "Departments" OU in the "contoso.com" domain.

.NOTES
    This function requires the Active Directory module to be installed.
#>
function Get-OUfqdn {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'ParameterSet1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]
        $SelectOU
    )
	
    $baseOU = (Get-ADDomain).DistinguishedName
    $OUs = Get-ADOrganizationalUnit -Filter * -SearchScope SubTree -SearchBase $baseOU | Sort-Object -Property DistinguishedName
    foreach ($OU in $OUs) {
        $OU | Select-Object -Property DistinguishedName | Where-Object { $_.DistinguishedName -like $SelectOU }
    }
	
    $obj = New-Object -TypeName PSObject -Property $SelectOU
    Write-Output $obj
}