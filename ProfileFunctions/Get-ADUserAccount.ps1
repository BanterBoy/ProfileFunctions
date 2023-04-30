function Get-ADUserAccount {

	<#

	.SYNOPSIS
	Function to extract the User Details from Active Directory for a Carpetright Employee
	
	.DESCRIPTION
	This Function will search for a Carpetright Employee in Active Directory and output the information as an object.
	
	SamAccountName, GivenName, Surname, Initials, DisplayName, EmployeeID, EmployeeNumber, Description, Title, Company, Organization, Department, departmentNumber, Division, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, photo, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated
	
	.PARAMETER EmployeeID
	Enter the Users EmployeeID. Wildcards are supported.
	
	.PARAMETER SamAccountName
	Enter the Users logon account detail. This will likely be the same as the EmployeeID. Wildcards are supported.
	
	.PARAMETER Surname
	Enter the Users Surname. This will return all accounts that match the entered value. Wildcards are supported.
	
	.PARAMETER GivenName
	Enter the Users GivenName. This will return all accounts that match the entered value. Wildcards are supported.

	
	.EXAMPLE
	Get-ADUserAccount -EmployeeID [UniqueID]
	
	This example will search all of Active Directory for users that match the Unique EmployeeID.
	
	.EXAMPLE
	Get-ADUserAccount -Surname *eig* | Format-Table -AutoSize
		
	This example will search all of Active Directory for users that match the search parameter as no filter has been applied.
	
	.OUTPUTS
	System.String
	
	.NOTES
	Author:     Luke Leigh
	Website:    https://blog.lukeleigh.com/
	LinkedIn:   https://www.linkedin.com/in/lukeleigh/
	GitHub:     https://github.com/BanterBoy/
	GitHubGist: https://gist.github.com/BanterBoy
	
	.LINK
	https://github.com/BanterBoy

	#>
	
	[CmdletBinding(DefaultParameterSetName = 'Default',
		SupportsShouldProcess = $true)]
	[OutputType([string])]
	param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the Users EmployeeID. This will return all accounts that match the entered value. Wildcards are supported.')]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[Alias('EmpCode')]
		[string[]]$EmployeeID,

		[Parameter(ParameterSetName = 'Identity',
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the Users logon account detail. This will likely be the same as the EmployeeID. Wildcards are supported.')]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[Alias('sam')]
		[string[]]$SamAccountName,

		[Parameter(ParameterSetName = 'Surname',
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the Users Surname. This will return all accounts that match the entered value. Wildcards are supported.')]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[Alias('sn')]
		[string[]]$Surname,
		
		[Parameter(ParameterSetName = 'GivenName',
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the Users GivenName. This will return all accounts that match the entered value. Wildcards are supported.')]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[Alias('gn')]
		[string[]]$GivenName
	)
	
	BEGIN { }
	
	PROCESS {
		
		if ($EmployeeID) {
			if ($PSCmdlet.ShouldProcess("$($EmployeeID)", "searching AD for user details.")) {
				try {
					Get-ADUser -Filter "employeeID -like '$($EmployeeID)' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
				}
				catch {
					Write-Error -Message "$_"
				}
			}
		}
				
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
				
		if ($Surname) {
			if ($PSCmdlet.ShouldProcess("$($Surname)", "searching AD for user details.")) {
				try {
					Get-ADUser -Filter " Surname -like '$Surname' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
				}
				catch {
					Write-Error -Message "$_"
				}
			}
		}
				
		if ($GivenName) {
			if ($PSCmdlet.ShouldProcess("$($GivenName)", "searching AD for user details.")) {
				try {
					Get-ADUser -Filter " GivenName -like '$GivenName' " -Properties * | Select-Object -Property SamAccountName, GivenName, Surname, DisplayName, EmployeeID, Description, Title, Company, Department, departmentNumber, Office, physicalDeliveryOfficeName, StreetAddress, City, State, Country, PostalCode, extensionAttribute*, Manager, distinguishedName, HomePhone, OfficePhone, MobilePhone, Fax, mail, mailNickname, EmailAddress, UserPrincipalName, proxyAddresses, HomePage, ProfilePath, HomeDirectory, HomeDrive, ScriptPath, AccountExpirationDate, PasswordNeverExpires, Enabled, CannotChangePassword, ChangePasswordAtLogon, PasswordNotRequired, PasswordLastSet, LastLogonDate, LastBadPasswordAttempt, whenChanged, whenCreated, directReports, MemberOf
				}
				catch {
					Write-Error -Message "$_"
				}
			}
		}
				
	}
			
	END { }

}
