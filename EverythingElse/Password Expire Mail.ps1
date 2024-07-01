#========================================================================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================

# Set when users should get a warning...

# First time
$FirstPasswordWarningDays = 14

# Second time
$SecondPasswordWarningDays = 7

# Last time
$LastPasswordWarningDays = 3

# Set SMTP-server
$SMTPServer = "MySMTP.Contoso.Com"

# Get the password expires policy
$PasswordExpiresLength = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

# Calculating when passwords would have been set if they expire today
$CurrentPWChangeDateLimit = (Get-Date).AddDays(-$PasswordExpiresLength.Days)

# Calculating all dates
$FirstPasswordDateLimit = $CurrentPWChangeDateLimit.AddDays($FirstPasswordWarningDays)
$SecondPasswordDateLimit = $CurrentPWChangeDateLimit.AddDays($SecondPasswordWarningDays)
$LastPasswordDateLimit = $CurrentPWChangeDateLimit.AddDays($LastPasswordWarningDays)

# Load the users
$MailUsers = Get-ADUser -Filter "(Mail -like '*@*') -AND `
(	PasswordLastSet -le '$FirstPasswordDateLimit' -AND PasswordLastSet -gt '$($FirstPasswordDateLimit.AddDays(-1))' -OR `
	PasswordLastSet -le '$SecondPasswordDateLimit' -AND PasswordLastSet -gt '$($SecondPasswordDateLimit.AddDays(-1))' -OR `
	PasswordLastSet -le '$LastPasswordDateLimit' -AND PasswordLastSet -gt '$($LastPasswordDateLimit.AddDays(-1))') -AND `
(	PasswordNeverExpires -eq '$false' -AND Enabled -eq '$true')" -Properties PasswordLastSet, DisplayName, PasswordNeverExpires, mail

# Loop through them
foreach ($MailUser in $MailUsers) {

	# Count how many days are left before the password expires and round that number
	$PasswordExpiresInDays = [System.Math]::Round((New-TimeSpan -Start $CurrentPWChangeDateLimit -End ($MailUser.PasswordLastSet)).TotalDays)

	# Write some status...
	Write-Output "$($MailUser.DisplayName) needs to change password in $PasswordExpiresInDays days."

	# Build the body depending on where in the organisation the user is

	# Change MyOU1 to match your the OU you want your users are in.
	if ($MailUser.DistinguishedName -like "*MyOU1*") {
		$Subject = "Your password is expiring in $PasswordExpiresInDays days"
		$Body = "Hi $($MailUser.DisplayName),<BR><BR>Your password is expiring in $PasswordExpiresInDays days. Please change it now!<BR><BR>Don't forget to change it in your mobile devices if you are using mailsync.<BR><BR>Helpdesk 1"
		$EmailFrom = "Helpdesk 1 <no-reply@contoso.com>"
	}
	# Change MyOU2 to match your environment
	elseif ($MailUser.DistinguishedName -like "*MyOU2*") {
		$Subject = "Your password is expiring in $PasswordExpiresInDays days"
		$Body = "Hi $($MailUser.DisplayName),<BR><BR>Your password is expiring in $PasswordExpiresInDays days. Please change it now!<BR><BR>Don't forget to change it in your mobile devices if you are using mailsync.<BR><BR>Helpdesk 2"
		$EmailFrom = "Helpdesk 2 <no-reply@contoso.com>"
	}
	# This is the default e-mail
	else {
		$Subject = "Your password is expiring in $PasswordExpiresInDays days"
		$Body = "Hi $($MailUser.DisplayName),<BR><BR>Your password is expiring in $PasswordExpiresInDays days. Please change it now!<BR><BR>Don't forget to change it in your mobile devices if you are using mailsync.<BR><BR>Helpdesk 3"
		$EmailFrom = "Helpdesk 3 <no-reply@contoso.com>"
	}

	# Time to send the e-mail

	# The line below might need changing depending on what SMTP you are using (authentication or not)
	Send-MailMessage -Body $Body -From $EmailFrom -SmtpServer $SMTPServer -Subject $Subject -Encoding UTF8 -BodyAsHtml -To $MailUser.mail

	# E-mail is sent!
}