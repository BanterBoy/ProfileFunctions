Function Disable-InactiveComputer {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the...')]
        [string]$DaysAgo = 90
    )
    $Date = (Get-Date).AddDays(-$daysAgo)

    $TargetOU = "OU=DisabledAccounts,DC=domain,DC=leigh-services,DC=com"
    $InactiveComputers = Search-ADAccount -AccountInactive -ComputersOnly -SearchBase "DC=domain,DC=leigh-services,DC=com"
    foreach ($Computer in $InactiveComputers) {
        if ($PSCmdlet.ShouldProcess("$($Computer)", "Disabling inactive Computer")) {
            try {
                if ( $Computer.PasswordLastSet -lt $Date ) {
                    Write-Output "Disabling $($Computer.Name)"
                    Set-ADComputer -Identity $Computer.DistinguishedName -Enabled:$false
                    Write-Output "Moving $($Computer.Name) to $($TargetOU)"
                    Move-ADObject -Identity $Computer.Name -TargetPath $TargetOU -Confirm:$false -ErrorAction Continue
                }
                else {
                    Write-Output "Computer $($Computer.Name) is active"
                }
            }
            catch {
                Write-Error "Error disabling $($Computer.Name)"
            }

        }
    }
}
