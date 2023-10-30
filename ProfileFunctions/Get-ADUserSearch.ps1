# The function will search AD for a user by LoginName, DisplayName or EmailAddress
# The function will return the user properties SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
# The function will also return the user's group membership
# The function will also return the user's direct reports
# The function will also return the user's manager
# The function will have the parameter -SamAccountName, -DisplayName and -EmailAddress
# it will also have the parameter -Verbose
# the function will return the user's properties and group membership as a PSObject

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