function Disable-ADUserAccount {

	<#
	
	.SYNOPSIS
	Disable-ADUserAccount will disable a Carpetright Active Directory User Account following the standard procedure.
	
	.DESCRIPTION
	The Disable-ADUserAccount funciton will disable a Carpetright Active Directory User Account using either the users SamAccountName or their EmployeeID. The internal process for disabling a user sets the users Enabled parameter to $false, moves the disabled account to the Disabled OU (OU=Disabled Accounts,DC=uk,DC=cruk,DC=net) and also removes the User Account from relevant groups.
	
	.PARAMETER EmployeeID
	Enter the Employee ID for the user you want to disable. The users account details are derived from this ID.
	
	.PARAMETER SamAccountName
	Enter the SamAccountName for the user you want to disable. The users account details are derived from this ID.
	
	.PARAMETER Initials
	Enter your Initials. This will be added to the Description Field.
	
	.EXAMPLE
	Disable-ADUserAccount -EmployeeID '12345678'
		
	User account with EmployeeID '12345678' will be disabled, moved to the disabled OU and also removed from groups.
	
	.EXAMPLE
	Disable-ADUserAccount -SamAccountName 'UserName'
		
	User account with SamAccountName 'UserName' will be disabled, moved to the disabled OU and also removed from groups.
	
	.OUTPUTS
	System.String
	
	.NOTES
	Author:     Luke Leigh
	Website:    https://blog.lukeleigh.com/
	LinkedIn:   https://www.linkedin.com/in/lukeleigh/
	GitHub:     https://github.com/BanterBoy/
	GitHubGist: https://gist.github.com/BanterBoy
	
	.INPUTS
	[string] SamAccountName
	[string] EmployeeID
	[string] Initials
	
	.LINK
	https://github.com/BanterBoy
	
	#>
	
	[CmdletBinding(DefaultParameterSetName = 'EmpID',
		PositionalBinding = $true,
		SupportsShouldProcess = $true)]
	[OutputType([string], ParameterSetName = 'EmpID')]
	[OutputType([string], ParameterSetName = 'SamID')]
	[OutputType([string])]
	param
	(
		[Parameter(ParameterSetName = 'EmpID',
			Mandatory = $true,
			ValueFromPipeline = $true,
			Position = 0,
			HelpMessage = 'Please enter a valid EmployeeID for the user that you wish to disable.')]
		[string]$EmployeeID,

		[Parameter(ParameterSetName = 'SamID',
			Mandatory = $true,
			ValueFromPipeline = $true,
			Position = 1,
			HelpMessage = 'Please enter a valid SamAccountName for the user that you wish to disable.')]
		[string]$SamAccountName,
		
		[Parameter(Mandatory = $true,
			ValueFromPipeline = $true,
			Position = 2,
			HelpMessage = 'Please enter your initials to complete this process.')]
		[string]$Initials
	)
	
	BEGIN {
		$TargetOU = "OU=Disabled Accounts,DC=uk,DC=cruk,DC=net"
		$Date = Get-Date
		$LeaverDescription = [DateTime]::ParseExact(($Date).ToShortDateString(), "dd/MM/yyyy", $null).ToString("yyyy MM dd") + " - Disabled by $($Initials)"
	}
	PROCESS {
		try {
			if ($EmployeeID) {
				if ($PSCmdlet.ShouldProcess("$EmployeeID", "Disabling User with EmployeeID")) {
					if (!(Test-EmployeeID -EmployeeID $EmployeeID)) {
						Write-Output "User with EmployeeID:$($EmployeeID) does not exist"
					}
					else {
						$User = Get-CarpetrightUser -EmployeeID $EmployeeID
						Write-Output "Disabling user account..."
						Set-ADUser -Identity "$($User.SamAccountName)" -Enabled $false
						Write-Output "Setting User Description..."
						Set-ADUser -Identity "$($User.SamAccountName)" -Description $LeaverDescription
						Write-Output "Removing user from Interact Group..."
						Remove-ADGroupMember -Identity "UK All Interact and Glo" -Members "$($User.SamAccountName)" -Confirm:$false
						Write-Output "Moving User account to Disabled Users..."
						Move-ADObject -Identity "$($User.DistinguishedName)" -TargetPath $TargetOU -Confirm:$false
						Write-Output "User $($User.SamAccountName),$($User.GivenName),$($User.Surname) has been disabled."
					}
				}
				
			}
			if ($SamAccountName) {
				if ($PSCmdlet.ShouldProcess("$SamAccountName", "Disabling User with SamAccountName")) {
					if (!(Test-SamAccountName -SamAccountName $SamAccountName)) {
						Write-Output "User with SamAccountName:$($SamAccountName) does not exist"
					}
					else {
						$User = Get-CarpetrightUser -SamAccountName $SamAccountName
						Write-Output "Disabling user account..."
						Set-ADUser -Identity "$($User.SamAccountName)" -Enabled $false
						Write-Output "Setting User Description..."
						Set-ADUser -Identity "$($User.SamAccountName)" -Description $LeaverDescription
						Write-Output "Removing user from Interact Group..."
						Remove-ADGroupMember -Identity "UK All Interact and Glo" -Members "$($User.SamAccountName)" -Confirm:$false
						Write-Output "Moving User account to Disabled Users..."
						Move-ADObject -Identity "$($User.DistinguishedName)" -TargetPath $TargetOU -Confirm:$false
						Write-Output "User $($User.SamAccountName),$($User.GivenName),$($User.Surname) has been disabled."
					}
				}
			}
		}
		catch {
			Write-Error -Message "$_"
		}
	}
	END {
		
	}
}
