#--------------------
# Generic Profile Commands
#--------------------
Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\*.ps1 | ForEach-Object {. $_ }

#--------------------
# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#--------------------
# Display running as Administrator in WindowTitle
Set-DisplayIsAdmin

function Connect-Office365Services {
	& (Join-Path ($PROFILE).TrimEnd('Microsoft.PowerShell_profile.ps1') "\Connect-Office365Services.ps1")
}

# basic greeting function, contents to be added to current function
Write-Host "Type Get-ProfileFunctions to see the available functions"
Write-Host ""

#--------------------
# Configure PowerShell Console Window Size/Preferences
Set-ConsoleConfig -WindowHeight 45 -WindowWidth 180

#--------------------
# Aliases
New-Alias -Name 'Notepad++' -Value 'C:\Program Files\Notepad++\notepad++.exe' -Description 'Launch Notepad++'

#--------------------
# Profile Starts here!
$DaysLeft = (New-TimeSpan -Start (Get-Date) -End ((Get-Date).AddMonths("1").Date)).Days
$properties = [ordered]@{
	PayDay = (Get-PayDay).DayofWeek
	PayDate = (Get-PayDay).LongDate
	DaysLeft = $DaysLeft
}
if ($DaysLeft -gt ($DaysLeft / 3 * 2) ) {
	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Blue -NoNewline:$false
	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Blue
}
elseif ($DaysLeft -lt ($DaysLeft / 2) ) {
	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Gray -NoNewline:$false
	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Gray
}
else { 
	Write-Host "Next PayDay Date   : $($properties.PayDay) $($properties.PayDate)" -ForegroundColor Green -NoNewline:$false
	Write-Host "Days until Pay Day : $($DaysLeft) Days Left" -ForegroundColor Green
}
Write-Host ""
Show-IsAdminOrNot
Write-Host ""
New-Greeting
Write-Host ""
Set-Location -Path C:\
