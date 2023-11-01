function Get-ADEmailAddress {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the AD object EmailAddress. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [Alias('mail')]
        [string[]]$EmailAddress
    )
    BEGIN { }

    PROCESS {
        if ($PSCmdlet.ShouldProcess("$($EmailAddress)", "searching AD for user details.")) {
            try {
                Get-ADObject -Filter ' mail -like "$($EmailAddress)" ' -Properties * | Select-Object -Property DistinguishedName, ObjectClass, Name, mail
            }
            catch {
                Write-Error -Message "$_"
            }
        }
    }
}

# function to search all attributes of an AD User or Contact object for an email address and return the object properties if found
