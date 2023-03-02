#--------------------
# Generic Profile Commands
#--------------------
Get-ChildItem C:\GitRepos\ProfileFunctions\ProfileFunctions\*.ps1 | ForEach-Object { . $_ }

#--------------------
# Set-ExecutionPolicy
# Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# basic greeting function, contents to be added to current function
Write-Output "Type Get-ProfileFunctions to see the available functions"
Write-Output ""
Show-IsAdminOrNot

#--------------------
# Aliases
New-Alias -Name 'Notepad++' -Value 'C:\Program Files\Notepad++\notepad++.exe' -Description 'Launch Notepad++'

#--------------------
# Configure PowerShell Console Window Size/Preferences
Set-ConsoleConfig -WindowHeight 35 -WindowWidth 140 | Out-Null

#--------------------
# Profile Starts here!
Write-Output ""
New-Greeting
Set-Location -Path C:\