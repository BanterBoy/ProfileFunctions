function Set-O365MailboxPermissions {

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
        [string]$Owner,

        [Parameter(
            ParameterSetName = 'Default',    
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the UserPrincipalName for the user who will be granted access to the mailbox. This parameter can be piped.')]
        [ValidateNotNullOrEmpty()]
        [string]$User,

        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the access level to grant to the user. The access level can be FullAccess, SendAs, ExternalAccount, DeleteItem, ReadPermission, ChangePermission, ChangeOwner. This parameter can be piped.')]
        [ValidateSet('FullAccess', 'SendAs', 'ExternalAccount', 'DeleteItem', 'ReadPermission', 'ChangePermission', 'ChangeOwner')]
        [string]$AccessLevel,

        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Update the permissions for the user named in User. This parameter can be piped. If this parameter is not used, the permissions for the user named in User will be added.')]
        [bool]$Update = $false,

        [Parameter(
            ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Remove the permissions for the user named in User. This parameter can be piped. If this parameter is used, the permissions for the user named in User will be removed.')]
        [bool]$Remove = $false
    )

    begin {
    
    }

    process {

        if ($PSCmdlet.ShouldProcess("$Owner", "Set permissions for $User to $AccessLevel")) {

            if ( $Remove -eq $true ) {
                Remove-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel -Confirm:$false
                return
            }
            if ( $AccessLevel -eq 'None' ) {
                Remove-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel -Confirm:$false
                return
            }
            if ( $Update -eq $true ) {
                Add-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel
                return
            }
            if ( $Update -eq $false ) {
                Add-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel
                return
            }

        }

    }

    end {
    }
}