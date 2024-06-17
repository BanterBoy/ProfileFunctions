function Get-OUDelegations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, 
            Position = 0, 
            HelpMessage = "Filter OUs by name.")]
        [string]$OUFilter = "*",

        [Parameter(Mandatory = $false, 
            Position = 1, 
            HelpMessage = "Filter by specific Active Directory rights.")]
        [ValidateSet("GenericAll", "GenericRead", "GenericWrite", "CreateChild", "DeleteChild", "ListChildren", 
            "Self", "ReadProperty", "WriteProperty", "DeleteTree", "ListObject", 
            "ExtendedRight", "Delete", "ReadControl", "WriteDacl", "WriteOwner")]
        [string[]]$RightsFilter,

        [Parameter(Mandatory = $false, 
            Position = 2, 
            HelpMessage = "Enable verbose output.")]
        [switch]$VerboseOutput
    )

    # Initialize result array
    $Result = @()

    # Get all OUs in the domain matching the filter
    if ($VerboseOutput) {
        Write-Verbose "Fetching OUs with filter: $OUFilter"
    }
    $OUs = Get-ADOrganizationalUnit -Filter ("Name -like '{0}'" -f [System.Management.Automation.WildcardPattern]::Escape($OUFilter))

    # Process each OU
    ForEach ($OU In $OUs) {
        $Path = "AD:\" + $OU.DistinguishedName
        $ACLs = (Get-Acl -Path $Path).Access

        # Process each ACL
        ForEach ($ACL in $ACLs) {
            If ($ACL.IsInherited -eq $False) {
                $Rights = $ACL.ActiveDirectoryRights.ToString().Split(", ")
                if (-not $RightsFilter -or ($RightsFilter | ForEach-Object { $_ -in $Rights })) {
                    # Create custom PSObject
                    $IdentityReference = try {
                        (New-Object System.Security.Principal.SecurityIdentifier($ACL.IdentityReference.Value)).Translate([System.Security.Principal.NTAccount]).Value
                    }
                    catch {
                        $ACL.IdentityReference.Value
                    }

                    $Delegation = [PSCustomObject]@{
                        OU                    = $OU.DistinguishedName
                        IdentityReference     = $IdentityReference
                        ActiveDirectoryRights = $ACL.ActiveDirectoryRights
                        AccessControlType     = $ACL.AccessControlType
                    }
                    $Result += $Delegation
                }
            }
        }

        if ($VerboseOutput) {
            Write-Verbose "Processed OU: $($OU.DistinguishedName)"
        }
    }

    # Return results as PSObjects
    return $Result
}

# # Example usage
# $delegations = Get-OUDelegations -OUFilter "Sales*" -VerboseOutput
# $delegations | Format-Table -AutoSize
