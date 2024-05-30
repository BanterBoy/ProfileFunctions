<#

GitHub Copilot: The code is a PowerShell script that defines a function called `Get-GroupMembers`. This function exports the users within Active Directory groups that match a specified search string. 

The function takes a single parameter called `GroupName`, which is used to specify the name of the group to search for. This parameter supports wildcards, allowing for more flexible search criteria. 

The function uses the `Get-ADGroup` cmdlet to retrieve a collection of groups that match the search string. It then uses a `ForEach-Object` loop to iterate over each group and retrieve its members using the `Get-ADGroupMember` cmdlet. 

For each group member, the function uses the `Get-ADUser` cmdlet to retrieve detailed information about the user, including all available properties. The resulting user objects are output as a collection of `Object` objects.

Overall, this script is a useful tool for extracting information about users in Active Directory groups. It uses the `Get-ADGroup`, `Get-ADGroupMember`, and `Get-ADUser` cmdlets to perform the search and retrieve detailed information about each user. 

To improve the readability of the code, the author could consider adding comments to explain the purpose of each section of the script. Additionally, they could use more descriptive variable names to make the code easier to understand. Finally, they could consider adding error handling to the script to handle cases where the search fails or returns unexpected results.

#>

<#
.SYNOPSIS
    Get-GroupMembers

.DESCRIPTION
    This function exports the users within Active Directory groups that match a specified search string.

.PARAMETER GroupName
    Specifies the name of the group to search for. This parameter supports wildcards.

.EXAMPLE
    Get-GroupMembers -GroupName "Domain Admins"
    Outputs a list of users in the Active Directory groups matching the search string.

.OUTPUTS
    [Object]

.NOTES
    Author: Luke Leigh
    Date: 05/07/2023
    Version: 0001
    Changelog:
        - initial version

.INPUTS
    [string]GroupName
#>
function Get-GroupMembers {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        PositionalBinding = $true,
        SupportsShouldProcess = $true)]
    [OutputType([string], ParameterSetName = 'Default')]
    [Alias('ggm')]
    param
    (
        [Parameter(ParameterSetName = 'Default',
            Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 1,
            HelpMessage = 'Enter the group name that you want to search for. This field supports wildcards.')]
        [Alias('gn')]
        [String]$GroupName
    )

    begin {

    }

    process {
        if ($PSCmdlet.ShouldProcess("$GroupName", "Extract members of group")) {
            $groups = Get-ADGroup -Filter ' Name -like $GroupName '
            $groups | ForEach-Object -Process {
                $groupMembers = Get-ADGroupMember -Identity $_.SamAccountName
                $groupMembers |
                ForEach-Object -Process {
                    Get-ADUser -Filter ' SamAccountName -like $_.SamAccountName ' -Properties *
                }
            }
        }
    }
    end {

    }
}
