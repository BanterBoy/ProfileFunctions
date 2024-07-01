<#
.SYNOPSIS
    Unlock AD User Accounts for users who are currently locked out.

.DESCRIPTION
    This function gathers user account information from Active Directory and compiles a list of user accounts
    that are currently locked due to incorrect passwords being entered. When running the function, it searches
    all AD User accounts from AD looking for those that are locked out. It then produces an alphabetical list 
    output in Grid-View with the user details "Name,SamAccountName,LastLogonDate,UserPrincipalName,LockedOut".
    You can then select the User/s accounts and click OK to unlock them.

.EXAMPLE
    PS C:\> Unlock-UserAccount -Verbose
    Searches for locked-out user accounts in Active Directory and unlocks the selected accounts.

.NOTES
    The user account running this function needs to have 'Domain Admin Privileges' in order to unlock the account.
#>

function Unlock-UserAccount {
    [CmdletBinding()]
    param ()

    BEGIN {
        Write-Verbose "Starting the Unlock-UserAccount function."
    }

    PROCESS {
        Write-Verbose "Searching for locked-out user accounts in Active Directory."

        try {
            # Search for locked-out accounts
            $lockedOutAccounts = Search-ADAccount -LockedOut

            if ($lockedOutAccounts.Count -eq 0) {
                Write-Verbose "No locked-out accounts found."
                return
            }

            Write-Verbose "Found $($lockedOutAccounts.Count) locked-out accounts. Preparing to display in GridView."

            # Select necessary properties and sort by name
            $selectedAccounts = $lockedOutAccounts |
            Select-Object Name, SamAccountName, LastLogonDate, UserPrincipalName, LockedOut |
            Sort-Object Name |
            Out-GridView -PassThru

            if ($selectedAccounts.Count -eq 0) {
                Write-Verbose "No accounts selected for unlocking."
                return
            }

            Write-Verbose "Selected $($selectedAccounts.Count) accounts for unlocking."

            # Unlock selected accounts
            foreach ($account in $selectedAccounts) {
                Write-Verbose "Unlocking account: $($account.SamAccountName)"
                try {
                    Unlock-ADAccount -Identity $account.DistinguishedName -ErrorAction Stop
                    Write-Verbose "Successfully unlocked account: $($account.SamAccountName)"
                }
                catch {
                    Write-Error "Failed to unlock account: $($account.SamAccountName). Error: $_"
                }
            }
        }
        catch {
            Write-Error "An error occurred while searching for locked-out accounts: $_"
        }
    }

    END {
        Write-Verbose "Unlock-UserAccount function completed."
    }
}

# Example call to the function with verbose output
# Unlock-UserAccount -Verbose
