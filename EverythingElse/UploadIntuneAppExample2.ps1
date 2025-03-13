New-IntuneWin32AppPackage -SourceFolder  "C:\Temp\1Password" -SetupFile "Invoke-AppDeployToolkit.exe" -OutputFolder "C:\Temp\IntuneWinFiles\"


$DetectionRule = New-IntuneWin32AppDetectionRuleRegistry -KeyPath "HKLM\SOFTWARE\InstalledApps\AgileBits, Inc._1Password_8.10.64" -Existence -DetectionType exists -Check32BitOn64System $false
	
Add-IntuneWin32App -FilePath "C:\Temp\IntuneWinFiles\1Password.intunewin" -DisplayName "1Password" -Description "Deploys 1Password via Intune using PSAppDeployToolkit v4" -Publisher "AgileBits, Inc." -InstallCommand "Invoke-AppDeployToolkit.exe -Silent" -UninstallCommand "Invoke-AppDeployToolkit.exe -Uninstall -Silent" -InstallExperience system -RestartBehavior suppress -DetectionRule $DetectionRule


HKLM\SOFTWARE\InstalledApps\AgileBits, Inc._1Password_8.10.64