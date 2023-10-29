# a function to list all admin accounts in active directory
# Usage: Get-AdminAccounts
# parameters:
# Domain: the domain to query, defaults to current domain
# Output: the output file to write to, defaults to screen
# output should be a psobject containing the following properties:
# Name: the name of the admin account
# Description: the description of the admin account
# Enabled: whether the account is enabled or not
# PasswordNeverExpires: whether the password for the account expires or not
# PasswordLastSet: when the password was last set
# PasswordExpires: when the password expires
# PasswordAge: how old the password is
# Groups: the groups the account is a member of

function Get-AdminAccounts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Domain = $env:USERDOMAIN,
        [Parameter(Mandatory = $false)]
        [string]$Output = $null
    )

    begin {
        Import-Module ActiveDirectory
    }

    $AdminAccounts = @()
    $SearchBase = "OU=AdminAccounts,DC=example,DC=com"
    $AdminAccounts += Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false -and PasswordLastSet -gt 0 } -Properties PasswordLastSet, PasswordNeverExpires, Enabled, Description, PasswordExpired, PasswordNeverExpires, PasswordLastSet, PasswordExpires, PasswordAge, MemberOf -Server $Domain -SearchBase $SearchBase | Select-Object Name, Description, Enabled, PasswordNeverExpires, PasswordLastSet, PasswordExpires, PasswordAge, @{Name = "Groups"; Expression = { $_.MemberOf -join ';' } }
    $AdminAccounts += Get-ADUser -Filter { Enabled -eq $true -and PasswordNeverExpires -eq $false -and PasswordLastSet -gt 0 } -Properties PasswordLastSet, PasswordNeverExpires, Enabled, Description, PasswordExpired, PasswordNeverExpires, PasswordLastSet, PasswordExpires, PasswordAge, MemberOf -Server $Domain -SearchBase $SearchBase -SearchScope OneLevel | Select-Object Name, Description, Enabled, PasswordNeverExpires, PasswordLastSet, PasswordExpires, PasswordAge, @{Name = "Groups"; Expression = { $_.MemberOf -join ';' } }
    if ($Output) {
        $AdminAccounts | Export-Csv -Path $Output -NoTypeInformation
    }
    else {
        $AdminAccounts
    }
}
