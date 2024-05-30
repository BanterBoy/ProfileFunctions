<#
.SYNOPSIS
Searches Active Directory for a user by LoginName, DisplayName, or EmailAddress and returns user properties, group membership, direct reports, and manager.

.DESCRIPTION
The Get-ADUserSearch function searches Active Directory for a user based on the provided parameters: SamAccountName, DisplayName, UserPrincipalName, or proxyAddress. It retrieves the user's properties and group membership as a PSObject.

.PARAMETER SamAccountName
Specifies the SamAccountName of the user to search for.

.PARAMETER DisplayName
Specifies the DisplayName of the user to search for.

.PARAMETER UserPrincipalName
Specifies the UserPrincipalName of the user to search for.

.PARAMETER proxyAddress
Specifies the proxyAddress of the user to search for.

.EXAMPLE
Get-ADUserSearch -SamAccountName "john.doe"
Searches Active Directory for a user with the SamAccountName "john.doe" and returns the user's properties and group membership.

.EXAMPLE
Get-ADUserSearch -DisplayName "John Doe"
Searches Active Directory for a user with the DisplayName "John Doe" and returns the user's properties and group membership.

.EXAMPLE
Get-ADUserSearch -UserPrincipalName "john.doe@example.com"
Searches Active Directory for a user with the UserPrincipalName "john.doe@example.com" and returns the user's properties and group membership.

.EXAMPLE
Get-ADUserSearch -proxyAddress "john.doe@example.com"
Searches Active Directory for a user with the proxyAddress "john.doe@example.com" and returns the user's properties and group membership.

.INPUTS
None.

.OUTPUTS
System.Management.Automation.PSObject

.NOTES
Author: Your Name
Date: Today's Date

.LINK
https://link-to-your-documentation

#>

function Get-ADUserSearch {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $false)]
        [String]
        $SamAccountName,
        [Parameter(Mandatory = $false)]
        [String]
        $DisplayName,
        [Parameter(Mandatory = $false)]
        [String]
        $UserPrincipalName,
        [Parameter(Mandatory = $false)]
        [string]$proxyAddress
    )
    BEGIN { }

    PROCESS {
        $user = $null
        if ($SamAccountName) {
            $user = Get-ADUser -Filter { SamAccountName -like $SamAccountName } -Properties *
        }
        elseif ($DisplayName) {
            $user = Get-ADUser -Filter { DisplayName -like $DisplayName } -Properties *
        }
        elseif ($UserPrincipalName) {
            $user = Get-ADUser -Filter { UserPrincipalName -like $UserPrincipalName } -Properties *
        }
        elseif ($proxyAddress) {
            $proxyAddress = "*" + $proxyAddress + "*"
            $user = Get-ADUser -Filter { proxyaddresses -like $proxyAddress } -Properties *
        }

        if ($user) {
            $managerDisplayNames = if ($user.Manager) {
                $user.Manager | Where-Object { $_ } | ForEach-Object {
                    (Get-ADUser -Identity $_ -Properties DisplayName).DisplayName
                }
            }
            $directReportsDisplayNames = if ($user.directReports) {
                $user.directReports | ForEach-Object {
                    (Get-ADUser -Identity $_ -Properties DisplayName).DisplayName
                }
            }
            $memberOfGroupNames = if ($user.MemberOf) {
                $user.MemberOf | ForEach-Object {
                    (Get-ADGroup -Identity $_).Name
                }
            }
            $user | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, @{Name = 'Manager'; Expression = { $managerDisplayNames } }, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, @{Name = 'directReports'; Expression = { $directReportsDisplayNames } }, @{Name = 'MemberOf'; Expression = { $memberOfGroupNames } }
        }
    }
}