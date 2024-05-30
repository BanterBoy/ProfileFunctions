function Find-UnusedUserAccounts {

    <#
    .SYNOPSIS
    Finds unused user accounts in Active Directory.

    .DESCRIPTION
    The Find-UnusedUserAccounts function is used to find unused user accounts in Active Directory. It retrieves user accounts that meet certain conditions, such as disabled accounts, expired passwords, and accounts that have not been logged into for a specified period of time.

    .EXAMPLE
    $unused_accounts = Find-UnusedUserAccounts
    $unused_accounts | Where-Object { $_.Enabled -eq $false } | Select-Object Username, FirstName, LastName, DistinguishedName, PasswordLastSet, PasswordNeverExpires, PasswordExpired, PasswordAge, LastLogonDate, LastLogonAge, AccountExpirationDate, AccountCreated, AccountModified, EmailAddress, PhoneNumber

    .PARAMETER RemoveUsersFound
    Specifies whether to remove the found unused user accounts. By default, it is set to $false.

    .NOTES
    This function requires the Active Directory module to be installed.

    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$RemoveUsersFound = $false
    )

    $today_object = Get-Date
    
    $unused_conditions_met = {
        (!$_.Enabled -or
        $_.PasswordExpired -or
        (!$_.LastLogonDate -or
        ($_.LastLogonDate.AddDays(60) -lt $today_object)))
    }

    $unused_accounts = Get-ADUser -Filter * -Properties DistinguishedName, samAccountName, givenName, surName, Enabled, PasswordExpired, LastLogonDate, PasswordLastSet, PasswordNeverExpires, AccountExpirationDate, Created, Modified, isCriticalSystemobject, EmailAddress, telephoneNumber, MobilePhone, UserPrincipalName, proxyAddresses |
    Where-Object $unused_conditions_met |
    Select-Object @{Name = 'Username'; Expression = { $_.samAccountName } },
    @{Name = 'FirstName'; Expression = { $_.givenName } },
    @{Name = 'LastName'; Expression = { $_.surName } },
    @{Name = 'DistinguishedName'; Expression = { $_.DistinguishedName } },
    @{Name = 'Enabled'; Expression = { $_.Enabled } },
    @{Name = 'PasswordExpired'; Expression = { $_.PasswordExpired } },
    @{Name = 'PasswordAge'; Expression = { if (!$_.PasswordLastSet) { 'Never' } else { ($today_object - $_.PasswordLastSet).Days } } },
    @{Name = 'PasswordLastSet'; Expression = { $_.PasswordLastSet } },
    @{Name = 'PasswordNeverExpires'; Expression = { $_.PasswordNeverExpires } },
    @{Name = 'LastLogonAge'; Expression = { if (!$_.LastLogonDate) { 'Never' } else { ($today_object - $_.LastLogonDate).Days } } },
    @{Name = 'LastLogonDate'; Expression = { $_.LastLogonDate } },
    @{Name = 'AccountExpirationDate'; Expression = { $_.AccountExpirationDate } },
    @{Name = 'AccountCreated'; Expression = { $_.Created } },
    @{Name = 'AccountModified'; Expression = { $_.Modified } },
    @{Name = 'EmailAddress'; Expression = { $_.EmailAddress } },
    @{Name = 'UserPrincipalName'; Expression = { $_.UserPrincipalName } },
    @{Name = 'PhoneNumber'; Expression = { $_.telephoneNumber } },
    @{Name = 'Mobile'; Expression = { $_.MobilePhone } }
    @{Name = 'proxyAddresses'; Expression = { $_.proxyAddresses } }
    

    if ($RemoveUsersFound) {
        foreach ($account in $unused_accounts) {
            if ($PSCmdlet.ShouldProcess("Removing user $($account.Username)")) {
                Remove-ADUser $account.Username -Confirm:$false
            }
        }
    }

    return $unused_accounts
}
