<#
.SYNOPSIS
Disables inactive computers in Active Directory.

.DESCRIPTION
The Disable-InactiveComputer function disables inactive computers in Active Directory based on the specified criteria.

.PARAMETER DaysAgo
Specifies the number of days ago from the current date to consider a computer as inactive. The default value is 90 days.

.PARAMETER DisabledAccountsOU
Specifies the Organizational Unit (OU) where disabled computer accounts will be moved. The default value is "OU=DisabledAccounts," followed by the distinguished name of the current domain.

.PARAMETER SearchBase
Specifies the search base for finding inactive computer accounts. The default value is the distinguished name of the current domain.

.EXAMPLE
Disable-InactiveComputer -DaysAgo 60 -DisabledAccountsOU "OU=InactiveComputers,DC=contoso,DC=com" -SearchBase "DC=contoso,DC=com"
Disables inactive computers that have not been used for the past 60 days. The disabled computer accounts will be moved to the "OU=InactiveComputers,DC=contoso,DC=com" OU.

.NOTES
This function requires the Active Directory module to be installed. You can install it by running the following command:
Install-WindowsFeature RSAT-AD-PowerShell
#>

Function Disable-InactiveComputer {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the number of days ago to consider a computer as inactive.')]
        [string]$DaysAgo = 90,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Specify the OU where disabled computer accounts will be moved.')]
        [string]$DisabledAccountsOU = "OU=DisabledAccounts," + (Get-ADDomain).DistinguishedName,
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Specify the search base for finding inactive computer accounts.')]
        [string]$SearchBase = (Get-ADDomain).DistinguishedName
    )
    begin {
    }
    process {
        if ($PSCmdlet.ShouldProcess("$SearchBase", "Disabling Inactive Computers...")) {
            $Date = (Get-Date).AddDays(-$daysAgo)
            $InactiveComputers = Search-ADAccount -AccountInactive -ComputersOnly -SearchBase $SearchBase
            foreach ($Computer in $InactiveComputers) {
                try {
                    if ( $Computer.PasswordLastSet -lt $Date ) {
                        Write-Verbose "Disabling $($Computer.Name)"
                        Set-ADComputer -Identity $Computer.DistinguishedName -Enabled:$false -WhatIf
                        Write-Verbose "Moving $($Computer.Name) to $($DisabledAccountsOU)"
                        Move-ADObject -Identity $Computer.Name -TargetPath $DisabledAccountsOU -Confirm:$false -ErrorAction Continue -WhatIf
                    }
                    else {
                        Write-Verbose "Computer $($Computer.Name) is active"
                    }
                }
                catch {
                    Write-Error "Error disabling $($Computer.Name)"
                }
    
            }
        }
    }
    end {
    }
}
