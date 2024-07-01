<#
.SYNOPSIS
    Retrieves Active Directory user account details based on different parameters.

.DESCRIPTION
    The Get-ADUserAccount function retrieves Active Directory user account details based on the provided parameters. 
    It supports searching by SamAccountName, Surname, and GivenName. The function can also filter results based on 
    whether the account is enabled or disabled. Additionally, it provides the option to retrieve only password-related 
    details for the user accounts.

.PARAMETER SamAccountName
    Specifies the logon account detail of the users. This parameter accepts wildcards and is used to filter user accounts 
    based on the SamAccountName property.

.PARAMETER Surname
    Specifies the surname of the users. This parameter accepts wildcards and is used to filter user accounts based on the 
    Surname property.

.PARAMETER GivenName
    Specifies the given name of the users. This parameter accepts wildcards and is used to filter user accounts based on the 
    GivenName property.

.PARAMETER PasswordDetailsOnly
    Specifies whether to retrieve only password-related details for the user accounts. If this switch is used, the function 
    will only return the Name, SamAccountName, Enabled, PasswordNeverExpires, PasswordLastSet, and AccountExpirationDate 
    properties.

.PARAMETER IsEnabled
    Specifies whether to retrieve only enabled user accounts. If this switch is used, the function will only return user 
    accounts that are enabled.

.OUTPUTS
    System.String
    The function outputs a string representing the user account details. The properties included in the output can vary 
    depending on the parameters used.

.EXAMPLE
    Get-ADUserAccount -SamAccountName "john.doe"
    Retrieves the user account details for the user with the SamAccountName "john.doe".

.EXAMPLE
    Get-ADUserAccount -Surname "Doe" -IsEnabled
    Retrieves the enabled user account details for all users with the surname "Doe".

.EXAMPLE
    Get-ADUserAccount -GivenName "John" -PasswordDetailsOnly
    Retrieves only the password-related details for all users with the given name "John".

#>
function Get-ADUserAccount {
    [CmdletBinding(DefaultParameterSetName = 'Default',
        SupportsShouldProcess = $true)]
    [OutputType([string])]
    param
    (
        [Parameter(ParameterSetName = 'Identity',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the Users logon account detail. This will likely be the same as the EmployeeID. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string[]]$SamAccountName,

        [Parameter(ParameterSetName = 'Surname',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the Users Surname. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string[]]$Surname,
        
        [Parameter(ParameterSetName = 'GivenName',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Enter the Users GivenName. This will return all accounts that match the entered value. Wildcards are supported.')]
        [SupportsWildcards()]
        [ValidateNotNullOrEmpty()]
        [string[]]$GivenName,

        [Parameter()]
        [switch]$PasswordDetailsOnly,

        [Parameter()]
        [switch]$IsEnabled
    )
    
    BEGIN { }
    
    PROCESS {
        if ($PasswordDetailsOnly) {
            $propertiesToSelect = 'Name', 'SamAccountName', 'Enabled', 'PasswordNeverExpires', 'PasswordLastSet', 'AccountExpirationDate'
        }
        else {
            $propertiesToSelect = 'Name', 'SamAccountName', 'GivenName', 'Surname', 'DisplayName', 'EmployeeID', 'Description', 'Title', 'Company', 'Department', 'departmentNumber', 'Office', 'physicalDeliveryOfficeName', 'StreetAddress', 'City', 'State', 'Country', 'PostalCode', 'extensionAttribute*', 'Manager', 'distinguishedName', 'HomePhone', 'OfficePhone', 'MobilePhone', 'Fax', 'mail', 'mailNickname', 'EmailAddress', 'UserPrincipalName', 'proxyAddresses', 'HomePage', 'ProfilePath', 'HomeDirectory', 'HomeDrive', 'ScriptPath', 'AccountExpirationDate', 'PasswordNeverExpires', 'Enabled', 'CannotChangePassword', 'ChangePasswordAtLogon', 'PasswordNotRequired', 'PasswordLastSet', 'LastLogonDate', 'LastBadPasswordAttempt', 'whenChanged', 'whenCreated', 'directReports', 'MemberOf'
        }

        # Add password age to the properties to select
        $propertiesToSelect += @{Name = 'PasswordAge'; Expression = { if ($_.PasswordLastSet) { ((Get-Date) - $_.PasswordLastSet).Days } } }

        if ($SamAccountName) {
            if ($PSCmdlet.ShouldProcess("$($SamAccountName)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "SamAccountName -like '$($SamAccountName)' -and Enabled -eq '$($IsEnabled.IsPresent)'" -Properties * | Select-Object -Property $propertiesToSelect
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }

        if ($Surname) {
            if ($PSCmdlet.ShouldProcess("$($Surname)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "Surname -like '$Surname' -and Enabled -eq '$($IsEnabled.IsPresent)'" -Properties * | Select-Object -Property $propertiesToSelect
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }

        if ($GivenName) {
            if ($PSCmdlet.ShouldProcess("$($GivenName)", "searching AD for user details.")) {
                try {
                    Get-ADUser -Filter "GivenName -like '$GivenName' -and Enabled -eq '$($IsEnabled.IsPresent)'" -Properties * | Select-Object -Property $propertiesToSelect
                }
                catch {
                    Write-Error -Message "$_"
                }
            }
        }
    }
            
    END { }
}
