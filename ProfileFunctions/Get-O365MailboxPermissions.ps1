<#
.SYNOPSIS
    Retrieves mailbox permissions for Office 365 mailboxes.

.DESCRIPTION
    The Get-O365MailboxPermissions function retrieves mailbox permissions for Office 365 mailboxes. It queries the mailbox permissions for the specified mailbox owners and returns the relevant information.

.PARAMETER UserPrincipalName
    Specifies the UserPrincipalName for the mailbox owner whose mailbox permissions you want to query. This parameter can accept multiple values and can be piped. If not specified, the function will retrieve mailbox permissions for all mailbox owners.

.INPUTS
    None. You cannot pipe objects to this function.

.OUTPUTS
    System.String
    The function returns a string containing the mailbox permissions information.

.EXAMPLE
    Get-O365MailboxPermissions -UserPrincipalName user1@contoso.com
    Retrieves mailbox permissions for the mailbox owner with the UserPrincipalName 'user1@contoso.com'.

.EXAMPLE
    'user1@contoso.com', 'user2@contoso.com' | Get-O365MailboxPermissions
    Retrieves mailbox permissions for the mailbox owners with the UserPrincipalNames 'user1@contoso.com' and 'user2@contoso.com'.

.NOTES
    Author: Your Name
    Date:   Current Date
#>
function Get-O365MailboxPermissions {

    [CmdletBinding(DefaultParameterSetName = 'Default',
        ConfirmImpact = 'Medium',
        SupportsShouldProcess = $true,
        HelpUri = 'http://scripts.lukeleigh.com/')]
    [OutputType([string], ParameterSetName = 'Default')]

    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the UserPrincipalName for the mailbox owner whose mailbox you want to query. This parameter can be piped.')]
        [ValidateNotNullOrEmpty()]
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
                            'MailboxOwner'      = $Permission.Identity -split ':' | Select-Object -First 1
                            'UserPrincipalName' = $User
                            'UserType'          = $Permission.User.UserType
                            'PermissionType'    = 'Mailbox'
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