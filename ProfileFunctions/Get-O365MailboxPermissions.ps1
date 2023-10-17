function Get-O365MailboxPermissions {

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')]
    [OutputType([string], ParameterSetName = 'Default')]
    [Alias('gmp')]

    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the UserPrincipalName for the mailbox owner whose mailbox you want to query. This parameter can be piped.')]
        [ValidateNotNullOrEmpty()]
        [Alias('upn')]
        [string[]]$UserPrincipalName
    )

    begin {
    }

    process {

        if ($PSCmdlet.ShouldProcess("$UserPrincipalName", "Querying mailbox permissions for")) {
            
            foreach ($User in $UserPrincipalName) {
            
                $Permissions = Get-MailboxPermission -Identity $User | Where-Object { $_.IsInherited -eq $false }
                
                foreach ($Permission in $Permissions) {

                    if ($Permission.User.UserType -like 'Internal') {
                        $properties = @{
                            'UserPrincipalName' = $User
                            'User'              = $Permission.User.DisplayName
                            'AccessRights'      = $Permission.AccessRights
                        }
                        $Output = New-Object -TypeName psobject -Property $properties
                        Write-Output -InputObject $Output

                    }

                }

            }

        }

    }

    end {
        
    }

}