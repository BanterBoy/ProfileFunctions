#--------------------
# Generic Profile Commands
#--------------------

Get-ChildItem C:\Users\bante\OneDrive\Documents\WindowsPowerShell\ProfileFunctions\*.ps1 | ForEach-Object {. $_ }

#--------------------
# Menu - KeyPresses
#--------------------
# Add required assemblies
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName PresentationCore
 
#--------------------
# Pause to be able to press and hold a key
Start-Sleep -Seconds 2

#--------------------
# Key list
$Nokey = [System.Windows.Input.Key]::None
$key1 = [System.Windows.Input.Key]::LeftCtrl
$key2 = [System.Windows.Input.Key]::LeftShift

#--------------------
# Key presses
$isCtrl = [System.Windows.Input.Keyboard]::IsKeyDown($key1)
$isShift = [System.Windows.Input.Keyboard]::IsKeyDown($key2)

# If no key is pressed, launch User Home Profile
if ($Nokey -eq 'None') {
	Write-Warning -Message "No key has been pressed - User Home Profile"
}

# If LeftCtrl key is pressed, launch User Work Profile
elseif ($isCtrl) {
	Write-Warning -Message "LeftCtrl key has been pressed - User Work Profile"
}

# If LeftShift key is pressed, start PowerShell without a Profile
elseif ($isShift) {
	Write-Warning -Message "LeftShift key has been pressed - PowerShell without a Profile"
	Start-Process "pwsh.exe" -ArgumentList "-NoNewWindow -noprofile"
}


#--------------------
# Profile Start
#--------------------
# Set-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

#--------------------
# Display running as Administrator in WindowTitle
$whoami = whoami /Groups /FO CSV | ConvertFrom-Csv -Delimiter ','
$MSAccount = $whoami."Group Name" | Where-Object { $_ -like 'MicrosoftAccount*' }
$LocalAccount = $whoami."Group Name" | Where-Object { $_ -like 'Local' }
if ((Test-IsAdmin) -eq $true) {
	if (($MSAccount)) {
		$host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - Admin Privileges"
	}
	else {
		$host.UI.RawUI.WindowTitle = "$($LocalAccount) - Admin Privileges"
	}
}	
else {
	if (($LocalAccount)) {
		$host.UI.RawUI.WindowTitle = "$($MSAccount.Split('\')[1]) - User Privileges"
	}
	else {
		$host.UI.RawUI.WindowTitle = "$($LocalAccount) - User Privileges"
	}
}	

#--------------------
# Configure PowerShell Console Window Size/Preferences
Format-Console -WindowHeight 45 -WindowWidth 170 -BufferHeight 9000 -BufferWidth 170

#--------------------
# Aliases
New-Alias -Name 'Notepad++' -Value 'C:\Program Files\Notepad++\notepad++.exe' -Description 'Launch Notepad++'

#--------------------
# Profile Starts here!
Show-IsAdminOrNot
Write-Host ""
New-Greeting
Write-Host ""
Set-Location -Path D:\GitRepos
