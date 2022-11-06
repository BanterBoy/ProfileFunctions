Function Copy-GroupMembership {

    <#
    .SYNOPSIS
        Copy Group Membership from an existing Active Directory User to another Active Directory User
    .DESCRIPTION
        This function will copy a users Active Directory Group Membership to another Active Directory User by querying a users current membership and adding the same groups to another user.
    .EXAMPLE
        PS C:\> Copy-GroupMembership -SourceUser SAMACCOUNTNAME -DestinationUser SAMACCOUNTNAME
        Copies all group membership from one Active Directory User and replicates on another Active Directory User
    .INPUTS
        Active Directory SamAccountName
    .OUTPUTS
        Outputs a list of Active Directory Groups the Active Directory User has been added to.
    .NOTES
        General notes
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
        $DestinationUser
    )

    begin {
    }

    process {
        if ($PSCmdlet.ShouldProcess("$DestinationUser", "Copy User $SourceUser Group Memberships")) {
            $GroupMembership = Get-ADUser -Identity $SourceUser -Properties memberof
            foreach ($Group in $GroupMembership.memberof) {
                if ($Group -notcontains $Group.SamAccountName) {
                    try {
                        Add-ADGroupMember -Identity $Group $DestinationUser -ErrorAction SilentlyContinue
                    }
                    catch {
                        Write-Error -Message $_
                    }
                    finally {
                        Write-Output $Group
                    }
                } 
            }
        }
    }
    
    end {
    }
    
}
 