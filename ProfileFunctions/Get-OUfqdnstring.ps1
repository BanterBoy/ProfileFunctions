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