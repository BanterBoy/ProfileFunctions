function Get-ADPasswordReminderUsers {
	<#
    .SYNOPSIS
        Retrieves a list of Active Directory users whose passwords are about to expire.

    .DESCRIPTION
        The Get-ADPasswordReminderUsers function retrieves a list of Active Directory users whose passwords are about to expire. It calculates the number of days remaining until password expiration and provides information about the user, such as name, SamAccountName, email address, password set date, creation date, and whether the password is set to never expire.

    .PARAMETER DaysToWarn
        Specifies the number of days before password expiration to issue a warning. Default is 3 days.

    .PARAMETER SearchBase
        Specifies the distinguished name (DN) of the organizational unit (OU) to search for users. Default is the distinguished name of the current domain.

    .PARAMETER SamAccountName
        Specifies the SamAccountName of a specific user to check.

    .PARAMETER IncludeNeverExpires
        Specifies whether to include users whose passwords are set to never expire.

    .EXAMPLE
        PS C:\> Get-ADPasswordReminderUsers -DaysToWarn 5

    .EXAMPLE
        PS C:\> Get-ADPasswordReminderUsers -IncludeNeverExpires

    .OUTPUTS
        System.Management.Automation.PSObject

    .NOTES
        This function requires the ActiveDirectory module to be imported.

    #>
	[CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	Param
	(
		[Parameter(ParameterSetName = 'Default',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the distinguished name for the OU you would like to target.')]
		[string]$SearchBase = (Get-ADDomain).DistinguishedName,

		[Parameter(ParameterSetName = 'Individual',
			Mandatory = $false,
			ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			HelpMessage = 'Enter the SamAccountName you would like to target.')]
		[string]$SamAccountName,

		[Parameter(Mandatory = $false, HelpMessage = 'Enter the number of days before password expiration to issue a warning.')]
		[int]$DaysToWarn = 14,

		[Parameter(Mandatory = $false, HelpMessage = 'Include users whose passwords are set to never expire.')]
		[switch]$IncludeNeverExpires
	)
	BEGIN {
		Import-Module ActiveDirectory -ErrorAction Stop
		Write-Verbose "ActiveDirectory module imported."
	}
	PROCESS {
		Write-Verbose "Days to warn: $DaysToWarn"

		if ($SamAccountName) {
			Write-Verbose "Retrieving user with SamAccountName: $SamAccountName"
			$users = Get-ADUser -Identity $SamAccountName -Properties *
		}
		else {
			Write-Verbose "Retrieving users from SearchBase: $SearchBase"
			$users = Get-ADUser -Filter "mail -like '*'" -SearchBase $SearchBase -Properties * |
			Where-Object { ($_.Enabled -eq $true) -and ($_.PasswordLastSet) }
		}

		$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
		Write-Verbose "Default maximum password age: $DefaultmaxPasswordAge"

		foreach ($user in $users) {
			if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Processing user")) {
				$dName = $user.DisplayName
				$sName = $user.SamAccountName
				$emailaddress = $user.UserPrincipalName
				$whencreated = $user.WhenCreated
				$passwordSetDate = $user.PasswordLastSet
				$employeeID = $user.EmployeeID
				$passwordNeverExpires = $user.PasswordNeverExpires

				$PasswordPol = Get-ADUserResultantPasswordPolicy -Identity $user

				if ($PasswordPol) {
					$maxPasswordAge = $PasswordPol.MaxPasswordAge
				}
				else {
					$maxPasswordAge = $DefaultmaxPasswordAge
				}

				$expiresOn = $passwordSetDate.Add($maxPasswordAge)
				$today = Get-Date
				$daystoexpire = "NA"
				$messageDays = "N/A"
				$includeUser = $false

				if ($passwordNeverExpires -eq $true) {
					$messageDays = "Password never expires"
					if ($IncludeNeverExpires) {
						$includeUser = $true
					}
				}
				elseif ($maxPasswordAge.Ticks -ne 0) {
					$daystoexpire = (New-TimeSpan -Start $today -End $expiresOn).Days
					if ($daystoexpire -le $DaysToWarn) {
						$includeUser = $true
						Switch ($daystoexpire) {
							{ $_ -le -1 } { $messageDays = "has expired" }
							0 { $messageDays = "will expire today" }
							1 { $messageDays = "will expire in 1 day" }
							default { $messageDays = "will expire in $daystoexpire days" }
						}
					}
				}

				if ($includeUser) {
					$properties = [ordered]@{
						'Name'                 = $dName
						'SamAccountName'       = $sName
						'EmployeeID'           = $employeeID
						'EmailAddress'         = $emailaddress
						'PasswordSetDate'      = $passwordSetDate
						'WhenCreated'          = $whencreated
						'MaxPasswordAge'       = $maxPasswordAge
						'ExpiresOn'            = $expiresOn
						'MessageDays'          = $messageDays
						'DaysToExpire'         = $daystoexpire
						'PasswordNeverExpires' = $passwordNeverExpires
						'ReasonForExpiryDays'  = "Password last set on $passwordSetDate with a maximum age of $maxPasswordAge."
					}

					$obj = [PSCustomObject]$properties
					Write-Output $obj
				}
			}
		}
	}
	END {
	}
}
