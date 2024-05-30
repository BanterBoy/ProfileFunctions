Function Get-ADPasswordReminderUsers {
	<#
	.SYNOPSIS
		Retrieves a list of Active Directory users whose passwords are about to expire.

	.DESCRIPTION
		The Get-ADPasswordReminderUsers function retrieves a list of Active Directory users whose passwords are about to expire. It calculates the number of days remaining until password expiration and provides information about the user, such as name, SamAccountName, email address, password set date, and creation date.

	.PARAMETER DaysToWarn
		Specifies the number of days before password expiration to issue a warning. Default is 3 days.

	.PARAMETER SearchBase
		Specifies the distinguished name (DN) of the organizational unit (OU) to search for users. Default is the distinguished name of the current domain.

	.EXAMPLE
		PS C:\> Get-ADPasswordReminderUsers

	.OUTPUTS
		System.String

	.NOTES
		This function requires the ActiveDirectory module to be imported.

	#>
	[CmdletBinding(DefaultParameterSetName = 'Default')]
	[OutputType([string], ParameterSetName = 'Default')]
	Param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the distinguished name for the OU you would like to target.')]
		[Alias('sb')]
		[string]$SearchBase = (Get-ADDomain).DistinguishedName,

		[Parameter(ParameterSetName = 'Individual',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the SamAccountName you would like to target.')]
		[Alias('sam')]
		[string]$SamAccountName
	)
	BEGIN {
	}
	PROCESS {
		Import-Module ActiveDirectory
		$negativedays = -3
		if ($SamAccountName) {
			$users = Get-ADUser -Identity $SamAccountName -properties *
		}
		else {
			# $users = Get-ADUser -SearchBase $SearchBase -Filter { (enabled -eq $true) -and (passwordNeverExpires -eq $false) } -properties *
			$Users = Get-ADUser -Filter { mail -ne '$null' } -SearchBase $SearchBase -Properties * | Where-Object { ($_.passwordneverexpires -ne $true) -and ($_.enabled -eq $true) -and ($_.passwordlastset) }
		}

		### PURGING this option; seems to cause issue. # $users = $users | Where-Object {$_.DistinguishedName -notmatch $ExcludeList}
		$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

		# Process Each User for Password Expiry
		foreach ($user in $users) {
			$dName = $user.displayName
			$sName = $user.sAMAccountName
			$emailaddress = $User.UserPrincipalName
			$whencreated = $user.whencreated
			$passwordSetDate = $user.PasswordLastSet
			$employeeID = $user.employeeID

			$PasswordPol = (Get-AduserResultantPasswordPolicy $user)
			# Check for Fine Grained Password
			if ($null -ne ($PasswordPol)) {
				$maxPasswordAge = ($PasswordPol).MaxPasswordAge
			}
			else {
				# No FGPP set to Domain Default
				$maxPasswordAge = $DefaultmaxPasswordAge
			}
			$expiresOn = $passwordsetdate + $maxPasswordAge
			$today = (get-date)
			if ( ($user.passwordexpired -eq $false) -and ($maxPasswordAge -ne 0) ) {
				#not Expired and not PasswordNeverExpires
				$daystoexpire = (New-TimeSpan -Start $today -End $expiresOn).Days
				$expirydayint = (New-TimeSpan -Start $today -End $expiresOn).Days
			}
			elseif ( ($user.passwordexpired -eq $true) -and ($null -ne $passwordSetDate) -and ($maxPasswordAge -ne 0) ) {
				#if expired and passwordSetDate exists and not PasswordNeverExpires
				# i.e. already expired
				$daystoexpire = - ((New-TimeSpan -Start $expiresOn -End $today).Days)
			}
			else {
				# i.e. (passwordSetDate = never) OR (maxPasswordAge = 0)
				$daystoexpire = "NA"
				#continue #"continue" would skip user, but bypass any non-expiry logging
			}
			# Set verbiage based on Number of Days to Expiry.
			Switch ($daystoexpire) {
				{ $_ -ge $negativedays -and $_ -le "-1" } { $messageDays = "has expired" }
				"0" { $messageDays = "will expire today" }
				"1" { $messageDays = "will expire in 1 day" }
				default { $messageDays = "will expire in " + "$daystoexpire" + " days" }
			}
			If ($daysToExpire -eq 0) {
				[string]$daysToExpire = "Today"
			}
			$properties = [ordered]@{
				'Name'            = $dName
				'SamAccountName'  = $sName
				'employeeID'      = $employeeID
				'EmailAddress'    = $emailaddress
				'passwordSetDate' = $passwordSetDate
				'WhenCreated'     = $whencreated
				'messageDays'     = $messageDays
				'daystoexpire'    = $expirydayint
			}
			$obj = New-Object -TypeName PSObject -Property $properties
			Write-Output $obj
		}
	}
	End {
	}
}
