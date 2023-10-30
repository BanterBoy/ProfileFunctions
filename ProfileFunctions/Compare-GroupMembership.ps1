Function Compare-GroupMembership {
    <#
    .SYNOPSIS
        Compares the group membership of two Active Directory users.
    
    .DESCRIPTION
        The Compare-GroupMembership function compares the group membership of two Active Directory users and returns a list of all the groups that either user is a member of, along with a Boolean value indicating whether each user is a member of each group.
    
    .PARAMETER SourceUser
        The username of the source user to compare.
    
    .PARAMETER DestinationUser
        The username of the destination user to compare.
    
    .EXAMPLE
        Compare-GroupMembership -SourceUser "jdoe" -DestinationUser "asmith"
    
        This example compares the group membership of the "jdoe" and "asmith" users.
    
    .NOTES
        Author: John Doe
        Date:   01/01/2022
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string] $SourceUser,

        [Parameter(Mandatory = $true)]
        [string] $DestinationUser
    )

    Try {
        $SourceUserGroups = @(Get-ADUser -Identity $SourceUser -Properties memberof, PrimaryGroup | Select-Object -ExpandProperty memberof)
        $SourceUserPrimaryGroup = Get-ADGroup -Identity (Get-ADUser -Identity $SourceUser -Properties PrimaryGroup).PrimaryGroup
        $SourceUserGroups += $SourceUserPrimaryGroup.DistinguishedName
    } Catch {
        Write-Error "Source user $SourceUser does not exist."
        return
    }

    Try {
        $DestinationUserGroups = @(Get-ADUser -Identity $DestinationUser -Properties memberof, PrimaryGroup | Select-Object -ExpandProperty memberof)
        $DestinationUserPrimaryGroup = Get-ADGroup -Identity (Get-ADUser -Identity $DestinationUser -Properties PrimaryGroup).PrimaryGroup
        $DestinationUserGroups += $DestinationUserPrimaryGroup.DistinguishedName
    } Catch {
        Write-Error "Destination user $DestinationUser does not exist."
        return
    }

    $AllGroups = @()
    foreach ($Group in ($SourceUserGroups + $DestinationUserGroups)) {
        if ($Group -notin $AllGroups) {
            $AllGroups += $Group
        }
    }

    $GroupNames = @{}
    foreach ($Group in $AllGroups) {
        $GroupObject = Get-ADGroup -Identity $Group -ErrorAction SilentlyContinue
        if ($GroupObject) {
            $GroupNames[$Group] = $GroupObject.Name
        }
    }

    foreach ($Group in $AllGroups) {
        $GroupName = $GroupNames[$Group]
        $SourceUserMember = $SourceUserGroups -contains $Group
        $DestinationUserMember = $DestinationUserGroups -contains $Group

        $output = [ordered]@{
            'GroupName'         = $GroupName
            'DistinguishedName' = $Group
            $SourceUser         = $SourceUserMember
            $DestinationUser    = $DestinationUserMember
        }

        [PSCustomObject]$output
    }
}
