<#
    .SYNOPSIS
        Compares the group membership of two Active Directory users.
    
    .DESCRIPTION
        The Compare-GroupMembership function compares the group membership of two Active Directory users and returns a list of all the groups that either user is a member of, along with a Boolean value indicating whether each user is a member of each group.
        This function is useful for identifying differences and similarities in group memberships between two users, which can be helpful for troubleshooting permissions issues or preparing for user role changes.
    
    .PARAMETER SourceUser
        The username (sAMAccountName) of the source user to compare. This parameter is mandatory.
    
    .PARAMETER DestinationUser
        The username (sAMAccountName) of the destination user to compare. This parameter is mandatory.
    
    .EXAMPLE
        Compare-GroupMembership -SourceUser "jdoe" -DestinationUser "asmith"
    
        This example compares the group membership of the "jdoe" and "asmith" users and returns a list of groups with membership status for each user.
    
    .EXAMPLE
        $comparison = Compare-GroupMembership -SourceUser "jdoe" -DestinationUser "asmith"
        $comparison | Format-Table -AutoSize
    
        This example stores the comparison result in the $comparison variable and then formats the output as a table for better readability.
    
    .EXAMPLE
        Compare-GroupMembership -SourceUser "jdoe" -DestinationUser "asmith" | Export-Csv -Path "C:\GroupComparison.csv" -NoTypeInformation
    
        This example compares the group membership of the "jdoe" and "asmith" users and exports the result to a CSV file.
    
    .NOTES
        Author: John Doe
        Date:   01/01/2022
        Version: 1.0
        Requires: ActiveDirectory module
    
    .OUTPUTS
        PSCustomObject
            An object representing each group with the following properties:
            - GroupName: The name of the group.
            - DistinguishedName: The distinguished name of the group.
            - <SourceUser>: Boolean indicating if the source user is a member of the group.
            - <DestinationUser>: Boolean indicating if the destination user is a member of the group.
    
    .REMARKS
        Ensure that the ActiveDirectory module is imported and that you have the necessary permissions to query Active Directory.
#>

Function Compare-GroupMembership {

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
