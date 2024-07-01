function Set-O365MailboxPermissions {
    <#
    .SYNOPSIS
        Sets or removes permissions for a user on an Office 365 mailbox.

    .DESCRIPTION
        This function allows you to set or remove various permissions for a user on an Office 365 mailbox. It supports setting FullAccess, SendAs, and other permissions. The function also supports updating or removing existing permissions.

    .PARAMETER Owner
        The UserPrincipalName of the mailbox owner whose mailbox you want to query. This parameter can be piped.

    .PARAMETER User
        The UserPrincipalName of the user who will be granted access to the mailbox. This parameter can be piped.

    .PARAMETER AccessLevel
        The access level to grant to the user. Valid values are FullAccess, SendAs, ExternalAccount, DeleteItem, ReadPermission, ChangePermission, ChangeOwner. This parameter can be piped.

    .PARAMETER Update
        Update the permissions for the user named in User. If this parameter is not used, the permissions for the user named in User will be added.

    .PARAMETER Remove
        Remove the permissions for the user named in User. If this parameter is used, the permissions for the user named in User will be removed.

    .EXAMPLE
        Set-O365MailboxPermissions -Owner 'owner@domain.com' -User 'user@domain.com' -AccessLevel FullAccess -Verbose
        This example grants FullAccess permission to 'user@domain.com' on the mailbox owned by 'owner@domain.com'.

    .EXAMPLE
        Set-O365MailboxPermissions -Owner 'owner@domain.com' -User 'user@domain.com' -AccessLevel SendAs -Remove -Verbose
        This example removes the SendAs permission for 'user@domain.com' on the mailbox owned by 'owner@domain.com'.

    .NOTES
        Author: [Your Name]
        Last Edit: 2024-06-30

    .LINK
        http://scripts.lukeleigh.com/
    #>

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
        Write-Verbose "Starting Set-O365MailboxPermissions function"
    }

    process {
        if ($PSCmdlet.ShouldProcess("$Owner", "Set permissions for $User to $AccessLevel")) {

            if ($Remove -eq $true) {
                Write-Verbose "Removing $AccessLevel permissions for $User on $Owner's mailbox"
                Remove-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel -Confirm:$false
                Write-Verbose "Removed $AccessLevel permissions for $User on $Owner's mailbox"
                return
            }

            if ($Update -eq $true) {
                Write-Verbose "Updating $AccessLevel permissions for $User on $Owner's mailbox"
                Add-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel -Confirm:$false
                Write-Verbose "Updated $AccessLevel permissions for $User on $Owner's mailbox"
                return
            }

            Write-Verbose "Adding $AccessLevel permissions for $User on $Owner's mailbox"
            Add-MailboxPermission -Identity $Owner -User $User -AccessRights $AccessLevel -Confirm:$false
            Write-Verbose "Added $AccessLevel permissions for $User on $Owner's mailbox"
        }
    }

    end {
        Write-Verbose "Ending Set-O365MailboxPermissions function"
    }
}

# Example usage:
# Import-Csv -Path 'path_to_your_csv_file.csv' | Set-O365MailboxPermissions -Verbose
