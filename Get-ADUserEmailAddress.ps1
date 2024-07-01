<#
.SYNOPSIS
Searches all attributes of an Active Directory (AD) User or Contact object for an email address and returns the object properties if found.

.DESCRIPTION
This function allows you to search for an email address or a SamAccountName in Active Directory. It accepts pipeline input and supports wildcards for both parameters. If a match is found, it returns the object properties of the matched user or contact.

.PARAMETER SamAccountName
Specifies the SamAccountName of the AD object to search for. This parameter supports wildcards and can accept multiple values.

.PARAMETER EmailAddress
Specifies the email address of the AD object to search for. This parameter supports wildcards and can accept multiple values.

.EXAMPLE
Get-ADUserEmailAddress -SamAccountName "john.doe"
Searches for the AD object with the SamAccountName "john.doe" and returns the object properties if found.

.EXAMPLE
Get-ADUserEmailAddress -EmailAddress "*@example.com"
Searches for the AD objects with email addresses ending with "@example.com" and returns the object properties if found.

.INPUTS
System.String

.OUTPUTS
System.Management.Automation.PSCustomObject

.NOTES
Author: Your Name
Date: Today's Date
Version: 1.0
#>

function Get-ADUserEmailAddress {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    param (
        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the AD object SamAccountName. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string[]]$SamAccountName,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the AD object EmailAddress. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string[]]$EmailAddress
    )
    BEGIN { }

    PROCESS {
        if ($SamAccountName) {
            if ($PSCmdlet.ShouldProcess("$($SamAccountName)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "SamAccountName -like '$($SamAccountName)' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }

        if ($EmailAddress) {
            if ($PSCmdlet.ShouldProcess("$($EmailAddress)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter " EmailAddress -like '$EmailAddress' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }
    }
}
