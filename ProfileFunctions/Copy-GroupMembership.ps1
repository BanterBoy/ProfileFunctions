Function Copy-GroupMembership {
    <#
    .SYNOPSIS
    Copies the group membership of one user to another user.
    
    .DESCRIPTION
    This function copies the group membership of one user to another user. It can also align the destination user's group membership with the source user's.
    
    .PARAMETER SourceUser
    The SamAccountName of the user you are copying from.
    
    .PARAMETER DestinationUser
    The SamAccountName of the user you are copying to.
    
    .PARAMETER AlignMembership
    If specified, aligns the destination user's group membership with the source user's.
    
    .EXAMPLE
    Copy-GroupMembership -SourceUser "User1" -DestinationUser "User2" -AlignMembership
    Copies the group membership of User1 to User2 and aligns User2's group membership with User1's.
    
    .NOTES
    Author: Unknown
    Date: Unknown
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (
        [Parameter( Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter the SamAccountName for the user you are copying from."
        )]
        [string]
        $SourceUser,

        [Parameter( Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Enter the SamAccountName of the user you are copying to."
        )]
        [string]
        $DestinationUser,

        [Parameter(
            HelpMessage = "Align the destination user's group membership with the source user's."
        )]
        [switch]
        $AlignMembership
    )

    process {
        if ($PSCmdlet.ShouldProcess("$DestinationUser", "Copy User $SourceUser Group Memberships")) {
            $SourceUserGroups = Get-ADUser -Identity $SourceUser -Properties memberof

            if ($AlignMembership) {
                $DestinationUserGroups = Get-ADUser -Identity $DestinationUser -Properties memberof
                foreach ($Group in $DestinationUserGroups.memberof) {
                    if ($SourceUserGroups.memberof -notcontains $Group) {
                        Remove-ADGroupMember -Identity $Group -Members $DestinationUser -Confirm:$false
                    }
                }
            }

            foreach ($Group in $SourceUserGroups.memberof) {
                Add-ADGroupMember -Identity $Group -Members $DestinationUser -ErrorAction SilentlyContinue
            }
        }
    }
}
